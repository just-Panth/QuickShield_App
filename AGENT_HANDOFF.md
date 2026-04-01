# 🛡️ QuickShield — Complete Agent Handoff Document

> **FOR THE LLM:** Read this file completely before doing anything. This is a live hackathon project.
> Every decision, every file, every pending task is documented here. Do not assume. Ask if unclear.

---

## 0. Quick Orientation

| Item | Value |
|------|-------|
| **Project** | QuickShield — parametric micro-insurance for gig delivery workers |
| **Hackathon** | Guidewire DevTrails Hackathon 2026 |
| **Repo owner** | Vighnesh Garg (vighneshgarg96@gmail.com) |
| **Workspace path** | `c:\Users\Administrator\OneDrive\Desktop\shitido\Guidewire\` |
| **Postman workspace** | ID: `130ae796-6f55-43c1-8bc5-2cb771c9835d` (team workspace) |
| **Postman collection** | Name: "QuickShield API", ID: `2676f427-ea9c-4fe2-a32f-b57ced2a3f9b` |
| **Postman user ID** | `49721884` (vighneshgarg96) |
| **Flutter repo** | https://github.com/just-Panth/QuickShield_App (cloned locally) |
| **MCP server** | postman-mcp-server is connected and working |

---

## 1. The Project — What QuickShield Is

QuickShield insures gig delivery workers (Blinkit / Swiggy / Zomato / Zepto) against **income loss** from localized disruptions: weather, traffic jams, civic events. It is **parametric** — meaning payouts are triggered automatically by verified conditions, not manual claims.

### The Core Flow (for a lost delivery day)
```
1. Worker opens app → purchases weekly policy (₹50–500/week, based on risk score)
2. Disruption hits their zone (rain, traffic jam, local event)
3. Worker submits claim → backend runs 3-Gate pipeline:
   Gate 1: Real disruption confirmed in zone? (parametric trigger)
   Gate 2: Anti-fraud check passes? (6 layers: GPS, Z-axis, photo hash, peer consensus, velocity, activity)
   Gate 3: Payout calculated (2/3 formula) → UPI disbursement
4. Worker receives ₹X directly to phone
```

### The 2/3 Payout Formula
```
Expected Daily  = Worker's 14-day rolling average (e.g., ₹900)
Guarantee Floor = Expected × 2/3 (e.g., ₹600)
Payout          = Guarantee Floor − Already Earned Today (e.g., ₹600 − ₹200 = ₹400)
```

---

## 2. Team Structure

| Person | Role | Status |
|--------|------|--------|
| Vighnesh Garg | **Backend (you are helping him)** | Active |
| Teammate 1 | Flutter frontend | In progress |
| Teammate 2 | ML model (XGBoost) | Model trained, file pending |

---

## 3. Architecture — Final Decisions

### Services
- **Service 1:** `QuickShield-Backend/` — Node.js / Express — Port **3000**
- **Service 2:** `QuickShield-ML/` — Python / FastAPI — Port **8000**

### Databases (cloud-hosted for team sharing)
- **PostgreSQL:** Supabase — `⚠️ NOT YET SET UP — credentials not in .env`
- **Cache:** Upstash Redis — `⚠️ NOT YET SET UP — credentials not in .env`

### Auth
- **Custom JWT** (jsonwebtoken) — NO password required
- Registration: `email + phone + worker_platform_id` → creates DB record → returns JWT (7d expiry)
- Login: `email` only → lookup → return new JWT
- All protected routes validate JWT via `authenticate` middleware

### ML Model
- Format: **XGBoost `.json`** (saved with `model.save_model('model.json')`)
- Output: **Risk score only (0–100)** — premium is calculated in Node.js, NOT by the model
- Feature names: **⚠️ NOT YET CONFIRMED by ML teammate** — placeholder feature order in `main.py`
- The FastAPI service has a **mock fallback** that works without the real model

### Premium Formula (Node.js side)
```
weeklyEarnings = avg14DayEarnings × 7
basePremium    = weeklyEarnings × 1.5% × durationWeeks
riskMultiplier = 0.8 (Low) | 1.0 (Medium) | 1.3 (High)
premium        = basePremium × riskMultiplier
                 → Floor: ₹50, Ceiling: ₹500
```

---

## 4. Complete File Map — What Exists and What It Does

### `QuickShield-Backend/` (Node.js service)

```
QuickShield-Backend/
├── package.json              ✅ Complete — all deps installed (npm install done)
├── .env.example              ✅ Template with all variable names
├── .env                      ⚠️  Exists but EMPTY credentials (Supabase + Redis not filled)
├── .gitignore                ✅ node_modules/, .env
└── src/
    ├── index.js              ✅ Express app with all routes registered
    ├── config/
    │   ├── supabase.js       ✅ Service-role Supabase client
    │   ├── redis.js          ✅ Upstash Redis client with in-memory fallback mock
    │   └── jwt.js            ✅ signToken() / verifyToken() helpers
    ├── middleware/
    │   ├── authenticate.js   ✅ JWT guard — sets req.worker on all protected routes
    │   └── errorHandler.js   ✅ Global error handler
    ├── routes/
    │   ├── auth.routes.js        ✅ POST /register, POST /login, GET /me
    │   ├── dashboard.routes.js   ✅ GET /dashboard (single call for Flutter)
    │   ├── policy.routes.js      ✅ GET /, GET /:id, POST /purchase
    │   ├── premium.routes.js     ✅ POST /calculate
    │   ├── claim.routes.js       ✅ GET /, GET /:id, POST /submit (full 3-gate)
    │   └── simulate.routes.js    ✅ POST /trigger-disruption, /full-claim-pipeline, /fraud-attempt
    ├── services/
    │   ├── premium.service.js    ✅ fetchRiskScore (calls ML or fallback) + calculatePremium + calculatePayout
    │   └── claims.service.js     ✅ gate1, gate2 (6-layer), gate3 + mock UPI/weather
    └── db/
        └── schema.sql            ✅ Full SQL — tables + indexes + seed zones
```

### `QuickShield-ML/` (FastAPI service)

```
QuickShield-ML/
├── requirements.txt     ✅ fastapi, uvicorn, xgboost, numpy, pydantic, python-dotenv
├── .gitignore           ✅ Excludes model.json (don't commit the model)
└── main.py              ✅ Full FastAPI app
                              - Tries to load model.json at startup
                              - Falls back to heuristic mock if not found
                              - GET  /health
                              - POST /score/risk     ← main endpoint called by Node.js
                              - POST /score/premium  ← optional direct endpoint
```

### `QuickShield_App/` (Flutter frontend — READ ONLY, teammate's code)
```
QuickShield_App/QuickShield/lib/
├── main.dart
├── core/constants/colors.dart + spacing.dart
├── navigation/app_shell.dart
├── providers/
│   ├── auth_provider.dart        ← Currently LOCAL STATE ONLY (no API calls yet)
│   └── quickshield_provider.dart ← Currently LOCAL STATE ONLY (no API calls yet)
└── screens/
    ├── auth/login_screen.dart         ← UI exists, no API call
    ├── auth/registration_screen.dart  ← Collects email, phone, worker_id (3 steps)
    ├── dashboard/dashboard_screen.dart ← All hardcoded dummy data (Ravi, ₹0, etc.)
    ├── claims/claims_screen.dart       ← Hardcoded CLM-123, CLM-124
    ├── policies/policies_screen.dart
    └── premium/premium_calculator_screen.dart
```

**Key insight about Flutter:** The entire app is a beautiful UI skeleton — **zero HTTP calls are wired up anywhere.** The Flutter teammate still needs to wire all API calls. Our backend is the source of truth.

---

## 5. All API Routes — Complete Contract

### Base URL: `http://localhost:3000/api`
### Auth header for protected routes: `Authorization: Bearer <token>`

#### 🔐 Auth
| Method | Path | Auth | Body | Returns |
|--------|------|------|------|---------|
| POST | `/auth/register` | ❌ | `{email, phone, worker_platform_id, platform?, city?, zone_id?, full_name?}` | `{token, worker}` |
| POST | `/auth/login` | ❌ | `{email}` | `{token, worker}` |
| GET | `/auth/me` | ✅ | — | `{worker}` |

#### 📊 Dashboard
| Method | Path | Auth | Returns |
|--------|------|------|---------|
| GET | `/dashboard` | ✅ | `{worker, stats, active_coverage[], zone_risk, recent_activity[]}` |

#### 📋 Policy
| Method | Path | Auth | Body | Returns |
|--------|------|------|------|---------|
| GET | `/policy` | ✅ | — | `{policies[]}` |
| GET | `/policy/:id` | ✅ | — | `{policy}` |
| POST | `/policy/purchase` | ✅ | `{plan_type, duration_weeks?}` | `{policy}` |

Valid `plan_type` values: `daily_income_shield`, `monsoon_surge_cover`, `traffic_disruption`

#### 💰 Premium
| Method | Path | Auth | Body | Returns |
|--------|------|------|------|---------|
| POST | `/premium/calculate` | ✅ | `{zone_id?, platform?, duration_weeks?}` | `{risk_score, risk_level, premium_inr, breakdown}` |

#### 🚨 Claims
| Method | Path | Auth | Body | Returns |
|--------|------|------|------|---------|
| GET | `/claim` | ✅ | — | `{summary: {total_inr, paid_inr, pending_inr}, claims[]}` |
| GET | `/claim/:id` | ✅ | — | `{claim}` |
| POST | `/claim/submit` | ✅ | See below | `{claim_id, status, payout_inr, gates{}, upi_reference}` |

**Claim submit body:**
```json
{
  "policy_id": "uuid",
  "disruption_type": "weather",
  "gps_trail": [{"lat": 12.97, "lng": 77.59, "timestamp": 1700000000}],
  "z_axis_trail": [{"altitude_m": 920.5, "timestamp": 1700000000}],
  "photo_hash": "sha256_string",
  "earned_today_inr": 200
}
```

**Claim statuses / statusIndex for Flutter:**
```
submitted → 0
verified  → 1
approved  → 2
paid      → 3
rejected  → -1
```

#### 🎭 Simulation (Demo Video)
| Method | Path | Auth | Body | Purpose |
|--------|------|------|------|---------|
| POST | `/simulate/trigger-disruption` | ✅ | `{zone_id, disruption_type?, severity?, worker_email?}` | Seeds Redis disruption so Gate 1 passes |
| POST | `/simulate/full-claim-pipeline` | ✅ | `{worker_email, scenario?, force_pass_all_gates?}` | **One-shot demo** — does everything end-to-end |
| POST | `/simulate/fraud-attempt` | ✅ | `{worker_email, attack_type?}` | Shows Gate 2 blocking GPS spoofing |

#### 🤖 ML Service (FastAPI — port 8000)
| Method | Path | Body | Returns |
|--------|------|------|---------|
| GET | `/health` | — | `{status, model_loaded, model_path}` |
| POST | `/score/risk` | `{zone_id, platform, city, hour_of_day, day_of_week, days_active_last_30, avg_daily_earnings_14d}` | `{risk_score, risk_level, model_used}` |
| POST | `/score/premium` | `{risk_score, avg_daily_earnings_14d, duration_weeks, zone_id}` | `{premium_inr, breakdown}` |

---

## 6. Database Schema (Supabase PostgreSQL)

Four tables exist in `src/db/schema.sql`:

### `workers`
```sql
id UUID PK, email TEXT UNIQUE, phone TEXT, full_name TEXT,
worker_platform_id TEXT,     -- "GW-1234567" from Blinkit/etc
platform TEXT,               -- blinkit | swiggy | zomato | zepto
city TEXT, zone_id TEXT,
is_active BOOLEAN,
avg_daily_earnings_14d NUMERIC DEFAULT 900,
days_active_last_30 INTEGER DEFAULT 20,
onboarded_at TIMESTAMPTZ
```

### `zones` (seeded with 8 zones)
```sql
id TEXT PK,          -- "BLR-SOUTH", "BLR-NORTH", "MUM-CENTRAL", etc.
city TEXT, display_name TEXT, base_risk_score NUMERIC,
lat_center NUMERIC, lng_center NUMERIC
```

### `policies`
```sql
id UUID PK, worker_id UUID FK→workers,
plan_type TEXT,      -- daily_income_shield | monsoon_surge_cover | traffic_disruption
premium_inr NUMERIC, risk_score NUMERIC, duration_weeks INTEGER,
status TEXT,         -- active | expired | cancelled
started_at TIMESTAMPTZ, expires_at TIMESTAMPTZ
```

### `claims`
```sql
id UUID PK, worker_id UUID FK→workers, policy_id UUID FK→policies,
disruption_type TEXT,
status TEXT,         -- submitted | verified | approved | paid | rejected
earned_today_inr NUMERIC, amount_inr NUMERIC,
gps_trail JSONB, z_axis_trail JSONB, photo_hash TEXT,
gate_results JSONB,  -- full audit trail {gate1:{}, gate2:{}, gate3:{}}
settled_at TIMESTAMPTZ
```

### `earnings_ledger`
```sql
id UUID PK, worker_id UUID FK→workers,
date DATE, amount_inr NUMERIC, platform TEXT,
UNIQUE(worker_id, date)  -- one record per day per worker
```

---

## 7. The 3-Gate Pipeline — Detailed Logic

### Gate 1: Parametric Trigger
- Checks Redis for key `disruption:active:{zone_id}`
- If not in Redis, falls back to `mockWeatherCheck()` (returns true for BLR-SOUTH, BLR-NORTH, MUM-CENTRAL)
- **TODO:** Replace mock with real IMD / OpenWeatherMap API

### Gate 2: Anti-Fraud (6 Layers)
| Layer | What it checks | Key |
|-------|---------------|-----|
| GPS | Trail must have 2+ points, not all identical, timestamps ascending | — |
| Z-axis | Altitude 0–5000m (optional layer, passes if no z-trail sent) | — |
| Photo hash | SHA-256 must be unique — checks Redis, stores with 30d TTL | `photo_hash:{workerId}:{hash}` |
| Peer consensus | Checks Redis `peer_consensus:{zone_id}` — needs ≥2 reports | `peer_consensus:{zone_id}` |
| Claim velocity | Max 3 claims per 7 days | `claim_velocity:{workerId}` |
| Account activity | Always passes (placeholder) | — |

### Gate 3: Payout
- Calculates `guaranteeFloor = avg14DayEarnings × 2/3`
- `payout = max(0, guaranteeFloor - earnedToday)`
- Calls `mockUpiTransfer()` → returns fake transaction ID
- **TODO:** Replace with Razorpay / PayU UPI Payout API

---

## 8. Redis Key Map (Upstash)

| Key | TTL | Purpose |
|-----|-----|---------|
| `disruption:active:{zone_id}` | 1 hour | Active disruption event (Gate 1) |
| `peer_consensus:{zone_id}` | 1 hour | Number of workers reporting disruption (Gate 2 Layer 4) |
| `photo_hash:{workerId}:{hash}` | 30 days | Used photo hashes (Gate 2 Layer 3, replay attack prevention) |
| `claim_velocity:{workerId}` | 7 days | Claim count this week (Gate 2 Layer 5) |
| `zone_risk:{zone_id}` | — | Zone risk distribution for dashboard (optional cache) |

---

## 9. What Is NOT Done Yet (Pending Tasks)

### 🔴 CRITICAL — Must Do Before Testing
- [ ] **Set up Supabase project** (go to supabase.com → new project)
  - Run `QuickShield-Backend/src/db/schema.sql` in Supabase SQL Editor
  - Fill `.env`: `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `SUPABASE_ANON_KEY`
- [ ] **Set up Upstash Redis** (go to console.upstash.com)
  - Fill `.env`: `UPSTASH_REDIS_URL`, `UPSTASH_REDIS_TOKEN`
- [ ] **Set a real JWT_SECRET** in `.env` (any 64+ char random string)
- [ ] **Note:** Without Supabase/Redis, the server will still BOOT (both have fallbacks) but DB writes will fail

### 🟡 IMPORTANT — For Full Demo
- [ ] **ML teammate** must provide `model.json` → place in `QuickShield-ML/model.json`
- [ ] **ML teammate** must confirm exact feature names → update `build_feature_vector()` in `main.py`
- [ ] **Python ML service:** `pip install -r requirements.txt` then `python main.py`
- [ ] **Flutter teammate** must wire API calls using the contract in Section 5 above
- [ ] **Auth refinement:** Consider adding OTP or any secondary check if needed for demo

### 🟢 NICE TO HAVE — Improvements
- [ ] `GET /policy` and `GET /claim` have no hardcoded `policy_id` variable in Postman — set it after purchase
- [ ] `earnings_ledger` table has no seed data — `avg_daily_earnings_14d` defaults to 900 for all workers
- [ ] Add a seed script (`src/db/seed.js`) to create a demo worker with full history
- [ ] Add `PATCH /worker/earnings` endpoint so the app can update daily earnings
- [ ] Dashboard `zone_risk` section uses Redis cache — currently only populated by `/simulate/trigger-disruption`
- [ ] Real weather API integration (IMD / OpenWeatherMap)
- [ ] Real UPI payout integration (Razorpay Payout API)

---

## 10. How to Run Everything

### Node.js Backend
```bash
cd QuickShield-Backend
# First: fill in .env with Supabase + Redis credentials
npm run dev          # starts with nodemon on port 3000
# OR
npm start            # production start
```
Health check: `GET http://localhost:3000/health`

### Python FastAPI ML Service
```bash
cd QuickShield-ML
pip install -r requirements.txt
python main.py       # starts uvicorn on port 8000
```
Health check: `GET http://localhost:8000/health`

### Demo Sequence (Postman — for hackathon video)
```
Step 1: Register Worker     → POST /api/auth/register        (saves token automatically)
Step 2: Purchase Policy     → POST /api/policy/purchase      (saves policy_id automatically)
Step 3: Trigger Disruption  → POST /api/simulate/trigger-disruption
Step 4: Full Pipeline       → POST /api/simulate/full-claim-pipeline  ← THE MONEY SHOT
Step 5: Fraud Demo          → POST /api/simulate/fraud-attempt        ← Shows rejection
```

---

## 11. Postman Collection Details

- **Collection name:** QuickShield API
- **Collection ID:** `2676f427-ea9c-4fe2-a32f-b57ced2a3f9b`
- **Workspace ID:** `130ae796-6f55-43c1-8bc5-2cb771c9835d`
- **Collection variables:** `base_url`, `ml_url`, `token` (auto-set), `worker_id` (auto-set), `policy_id` (auto-set)

**Requests already in Postman (all added):**
1. Register Worker (with auto-save token test script)
2. Login Worker (with auto-save token test script)
3. Get My Profile
4. Get Dashboard Data
5. Purchase Policy (with auto-save policy_id test script)
6. Calculate Premium
7. Submit Claim (3-Gate Pipeline)
8. 🎬 Trigger Disruption (Demo Step 1)
9. 🎬 Full Claim Pipeline (Demo Step 2)
10. 🚫 Simulate Fraud — GPS Spoofing

---

## 12. Flutter API Contract — What Teammate Needs to Know

Tell your Flutter teammate to wire up these calls:

### Registration (3-step form)
```
POST /api/auth/register
Body: { email, phone, worker_platform_id, platform: "blinkit", city: "Bangalore", zone_id: "BLR-SOUTH", full_name }
→ Save token from response.token to secure storage (flutter_secure_storage)
```

### Login
```
POST /api/auth/login
Body: { email }
→ Save token
```

### Dashboard screen (replace ALL hardcoded data)
```
GET /api/dashboard
Headers: Authorization: Bearer {token}
→ response.worker.full_name     → greeting name
→ response.stats.protected_inr  → "Protected" stat card
→ response.stats.risk_level     → "Risk level" stat card  
→ response.stats.active_policies → "Policies" stat card
→ response.active_coverage[]    → Coverage items list
→ response.zone_risk            → Risk bar distribution
→ response.recent_activity[]    → Activity feed
```

### Claims screen (replace hardcoded CLM-123/124)
```
GET /api/claim
Headers: Authorization: Bearer {token}
→ response.summary.total_inr    → "Total" chip
→ response.summary.paid_inr     → "Paid" chip
→ response.summary.pending_inr  → "Pending" chip
→ response.claims[]             → Claim cards
  - claim.id                    → display as CLM prefix
  - claim.amount_inr            → amount
  - claim.status_index          → 0/1/2/3 maps to Submitted/Verified/Approved/Paid
  - claim.created_at            → date
  - claim.disruption_type       → type label
```

### Premium Calculator screen
```
POST /api/premium/calculate
Headers: Authorization: Bearer {token}
Body: { zone_id, platform, duration_weeks }
→ response.premium_inr    → show price
→ response.risk_level     → show risk badge
→ response.risk_score     → show score (0-100)
```

---

## 13. ML Teammate Information

**What they need to know:**
1. Save model as: `model.save_model('model.json')` — XGBoost native format
2. Place `model.json` in `QuickShield-ML/model.json`
3. Confirm the **exact feature names and order** their model was trained on
4. Update `build_feature_vector()` function in `QuickShield-ML/main.py` to match
5. The expected input features (current placeholder):
   - `hour_of_day` (0-23)
   - `day_of_week` (0-6)
   - `zone_risk_score` (from zone map, 45-70)
   - `platform_code` (blinkit=0, swiggy=1, zomato=2, zepto=3)
   - `days_active_last_30` (0-30)
   - `avg_daily_earnings_14d` (float, INR)
6. Model output: **probability / score (0-1 or 0-100)** — if 0-1, multiply by 100 in `main.py` (already handled)

---

## 14. Key Business Rules (Do Not Change Without Asking)

1. **Loss of income only** — not health, not vehicle damage, only income
2. **Weekly pricing only** — policies are weekly (7 days), no monthly or one-day
3. **Floor ₹50, ceiling ₹500** for premium per week
4. **2/3 formula for payout** — worker gets at most 2/3 of their average daily earnings
5. **All claim amounts in INR (₹)**
6. **No password** in auth — worker_platform_id is the identity anchor (issued by Blinkit/Swiggy)
7. **3 claims max per 7 days** (claim velocity limit)
8. **Photo must be taken in-app** (Flutter blocks gallery access) — hash is SHA-256 of raw photo bytes
9. **GPS must show movement** — static GPS = fraud flag (Gate 2 Layer 1)

---

## 15. Where Things Are Stored

| What | Location |
|------|----------|
| All backend code | `Guidewire/QuickShield-Backend/` |
| ML FastAPI service | `Guidewire/QuickShield-ML/` |
| Flutter app (read-only) | `Guidewire/QuickShield_App/QuickShield/` |
| DB schema SQL | `Guidewire/QuickShield-Backend/src/db/schema.sql` |
| Env template | `Guidewire/QuickShield-Backend/.env.example` |
| Project decisions log | `Guidewire/PROJECT_CONTEXT.md` |
| Original project spec | `Guidewire/context.txt` |
| Use case / phase plan | `Guidewire/usecase.txt` |

---

## 16. First Things to Do When Resuming

**If Supabase and Redis are now set up (credentials available):**
1. Open `QuickShield-Backend/.env` and fill in the 5 credential lines
2. Run `npm run dev` — should connect to DB
3. Open Postman → "QuickShield API" collection → run "Register Worker"
4. If it returns a token, the system works end-to-end
5. Run "Purchase Policy" → "Trigger Disruption" → "Full Claim Pipeline" — check the demo flow

**If Supabase and Redis are NOT yet set up:**
1. Follow Section 9 "Critical — Must Do Before Testing"
2. Then follow the demo sequence in Section 10

**If continuing code work:**
- The most impactful next improvement is the **seed script** (`src/db/seed.js`) to pre-populate demo data
- Second priority: wire Flutter API calls using Section 12 as the guide
- Third priority: get ML teammate's `model.json` and update `build_feature_vector()` in `main.py`

---

*This document was auto-generated as a handoff snapshot. Last updated: 2026-04-02 at 03:11 IST.*
*All code is complete and the server boots successfully (`npm run dev` tested and working).*
