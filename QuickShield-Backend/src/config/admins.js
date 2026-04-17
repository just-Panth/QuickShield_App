/**
 * Admin email whitelist.
 *
 * Any email in this list will be auto-assigned the 'admin' role at registration.
 * For existing accounts, run the SQL migration to update the role directly.
 *
 * ─── HOW TO ADD MORE ADMINS ───────────────────────────────────────────────────
 * 1. Add their email to the ADMIN_EMAILS array below (lowercase).
 * 2. Save this file — the backend picks it up on next start (nodemon auto-reloads).
 * 3. If the account already exists in the DB, run in Supabase SQL Editor:
 *    UPDATE workers SET role = 'admin' WHERE email = 'new@email.com';
 * ──────────────────────────────────────────────────────────────────────────────
 */
const ADMIN_EMAILS = [
  'vighneshgarg96@gmail.com',
  // Add more admin emails below this line:
  // 'another@admin.com',
];

/**
 * Returns true if the given email should have admin role.
 * @param {string} email - lowercased email to check
 */
function isAdminEmail(email) {
  return ADMIN_EMAILS.includes(email.toLowerCase());
}

module.exports = { ADMIN_EMAILS, isAdminEmail };
