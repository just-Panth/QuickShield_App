const express   = require('express');
const router    = express.Router();
const { v4: uuidv4 } = require('uuid');
const supabase  = require('../config/supabase');
const authenticate = require('../middleware/authenticate');
const { fetchRiskScore, calculatePremium } = require('../services/premium.service');

router.use(authenticate);

// Plan definitions
const PLANS = {
  daily_income_shield: { label: 'Daily income shield', duration_days: 7 },
  monsoon_surge_cover: { label: 'Monsoon surge cover', duration_days: 7 },
  traffic_disruption:  { label: 'Traffic disruption cover', duration_days: 7 },
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/policy
// Returns all policies for the current worker
// ─────────────────────────────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  const { data: policies, error } = await supabase
    .from('policies')
    .select('*')
    .eq('worker_id', req.worker.id)
    .order('created_at', { ascending: false });

  if (error) return res.status(500).json({ error: 'Failed to fetch policies' });

  res.json({ policies });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/policy/:id
// Returns a single policy
// ─────────────────────────────────────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  const { data: policy, error } = await supabase
    .from('policies')
    .select('*')
    .eq('id', req.params.id)
    .eq('worker_id', req.worker.id)
    .single();

  if (error || !policy) {
    return res.status(404).json({ error: 'Policy not found' });
  }

  res.json({ policy });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/policy/purchase
// Body: { plan_type, duration_weeks }
// Creates a new policy after computing risk + premium
// ─────────────────────────────────────────────────────────────────────────────
router.post('/purchase', async (req, res) => {
  const { plan_type = 'daily_income_shield', duration_weeks = 1 } = req.body;
  const worker = req.worker;

  if (!PLANS[plan_type]) {
    return res.status(400).json({
      error: 'Invalid plan_type',
      valid_plans: Object.keys(PLANS),
    });
  }

  // Compute risk + premium
  const features = {
    zone_id:                worker.zone_id,
    platform:               worker.platform,
    city:                   worker.city,
    hour_of_day:            new Date().getHours(),
    day_of_week:            new Date().getDay(),
    days_active_last_30:    worker.days_active_last_30 || 20,
    avg_daily_earnings_14d: worker.avg_daily_earnings_14d || 900,
  };

  const riskScore  = await fetchRiskScore(features);
  const premiumInr = calculatePremium({
    riskScore,
    avgDailyEarnings14d: worker.avg_daily_earnings_14d || 900,
    durationWeeks: duration_weeks,
  });

  const now       = new Date();
  const expiresAt = new Date(now);
  expiresAt.setDate(expiresAt.getDate() + (duration_weeks * 7));

  const policyId = uuidv4();
  const { data: policy, error } = await supabase
    .from('policies')
    .insert([{
      id:           policyId,
      worker_id:    worker.id,
      plan_type,
      premium_inr:  premiumInr,
      risk_score:   riskScore,
      duration_weeks,
      status:       'active',
      started_at:   now.toISOString(),
      expires_at:   expiresAt.toISOString(),
    }])
    .select()
    .single();

  if (error) {
    console.error('[Policy] Insert error:', error);
    return res.status(500).json({ error: 'Failed to create policy' });
  }

  res.status(201).json({
    message: 'Policy purchased successfully',
    policy,
  });
});

module.exports = router;
