const express   = require('express');
const router    = express.Router();
const supabase  = require('../config/supabase');
const redis     = require('../config/redis');
const authenticate = require('../middleware/authenticate');
const { getRiskLevel } = require('../services/premium.service');

// All dashboard routes require auth
router.use(authenticate);

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/dashboard
// Returns everything the Flutter dashboard screen needs in one call
// ─────────────────────────────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  const workerId = req.worker.id;

  // Fetch in parallel: policies, claims, earnings ledger
  const [policiesRes, claimsRes, ledgerRes] = await Promise.all([
    supabase
      .from('policies')
      .select('*')
      .eq('worker_id', workerId)
      .eq('status', 'active'),

    supabase
      .from('claims')
      .select('id, amount_inr, status, created_at, disruption_type')
      .eq('worker_id', workerId)
      .order('created_at', { ascending: false })
      .limit(5),

    supabase
      .from('earnings_ledger')
      .select('date, amount_inr')
      .eq('worker_id', workerId)
      .order('date', { ascending: false })
      .limit(14),
  ]);

  const policies       = policiesRes.data  || [];
  const recentClaims   = claimsRes.data    || [];
  const ledgerEntries  = ledgerRes.data    || [];

  // ── Compute stats ──────────────────────────────────────────────────────
  const totalPaid = recentClaims
    .filter(c => c.status === 'paid')
    .reduce((sum, c) => sum + (c.amount_inr || 0), 0);

  const avg14DayEarnings = ledgerEntries.length > 0
    ? Math.round(ledgerEntries.reduce((s, e) => s + e.amount_inr, 0) / ledgerEntries.length)
    : 0;

  // ── Zone risk distribution (from Redis cache or default) ──────────────
  let zoneRisk;
  try {
    const cached = await redis.get(`zone_risk:${req.worker.zone_id}`);
    zoneRisk = cached ? JSON.parse(cached) : defaultZoneRisk();
  } catch {
    zoneRisk = defaultZoneRisk();
  }

  // ── Recent activity feed ───────────────────────────────────────────────
  const activity = recentClaims.map(c => ({
    title:    activityTitle(c.status),
    subtitle: `${c.id.substring(0, 8).toUpperCase()} · ₹${c.amount_inr || '—'}`,
    time:     timeAgo(c.created_at),
    type:     c.status === 'paid' ? 'payment' : 'claim',
  }));

  res.json({
    worker: {
      full_name:             req.worker.full_name,
      zone_id:               req.worker.zone_id,
      platform:              req.worker.platform,
      avg_daily_earnings_14d: avg14DayEarnings,
    },
    stats: {
      protected_inr:    totalPaid,
      risk_level:       getRiskLevel(zoneRisk.score || 50),
      active_policies:  policies.length,
    },
    active_coverage: policies.map(p => ({
      policy_id:   p.id,
      plan_type:   p.plan_type,
      label:       planLabel(p.plan_type),
      premium_inr: p.premium_inr,
      period:      `₹${p.premium_inr}/week`,
      status:      p.status,
      expires_at:  p.expires_at,
    })),
    zone_risk: zoneRisk,
    recent_activity: activity,
    ledger: ledgerEntries,
  });
});

// ── Helpers ──────────────────────────────────────────────────────────────────

function defaultZoneRisk() {
  return { score: 45, low: 0.35, medium: 0.45, high: 0.20 };
}

function getRiskLevelFromScore(score) {
  if (score >= 70) return 'High';
  if (score >= 40) return 'Medium';
  return 'Low';
}

function planLabel(planType) {
  const labels = {
    daily_income_shield: 'Daily income shield',
    monsoon_surge_cover: 'Monsoon surge cover',
    traffic_disruption:  'Traffic disruption cover',
  };
  return labels[planType] || planType;
}

function activityTitle(status) {
  const map = {
    submitted:  'Claim submitted',
    verified:   'Claim verified',
    approved:   'Claim approved',
    paid:       'Payout received',
    rejected:   'Claim rejected',
  };
  return map[status] || 'Claim updated';
}

function timeAgo(isoString) {
  const diffMs  = Date.now() - new Date(isoString).getTime();
  const diffMin = Math.floor(diffMs / 60000);
  if (diffMin < 60)   return `${diffMin} min ago`;
  const diffHr = Math.floor(diffMin / 60);
  if (diffHr < 24)    return `${diffHr} hr ago`;
  return `${Math.floor(diffHr / 24)} day ago`;
}

module.exports = router;
