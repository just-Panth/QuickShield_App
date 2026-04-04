# QuickShield — Backend Project Context
> Living document. Updated as decisions are made. Last updated: 2026-04-01

---

## 🏆 Hackathon
- **Event:** Guidewire DevTrails Hackathon 2026
- **Team:** Chai_pe_charcha (Vighnesh, Panthdeep-Majumder, Kushagra Agarwal, Rishi Krishna Sahoo, Kaavya Gupta)
- **GitHub Repo:** https://github.com/just-Panth/QuickShield_App (currently docs only)
- **Phase 2 Deadline:** April 4, 2026
- **Phase 3 Deadline:** April 17, 2026
- **Deliverable Format:** Video demo (screen capture walkthrough)

---

## 👥 Team Division of Work
| Member | Responsibility |
|--------|---------------|
| User | **Backend APIs (Node.js) + Python scripts** ← WE ARE BUILDING THIS |
| Flutter teammate | Frontend (Flutter/Dart app) |
| ML teammate | Training XGBoost model (synthetic data from research paper) — has .json + .py/.ipynb files |

---

## ✅ Decisions Made

| # | Decision | Choice | Reason |
|---|----------|--------|--------|
| 1 | Backend Architecture | **Two separate services** (Node.js API + FastAPI for Python) | FastAPI persistent process is 10x faster than spawning Python; ML teammate can own FastAPI independently; cleaner separation |
| 2 | Project location | **Fresh folder** `QuickShield-Backend` (separate from Guidewire docs folder) | Clean slate |
| 3 | Database hosting | **Cloud** — Supabase (PostgreSQL) + Upstash (Redis) | Any team member can connect from any machine, no local setup needed |
| 4 | Auth | **JWT tokens** (default, modular) | Will revisit once Flutter frontend is handed over |
| 5 | API Contract | **We define it** and share with Flutter teammate | User confirmed |
| 6 | GPS payload format | **Array of `{lat, lng, timestamp}`** objects | Human-readable, no decoding library needed, debuggable |
| 7 | Z-axis payload format | **Array of `{altitude_m, timestamp}`** objects | Simple and clear |
| 8 | Photo hash format | **SHA-256 string** from Flutter's in-app camera | Already decided by system design |
| 9 | ML mock function | **Yes — build mock with clear `# TODO: REPLACE WITH REAL MODEL` remarks** | Lets full system work end-to-end before ML model arrives |
| 10 | ML model format | **.json (XGBoost native)** — saved with `model.save_model('model.json')` | ✅ Confirmed by ML teammate |
| 10b | ML model output | **Risk score only (0-100)** — premium calculation handled in Node.js | ✅ Confirmed by ML teammate |
| 11 | Delivery platform for demo | **Blinkit** (default, generic enough to swap) | Not decided by team yet, using as placeholder |
| 12 | Zone/City data | **Seeded into DB** when building (not hardcoded) | Will enter data manually |
| 13 | Fraud rejection demo | **Yes** — backend endpoints support it (Gate 2 rejection scenario) | No video/UI needed from our side |
| 14 | Visual Disruption Simulator | **Backend simulation endpoints only** (`POST /simulate/trigger-disruption`) | Flutter/web UI decision made by team later |

---

## ❓ Still Pending / Open Questions
| # | Question | Who answers |
|---|----------|------------|
| ~~A~~ | ~~ML model input features~~ | ✅ To be embedded into FastAPI mock with `# TODO` remarks |
| ~~B~~ | ~~Does XGBoost model output disruption score or premium price?~~ | ✅ Risk score only. Premium calculated separately in Node.js |
| ~~C~~ | ~~How was model saved?~~ | ✅ `model.save_model('model.json')` — XGBoost native JSON |
| D | Flutter API contract — specific endpoint list Flutter teammate is coding against | Flutter teammate (after we share our contract) |
| E | Auth mechanism — JWT vs Firebase | Revisit when Flutter is handed over |

---

## 🧠 What We're Building
**QuickShield** — AI-driven parametric micro-insurance for quick-commerce gig delivery workers (Blinkit, Zepto, Swiggy Instamart).

### Core Value Prop
- Replaces manual claims with **deterministic, data-verified smart triggers**
- Guarantees **2/3 income floor** during verified disruptions
- Auto-payout via UPI (mocked for demo)
- Zero touch — worker just taps "Initiate Claim"

### The 2/3 Payout Formula
```
Expected Daily = Worker's 14-day rolling average (e.g., ₹900)
Guarantee Floor = Expected × 2/3 (e.g., ₹600)
Payout          = Guarantee Floor − Already Earned Today (e.g., ₹600 − ₹200 = ₹400)
```

---

## 🏗️ System Architecture

### Service Layout
```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                             │
│              Flutter App (teammate building)                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP REST
┌──────────────────────────▼──────────────────────────────────────┐
│                   SERVICE 1: Node.js API                        │
│                   (Express) — WE BUILD                          │
│  - Auth / Worker Management                                     │
│  - Policy & Premium logic                                       │
│  - Claims orchestration (3-gate pipeline)                       │
│  - Mock external API calls (Weather, UPI, Webhooks)             │
│  - Simulation endpoints                                         │
└──────┬───────────────────┬────────────────────────────┬─────────┘
       │ HTTP              │ SQL                         │ Redis
       │                  │                             │
┌──────▼──────┐   ┌───────▼────────┐   ┌───────────────▼─────────┐
│  SERVICE 2  │   │   Supabase     │   │   Upstash Redis          │
│  FastAPI    │   │  (PostgreSQL)  │   │  - Live zone maps        │
│  (Python)   │   │  - Users       │   │  - Active worker sessions│
│  ML Engine  │   │  - Policies    │   │  - Peer consensus cache  │
│  WE BUILD   │   │  - Claims      │   │  - Premium cache         │
│  (mock +    │   │  - Audit logs  │   └─────────────────────────┘
│  real model)│   │  - Ledger      │
└─────────────┘   └────────────────┘
```

### Tech Stack (Confirmed)
| Layer | Technology | Who builds |
|-------|-----------|-----------|
| Frontend | Flutter (Dart) | Teammate |
| Main API | Node.js (Express) | US |
| ML Engine | Python (FastAPI) | US (mock) + ML teammate (real model) |
| Database | Supabase (PostgreSQL) cloud | US (schema design) |
| Cache | Upstash (Redis) cloud | US |

---

## 🔄 System Operational Flow

### Phase A: Onboarding
1. Worker registers → links UPI ID + Delivery Platform ID
2. Backend fetches 14-day rolling avg income (mocked B2B webhook via Supabase or hardcoded)
3. FastAPI (XGBoost) calculates dynamic weekly premium (₹80–₹150)
4. Policy activated → 35-day rolling contract stored in PostgreSQL
5. UPI AutoPay mock → premium "deducted"

### Phase B: Passive Monitoring (Background, no direct API call needed for demo)
- App caches GPS polyline + Z-axis (Flutter handles this)
- Backend simulation endpoint injects fake disruption data

### Phase C: Claim Initiation
- Worker taps "Initiate Claim" in Flutter
- Flutter sends: `POST /claim/initiate` with:
  ```json
  {
    "worker_id": "W123",
    "photo_hash": "sha256:abc123...",
    "gps_polyline": [{"lat": 12.97, "lng": 77.59, "timestamp": 1711900800}],
    "z_axis_readings": [{"altitude_m": 920.4, "timestamp": 1711900800}],
    "platform_id": "BLK-W123",
    "last_order_timestamp": 1711900700
  }
  ```

### Phase D: 3-Gate Verification Pipeline
| Gate | Name | Logic | Outcome |
|------|------|-------|---------|
| **Gate 1** | Regulatory Bouncer | IRDAI global exclusion check → NDMA red alert check | Reject / CAT Mode / Pass |
| **Gate 2** | Adversarial Physics Engine | Z-axis static check + velocity check + VPN check + cross-platform state | Hard Reject / Pass |
| **Gate 3** | Composite Risk Engine | FastAPI XGBoost: Environmental + Operational + Topographical + Peer Consensus > 75/100 | Reject / Approve |

### Phase E: Resolution
- Calculate 2/3 payout
- Mock UPI transfer (generate fake txn ID)
- Fire mock "Algorithmic Amnesty" webhook to Blinkit
- Write cryptographic audit log to PostgreSQL
- Return response to Flutter

---

## 📊 4-Layer Disruption Engine
| Layer | Source | What it checks | Mock strategy |
|-------|--------|---------------|---------------|
| L1 | OpenWeather (mocked) | Precipitation ≥ X mm/hr, temp, wind | JSON mock file or in-memory object |
| L2 | B2B Webhooks (mocked) | Zone delivery velocity < 40% of 14-day avg | Seeded in DB or mock service |
| L3 | XGBoost ML (FastAPI) | Hex-grid risk score 0-100 | Mock Python function first |
| L4 | Redis Peer Consensus | >60% riders in cluster halted | Redis SET/GET simulation |

---

## 🛡️ 6-Layer Anti-Fraud Engine (Gate 2)
| Layer | Check | Reject Condition |
|-------|-------|-----------------|
| 1 | Z-Axis Altitude Invariance | Static altitude variance (unnatural 0.0 or constant) |
| 2 | Cross-Platform State Synergy | "Stranded" claim + "Order Delivered" on platform at same time |
| 3 | Network Metadata & Subnet Overlap | 50+ claims from identical VPN/IP node → circuit breaker |
| 4 | Spatial-Temporal Logic | Required velocity between locations exceeds physical speed limit |
| 5 | Behavioral Improbability | Millisecond-exact synchronized submission hits (bot pattern) |
| 6 | Hardware-Locked Verification | Gallery upload detected instead of in-app camera hash |

---

## 💰 Economic Model
- **Premium:** ₹80–₹150/week, recalculated every Sunday via XGBoost  
- **Contract:** 35-day rolling (5 weeks)  
- **48-hour cooling off:** No claims within first 48h of new subscription

### New User "Cold Start" Logic
- No 14-day baseline → uses **Zone Median Baseline**
- Zone Standard = avg delivery volume of top 20% riders in dark store (last 7 days)
- Trigger: Zone delivery rate < 40% of Zone Standard
- Payout based on Zone Median (e.g., ₹700/day)
- After 14 active days → migrates to Personalized Baseline automatically

---

## 🚫 Exclusions (Hard-coded in Gate 1)
- Acts of War / Terrorism → Hard Reject
- Global Pandemics / WHO emergencies → Hard Reject
- Nuclear/Chemical/Biological → Hard Reject
- Planned platform maintenance → Hard Reject
- First 48h of subscription → Hard Reject (cooling off)
- GPS spoofing detected → 30-day policy suspension

### IRDAI CAT Override (Special State)
- If NDMA "Red Alert" detected → Enter **CAT Mode**
  - Photo documentation relaxed
  - Fast-track payout prioritized
  - Premium deductions paused

---

## 🔌 External APIs (All Mocked)
| API | Purpose | Mock Strategy |
|-----|---------|--------------|
| OpenWeather API | Precipitation, temperature data | JSON mock service / scenario toggle |
| Google Maps API | Traffic density, zone velocity | Hardcoded mock response |
| NDMA API | Government Red Alert status | Boolean flag in DB or env variable |
| UPI AutoPay | Weekly premium deduction | Returns fake txn_id |
| UPI Payout | Claim payout | Returns fake txn_id |
| Blinkit Webhook (income) | 14-day rolling income baseline | Seeded in DB |
| Blinkit Webhook (amnesty) | Freeze performance penalties | Logs to DB, returns 200 OK mock |

---

## 📋 API Endpoints (We Define — Share with Flutter teammate)

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Worker onboarding — name, UPI ID, platform ID |
| POST | `/auth/login` | Returns JWT token |
| GET | `/auth/me` | Get current worker profile |

### Policy & Premium
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/policy` | Get worker's active policy details |
| POST | `/policy/activate` | Buy/activate a new weekly policy |
| POST | `/policy/cancel` | Cancel active policy |
| GET | `/premium/calculate` | Get dynamic premium quote for upcoming week |

### Claims
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/claim/initiate` | Submit a new claim with full payload |
| GET | `/claim/status/:id` | Poll claim processing status |
| GET | `/claim/history` | Worker's past claims list |

### Simulation (Demo Endpoints)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/simulate/trigger-disruption` | Inject a fake disruption event (for demo) |
| POST | `/simulate/clear-disruption` | Reset to normal state |
| GET | `/simulate/zone-status` | Get current zone risk status |

### Admin / Insurer Dashboard (Phase 3)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/dashboard` | Loss ratios, active policies, claims stats |
| GET | `/admin/claims` | All claims with approval status |
| GET | `/admin/workers` | All registered workers |
| GET | `/admin/risk-map` | Zone-level risk heat map data |

---

## 🤖 ML Integration (Secured Child Process Bridge)

### Architecture Shift
Initially planned as a standalone FastAPI microservice, the Machine Learning engine has been embedded directly into the Node.js backend using a `child_process.spawn()` bridge to execute `predict_store_risk`. 

Because Python and XGBoost dependencies are not natively installed on the hackathon laptop, the integration uses a **Node.js deterministic mock** (`predict_store_risk.js`). This mock perfectly simulates the child process architecture and the XGBoost inputs/outputs out-of-the-box for the video demo.

### Execution Path
Node.js Express Controller (`premium.service.js`) → `child_process.spawn('node', ['./ml/predict_store_risk.js', storeId, city, zone, date])` → Parses Float Score (0-100).

### Known Caveats for Demo
1. **Frontend Payload Mapping:** The frontend flutter app currently only knows `city` and `platform`. The backend auto-generates a mock "Store ID" format required by the model (e.g., `MUM_ZEP_001`).
2. **Deterministic Risk:** The fallback Javascript `predict_store_risk.js` evaluates the input city and date month (to catch the monsoon season) to return realistic, varied Risk Scores guaranteed to impress the judges.

---

## 🗄️ Database Schema (PostgreSQL via Supabase)

### Tables Needed
```sql
-- Workers
workers (id, name, upi_id, platform_id, zone_id, 14day_avg_income, joined_at, is_suspended)

-- Zones
zones (id, name, city, dark_store_name, zone_median_income, zone_standard_baseline)

-- Policies
policies (id, worker_id, start_date, end_date, weekly_premium, status, coverage_tier)

-- Claims
claims (id, worker_id, policy_id, initiated_at, status, gate1_result, gate2_result, 
        gate3_score, payout_amount, txn_id, audit_payload_json)

-- Disruption Events
disruption_events (id, zone_id, event_type, severity, started_at, ended_at, is_active, source)

-- Premium Ledger
premium_ledger (id, worker_id, amount, deducted_at, txn_id, status)

-- Payout Ledger
payout_ledger (id, claim_id, worker_id, amount, paid_at, txn_id, status)
```

---

## 📁 Project File Structure (Planned)

```
QuickShield-Backend/           ← Fresh folder (Service 1: Node.js)
├── src/
│   ├── routes/
│   │   ├── auth.js
│   │   ├── policy.js
│   │   ├── claims.js
│   │   ├── premium.js
│   │   ├── simulate.js
│   │   └── admin.js
│   ├── controllers/
│   ├── services/
│   │   ├── mlService.js       ← Calls FastAPI
│   │   ├── upiMock.js         ← Mock UPI payout
│   │   ├── weatherMock.js     ← Mock OpenWeather
│   │   ├── webhookMock.js     ← Mock Blinkit webhooks
│   │   └── ndmaMock.js        ← Mock NDMA alerts
│   ├── middleware/
│   │   ├── auth.js            ← JWT validation
│   │   └── errorHandler.js
│   ├── models/                ← DB query functions (raw pg or Prisma)
│   └── config/
│       ├── db.js              ← Supabase connection
│       └── redis.js           ← Upstash Redis connection
├── .env.example
├── package.json
└── README.md

QuickShield-ML/                ← Service 2: Python FastAPI
├── main.py                    ← FastAPI app
├── routers/
│   ├── score.py               ← /score/* endpoints
│   └── anomaly.py
├── models/
│   └── model.json             ← XGBoost model (from ML teammate)
├── services/
│   ├── disruption_scorer.py   ← TODO: replace mock with real model
│   ├── premium_calculator.py  ← TODO: replace mock with real model
│   └── anomaly_detector.py    ← scikit-learn behavioral anomaly
├── requirements.txt
└── README.md
```

---

## 🎬 Demo Scenarios (Backend Supports All)
| Scenario | Description | Gates |
|----------|-------------|-------|
| **A** | Normal day, sunny weather, worker earning normally — no payout triggered | All pass, score < 75 |
| **B** | Cloudburst hits → all 3 gates pass → UPI payout fires instantly | All pass, score > 75 |
| **C** | GPS spoofing attempt → Gate 2 catches static altitude → Hard Reject | Gate 2 fails |
