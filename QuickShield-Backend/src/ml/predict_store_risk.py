import sys
import pandas as pd
import xgboost as xgb
import joblib
from datetime import datetime

def predict_risk(store_id, city, zone, date_str):
    try:
        # 1. Load Model and Encoders
        model = xgb.XGBRegressor()
        model.load_model("quickshield_store_risk_model.json")

        s_enc = joblib.load('store_encoder.pkl')
        c_enc = joblib.load('city_encoder.pkl')
        z_enc = joblib.load('zone_encoder.pkl')

        # 2. Process Inputs
        date_obj = datetime.strptime(date_str, '%Y-%m-%d')
        month = date_obj.month
        week = date_obj.isocalendar()[1]

        # Convert text to IDs
        s_id = s_enc.transform([store_id])[0]
        c_id = c_enc.transform([city])[0]
        z_id = z_enc.transform([zone])[0]

        # 3. Predict
        input_df = pd.DataFrame([[s_id, c_id, z_id, month, week]], 
                                columns=['Store_Code', 'City_Code', 'Zone_Code', 'Month', 'Week_Number'])

        score = model.predict(input_df)[0]
        return round(float(score), 2)

    except Exception as e:
        return f"Error: {str(e)}"

if __name__ == "__main__":
    # Expects: python predict_store_risk.py "BLR_ZEP_001" "Bangalore" "Indiranagar" "2026-04-02"
    if len(sys.argv) == 5:
        print(predict_risk(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]))
