const supabase = require('../config/supabase');

// ─────────────────────────────────────────────────────────────────────────────
// QuickShield Instant Payout Service (Simulated)
//
// Simulates a Razorpay UPI payout:
//   - Generates realistic TXN ID
//   - Adds 1–2 second processing delay
//   - 5% simulated failure rate (for realism)
//   - Writes to payout_ledger on success
//   - Returns structured JSON matching real gateway shape
// ─────────────────────────────────────────────────────────────────────────────

const GATEWAY_NAME    = 'Razorpay (Simulated)';
const FAILURE_RATE    = 0.05;          // 5% failure rate
const MIN_DELAY_MS    = 1000;
const MAX_DELAY_MS    = 2000;

/**
 * Simulate a Razorpay UPI payout.
 * @param {object} params
 * @param {string} params.workerId
 * @param {string} params.claimId
 * @param {number} params.amountInr
 * @param {string} params.upiId       Worker's UPI ID (e.g. "rishi@upi")
 * @param {string} params.workerName
 * @returns {Promise<PayoutResult>}
 */
async function simulateRazorpayPayout({ workerId, claimId, amountInr, upiId, workerName }) {
  // ── Artificial processing delay ───────────────────────────────────────────
  const delayMs = MIN_DELAY_MS + Math.random() * (MAX_DELAY_MS - MIN_DELAY_MS);
  await sleep(delayMs);

  // ── Simulate gateway acceptance/failure ───────────────────────────────────
  const isFailure  = Math.random() < FAILURE_RATE;
  const txnId      = generateTxnId();
  const timestamp  = new Date().toISOString();

  // ── Build result ──────────────────────────────────────────────────────────
  const result = {
    txn_id:       txnId,
    status:       isFailure ? 'FAILED' : 'SUCCESS',
    amount_inr:   amountInr,
    upi_id:       upiId || 'worker@upi',
    gateway:      GATEWAY_NAME,
    timestamp,
    processing_ms: Math.round(delayMs),
    mock:          true,
  };

  if (isFailure) {
    result.error_code    = 'GATEWAY_TIMEOUT';
    result.error_message = 'Simulated gateway timeout — retry in 60 seconds';
    await writeLedger({ workerId, claimId, amountInr, upiId, txnId, status: 'failed', errorMsg: result.error_message });
    return result;
  }

  // ── Write successful payout to ledger ─────────────────────────────────────
  await writeLedger({ workerId, claimId, amountInr, upiId, txnId, status: 'success' });

  return result;
}

/**
 * Fetch the full payout history for a worker.
 * @param {string} workerId
 * @returns {Promise<Array>}
 */
async function getPayoutHistory(workerId) {
  const { data, error } = await supabase
    .from('payout_ledger')
    .select('*')
    .eq('worker_id', workerId)
    .order('paid_at', { ascending: false })
    .limit(20);

  if (error) {
    console.error('[Payout] Failed to fetch ledger:', error.message);
    return [];
  }
  return data || [];
}

/**
 * Look up a specific transaction by ID.
 * @param {string} txnId
 * @returns {Promise<object|null>}
 */
async function getPayoutByTxn(txnId) {
  const { data, error } = await supabase
    .from('payout_ledger')
    .select('*')
    .eq('txn_id', txnId)
    .single();

  if (error || !data) return null;
  return data;
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

async function writeLedger({ workerId, claimId, amountInr, upiId, txnId, status, errorMsg }) {
  try {
    await supabase.from('payout_ledger').insert([{
      claim_id:   claimId,
      worker_id:  workerId,
      amount_inr: amountInr,
      upi_id:     upiId || 'worker@upi',
      txn_id:     txnId,
      gateway:    'razorpay_mock',
      status,
      paid_at:    new Date().toISOString(),
      error_msg:  errorMsg || null,
    }]);
  } catch (err) {
    // Non-fatal — log and continue (claim is still processed)
    console.error('[Payout] Ledger write failed:', err.message);
  }
}

function generateTxnId() {
  const timestamp = Date.now();
  const random    = Math.random().toString(36).slice(2, 7).toUpperCase();
  return `TXN_QS_${timestamp}_${random}`;
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = {
  simulateRazorpayPayout,
  getPayoutHistory,
  getPayoutByTxn,
};
