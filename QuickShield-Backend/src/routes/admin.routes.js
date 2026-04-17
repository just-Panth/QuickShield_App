const express      = require('express');
const router       = express.Router();
const supabase     = require('../config/supabase');
const redis        = require('../config/redis');
const authenticate = require('../middleware/authenticate');
const requireAdmin = require('../middleware/requireAdmin');

// All admin routes are protected by both authenticate + requireAdmin
router.use(authenticate, requireAdmin);

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/admin/overview
// KPI dashboard: workers, policies, payouts, loss ratio, fraud blocked, zone risk
// ─────────────────────────────────────────────────────────────────────────────
router.get('/overview', async (req, res) => {
  // Fetch data in parallel for performance
  const [
    workersResult,
    activePoliciesResult,
    paidClaimsResult,
    allPoliciesResult,
    recentClaimsResult,
    rejectedClaimsResult,
  ] = await Promise.all([
    supabase.from('workers').select('id', { count: 'exact', head: true }),
    supabase.from('policies').select('id', { count: 'exact', head: true }).eq('status', 'active'),
    supabase.from('claims').select('amount_inr').eq('status', 'paid'),
    supabase.from('policies').select('premium_inr'),
    supabase
      .from('claims')
      .select('id, worker_id, disruption_type, status, amount_inr, created_at, workers(full_name, zone_id)')
      .order('created_at', { ascending: false })
      .limit(10),
    supabase.from('claims').select('id', { count: 'exact', head: true }).eq('status', 'rejected'),
  ]);

  // Loss Ratio
  const totalPaid    = (paidClaimsResult.data || []).reduce((s, c) => s + (c.amount_inr || 0), 0);
  const totalPremium = (allPoliciesResult.data || []).reduce((s, p) => s + (p.premium_inr || 0), 0);
  const lossRatio    = totalPremium > 0 ? +((totalPaid / totalPremium) * 100).toFixed(1) : 0;

  // This-week payout
  const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const { data: weeklyPaid } = await supabase
    .from('claims')
    .select('amount_inr')
    .eq('status', 'paid')
    .gte('created_at', oneWeekAgo);
  const payoutThisWeek = (weeklyPaid || []).reduce((s, c) => s + (c.amount_inr || 0), 0);

  // Zone risk map — derive from recent claims per zone
  const { data: zoneClaims } = await supabase
    .from('claims')
    .select('workers(zone_id), status')
    .gte('created_at', oneWeekAgo);

  const zoneRiskMap = {};
  (zoneClaims || []).forEach(c => {
    const z = c.workers?.zone_id || 'DEFAULT';
    if (!zoneRiskMap[z]) zoneRiskMap[z] = { total: 0, paid: 0 };
    zoneRiskMap[z].total++;
    if (c.status === 'paid') zoneRiskMap[z].paid++;
  });

  // Convert to risk score (0-100)
  const zoneRiskScores = {};
  Object.entries(zoneRiskMap).forEach(([zone, { total, paid }]) => {
    zoneRiskScores[zone] = total > 0 ? Math.round((paid / total) * 100) : 0;
  });
  // Fallback: always include known zones
  ['BLR-SOUTH', 'BLR-NORTH', 'MUM-CENTRAL', 'DEFAULT'].forEach(z => {
    if (!zoneRiskScores[z]) zoneRiskScores[z] = 0;
  });

  res.json({
    total_workers:          workersResult.count || 0,
    active_policies:        activePoliciesResult.count || 0,
    total_payout_inr:       totalPaid,
    payout_this_week_inr:   payoutThisWeek,
    loss_ratio:             lossRatio,
    fraud_blocked_count:    rejectedClaimsResult.count || 0,
    zone_risk_map:          zoneRiskScores,
    recent_claims:          recentClaimsResult.data || [],
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/admin/claims?status=all&limit=50&offset=0
// All claims across all workers (paginated, filterable by status)
// ─────────────────────────────────────────────────────────────────────────────
router.get('/claims', async (req, res) => {
  const { status = 'all', limit = 50, offset = 0 } = req.query;

  let query = supabase
    .from('claims')
    .select('id, disruption_type, status, amount_inr, earned_today_inr, created_at, settled_at, workers(id, full_name, zone_id, platform, email)')
    .order('created_at', { ascending: false })
    .range(Number(offset), Number(offset) + Number(limit) - 1);

  if (status !== 'all') {
    query = query.eq('status', status);
  }

  const { data, error, count } = await query;
  if (error) return res.status(500).json({ error: error.message });

  res.json({ claims: data || [], total: count || (data || []).length });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/admin/claims/:id
// Full audit trail for a single claim — includes gate_results breakdown
// ─────────────────────────────────────────────────────────────────────────────
router.get('/claims/:id', async (req, res) => {
  const { data, error } = await supabase
    .from('claims')
    .select('*, workers(id, full_name, zone_id, platform, email, phone, upi_id, avg_daily_earnings_14d)')
    .eq('id', req.params.id)
    .single();

  if (error || !data) return res.status(404).json({ error: 'Claim not found' });

  // Parse gate_results JSON if stored as string
  let gateResults = data.gate_results;
  if (typeof gateResults === 'string') {
    try { gateResults = JSON.parse(gateResults); } catch (_) {}
  }

  res.json({ claim: { ...data, gate_results: gateResults } });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/admin/claims/:id/approve
// Manual override — admin forces a claim to 'paid' status
// ─────────────────────────────────────────────────────────────────────────────
router.post('/claims/:id/approve', async (req, res) => {
  const { amount_inr, note } = req.body;

  // Fetch the claim first
  const { data: claim } = await supabase
    .from('claims')
    .select('*')
    .eq('id', req.params.id)
    .single();

  if (!claim) return res.status(404).json({ error: 'Claim not found' });

  const updatePayload = {
    status:       'paid',
    settled_at:   new Date().toISOString(),
  };
  if (amount_inr) updatePayload.amount_inr = amount_inr;

  const { data, error } = await supabase
    .from('claims')
    .update(updatePayload)
    .eq('id', req.params.id)
    .select()
    .single();

  if (error) return res.status(500).json({ error: 'Approval failed' });

  res.json({
    message:      `Claim ${req.params.id} manually approved by admin`,
    claim:        data,
    approved_by:  req.worker.email,
    note:         note || 'Manual admin override',
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/admin/workers
// All workers with active policy count and total claims paid
// ─────────────────────────────────────────────────────────────────────────────
router.get('/workers', async (req, res) => {
  const { search, zone } = req.query;

  let query = supabase
    .from('workers')
    .select('id, full_name, email, phone, zone_id, platform, city, role, is_active, onboarded_at, avg_daily_earnings_14d, upi_id');

  if (search) {
    query = query.or(`full_name.ilike.%${search}%,email.ilike.%${search}%`);
  }
  if (zone) {
    query = query.eq('zone_id', zone);
  }

  const { data: workers, error } = await query.order('onboarded_at', { ascending: false });
  if (error) return res.status(500).json({ error: error.message });

  // For each worker, get active policy count and total payout
  const workerIds = (workers || []).map(w => w.id);

  const [activePoliciesResult, paidClaimsResult] = await Promise.all([
    workerIds.length > 0
      ? supabase.from('policies').select('worker_id').eq('status', 'active').in('worker_id', workerIds)
      : Promise.resolve({ data: [] }),
    workerIds.length > 0
      ? supabase.from('claims').select('worker_id, amount_inr').eq('status', 'paid').in('worker_id', workerIds)
      : Promise.resolve({ data: [] }),
  ]);

  // Build lookup maps
  const policyCountMap  = {};
  const totalPayoutMap  = {};
  (activePoliciesResult.data || []).forEach(p => {
    policyCountMap[p.worker_id] = (policyCountMap[p.worker_id] || 0) + 1;
  });
  (paidClaimsResult.data || []).forEach(c => {
    totalPayoutMap[c.worker_id] = (totalPayoutMap[c.worker_id] || 0) + (c.amount_inr || 0);
  });

  const enriched = (workers || []).map(w => ({
    ...w,
    active_policies: policyCountMap[w.id] || 0,
    total_paid_inr:  totalPayoutMap[w.id]  || 0,
  }));

  res.json({ workers: enriched, total: enriched.length });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/admin/zones
// Active Redis disruption events across all zones with TTL
// ─────────────────────────────────────────────────────────────────────────────
router.get('/zones', async (req, res) => {
  const KNOWN_ZONES = ['BLR-SOUTH', 'BLR-NORTH', 'MUM-CENTRAL', 'DEFAULT'];

  const disruptions = await Promise.all(
    KNOWN_ZONES.map(async zone => {
      const key  = `disruption:active:${zone}`;
      const data = await redis.get(key);
      const ttl  = await redis.ttl(key);
      const peerKey    = `peer_consensus:${zone}`;
      const peerCount  = await redis.get(peerKey);

      return {
        zone_id:      zone,
        active:       !!data,
        event:        data ? JSON.parse(data) : null,
        ttl_seconds:  ttl > 0 ? ttl : null,
        expires_at:   ttl > 0 ? new Date(Date.now() + ttl * 1000).toISOString() : null,
        peer_reports: peerCount ? parseInt(peerCount) : 0,
      };
    })
  );

  res.json({
    zones:           disruptions,
    active_count:    disruptions.filter(d => d.active).length,
  });
});

module.exports = router;
