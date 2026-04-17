require('dotenv').config();
require('express-async-errors');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const authRoutes       = require('./routes/auth.routes');
const dashboardRoutes  = require('./routes/dashboard.routes');
const policyRoutes     = require('./routes/policy.routes');
const premiumRoutes    = require('./routes/premium.routes');
const claimRoutes      = require('./routes/claim.routes');
const simulateRoutes   = require('./routes/simulate.routes');
const payoutRoutes     = require('./routes/payout.routes');
const adminRoutes      = require('./routes/admin.routes');
const errorHandler     = require('./middleware/errorHandler');

const app = express();

// ── Security & utilities ───────────────────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// ── Rate limiter: max 200 req/15 min per IP ────────────────────────────────
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 200 }));

// ── Health check (unauthenticated) ────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status:    'ok',
    service:   'QuickShield Backend',
    version:   '2.0.0',
    features:  ['fraud-detection-v2', 'instant-payout', 'admin-dashboard'],
    timestamp: new Date().toISOString(),
  });
});

// ── API routes ────────────────────────────────────────────────────────────
app.use('/api/auth',      authRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/policy',    policyRoutes);
app.use('/api/premium',   premiumRoutes);
app.use('/api/claim',     claimRoutes);
app.use('/api/simulate',  simulateRoutes);
app.use('/api/payout',    payoutRoutes);
app.use('/api/admin',     adminRoutes);

// ── 404 catch ─────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found', path: req.path });
});

// ── Global error handler ──────────────────────────────────────────────────
app.use(errorHandler);

// ── Start server ──────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🛡️  QuickShield Backend v2.0 running on port ${PORT}`);
  console.log(`   Health:   http://localhost:${PORT}/health`);
  console.log(`   API:      http://localhost:${PORT}/api`);
  console.log(`   Admin:    http://localhost:${PORT}/api/admin/dashboard`);
  console.log(`   Payout:   http://localhost:${PORT}/api/payout/history\n`);
});

module.exports = app;
