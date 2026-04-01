-- ─────────────────────────────────────────────────────────────────────────────
-- QuickShield Database Schema
-- Run this entire file in the Supabase SQL Editor:
-- https://supabase.com → Your Project → SQL Editor → New Query → Paste → Run
-- ─────────────────────────────────────────────────────────────────────────────

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Workers ──────────────────────────────────────────────────────────────────
-- Stores gig delivery workers registered on QuickShield
CREATE TABLE IF NOT EXISTS workers (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email                   TEXT UNIQUE NOT NULL,
  phone                   TEXT NOT NULL,
  full_name               TEXT NOT NULL DEFAULT 'Worker',
  worker_platform_id      TEXT NOT NULL,           -- e.g. "GW-1234567" from Blinkit/Swiggy
  platform                TEXT NOT NULL DEFAULT 'blinkit',  -- blinkit | swiggy | zomato | zepto
  city                    TEXT NOT NULL DEFAULT 'Bangalore',
  zone_id                 TEXT NOT NULL DEFAULT 'BLR-SOUTH',
  is_active               BOOLEAN DEFAULT TRUE,
  avg_daily_earnings_14d  NUMERIC DEFAULT 900,     -- updated periodically by earnings ledger
  days_active_last_30     INTEGER DEFAULT 20,
  onboarded_at            TIMESTAMPTZ DEFAULT NOW(),
  created_at              TIMESTAMPTZ DEFAULT NOW()
);

-- ── Zones ─────────────────────────────────────────────────────────────────────
-- City zones with baseline risk data
CREATE TABLE IF NOT EXISTS zones (
  id              TEXT PRIMARY KEY,               -- e.g. "BLR-SOUTH"
  city            TEXT NOT NULL,
  display_name    TEXT NOT NULL,
  base_risk_score NUMERIC DEFAULT 45,
  lat_center      NUMERIC,
  lng_center      NUMERIC,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Policies ──────────────────────────────────────────────────────────────────
-- Insurance policies purchased by workers
CREATE TABLE IF NOT EXISTS policies (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  worker_id       UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  plan_type       TEXT NOT NULL,                  -- daily_income_shield | monsoon_surge_cover | traffic_disruption
  premium_inr     NUMERIC NOT NULL,
  risk_score      NUMERIC,
  duration_weeks  INTEGER DEFAULT 1,
  status          TEXT DEFAULT 'active',          -- active | expired | cancelled
  started_at      TIMESTAMPTZ DEFAULT NOW(),
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Claims ────────────────────────────────────────────────────────────────────
-- Claims submitted by workers through the 3-Gate pipeline
CREATE TABLE IF NOT EXISTS claims (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  worker_id         UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  policy_id         UUID REFERENCES policies(id),
  disruption_type   TEXT NOT NULL DEFAULT 'weather',   -- weather | traffic | event
  status            TEXT DEFAULT 'submitted',           -- submitted | verified | approved | paid | rejected
  earned_today_inr  NUMERIC DEFAULT 0,
  amount_inr        NUMERIC,                            -- payout amount (set at Gate 3)
  gps_trail         JSONB,                              -- [{lat, lng, timestamp}]
  z_axis_trail      JSONB,                              -- [{altitude_m, timestamp}]
  photo_hash        TEXT,                               -- SHA-256 of incident photo
  gate_results      JSONB DEFAULT '{}',                 -- full audit trail of all 3 gates
  settled_at        TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ── Earnings Ledger ───────────────────────────────────────────────────────────
-- Daily earnings records — used for 14-day rolling average premium calculation
CREATE TABLE IF NOT EXISTS earnings_ledger (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  worker_id   UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  date        DATE NOT NULL,
  amount_inr  NUMERIC NOT NULL,
  platform    TEXT,
  note        TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(worker_id, date)  -- one record per worker per day
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Indexes for common query patterns
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_policies_worker ON policies(worker_id);
CREATE INDEX IF NOT EXISTS idx_claims_worker   ON claims(worker_id);
CREATE INDEX IF NOT EXISTS idx_claims_status   ON claims(status);
CREATE INDEX IF NOT EXISTS idx_ledger_worker   ON earnings_ledger(worker_id, date DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- Seed Data: Zones
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO zones (id, city, display_name, base_risk_score, lat_center, lng_center) VALUES
  ('BLR-SOUTH',    'Bangalore',  'Bangalore South',  45, 12.9141, 77.6022),
  ('BLR-NORTH',    'Bangalore',  'Bangalore North',  60, 13.0358, 77.5970),
  ('BLR-EAST',     'Bangalore',  'Bangalore East',   50, 12.9784, 77.6408),
  ('MUM-CENTRAL',  'Mumbai',     'Mumbai Central',   70, 18.9720, 72.8205),
  ('MUM-WEST',     'Mumbai',     'Mumbai West',      55, 19.0596, 72.8295),
  ('DEL-EAST',     'Delhi',      'Delhi East',       65, 28.6669, 77.2590),
  ('DEL-SOUTH',    'Delhi',      'Delhi South',      50, 28.5355, 77.2500),
  ('DEFAULT',      'Generic',    'Default Zone',     50, 0, 0)
ON CONFLICT (id) DO NOTHING;
