const axios   = require('axios');
const supabase = require('../config/supabase');

// ─────────────────────────────────────────────────────────────────────────────
// QuickShield Fraud Detection Engine
//
// Scoring pillars (total: 0–100):
//   GPS Mismatch       — 0–40 pts  (haversine distance logic)
//   Weather Mismatch   — 0–30 pts  (OpenWeather cross-check)
//   Claim History      — 0–30 pts  (frequency in last 30 days)
//
// Decision:
//   < 40  → AUTO_APPROVE
//   40–70 → FLAG_FOR_REVIEW
//   > 70  → REJECT
// ─────────────────────────────────────────────────────────────────────────────

const ZONE_CENTERS = {
  'BLR-SOUTH':   { lat: 12.9141, lng: 77.5848 },
  'BLR-NORTH':   { lat: 13.0604, lng: 77.5871 },
  'MUM-CENTRAL': { lat: 19.0150, lng: 72.8282 },
  'DEL-CENTRAL': { lat: 28.6139, lng: 77.2090 },
  'HYD-CENTRAL': { lat: 17.3850, lng: 78.4867 },
  'DEFAULT':     { lat: 12.9716, lng: 77.5946 },
};

/**
 * Main entry point — scores a claim for fraud risk (0–100).
 * @param {object} params
 * @param {string} params.workerId
 * @param {string} params.zoneId
 * @param {string} params.disruptionType  e.g. 'weather' | 'traffic'
 * @param {Array}  params.gpsTrail        [{lat, lng, timestamp}]
 * @param {object} params.gate1Result     Result from Gate 1 (has disruption_active + type)
 * @returns {Promise<FraudResult>}
 */
async function scoreFraud({ workerId, zoneId, disruptionType, gpsTrail, gate1Result }) {
  const pillarScores = {};
  const explanations = [];

  // ── Pillar 1: GPS Mismatch (max 40 pts) ──────────────────────────────────
  const gpsResult = scoreGpsMismatch(gpsTrail, zoneId);
  pillarScores.gps = gpsResult;
  if (gpsResult.score > 0) {
    explanations.push(gpsResult.reason);
  }

  // ── Pillar 2: Weather Cross-Validation (max 30 pts) ──────────────────────
  const weatherResult = await scoreWeatherMismatch(disruptionType, gate1Result, zoneId);
  pillarScores.weather = weatherResult;
  if (weatherResult.score > 0) {
    explanations.push(weatherResult.reason);
  }

  // ── Pillar 3: Claim History Frequency (max 30 pts) ───────────────────────
  const historyResult = await scoreClaimHistory(workerId);
  pillarScores.history = historyResult;
  if (historyResult.score > 0) {
    explanations.push(historyResult.reason);
  }

  const totalScore = gpsResult.score + weatherResult.score + historyResult.score;
  const fraudScore = Math.min(100, Math.round(totalScore));

  const verdict = getVerdict(fraudScore);
  const explanation = buildExplanation(fraudScore, verdict, explanations, pillarScores);

  return {
    fraud_score:   fraudScore,
    verdict,       // AUTO_APPROVE | FLAG_FOR_REVIEW | REJECT
    explanation,
    pillar_scores: pillarScores,
    decision_basis: `Score ${fraudScore}/100 → ${verdict}`,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Pillar 1: GPS Mismatch — Haversine distance scoring
// If worker's average GPS position is too far from the declared zone center,
// it increases fraud probability.
// ─────────────────────────────────────────────────────────────────────────────
function scoreGpsMismatch(gpsTrail, zoneId) {
  if (!gpsTrail || gpsTrail.length === 0) {
    return {
      score:    20,
      reason:   'GPS trail missing — cannot verify worker location',
      distance_km: null,
    };
  }

  // Compute centroid of GPS trail
  const centroid = {
    lat: gpsTrail.reduce((s, p) => s + p.lat, 0) / gpsTrail.length,
    lng: gpsTrail.reduce((s, p) => s + p.lng, 0) / gpsTrail.length,
  };

  const zoneCenter = ZONE_CENTERS[zoneId] || ZONE_CENTERS['DEFAULT'];
  const distanceKm = haversineKm(centroid, zoneCenter);

  // Scoring: < 3km = 0, 3-8km = 10-25, 8-15km = 25-35, >15km = 40
  let score = 0;
  let reason = '';

  if (distanceKm < 3) {
    score  = 0;
    reason = `GPS match: worker ${distanceKm.toFixed(1)} km from zone center (valid)`;
  } else if (distanceKm < 8) {
    score  = Math.round(10 + ((distanceKm - 3) / 5) * 15);
    reason = `Moderate GPS offset: worker ${distanceKm.toFixed(1)} km from zone center`;
  } else if (distanceKm < 15) {
    score  = Math.round(25 + ((distanceKm - 8) / 7) * 10);
    reason = `High GPS offset: worker ${distanceKm.toFixed(1)} km from declared zone`;
  } else {
    score  = 40;
    reason = `GPS mismatch: worker ${distanceKm.toFixed(1)} km from zone (likely not in zone)`;
  }

  return { score, reason, distance_km: parseFloat(distanceKm.toFixed(2)) };
}

// ─────────────────────────────────────────────────────────────────────────────
// Pillar 2: Weather Cross-Validation — max 30 pts
// Worker claims "weather" disruption but gate1 found no bad weather → flag
// ─────────────────────────────────────────────────────────────────────────────
async function scoreWeatherMismatch(disruptionType, gate1Result, zoneId) {
  // Only penalise weather-type claims
  if (disruptionType !== 'weather' && disruptionType !== 'rain') {
    return {
      score:  0,
      reason: `Non-weather claim (${disruptionType}) — weather check skipped`,
    };
  }

  // Gate 1 result has information about whether disruption was confirmed
  if (gate1Result && gate1Result.passed && gate1Result.event) {
    const evt = gate1Result.event;
    const disruptionConfirmed = evt.disruption_active !== false;
    if (disruptionConfirmed) {
      return {
        score:  0,
        reason: `Weather disruption confirmed by ${evt.source || 'Gate 1'}: ${evt.description || 'active event'}`,
      };
    }
  }

  // Try a direct OpenWeather lookup as fallback
  const coords = ZONE_CENTERS[zoneId] || ZONE_CENTERS['DEFAULT'];
  const apiKey  = process.env.OPENWEATHER_API_KEY;

  if (apiKey) {
    try {
      const url = `https://api.openweathermap.org/data/2.5/weather?lat=${coords.lat}&lon=${coords.lng}&appid=${apiKey}&units=metric`;
      const resp = await axios.get(url, { timeout: 4000 });
      const condition = resp.data.weather[0].main.toLowerCase();
      const isBad = ['rain', 'thunderstorm', 'snow', 'drizzle'].includes(condition);

      if (isBad) {
        return {
          score:  0,
          reason: `Live weather confirms bad conditions: ${condition}`,
          weather_condition: condition,
        };
      } else {
        return {
          score:  25,
          reason: `Weather mismatch: live data shows "${condition}" but worker claims rain/weather disruption`,
          weather_condition: condition,
        };
      }
    } catch {
      // API failed — use gate1 result as authoritative
    }
  }

  // No weather API available and gate1 didn't confirm → moderate penalty
  if (!gate1Result || !gate1Result.passed) {
    return {
      score:  20,
      reason: 'Weather disruption not confirmed by Gate 1 parametric check',
    };
  }

  return { score: 0, reason: 'Weather status indeterminate — no penalty applied' };
}

// ─────────────────────────────────────────────────────────────────────────────
// Pillar 3: Claim History Frequency — max 30 pts
// Too many claims in the last 30 days increases fraud probability
// ─────────────────────────────────────────────────────────────────────────────
async function scoreClaimHistory(workerId) {
  try {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

    const { data: recentClaims, error } = await supabase
      .from('claims')
      .select('id, status, created_at')
      .eq('worker_id', workerId)
      .gte('created_at', thirtyDaysAgo)
      .neq('status', 'rejected');   // Only count non-fraudulent claims

    if (error) {
      return { score: 5, reason: 'Claim history unavailable — minor uncertainty penalty', count: null };
    }

    const count = recentClaims ? recentClaims.length : 0;

    // Scoring table
    if (count === 0) return { score: 0,  reason: 'Clean history: no recent claims in 30 days', count };
    if (count === 1) return { score: 0,  reason: 'First claim this month — normal frequency', count };
    if (count === 2) return { score: 10, reason: `${count} claims in 30 days — slightly elevated frequency`, count };
    if (count === 3) return { score: 20, reason: `${count} claims in 30 days — high claim frequency`, count };
    return { score: 30, reason: `${count} claims in 30 days — excessive frequency (fraud signal)`, count };

  } catch (err) {
    return { score: 5, reason: 'Could not fetch claim history', count: null };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decision + Explanation helpers
// ─────────────────────────────────────────────────────────────────────────────
function getVerdict(score) {
  if (score < 40)  return 'AUTO_APPROVE';
  if (score <= 70) return 'FLAG_FOR_REVIEW';
  return 'REJECT';
}

function buildExplanation(score, verdict, flaggedReasons, pillarScores) {
  if (verdict === 'AUTO_APPROVE') {
    const positives = [];
    if (pillarScores.gps.score === 0)     positives.push('GPS location verified');
    if (pillarScores.weather.score === 0) positives.push('weather disruption confirmed');
    if (pillarScores.history.score === 0) positives.push('clean claim history');
    return `Low fraud risk (score ${score}/100). ${positives.join(', ')}.`;
  }

  if (verdict === 'FLAG_FOR_REVIEW') {
    const reasons = flaggedReasons.length > 0
      ? flaggedReasons.join('; ')
      : 'Moderate anomaly signals detected';
    return `Flagged for review (score ${score}/100): ${reasons}.`;
  }

  // REJECT
  const reasons = flaggedReasons.length > 0
    ? flaggedReasons.join('; ')
    : 'Multiple fraud signals detected';
  return `Rejected (score ${score}/100): ${reasons}.`;
}

// ─────────────────────────────────────────────────────────────────────────────
// Haversine formula — distance between two lat/lng points in km
// ─────────────────────────────────────────────────────────────────────────────
function haversineKm(a, b) {
  const R   = 6371;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const sinLat = Math.sin(dLat / 2);
  const sinLng = Math.sin(dLng / 2);
  const chord = sinLat * sinLat +
    Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * sinLng * sinLng;
  return R * 2 * Math.atan2(Math.sqrt(chord), Math.sqrt(1 - chord));
}

function toRad(deg) {
  return deg * (Math.PI / 180);
}

module.exports = { scoreFraud, getVerdict, ZONE_CENTERS };
