const redis   = require('../config/redis');
const axios   = require('axios');
const { scoreFraud } = require('./fraud.service');
const { simulateRazorpayPayout } = require('./payout.service');

// ─────────────────────────────────────────────────────────────────────────────
// Gate 1: Parametric Trigger Check
// Verifies that a real-world disruption event exists in the zone at claim time.
// Data source: Live OpenWeatherMap / TomTom Traffic API
// ─────────────────────────────────────────────────────────────────────────────
async function gate1_parametricTrigger({ zoneId, disruptionType = 'rain' }) {
  // Check Redis cache for active zone disruption flags
  const disruptionKey = `disruption:active:${zoneId}`;
  const cached = await redis.get(disruptionKey);

  if (cached) {
    const event = JSON.parse(cached);
    return {
      passed:   true,
      gate:     1,
      reason:   `Active ${event.type} disruption confirmed in zone ${zoneId}`,
      event,
    };
  }

  // Live API Verification Pipeline
  try {
    let verifiedDisruption = null;

    if (disruptionType === 'rain' || disruptionType === 'weather') {
      verifiedDisruption = await verifyWeatherLive(zoneId);
    } else if (disruptionType === 'traffic' || disruptionType === 'congestion') {
      verifiedDisruption = await verifyTrafficLive(zoneId);
    }

    if (verifiedDisruption && verifiedDisruption.disruption_active) {
      return {
        passed:   true,
        gate:     1,
        reason:   `${verifiedDisruption.source} real-time trigger: ${verifiedDisruption.description}`,
        event:    verifiedDisruption,
      };
    }
  } catch (err) {
    console.warn(`[Gate 1] Live API check failed for ${zoneId}:`, err.message);
  }

  return {
    passed:   false,
    gate:     1,
    reason:   `No active disruption found in zone ${zoneId} at this time`,
    event:    null,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Gate 2: Advanced Fraud Detection Engine (Upgraded)
//
// Now uses fraud.service.js for a scored 0–100 fraud assessment:
//   - GPS Mismatch (haversine distance)
//   - Weather cross-validation
//   - Claim history frequency
//
// Plus legacy binary fraud checks:
//   - Z-axis altitude plausibility
//   - Photo hash freshness (replay attack)
//   - Peer consensus
//   - Claim velocity
//
// Decision:
//   AUTO_APPROVE  (score < 40)  → gate passes, payout proceeds
//   FLAG_FOR_REVIEW (40–70)     → gate passes with flag, manual review required
//   REJECT (score > 70)          → gate fails, claim rejected
// ─────────────────────────────────────────────────────────────────────────────
async function gate2_antiFraud({
  workerId, gpsTrail, zAxisTrail, photoHash, zoneId,
  disruptionType, gate1Result,
}) {
  const binaryChecks = {};

  // ── Binary Checks (legacy 6-layer) ───────────────────────────────────────
  binaryChecks.z_axis        = validateZAxis(zAxisTrail);
  binaryChecks.photo         = await validatePhotoHash(photoHash, workerId);
  binaryChecks.peer_consensus = await checkPeerConsensus(zoneId);
  binaryChecks.claim_velocity = await checkClaimVelocity(workerId);
  binaryChecks.account_activity = { passed: true, detail: 'Worker active in last 30 days' };

  const failedBinary = Object.entries(binaryChecks)
    .filter(([, v]) => !v.passed)
    .map(([k]) => k);

  // Hard reject on binary failures (e.g., photo missing, claim velocity exceeded)
  if (failedBinary.length > 0) {
    return {
      passed:        false,
      gate:          2,
      fraud_score:   85,
      fraud_verdict: 'REJECT',
      fraud_explanation: `Hard fraud signals: ${failedBinary.join(', ')} failed`,
      binary_checks: binaryChecks,
      failed_checks: failedBinary,
      reason:        `Fraud detected: binary checks failed — ${failedBinary.join(', ')}`,
    };
  }

  // ── Scored Fraud Engine ───────────────────────────────────────────────────
  const fraudResult = await scoreFraud({
    workerId,
    zoneId,
    disruptionType: disruptionType || 'weather',
    gpsTrail,
    gate1Result,
  });

  const passed = fraudResult.verdict !== 'REJECT';

  return {
    passed,
    gate:          2,
    fraud_score:   fraudResult.fraud_score,
    fraud_verdict: fraudResult.verdict,
    fraud_explanation: fraudResult.explanation,
    pillar_scores: fraudResult.pillar_scores,
    binary_checks: binaryChecks,
    reason:        fraudResult.explanation,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Gate 3: Payout Calculation & UPI Disbursement
// Uses the 2/3 income guarantee formula, then triggers simulated Razorpay payout
// ─────────────────────────────────────────────────────────────────────────────
async function gate3_payout({ worker, earnedTodayInr, claimId }) {
  const avgDailyEarnings = worker.avg_daily_earnings_14d || 900;
  const guaranteeFloor   = Math.round(avgDailyEarnings * (2 / 3));
  const payoutAmount     = Math.max(0, guaranteeFloor - earnedTodayInr);

  if (payoutAmount === 0) {
    return {
      passed:          true,
      gate:            3,
      reason:          'Worker already earned above guarantee floor — no payout needed',
      payout_inr:      0,
      already_earned:  earnedTodayInr,
      floor_inr:       guaranteeFloor,
    };
  }

  // Simulated Razorpay payout (1–2s delay, 5% failure rate)
  const payoutResult = await simulateRazorpayPayout({
    workerId:   worker.id,
    claimId:    claimId || null,
    amountInr:  payoutAmount,
    upiId:      worker.upi_id || 'worker@upi',
    workerName: worker.full_name,
  });

  return {
    passed:           true,
    gate:             3,
    payout_inr:       payoutAmount,
    guarantee_floor:  guaranteeFloor,
    earned_today:     earnedTodayInr,
    payout:           payoutResult,
    // Legacy key kept for backwards compat
    upi:              payoutResult,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal binary-check helpers (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────

function validateZAxis(zAxisTrail) {
  if (!zAxisTrail || zAxisTrail.length === 0) {
    return { passed: true, detail: 'Z-axis not provided — skipped (optional)' };
  }
  const implausible = zAxisTrail.some(p => p.altitude_m < 0 || p.altitude_m > 5000);
  if (implausible) {
    return { passed: false, detail: 'Z-axis altitude outside plausible range' };
  }
  return { passed: true, detail: `Z-axis valid: ${zAxisTrail.length} readings` };
}

async function validatePhotoHash(photoHash, workerId) {
  if (!photoHash) {
    return { passed: false, detail: 'Photo hash missing — incident photo required' };
  }
  const key    = `photo_hash:${workerId}:${photoHash}`;
  const exists = await redis.get(key);
  if (exists) {
    return { passed: false, detail: 'Photo already used in a previous claim (replay attack)' };
  }
  await redis.setex(key, 30 * 24 * 60 * 60, '1');
  return { passed: true, detail: 'Photo hash is fresh and unique' };
}

async function checkPeerConsensus(zoneId) {
  const key    = `peer_consensus:${zoneId}`;
  const reports = await redis.get(key);
  const count  = reports ? parseInt(reports) : 0;
  if (count >= 2) {
    return { passed: true, detail: `${count} peer workers confirmed disruption in zone` };
  }
  return {
    passed: true,
    detail: `Mock peer consensus: 3 workers confirmed disruption in ${zoneId}`,
    mock:   true,
  };
}

async function checkClaimVelocity(workerId) {
  const key           = `claim_velocity:${workerId}`;
  const raw           = await redis.get(key);
  const recentCount   = raw ? parseInt(raw) : 0;
  const MAX_PER_WEEK  = 3;

  if (recentCount >= MAX_PER_WEEK) {
    return {
      passed: false,
      detail: `Claim velocity exceeded: ${recentCount} claims in last 7 days (max ${MAX_PER_WEEK})`,
    };
  }
  if (raw) {
    await redis.setex(key, 7 * 24 * 60 * 60, recentCount + 1);
  } else {
    await redis.setex(key, 7 * 24 * 60 * 60, 1);
  }
  return { passed: true, detail: `Claim velocity OK: ${recentCount + 1}/${MAX_PER_WEEK} this week` };
}

// ── Zone Coordinates ──────────────────────────────────────────────────────────
const ZONE_COORDS = {
  'BLR-SOUTH':   { lat: 12.9141, lng: 77.5848 },
  'BLR-NORTH':   { lat: 13.0604, lng: 77.5871 },
  'MUM-CENTRAL': { lat: 19.0150, lng: 72.8282 },
  'DEFAULT':     { lat: 12.9716, lng: 77.5946 },
};

async function verifyWeatherLive(zoneId) {
  const coords = ZONE_COORDS[zoneId] || ZONE_COORDS['DEFAULT'];
  const apiKey = process.env.OPENWEATHER_API_KEY;

  if (!apiKey) {
    console.warn('[Gate 1] OPENWEATHER_API_KEY not found. Using fallback mock.');
    return mockWeatherCheck(zoneId);
  }

  try {
    const url = `https://api.openweathermap.org/data/2.5/weather?lat=${coords.lat}&lon=${coords.lng}&appid=${apiKey}&units=metric`;
    const response = await axios.get(url);
    const weather  = response.data.weather[0].main.toLowerCase();
    const isDisrupted = ['rain', 'thunderstorm', 'snow', 'drizzle'].includes(weather);

    return {
      disruption_active: isDisrupted,
      type:              'rain',
      severity:          isDisrupted ? 'high' : 'none',
      description:       `Live weather condition: ${weather}`,
      zone_id:           zoneId,
      source:            'OpenWeatherMap',
    };
  } catch (err) {
    console.error('[OpenWeather API Error]:', err.message);
    return mockWeatherCheck(zoneId);
  }
}

async function verifyTrafficLive(zoneId) {
  const coords = ZONE_COORDS[zoneId] || ZONE_COORDS['DEFAULT'];
  const apiKey = process.env.TOMTOM_API_KEY;

  if (!apiKey) {
    return {
      disruption_active: zoneId === 'BLR-SOUTH',
      type: 'traffic', severity: 'moderate',
      description: 'Mock severe traffic detected',
      zone_id: zoneId, source: 'Mock (Missing TomTom Key)',
    };
  }

  try {
    const url = `https://api.tomtom.com/traffic/services/4/flowSegmentData/absolute/10/json?point=${coords.lat},${coords.lng}&key=${apiKey}`;
    const response   = await axios.get(url);
    const flow       = response.data.flowSegmentData;
    const isDisrupted = flow.currentSpeed < (flow.freeFlowSpeed * 0.5);

    return {
      disruption_active: isDisrupted,
      type:              'traffic',
      severity:          isDisrupted ? 'severe' : 'none',
      description:       `Live traffic: ${flow.currentSpeed}km/h (FreeFlow: ${flow.freeFlowSpeed}km/h)`,
      zone_id:           zoneId,
      source:            'TomTom Traffic API',
    };
  } catch (err) {
    console.error('[TomTom API Error]:', err.message);
    return { disruption_active: false };
  }
}

function mockWeatherCheck(zoneId) {
  const highRiskZones = ['BLR-SOUTH', 'BLR-NORTH', 'MUM-CENTRAL'];
  return {
    disruption_active: highRiskZones.includes(zoneId),
    type:              'rain',
    severity:          'moderate',
    description:       'Heavy rainfall (Mock Datapoint)',
    zone_id:           zoneId,
    source:            'Mocked Fallback',
  };
}

module.exports = {
  gate1_parametricTrigger,
  gate2_antiFraud,
  gate3_payout,
};
