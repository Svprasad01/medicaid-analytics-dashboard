
import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt

st.set_page_config(page_title="Healthcare Cost Dashboard", layout="wide")

st.title("📊 Medicaid Cost Forecasting & ER Spike Dashboard")

# Load datasets
@st.cache_data
def load_data():
    pmpm = pd.read_csv("pmpm.csv")
    er = pd.read_csv("avoidable_er_trend.csv")
    pmpm["member_month"] = pd.to_datetime(pmpm["member_month"])
    er["member_month"] = pd.to_datetime(er["member_month"])
    return pmpm, er

pmpm, er_trend = load_data()

# Sidebar filters
claim_types = pmpm["claim_type"].dropna().unique().tolist()
selected_claim = st.sidebar.selectbox("Select Claim Type", claim_types)

# Filtered PMPM data
filtered_pmpm = pmpm[pmpm["claim_type"] == selected_claim]

# PMPM Chart
st.subheader(f"PMPM Trend - {selected_claim}")
fig, ax = plt.subplots(figsize=(10, 4))
ax.plot(filtered_pmpm["member_month"], filtered_pmpm["pmpm"], marker="o", label="PMPM")
ax.set_xlabel("Month")
ax.set_ylabel("PMPM ($)")
ax.set_title(f"PMPM by Month - {selected_claim}")
ax.grid(True)
st.pyplot(fig)

# ER Spike Chart
st.subheader("Avoidable ER Cost Trend")
fig2, ax2 = plt.subplots(figsize=(10, 4))
ax2.plot(er_trend["member_month"], er_trend["total_avoidable_cost"], marker="o", color="red", label="ER Cost")
ax2.set_xlabel("Month")
ax2.set_ylabel("Total Avoidable ER Cost ($)")
ax2.set_title("Monthly Avoidable ER Cost")
ax2.grid(True)
st.pyplot(fig2)

# Data Preview
with st.expander("📄 Raw PMPM Data"):
    st.dataframe(filtered_pmpm)

with st.expander("📄 Raw ER Spike Data"):
    st.dataframe(er_trend)
