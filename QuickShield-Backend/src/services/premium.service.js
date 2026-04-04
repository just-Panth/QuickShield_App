const axios = require('axios');

// ── Risk level labels ─────────────────────────────────────────────────────
function getRiskLevel(score) {
  if (score >= 70) return 'High';
  if (score >= 40) return 'Medium';
  return 'Low';
}

// ── Secure Internal API Call (Calls ML Microservice) ──────────────────────
async function fetchRiskScore(features) {
  try {
    const mlServiceUrl = process.env.ML_SERVICE_URL || 'http://localhost:8000';
    
    const payload = {
      zone_id: features.zone_id || features.zone || 'DEFAULT',
      platform: features.platform || 'blinkit',
      city: features.city || 'Bangalore',
      hour_of_day: features.hour_of_day || new Date().getHours(),
      day_of_week: features.day_of_week || new Date().getDay(),
      days_active_last_30: features.days_active_last_30 || 20,
      avg_daily_earnings_14d: features.avg_daily_earnings_14d || 900.0
    };

    const response = await axios.post(`${mlServiceUrl}/score/risk`, payload);
    
    if (response.data && response.data.risk_score !== undefined) {
      return response.data.risk_score;
    }
    
    console.warn('[ML] Unexpected payload from ML service, using baseline 40.');
    return 40.0;
  } catch (err) {
    console.warn('[ML] Risk score API call failed, using fallback:', err.message);
    return 40.0;
  }
}

// ── Calculate premium from risk score (NODE.JS SIDE — ML only gives score) ──
// Formula: base = (avg_daily * 7 * 0.15) capped at tier limits
// Then adjusted by risk multiplier
function calculatePremium({ riskScore, avgDailyEarnings14d = 900, durationWeeks = 1 }) {
  const BASE_RATE        = 0.015;     // 1.5% of weekly earnings
  const weeklyEarnings   = avgDailyEarnings14d * 7;
  const basePremium      = weeklyEarnings * BASE_RATE * durationWeeks;

  // Risk multiplier: low=0.8, medium=1.0, high=1.3
  const riskMultiplier =
    riskScore >= 70 ? 1.3 :
    riskScore >= 40 ? 1.0 : 0.8;

  const premium = Math.round(basePremium * riskMultiplier);

  // Floor ₹50, ceiling ₹500 per week for affordability
  return Math.min(Math.max(premium, 50), 500);
}

// ── Payout calculation (2/3 formula) ─────────────────────────────────────
// guaranteeFloor = avg14DayEarnings * 2/3
// payout = guaranteeFloor - earnedToday (min 0)
function calculatePayout({ avgDailyEarnings14d, earnedTodayInr }) {
  const guaranteeFloor = Math.round(avgDailyEarnings14d * (2 / 3));
  const payout         = Math.max(0, guaranteeFloor - earnedTodayInr);
  return {
    guarantee_floor_inr:  guaranteeFloor,
    earned_today_inr:     earnedTodayInr,
    payout_inr:           payout,
  };
}

module.exports = {
  getRiskLevel,
  fetchRiskScore,
  calculatePremium,
  calculatePayout,
};
