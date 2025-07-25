
# 🩺 Medicaid Cost Analytics Dashboard

This project simulates, analyzes, forecasts, and visualizes Medicaid claim data using SQL, Python, and Power BI.

## 📊 Project Goals

- Simulate realistic Medicaid claims and enrollment data
- Calculate PMPM (Per Member Per Month) trends
- Detect avoidable ER visit cost spikes
- Forecast PMPM using time-series models
- Build interactive dashboards in Power BI and Streamlit

---

## 📁 Project Structure

```
medicaid-analytics-dashboard/
├── PowerBI/
│   ├── pmpm_final.csv
│   ├── er_spikes_powerbi.csv
│   └── medicaid_dashboard.pbix
├── Notebooks/
│   ├── pmpm_forecast_notebook.ipynb
│   ├── er_spike_detection_notebook.ipynb
├── Streamlit/
│   └── streamlit_app.py
├── README.md
```

---

## 🏗️ Tools Used

- **SQL**: Data modeling and PMPM calculation using window functions and CTEs
- **Python**: Forecasting with Pandas, Statsmodels
- **Streamlit**: Interactive dashboard (optional)
- **Power BI**: Visual dashboard with slicers and breakdowns

---

## 🔍 Key Features

### ✅ PMPM Calculation
- Monthly cost per member
- Grouped by claim type (Inpatient, Pharmacy)
- Cleaned and pre-aggregated in SQL

### ✅ ER Spike Detection
- Avoidable ER visits flagged via encounter data
- Monthly aggregation and z-score based spike alerts

### ✅ Forecasting
- PMPM trend forecast using exponential smoothing
- Optional ARIMA model (future extension)

### ✅ Dashboards
- **Power BI**: Trend line, ER table, cost breakdown
- **Streamlit**: Browser-based interactive app

---

## 🖥 How to Run

### 📊 Power BI
1. Open `medicaid_dashboard.pbix`
2. Load the CSVs from `PowerBI/`
3. Interact with slicers, trends, and tables

### 📘 Jupyter Notebooks
- Open notebooks from `Notebooks/`
- Run cell-by-cell to explore forecasting and spike detection

### 🖥 Streamlit (Optional)
```bash
pip install streamlit pandas matplotlib
streamlit run Streamlit/streamlit_app.py
```

---

## 🏁 Author
**Sai Vara Prasad Bhaskarla**

This project is designed for portfolio presentation, interview demo, or stakeholder engagement.

