"""
QuickShield ML Service — FastAPI
Provides risk scoring and premium calculation for the main Node.js backend.

Model: XGBoost binary classifier trained on synthetic gig worker disruption data.
Output: risk_score (0–100, float) — higher = more likely to be disrupted.
Premium is calculated in Node.js (not here), based on the risk score.
"""

import os
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from dotenv import load_dotenv
import numpy as np

load_dotenv()

# ── Try loading real XGBoost model ───────────────────────────────────────────
# TODO: REPLACE WITH REAL MODEL — place model.json in the same directory
# Your teammate should run: model.save_model('model.json') in their training script
MODEL_PATH = Path(__file__).parent / "model.json"

xgb_model = None
try:
    import xgboost as xgb
    if MODEL_PATH.exists():
        xgb_model = xgb.Booster()
        xgb_model.load_model(str(MODEL_PATH))
        print(f"[OK] XGBoost model loaded from {MODEL_PATH}")
    else:
        print(f"[WARN] model.json not found at {MODEL_PATH} -- using mock scorer")
except ImportError:
    print("[WARN] xgboost not installed -- using mock scorer")

# ─────────────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="QuickShield ML Service",
    description="Risk scoring API for QuickShield parametric insurance",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────────────────────────────────────
# Request / Response schemas
# ─────────────────────────────────────────────────────────────────────────────

class RiskRequest(BaseModel):
    zone_id: str                = Field(..., example="BLR-SOUTH")
    platform: str               = Field(..., example="blinkit")
    city: str                   = Field("Bangalore", example="Bangalore")
    hour_of_day: int            = Field(14, ge=0, le=23)
    day_of_week: int            = Field(2, ge=0, le=6)
    days_active_last_30: int    = Field(20, ge=0, le=30)
    avg_daily_earnings_14d: float = Field(900.0, ge=0)

class RiskResponse(BaseModel):
    risk_score: float
    risk_level: str
    model_used: str
    features_used: dict

class PremiumRequest(BaseModel):
    risk_score: float           = Field(..., ge=0, le=100)
    avg_daily_earnings_14d: float = Field(900.0)
    duration_weeks: int         = Field(1, ge=1, le=52)
    zone_id: str                = Field("DEFAULT")

class PremiumResponse(BaseModel):
    premium_inr: float
    risk_score: float
    breakdown: dict

# ─────────────────────────────────────────────────────────────────────────────
# Endpoints
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "QuickShield ML Service",
        "model_loaded": xgb_model is not None,
        "model_path": str(MODEL_PATH),
    }


@app.post("/score/risk", response_model=RiskResponse)
def score_risk(req: RiskRequest):
    """
    Returns a risk score (0–100) for a worker's zone and context.
    Higher score = higher disruption risk = higher premium.
    """
    features = req.model_dump()

    if xgb_model is not None:
        # ── Real model inference ──────────────────────────────────────────
        # TODO: CONFIRM EXACT FEATURE NAMES WITH ML TEAMMATE
        # The feature vector must match what was used during training.
        # Update this list once your teammate confirms the training features.
        feature_vector = build_feature_vector(features)
        dmatrix = xgb.DMatrix(np.array([feature_vector]))
        raw_score = float(xgb_model.predict(dmatrix)[0])
        # Normalize to 0-100 if model outputs probability (0-1)
        risk_score = raw_score * 100 if raw_score <= 1.0 else raw_score
        model_used = "xgboost_real"
    else:
        # ── Mock scorer fallback ──────────────────────────────────────────
        risk_score = mock_risk_score(features)
        model_used = "mock_heuristic"

    risk_level = get_risk_level(risk_score)

    return RiskResponse(
        risk_score=round(risk_score, 2),
        risk_level=risk_level,
        model_used=model_used,
        features_used=features,
    )


@app.post("/score/premium", response_model=PremiumResponse)
def score_premium(req: PremiumRequest):
    """
    Calculates insurance premium from risk score.
    NOTE: Node.js backend also calculates this — this endpoint is for direct
    ML service testing or if the mobile app calls ML directly in future.
    """
    risk_score       = req.risk_score
    weekly_earnings  = req.avg_daily_earnings_14d * 7
    base_rate        = 0.015   # 1.5% of weekly earnings
    base_premium     = weekly_earnings * base_rate * req.duration_weeks

    risk_multiplier = 1.3 if risk_score >= 70 else 1.0 if risk_score >= 40 else 0.8
    premium_inr     = round(min(max(base_premium * risk_multiplier, 50), 500), 2)

    return PremiumResponse(
        premium_inr=premium_inr,
        risk_score=risk_score,
        breakdown={
            "weekly_earnings": weekly_earnings,
            "base_rate": "1.5%",
            "base_premium": round(base_premium, 2),
            "risk_multiplier": risk_multiplier,
            "floor_inr": 50,
            "ceiling_inr": 500,
        },
    )

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def get_risk_level(score: float) -> str:
    if score >= 70: return "High"
    if score >= 40: return "Medium"
    return "Low"


def mock_risk_score(features: dict) -> float:
    """
    Heuristic mock scorer — used when model.json is not available.
    Delete or disable once real model is loaded.

    TODO: REPLACE WITH REAL MODEL — the logic below is a placeholder.
    Ask your ML teammate for the final trained model.json file.
    """
    score = 40.0  # baseline

    hour = features.get("hour_of_day", 12)
    if 11 <= hour <= 14:   score += 15  # lunch rush
    if 18 <= hour <= 21:   score += 20  # dinner rush

    zone_id = features.get("zone_id", "")
    high_risk_zones = ["BLR-NORTH", "MUM-CENTRAL", "DEL-EAST"]
    if zone_id in high_risk_zones: score += 15

    platform = features.get("platform", "")
    if platform in ("swiggy", "zomato"): score += 5

    days_active = features.get("days_active_last_30", 20)
    if days_active < 10: score += 10

    return float(min(max(score, 0), 100))


def build_feature_vector(features: dict) -> list:
    """
    Converts request features to the exact array format the XGBoost model expects.

    TODO: CONFIRM EXACT FEATURE ORDER WITH ML TEAMMATE.
    This list must match the column order used during model training.
    Update once your teammate shares the feature names / training code.
    """
    # Placeholder feature encoding
    zone_risk_map = {
        "BLR-SOUTH": 45, "BLR-NORTH": 60, "BLR-EAST": 50,
        "MUM-CENTRAL": 70, "MUM-WEST": 55, "DEL-EAST": 65,
        "DEL-SOUTH": 50, "DEFAULT": 50,
    }
    platform_map = {"blinkit": 0, "swiggy": 1, "zomato": 2, "zepto": 3}

    return [
        features.get("hour_of_day", 12),
        features.get("day_of_week", 2),
        zone_risk_map.get(features.get("zone_id", "DEFAULT"), 50),
        platform_map.get(features.get("platform", "blinkit"), 0),
        features.get("days_active_last_30", 20),
        features.get("avg_daily_earnings_14d", 900.0),
    ]


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
