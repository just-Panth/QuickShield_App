const fs = require('fs');
const readline = require('readline');
const path = require('path');

// ── Risk level labels ─────────────────────────────────────────────────────
function getRiskLevel(score) {
  if (score >= 70) return 'High';
  if (score >= 40) return 'Medium';
  return 'Low';
}

// In-memory cache for ultra-fast Risk Score lookups (loads 16MB CSV instantly on first hit)
let globalRiskCache = null;

async function buildRiskCache() {
  if (globalRiskCache) return globalRiskCache;
  globalRiskCache = new Map();
  
  try {
    const csvPath = path.join(__dirname, '../../../QuickShield_Store_Risk_Registry.csv');
    if (!fs.existsSync(csvPath)) {
      console.warn(`[ML Bypass Error]: Registry not found at ${csvPath}`);
      return globalRiskCache;
    }

    const fileStream = fs.createReadStream(csvPath);
    const rl = readline.createInterface({ input: fileStream, crlfDelay: Infinity });

    let headers = null;
    let riskIdx = -1;

    for await (const line of rl) {
      const cols = line.split(',');
      if (!headers) {
        headers = cols;
        riskIdx = headers.indexOf('Risk_Score');
        continue;
      }
      
      const storeId = cols[0];
      if (storeId && riskIdx !== -1) {
        const risk = parseFloat(cols[riskIdx]);
        if (!isNaN(risk)) {
          // Store the latest found risk score for the store
          globalRiskCache.set(storeId, risk); 
        }
      }
    }
    console.log(`[ML] Successfully cached ${globalRiskCache.size} store risk profiles from registry.`);
  } catch (err) {
    console.error('[ML Bypass Error]: Failed to parse CSV:', err.message);
  }
  
  return globalRiskCache;
}

// ── Secure Registry Lookup (Replaces mock child_process) ────────────────────────
async function fetchRiskScore(features) {
  try {
    const platform = features.platform || 'ZEP';
    const city = features.city || 'BLR';
    const storeId = `${city.substring(0, 3).toUpperCase()}_${platform.substring(0, 3).toUpperCase()}_001`;

    const cache = await buildRiskCache();
    
    if (cache.has(storeId)) {
      return cache.get(storeId);
    }
    
    console.warn(`[ML] Store ${storeId} not found in XGBoost registry. Using baseline 40.`);
    return 40.0;
  } catch (err) {
    console.warn('[ML] Risk score execution failed, using fallback:', err.message);
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
