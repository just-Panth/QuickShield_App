# QuickShield ML Integration Guide (Phase 2)

## 📌 Project Overview
This folder contains the trained Machine Learning engine for calculating seasonal Risk Scores based on historical climate data and public disruptions in India.

## 📁 File Manifest
1. `quickshield_seasonal_risk.json`: The trained XGBoost model (The Brain).
2. `city_encoder.pkl`: Label encoder for City names.
3. `state_encoder.pkl`: Label encoder for State names.
4. `model_metadata.json`: JSON mapping of all City/State IDs for reference.
5. `predict_risk.py`: The Bridge script used to get predictions.
6. `QUICKSHIELD_Final_Risk_Data.csv`: Historical dataset with pre-calculated risk scores.

## 🛠 Prerequisites
The server running this code must have Python installed with the following libraries:
- pip install xgboost pandas joblib scikit-learn numpy

## 🚀 How to Integrate (Node.js)
The backend should call `predict_risk.py` using a child process.

**Command Format:**
python predict_risk.py "<City>" "<State>" "<YYYY-MM-DD>"

**Example:**
python predict_risk.py "Mumbai" "Maharashtra" "2026-07-20"

## 📊 Input Features Explained
The model predicts risk based on the following features extracted from the input:
1. City_ID: Encoded ID of the city.
2. State_ID: Encoded ID of the state.
3. Month: Extracted from the date (captures seasonality like Monsoon/Summer).
4. Week_Number: Extracted from the date (captures specific weekly trends).

## ⚠️ Important Notes
- Ensure all .json and .pkl files remain in the same directory as predict_risk.py.
- The Risk Score returned is a float between 0 and 100.
- 0-30: Low Risk (Standard Premium)
- 31-60: Moderate Risk (Adjusted Premium)
- 61-100: High Risk (Adversarial Conditions - Protective Premium)

Developed for QuickShield Underwriting Engine.
