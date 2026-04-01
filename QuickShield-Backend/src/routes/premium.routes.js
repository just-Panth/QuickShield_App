const express   = require('express');
const router    = express.Router();
const authenticate = require('../middleware/authenticate');
const { fetchRiskScore, calculatePremium, getRiskLevel } = require('../services/premium.service');

router.use(authenticate);

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/premium/calculate
// Body: { zone_id, platform, duration_weeks }
// Returns: { risk_score, risk_level, premium_inr, breakdown }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/calculate', async (req, res) => {
  const { zone_id, platform, duration_weeks = 1 } = req.body;
  const worker = req.worker;

  // Build feature vector for ML service
  const now = new Date();
  const features = {
    zone_id:                zone_id  || worker.zone_id,
    platform:               platform || worker.platform,
    city:                   worker.city,
    hour_of_day:            now.getHours(),
    day_of_week:            now.getDay(),
    days_active_last_30:    worker.days_active_last_30 || 20,
    avg_daily_earnings_14d: worker.avg_daily_earnings_14d || 900,
  };

  const riskScore  = await fetchRiskScore(features);
  const riskLevel  = getRiskLevel(riskScore);
  const premiumInr = calculatePremium({
    riskScore,
    avgDailyEarnings14d: worker.avg_daily_earnings_14d || 900,
    durationWeeks: duration_weeks,
  });

  res.json({
    risk_score:   riskScore,
    risk_level:   riskLevel,
    premium_inr:  premiumInr,
    duration_weeks,
    breakdown: {
      base_rate:        '1.5% of weekly earnings',
      risk_multiplier:  riskScore >= 70 ? 1.3 : riskScore >= 40 ? 1.0 : 0.8,
      avg_daily_inr:    worker.avg_daily_earnings_14d || 900,
      weekly_earnings:  (worker.avg_daily_earnings_14d || 900) * 7,
    },
  });
});

module.exports = router;
