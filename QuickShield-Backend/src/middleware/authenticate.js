const { verifyToken } = require('../config/jwt');
const supabase = require('../config/supabase');

/**
 * Protects routes — extracts and validates JWT from the Authorization header.
 * On success: sets req.worker = { id, email, worker_platform_id, full_name, ... }
 */
async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header' });
  }

  const token = authHeader.split(' ')[1];

  let decoded;
  try {
    decoded = verifyToken(token);
  } catch (err) {
    return res.status(401).json({
      error: err.name === 'TokenExpiredError' ? 'Token expired' : 'Invalid token',
    });
  }

  // Fetch fresh worker record from DB so we always have current data
  const { data: worker, error } = await supabase
    .from('workers')
    .select('*')
    .eq('id', decoded.id)
    .single();

  if (error || !worker) {
    return res.status(401).json({ error: 'Worker account not found' });
  }

  req.worker = worker;
  next();
}

module.exports = authenticate;
