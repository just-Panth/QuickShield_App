const express = require('express');
const router  = express.Router();
const { v4: uuidv4 } = require('uuid');
const supabase        = require('../config/supabase');
const { signToken }   = require('../config/jwt');
const authenticate    = require('../middleware/authenticate');
const { isAdminEmail } = require('../config/admins');

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/register
// Body: { email, phone, worker_platform_id, platform, city, zone_id, full_name }
// Returns: { token, worker }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  const { email, phone, worker_platform_id, platform, city, zone_id, full_name } = req.body;

  // Validate required fields
  if (!email || !phone || !worker_platform_id) {
    return res.status(400).json({ error: 'email, phone, and worker_platform_id are required' });
  }

  // Validate worker ID format (e.g. GW-1234567 or any non-empty string)
  if (worker_platform_id.length < 3) {
    return res.status(400).json({ error: 'worker_platform_id must be at least 3 characters' });
  }

  // Check for duplicate email
  const { data: existing } = await supabase
    .from('workers')
    .select('id')
    .eq('email', email.toLowerCase())
    .single();

  if (existing) {
    return res.status(409).json({ error: 'An account with this email already exists. Use /auth/login instead.' });
  }

  // Resolve zone from zone_id or default
  const resolvedZoneId = zone_id || 'DEFAULT';

  // Create worker record
  const workerId = uuidv4();
  const assignedRole = isAdminEmail(email) ? 'admin' : 'worker';
  const { data: worker, error } = await supabase
    .from('workers')
    .insert([{
      id:                  workerId,
      email:               email.toLowerCase(),
      phone,
      worker_platform_id,
      platform:            platform || 'blinkit',
      city:                city || 'Bangalore',
      zone_id:             resolvedZoneId,
      full_name:           full_name || 'Worker',
      is_active:           true,
      role:                assignedRole,
      onboarded_at:        new Date().toISOString(),
    }])
    .select()
    .single();

  if (error) {
    console.error('[Register] DB insert error:', error);
    return res.status(500).json({ error: 'Failed to create account', detail: error.message });
  }

  const token = signToken({ id: worker.id, email: worker.email, worker_platform_id: worker.worker_platform_id, role: worker.role || 'worker' });

  res.status(201).json({
    message: 'Account created successfully',
    token,
    worker: sanitizeWorker(worker),
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/login
// Body: { email }
// No password — worker ID-verified system (platform already verified the worker)
// Returns: { token, worker }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ error: 'email is required' });
  }

  const { data: worker, error } = await supabase
    .from('workers')
    .select('*')
    .eq('email', email.toLowerCase())
    .single();

  if (error || !worker) {
    return res.status(401).json({ error: 'No account found with this email. Please register first.' });
  }

  if (!worker.is_active) {
    return res.status(403).json({ error: 'Account is deactivated. Contact support.' });
  }

  const token = signToken({ id: worker.id, email: worker.email, worker_platform_id: worker.worker_platform_id, role: worker.role || 'worker' });

  res.json({
    message: 'Login successful',
    token,
    worker: sanitizeWorker(worker),
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/auth/me   (protected)
// Returns current worker's profile
// ─────────────────────────────────────────────────────────────────────────────
router.get('/me', authenticate, (req, res) => {
  res.json({ worker: sanitizeWorker(req.worker) });
});

// ─────────────────────────────────────────────────────────────────────────────
// PUT /api/auth/profile   (protected)
// Update the authenticated worker's profile fields
// Body: { full_name?, city?, upi_id? }
// ─────────────────────────────────────────────────────────────────────────────
router.put('/profile', authenticate, async (req, res) => {
  const { full_name, city, upi_id } = req.body;

  // Build update object with only provided fields
  const updates = {};
  if (full_name !== undefined) updates.full_name = full_name.trim();
  if (city      !== undefined) updates.city      = city.trim();
  if (upi_id    !== undefined) updates.upi_id    = upi_id.trim();

  if (Object.keys(updates).length === 0) {
    return res.status(400).json({ error: 'No fields provided to update' });
  }

  const { data, error } = await supabase
    .from('workers')
    .update(updates)
    .eq('id', req.worker.id)
    .select()
    .single();

  if (error) {
    console.error('[Profile Update] DB error:', error);
    return res.status(500).json({ error: 'Profile update failed', detail: error.message });
  }

  res.json({ worker: sanitizeWorker(data), message: 'Profile updated successfully' });
});

// ─────────────────────────────────────────────────────────────────────────────
// Helper — remove internal fields before sending to client
// ─────────────────────────────────────────────────────────────────────────────
function sanitizeWorker(worker) {
  const { ...safe } = worker;
  return safe;
}

module.exports = router;
