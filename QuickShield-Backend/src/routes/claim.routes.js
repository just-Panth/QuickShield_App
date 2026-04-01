const express   = require('express');
const router    = express.Router();
const { v4: uuidv4 } = require('uuid');
const supabase  = require('../config/supabase');
const authenticate = require('../middleware/authenticate');
const {
  gate1_parametricTrigger,
  gate2_antiFraud,
  gate3_payout,
} = require('../services/claims.service');

router.use(authenticate);

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/claim
// Returns all claims for the worker with status breakdown summary
// ─────────────────────────────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  const { data: claims, error } = await supabase
    .from('claims')
    .select('*')
    .eq('worker_id', req.worker.id)
    .order('created_at', { ascending: false });

  if (error) return res.status(500).json({ error: 'Failed to fetch claims' });

  const totalInr   = claims.reduce((s, c) => s + (c.amount_inr || 0), 0);
  const paidInr    = claims.filter(c => c.status === 'paid').reduce((s, c) => s + (c.amount_inr || 0), 0);
  const pendingInr = totalInr - paidInr;

  // Map status to Flutter's 0-3 statusIndex
  const statusIndex = { submitted: 0, verified: 1, approved: 2, paid: 3, rejected: -1 };

  res.json({
    summary: { total_inr: totalInr, paid_inr: paidInr, pending_inr: pendingInr },
    claims: claims.map(c => ({
      ...c,
      status_index: statusIndex[c.status] ?? 0,
    })),
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/claim/:id
// Returns a single claim with full gate audit trail
// ─────────────────────────────────────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  const { data: claim, error } = await supabase
    .from('claims')
    .select('*')
    .eq('id', req.params.id)
    .eq('worker_id', req.worker.id)
    .single();

  if (error || !claim) {
    return res.status(404).json({ error: 'Claim not found' });
  }

  res.json({ claim });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/claim/submit
// Runs the full 3-Gate verification pipeline synchronously (for demo clarity)
// Body: {
//   policy_id, disruption_type,
//   gps_trail: [{lat, lng, timestamp}],
//   z_axis_trail: [{altitude_m, timestamp}],
//   photo_hash: "sha256...",
//   earned_today_inr: 200
// }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/submit', async (req, res) => {
  const {
    policy_id,
    disruption_type = 'weather',
    gps_trail,
    z_axis_trail,
    photo_hash,
    earned_today_inr = 0,
  } = req.body;

  const worker = req.worker;

  // Validate policy exists and belongs to worker
  const { data: policy, error: policyErr } = await supabase
    .from('policies')
    .select('*')
    .eq('id', policy_id)
    .eq('worker_id', worker.id)
    .eq('status', 'active')
    .single();

  if (policyErr || !policy) {
    return res.status(400).json({ error: 'Policy not found or not active' });
  }

  // Create claim record (status: submitted)
  const claimId = uuidv4();
  await supabase.from('claims').insert([{
    id:               claimId,
    worker_id:        worker.id,
    policy_id,
    disruption_type,
    status:           'submitted',
    earned_today_inr,
    gps_trail:        JSON.stringify(gps_trail),
    z_axis_trail:     JSON.stringify(z_axis_trail),
    photo_hash,
    gate_results:     JSON.stringify({}),
    amount_inr:       null,
    created_at:       new Date().toISOString(),
  }]);

  // ── Gate 1: Parametric Trigger ─────────────────────────────────────────
  const g1 = await gate1_parametricTrigger({
    zoneId:         worker.zone_id,
    disruptionType: disruption_type,
  });

  if (!g1.passed) {
    await updateClaimStatus(claimId, 'rejected', { gate1: g1 });
    return res.status(422).json({
      claim_id: claimId,
      status:   'rejected',
      stage:    'gate_1',
      reason:   g1.reason,
      gates:    { gate1: g1 },
    });
  }

  await updateClaimStatus(claimId, 'verified', { gate1: g1 });

  // ── Gate 2: Anti-Fraud Engine ──────────────────────────────────────────
  const g2 = await gate2_antiFraud({
    workerId:  worker.id,
    gpsTrail:  gps_trail,
    zAxisTrail: z_axis_trail,
    photoHash:  photo_hash,
    zoneId:    worker.zone_id,
  });

  if (!g2.passed) {
    await updateClaimStatus(claimId, 'rejected', { gate1: g1, gate2: g2 });
    return res.status(422).json({
      claim_id: claimId,
      status:   'rejected',
      stage:    'gate_2',
      reason:   g2.reason,
      gates:    { gate1: g1, gate2: g2 },
    });
  }

  await updateClaimStatus(claimId, 'approved', { gate1: g1, gate2: g2 });

  // ── Gate 3: Payout ────────────────────────────────────────────────────
  const g3 = await gate3_payout({ worker, earnedTodayInr: earned_today_inr });

  // Final: mark paid, store payout amount
  await supabase.from('claims').update({
    status:       'paid',
    amount_inr:   g3.payout_inr,
    gate_results: JSON.stringify({ gate1: g1, gate2: g2, gate3: g3 }),
    settled_at:   new Date().toISOString(),
  }).eq('id', claimId);

  res.status(201).json({
    claim_id:    claimId,
    status:      'paid',
    payout_inr:  g3.payout_inr,
    gates: {
      gate1: g1,
      gate2: g2,
      gate3: g3,
    },
    upi_reference: g3.upi?.transaction_id,
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────
async function updateClaimStatus(claimId, status, gateResults) {
  await supabase.from('claims').update({
    status,
    gate_results: JSON.stringify(gateResults),
  }).eq('id', claimId);
}

module.exports = router;
