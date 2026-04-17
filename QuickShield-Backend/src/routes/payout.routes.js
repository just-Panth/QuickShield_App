const express  = require('express');
const router   = express.Router();
const supabase = require('../config/supabase');
const authenticate    = require('../middleware/authenticate');
const { getPayoutHistory, getPayoutByTxn } = require('../services/payout.service');

// All payout routes require auth
router.use(authenticate);

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/payout/history
// Returns the worker's full payout ledger (most recent first)
// ─────────────────────────────────────────────────────────────────────────────
router.get('/history', async (req, res) => {
  const payouts = await getPayoutHistory(req.worker.id);

  const totalPaid = payouts
    .filter(p => p.status === 'success')
    .reduce((s, p) => s + (p.amount_inr || 0), 0);

  res.json({
    total_paid_inr: totalPaid,
    count:          payouts.length,
    payouts,
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/payout/status/:txn_id
// Returns the status of a specific payout transaction
// ─────────────────────────────────────────────────────────────────────────────
router.get('/status/:txn_id', async (req, res) => {
  const payout = await getPayoutByTxn(req.params.txn_id);

  if (!payout) {
    return res.status(404).json({
      error:  'Transaction not found',
      txn_id: req.params.txn_id,
    });
  }

  // Security: workers can only see their own payouts
  if (payout.worker_id !== req.worker.id) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  res.json({
    txn_id:     payout.txn_id,
    status:     payout.status.toUpperCase(),
    amount_inr: payout.amount_inr,
    upi_id:     payout.upi_id,
    gateway:    payout.gateway,
    paid_at:    payout.paid_at,
    error_msg:  payout.error_msg,
  });
});

module.exports = router;
