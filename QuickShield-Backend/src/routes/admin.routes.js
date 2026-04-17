const express  = require('express');
const router   = express.Router();
const supabase = require('../config/supabase');
const authenticate = require('../middleware/authenticate');

// ─────────────────────────────────────────────────────────────────────────────
// Admin middleware — gated by hardcoded admin email for demo
// In production: check worker.role === 'admin' from DB
// ─────────────────────────────────────────────────────────────────────────────
const ADMIN_EMAILS = [
  'admin@quickshield.io',
  'quickshield.admin@gmail.com',
];

async function requireAdmin(req, res, next) {
  const workerEmail = (req.worker.email || '').toLowerCase();
  if (!ADMIN_EMAILS.includes(workerEmail)) {
    return res.status(403).json({
      error: 'Admin access required',
      hint:  'Use an admin account to access this endpoint',
    });
  }
  next();
}

router.use(authenticate);
router.use(requireAdmin);

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/admin/dashboard
// Core KPI summary for the insurer dashboard
// ─────────────────────────────────────────────────────────────────────────────
router.get('/dashboard', async (req, res) => {
  const [claimsRes, workersRes, policiesRes, payoutsRes, premiumRes] = await Promise.all([
    supabase.from('claims').select('id, status, amount_inr, fraud_score, fraud_verdict, created_at'),
    supabase.from('workers').select('id, created_at'),
    supabase.from('policies').select('id, status, premium_inr'),
    supabase.from('payout_ledger').select('amount_inr, status'),
    supabase.from('policies').select('premium_inr').eq('status', 'active'),
  ]);

  const claims      = claimsRes.data   || [];
  const workers     = workersRes.data  || [];
  const policies    = policiesRes.data || [];
  const payouts     = payoutsRes.data  || [];
  const activePols  = premiumRes.data  || [];

  // ── Claim breakdown ───────────────────────────────────────────────────────
  const totalClaims    = claims.length;
  const approvedClaims = claims.filter(c => c.status === 'paid').length;
  const rejectedClaims = claims.filter(c => c.status === 'rejected').length;
  const reviewClaims   = claims.filter(c => c.status === 'review').length;
  const pendingClaims  = claims.filter(c => ['submitted', 'verified', 'approved'].includes(c.status)).length;

  // ── Fraud metrics ─────────────────────────────────────────────────────────
  const flaggedClaims   = claims.filter(c => c.fraud_verdict === 'FLAG_FOR_REVIEW').length;
  const rejectedByFraud = claims.filter(c => c.fraud_verdict === 'REJECT').length;
  const fraudDetectionRate = totalClaims > 0
    ? parseFloat(((flaggedClaims + rejectedByFraud) / totalClaims).toFixed(3))
    : 0;

  const avgFraudScore = totalClaims > 0
    ? Math.round(claims.reduce((s, c) => s + (c.fraud_score || 0), 0) / totalClaims)
    : 0;

  // ── Financials ────────────────────────────────────────────────────────────
  const totalPayoutInr = payouts
    .filter(p => p.status === 'success')
    .reduce((s, p) => s + (p.amount_inr || 0), 0);

  const totalPremiumCollectedInr = policies
    .reduce((s, p) => s + (p.premium_inr || 0), 0);

  const lossRatio = totalPremiumCollectedInr > 0
    ? parseFloat((totalPayoutInr / totalPremiumCollectedInr).toFixed(3))
    : 0;

  const activePolicies    = policies.filter(p => p.status === 'active').length;
  const weeklyPremiumPool = activePols.reduce((s, p) => s + (p.premium_inr || 0), 0);

  // ── Predictive analytics (deterministic model for demo) ───────────────────
  const prediction = predictNextWeekClaims({ claims, workers });

  // ── Recent claims (last 10 with fraud data) ───────────────────────────────
  const recentClaims = claims
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    .slice(0, 10)
    .map(c => ({
      id:              c.id.substring(0, 8).toUpperCase(),
      status:          c.status,
      amount_inr:      c.amount_inr,
      fraud_score:     c.fraud_score,
      fraud_verdict:   c.fraud_verdict,
      created_at:      c.created_at,
    }));

  res.json({
    snapshot_at: new Date().toISOString(),

    claims: {
      total:    totalClaims,
      approved: approvedClaims,
      rejected: rejectedClaims,
      review:   reviewClaims,
      pending:  pendingClaims,
    },

    fraud: {
      detection_rate:    fraudDetectionRate,
      flagged:           flaggedClaims,
      auto_rejected:     rejectedByFraud,
      avg_fraud_score:   avgFraudScore,
    },

    financials: {
      total_payout_inr:          totalPayoutInr,
      total_premium_collected:   totalPremiumCollectedInr,
      weekly_premium_pool:       weeklyPremiumPool,
      loss_ratio:                lossRatio,
    },

    workforce: {
      total_workers:   workers.length,
      active_policies: activePolicies,
    },

    prediction,
    recent_claims: recentClaims,
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/admin/claims
// All claims with fraud metadata, paginated
// ─────────────────────────────────────────────────────────────────────────────
router.get('/claims', async (req, res) => {
  const limit  = parseInt(req.query.limit)  || 50;
  const offset = parseInt(req.query.offset) || 0;
  const status = req.query.status;

  let query = supabase
    .from('claims')
    .select(`
      id, worker_id, policy_id, disruption_type, status,
      amount_inr, fraud_score, fraud_verdict, fraud_explanation,
      earned_today_inr, created_at, settled_at
    `)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (status) query = query.eq('status', status);

  const { data: claims, error } = await query;
  if (error) return res.status(500).json({ error: 'Failed to fetch claims' });

  res.json({
    claims:  claims || [],
    count:   (claims || []).length,
    offset,
    limit,
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/admin/workers
// All workers with policy + claim counts
// ─────────────────────────────────────────────────────────────────────────────
router.get('/workers', async (req, res) => {
  const { data: workers, error } = await supabase
    .from('workers')
    .select('id, full_name, email, platform, zone_id, avg_daily_earnings_14d, created_at')
    .order('created_at', { ascending: false });

  if (error) return res.status(500).json({ error: 'Failed to fetch workers' });
  res.json({ workers: workers || [], count: (workers || []).length });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/admin/analytics
// Extended analytics: trend data and predictions
// ─────────────────────────────────────────────────────────────────────────────
router.get('/analytics', async (req, res) => {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const { data: claims } = await supabase
    .from('claims')
    .select('id, status, amount_inr, fraud_score, created_at')
    .gte('created_at', thirtyDaysAgo)
    .order('created_at', { ascending: true });

  const claimsData = claims || [];

  // Daily claim count (last 14 days)
  const dailyBreakdown = buildDailyBreakdown(claimsData, 14);

  // fraud score distribution buckets
  const scoreDistribution = {
    low:    claimsData.filter(c => (c.fraud_score || 0) < 40).length,
    medium: claimsData.filter(c => (c.fraud_score || 0) >= 40 && (c.fraud_score || 0) <= 70).length,
    high:   claimsData.filter(c => (c.fraud_score || 0) > 70).length,
  };

  const prediction = predictNextWeekClaims({ claims: claimsData, workers: [] });

  res.json({
    period:              '30d',
    total_claims:        claimsData.length,
    daily_breakdown:     dailyBreakdown,
    score_distribution:  scoreDistribution,
    prediction,
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

function predictNextWeekClaims({ claims }) {
  if (!claims || claims.length === 0) {
    return {
      predicted_claims:       5,
      predicted_payout_inr:   8000,
      confidence:             0.40,
      based_on:               'Baseline estimate (insufficient data)',
    };
  }

  // Weeks of data we have
  const earliestClaim = new Date(claims[0].created_at);
  const weeksOfData   = Math.max(1, Math.ceil((Date.now() - earliestClaim.getTime()) / (7 * 24 * 60 * 60 * 1000)));

  const avgClaimsPerWeek = claims.length / weeksOfData;

  // Weather risk multiplier — monsoon season (June-Sep) = 1.4x
  const month = new Date().getMonth() + 1;
  const weatherMultiplier = (month >= 6 && month <= 9) ? 1.4 : 1.0;

  const predictedClaims = Math.round(avgClaimsPerWeek * weatherMultiplier);

  // Avg payout from paid claims
  const paidClaims = claims.filter(c => c.status === 'paid' && c.amount_inr > 0);
  const avgPayout  = paidClaims.length > 0
    ? Math.round(paidClaims.reduce((s, c) => s + c.amount_inr, 0) / paidClaims.length)
    : 1600;

  const confidence = Math.min(0.9, 0.4 + (weeksOfData * 0.05));

  return {
    predicted_claims:     Math.max(1, predictedClaims),
    predicted_payout_inr: Math.max(1, predictedClaims) * avgPayout,
    confidence:           parseFloat(confidence.toFixed(2)),
    avg_payout_per_claim: avgPayout,
    weather_multiplier:   weatherMultiplier,
    data_weeks:           weeksOfData,
    based_on:             `${weeksOfData}w rolling avg × weather factor (${weatherMultiplier}x)`,
  };
}

function buildDailyBreakdown(claims, days) {
  const result = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dateStr = d.toISOString().slice(0, 10);

    const daysClaims = claims.filter(c => c.created_at && c.created_at.startsWith(dateStr));

    result.push({
      date:       dateStr,
      total:      daysClaims.length,
      approved:   daysClaims.filter(c => c.status === 'paid').length,
      rejected:   daysClaims.filter(c => c.status === 'rejected').length,
      review:     daysClaims.filter(c => c.status === 'review').length,
      payout_inr: daysClaims.reduce((s, c) => s + (c.amount_inr || 0), 0),
    });
  }
  return result;
}

module.exports = router;
