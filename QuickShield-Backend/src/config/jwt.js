const jwt = require('jsonwebtoken');

const JWT_SECRET   = process.env.JWT_SECRET || 'dev_secret_change_in_production';
const JWT_EXPIRES  = process.env.JWT_EXPIRES_IN || '7d';

/**
 * Signs a JWT token for a worker.
 * @param {object} payload - { id, email, worker_platform_id }
 */
function signToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES });
}

/**
 * Verifies a JWT and returns the decoded payload.
 * Throws JsonWebTokenError on invalid/expired tokens.
 */
function verifyToken(token) {
  return jwt.verify(token, JWT_SECRET);
}

module.exports = { signToken, verifyToken };
