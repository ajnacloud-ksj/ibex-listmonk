#!/bin/bash

# Data Alert Examples for Ajna Listmonk
# User: ajna
# Password: pYh9XXkvTQuYP1kDT93y11tasHphuDze

BASE_URL="http://localhost:9000/api"
AUTH="ajna:pYh9XXkvTQuYP1kDT93y11tasHphuDze"

echo "🚨 Ajna Data Alert Templates Demo"
echo "=================================="
echo ""

# Email Data Alert Example
echo "📧 Sending Email Data Alert..."
curl -X POST $BASE_URL/tx \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_emails": ["admin@company.com"],
    "template_id": 5,
    "data": {
      "alert_type": "Critical Data Quality Issue",
      "severity": "CRITICAL",
      "metric_name": "data.completeness.percentage",
      "current_value": "65.2%",
      "threshold": "95%",
      "affected_records": 12847,
      "dataset": "customer_transactions",
      "description": "Data completeness has dropped significantly below acceptable thresholds. Multiple required fields are showing high null rates.",
      "recommended_action": "1. Check data ingestion pipeline\n2. Validate source system connectivity\n3. Review ETL transformations\n4. Contact data engineering team",
      "dashboard_url": "https://dashboard.company.com/data-quality",
      "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
      "alert_id": "DQ-'$(date +%s)'"
    }
  }'

echo ""
echo ""

# Slack Data Alert Example  
echo "💬 Sending Slack Data Alert..."
curl -X POST $BASE_URL/tx \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_emails": ["alerts@company.com"],
    "template_id": 6,
    "data": {
      "alert_type": "Memory Usage Alert",
      "severity": "WARNING", 
      "metric_name": "system.memory.usage",
      "current_value": "87.3%",
      "threshold": "85%",
      "description": "Memory usage on production servers is approaching critical levels.",
      "recommended_action": "Scale horizontally or investigate memory leaks",
      "dashboard_url": "https://monitoring.company.com/memory",
      "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
      "alert_id": "MEM-'$(date +%s)'"
    }
  }'

echo ""
echo ""
echo "✅ Data alert examples sent!"
echo ""
echo "Template IDs:"
echo "- Email Template: ID 5 (Data Alert Email)"
echo "- Slack Template: ID 6 (Data Alert Slack)"
echo ""
echo "Available data fields for templates:"
echo "- alert_type: Type of alert"
echo "- severity: CRITICAL, WARNING, INFO"
echo "- metric_name: Name of the metric"
echo "- current_value: Current metric value"
echo "- threshold: Alert threshold"
echo "- affected_records: Number of affected records"
echo "- dataset: Dataset name"
echo "- description: Alert description"
echo "- recommended_action: What to do"
echo "- dashboard_url: Link to dashboard"
echo "- timestamp: When the alert was triggered"
echo "- alert_id: Unique alert identifier"
