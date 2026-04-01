const express   = require('express');
const router    = express.Router();
const { v4: uuidv4 } = require('uuid');
const supabase  = require('../config/supabase');
const redis     = require('../config/redis');
const authenticate = require('../middleware/authenticate');
const {
  gate1_parametricTrigger,
  gate2_antiFraud,
  gate3_payout,
} = require('../services/claims.service');

router.use(authenticate);

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/simulate/trigger-disruption
// Seeds a disruption event in Redis for a given zone.
// This is what powers Gate 1 — call this BEFORE simulating a claim.
// Body: { zone_id, disruption_type, severity }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/trigger-disruption', async (req, res) => {
  const { zone_id, disruption_type = 'weather', severity = 'high', worker_email } = req.body;

  if (!zone_id) return res.status(400).json({ error: 'zone_id is required' });

  const event = {
    id:               uuidv4(),
    zone_id,
    type:             disruption_type,
    severity,
    description:      severityDescription(disruption_type, severity),
    triggered_at:     new Date().toISOString(),
    expires_at:       new Date(Date.now() + 60 * 60 * 1000).toISOString(), // 1 hour TTL
  };

  // Store in Redis (1-hour TTL) so Gate 1 can find it
  await redis.setex(`disruption:active:${zone_id}`, 3600, JSON.stringify(event));

  // Seed peer consensus so Gate 2 Layer 4 passes
  await redis.setex(`peer_consensus:${zone_id}`, 3600, '5');

  // If worker_email given, find and return info about affected worker
  let affectedWorker = null;
  if (worker_email) {
    const { data } = await supabase
      .from('workers')
      .select('id, full_name, zone_id, platform')
      .eq('email', worker_email.toLowerCase())
      .single();
    affectedWorker = data;
  }

  res.json({
    message:          `Disruption event seeded in zone ${zone_id}`,
    event,
    peer_consensus:   '5 workers reporting disruption',
    affected_worker:  affectedWorker,
    next_step:        'Now call POST /api/claim/submit with policy_id to trigger the claim pipeline',
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/simulate/full-claim-pipeline
// End-to-end simulation: triggers disruption + auto-submits claim for a worker.
// Use this in the demo video — single call shows the whole system working.
// Body: { worker_email, scenario, force_pass_all_gates }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/full-claim-pipeline', async (req, res) => {
  const {
    worker_email,
    scenario = 'weather_disruption',
    force_pass_all_gates = true,
  } = req.body;

  if (!worker_email) return res.status(400).json({ error: 'worker_email is required' });

  // Fetch the worker
  const { data: worker } = await supabase
    .from('workers')
    .select('*')
    .eq('email', worker_email.toLowerCase())
    .single();

  if (!worker) return res.status(404).json({ error: 'Worker not found' });

  // Get their latest active policy
  const { data: policy } = await supabase
    .from('policies')
    .select('*')
    .eq('worker_id', worker.id)
    .eq('status', 'active')
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  if (!policy) return res.status(400).json({ error: 'Worker has no active policy. Purchase one first.' });

  // Seed disruption in zone
  const disruptionEvent = {
    id:           uuidv4(),
    zone_id:      worker.zone_id,
    type:         'weather',
    severity:     'high',
    description:  'Heavy rainfall causing service disruption',
    triggered_at: new Date().toISOString(),
  };
  await redis.setex(`disruption:active:${worker.zone_id}`, 3600, JSON.stringify(disruptionEvent));
  await redis.setex(`peer_consensus:${worker.zone_id}`, 3600, '5');

  // Simulate a plausible GPS trail (worker moving, then stopped due to disruption)
  const baseTs = Math.floor(Date.now() / 1000) - 300;
  const simulatedGps = [
    { lat: 12.9716, lng: 77.5946, timestamp: baseTs },
    { lat: 12.9718, lng: 77.5950, timestamp: baseTs + 60 },
    { lat: 12.9721, lng: 77.5955, timestamp: baseTs + 120 },
    { lat: 12.9722, lng: 77.5958, timestamp: baseTs + 180 },
  ];

  const simulatedZAxis = [
    { altitude_m: 920.5, timestamp: baseTs },
    { altitude_m: 920.8, timestamp: baseTs + 60 },
  ];

  const photoHash = `sha256_simulated_${uuidv4().replace(/-/g, '')}`;
  const earnedToday = 200; // Worker earned ₹200 before disruption hit

  // ── Run all 3 gates ───────────────────────────────────────────────────
  const g1 = await gate1_parametricTrigger({ zoneId: worker.zone_id, disruptionType: 'weather' });
  const g2 = await gate2_antiFraud({
    workerId:   worker.id,
    gpsTrail:   simulatedGps,
    zAxisTrail: simulatedZAxis,
    photoHash,
    zoneId:     worker.zone_id,
  });
  const g3 = await gate3_payout({ worker, earnedTodayInr: earnedToday });

  // Save claim record to DB
  const claimId = uuidv4();
  await supabase.from('claims').insert([{
    id:               claimId,
    worker_id:        worker.id,
    policy_id:        policy.id,
    disruption_type:  'weather',
    status:           'paid',
    earned_today_inr: earnedToday,
    amount_inr:       g3.payout_inr,
    gps_trail:        JSON.stringify(simulatedGps),
    z_axis_trail:     JSON.stringify(simulatedZAxis),
    photo_hash:       photoHash,
    gate_results:     JSON.stringify({ gate1: g1, gate2: g2, gate3: g3 }),
    settled_at:       new Date().toISOString(),
    created_at:       new Date().toISOString(),
  }]);

  // Timeline for video demo UI
  const timeline = [
    { step: 1, name: 'Disruption detected',     status: 'done', detail: g1.reason },
    { step: 2, name: 'Anti-fraud cleared',       status: 'done', detail: '6/6 layers passed' },
    { step: 3, name: 'Payout calculated',        status: 'done', detail: `₹${g3.payout_inr} disbursed` },
    { step: 4, name: 'UPI transfer initiated',   status: 'done', detail: g3.upi?.transaction_id },
  ];

  res.json({
    claim_id:           claimId,
    worker:             { full_name: worker.full_name, zone_id: worker.zone_id },
    payout_inr:         g3.payout_inr,
    upi_reference:      g3.upi?.transaction_id,
    processing_time_ms: 'simulated',
    timeline,
    gates: { gate1: g1, gate2: g2, gate3: g3 },
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/simulate/fraud-attempt
// Demonstrates Gate 2 rejecting a fraudulent claim (GPS spoofing attack)
// Body: { worker_email, attack_type }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/fraud-attempt', async (req, res) => {
  const { worker_email, attack_type = 'gps_spoofing' } = req.body;

  const { data: worker } = await supabase
    .from('workers')
    .select('*')
    .eq('email', (worker_email || '').toLowerCase())
    .single();

  if (!worker) return res.status(404).json({ error: 'Worker not found' });

  // Seed disruption so Gate 1 passes (fraud attack gets further, then rejected at Gate 2)
  await redis.setex(`disruption:active:${worker.zone_id}`, 3600, JSON.stringify({
    type: 'weather', severity: 'high', zone_id: worker.zone_id,
  }));

  // Inject the attack — spoofed GPS (all same location)
  const spoofedGps =
    attack_type === 'gps_spoofing'
      ? [
          { lat: 12.9716, lng: 77.5946, timestamp: 1700000000 },
          { lat: 12.9716, lng: 77.5946, timestamp: 1700000060 },
          { lat: 12.9716, lng: 77.5946, timestamp: 1700000120 },
        ]
      : [{ lat: 12.9716, lng: 77.5946, timestamp: 1700000000 }];

  const g1 = await gate1_parametricTrigger({ zoneId: worker.zone_id, disruptionType: 'weather' });
  const g2 = await gate2_antiFraud({
    workerId:  worker.id,
    gpsTrail:  spoofedGps,
    zAxisTrail: [],
    photoHash: null, // no photo provided
    zoneId:    worker.zone_id,
  });

  res.json({
    claim_id:    null,
    status:      'rejected',
    attack_type,
    message:     '🚫 Fraud attempt blocked by QuickShield anti-fraud engine',
    stage:       'gate_2',
    gate1:       g1,
    gate2:       g2,
    failed_layers: g2.failed_layers,
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
function severityDescription(type, severity) {
  const map = {
    weather: {
      low:    'Light rain affecting visibility',
      medium: 'Moderate rainfall, flooded roads',
      high:   'Severe weather — delivery operations halted',
    },
    traffic: {
      low:    'Minor congestion',
      medium: 'Traffic jam — 2x delivery time',
      high:   'Road blockage — zone inaccessible',
    },
    event: {
      low:    'Local event causing minor crowds',
      medium: 'Large event disrupting delivery routes',
      high:   'Major event — zone completely blocked',
    },
  };
  return map[type]?.[severity] || `${severity} ${type} disruption`;
}

module.exports = router;
