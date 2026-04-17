/**
 * Admin guard middleware.
 * Must be used AFTER authenticate — relies on req.worker being set.
 * Rejects any request where the worker's role is not 'admin'.
 */
function requireAdmin(req, res, next) {
  if (!req.worker || req.worker.role !== 'admin') {
    return res.status(403).json({ error: 'Forbidden: admin access required' });
  }
  next();
}

module.exports = requireAdmin;
