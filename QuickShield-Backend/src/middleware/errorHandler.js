/**
 * Global error handler — catches all thrown errors and unhandled async errors
 * (express-async-errors patches all async route handlers automatically).
 */
function errorHandler(err, req, res, next) {
  // Supabase / DB errors
  if (err.code && err.code.startsWith('2')) {
    console.error('[DB Error]', err.message);
    return res.status(503).json({ error: 'Database error', detail: err.message });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }

  // Validation errors
  if (err.status === 400) {
    return res.status(400).json({ error: err.message });
  }

  console.error('[Unhandled Error]', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
  });
}

module.exports = errorHandler;
