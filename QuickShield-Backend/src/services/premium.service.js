const axios = require('axios');

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:8000';

// ── Risk level labels ─────────────────────────────────────────────────────
function getRiskLevel(score) {
  if (score >= 70) return 'High';
  if (score >= 40) return 'Medium';
  return 'Low';
}

// ── Call FastAPI ML service for risk score ────────────────────────────────
async function fetchRiskScore(features) {
  try {
    const { data } = await axios.post(`${ML_SERVICE_URL}/score/risk`, features, {
      timeout: 5000,
    });
    return data.risk_score;
  } catch (err) {
    console.warn('[ML] Risk score call failed, using fallback:', err.message);
    // Fallback mock score so the system still works even if ML service is down
    return mockRiskScore(features);
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

// ─────────────────────────────────────────────────────────────────────────────
// MOCK RISK SCORER — used as fallback when ML service is unavailable
// ─── TODO: REPLACE WITH REAL MODEL ──────────────────────────────────────────
// When the real XGBoost model (model.json) is loaded in FastAPI, this fallback
// will not be used in production — the ML service call above will succeed.
// ─────────────────────────────────────────────────────────────────────────────
function mockRiskScore(features) {
  let score = 40; // base

  // Hour-of-day risk (peak delivery hours = higher disruption risk)
  const hour = features.hour_of_day ?? new Date().getHours();
  if (hour >= 11 && hour <= 14) score += 15;
  if (hour >= 18 && hour <= 21) score += 20;

  // Zone-based adjustment
  const highRiskZones = ['BLR-NORTH', 'MUM-CENTRAL', 'DEL-EAST'];
  if (highRiskZones.includes(features.zone_id)) score += 15;

  // Platform adjustment (monsoon = Swiggy/Zomato higher)
  if (features.platform === 'swiggy' || features.platform === 'zomato') score += 5;

  // Worker tenure (fewer active days = higher risk)
  if ((features.days_active_last_30 ?? 20) < 10) score += 10;

  return Math.min(Math.max(score, 0), 100);
}

module.exports = {
  getRiskLevel,
  fetchRiskScore,
  calculatePremium,
  calculatePayout,
};
