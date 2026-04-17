-- ============================================================
-- Sprint 1 Migration: Add role column + promote admin accounts
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 1. Add role column with default 'worker'
ALTER TABLE workers
  ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'worker';

-- 2. Add check constraint so only valid roles are stored
-- (Fixed: Dropping if exists first, then adding, as Postgres doesn't allow IF NOT EXISTS for constraints)
ALTER TABLE workers DROP CONSTRAINT IF EXISTS workers_role_check;
ALTER TABLE workers ADD CONSTRAINT workers_role_check CHECK (role IN ('worker', 'admin'));

-- ────────────────────────────────────────────────────────────
-- 3. PROMOTE ADMIN ACCOUNTS
--    Add more emails below to grant admin access to existing accounts.
-- ────────────────────────────────────────────────────────────
UPDATE workers SET role = 'admin'
WHERE email IN (
  'vighneshgarg96@gmail.com'
  -- Add more admin emails below this line (comma-separated):
  -- ,'anotheradmin@email.com'
);

-- ────────────────────────────────────────────────────────────
-- 4. Verify results
-- ────────────────────────────────────────────────────────────
SELECT id, email, role, is_active FROM workers ORDER BY role DESC;