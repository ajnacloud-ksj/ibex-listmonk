#!/bin/bash

# Data Alert Testing Script for Ajna Listmonk
# User: ajna
# Password: pYh9XXkvTQuYP1kDT93y11tasHphuDze
# Subscriber: sbpraonalla@gmail.com

BASE_URL="http://localhost:9000/api"
AUTH="ajna:pYh9XXkvTQuYP1kDT93y11tasHphuDze"
SUBSCRIBER="sbpraonalla@gmail.com"

echo "🚨 Ajna Data Alert Templates - Live Testing"
echo "==========================================="
echo "Subscriber: $SUBSCRIBER"
echo "Templates: Email (ID: 5), Slack (ID: 6)"
echo ""

# Test 1: Critical Data Quality Alert (Email)
echo "📧 Test 1: Critical Data Quality Alert (Email Template)"
echo "---------------------------------------------------"
curl -X POST $BASE_URL/tx \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_emails": ["'"$SUBSCRIBER"'"],
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

# Test 2: Memory Usage Warning (Slack)
echo "💬 Test 2: Memory Usage Warning (Slack Template)"
echo "-----------------------------------------------"
curl -X POST $BASE_URL/tx \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_emails": ["'"$SUBSCRIBER"'"],
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

# Test 3: Database Failure (Email)
echo "🔥 Test 3: Database Connection Failure (Email Template)"
echo "-----------------------------------------------------"
curl -X POST $BASE_URL/tx \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_emails": ["'"$SUBSCRIBER"'"],
    "template_id": 5,
    "data": {
      "alert_type": "Database Connection Failure",
      "severity": "CRITICAL",
      "metric_name": "database.connection.status",
      "current_value": "FAILED",
      "threshold": "CONNECTED",
      "affected_records": 0,
      "dataset": "production_database",
      "description": "Primary database connection has failed. All write operations are currently blocked.",
      "recommended_action": "1. Check database server status\n2. Verify network connectivity\n3. Restart database service if needed\n4. Activate failover procedures",
      "dashboard_url": "https://monitoring.company.com/database",
      "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
      "alert_id": "DB-'$(date +%s)'"
    }
  }'

echo ""
echo ""

# Test 4: Disk Space Info Alert (Slack)
echo "💾 Test 4: Disk Space Info Alert (Slack Template)"
echo "------------------------------------------------"
curl -X POST $BASE_URL/tx \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_emails": ["'"$SUBSCRIBER"'"],
    "template_id": 6,
    "data": {
      "alert_type": "Disk Space Notification",
      "severity": "INFO",
      "metric_name": "disk.usage.percentage",
      "current_value": "72%",
      "threshold": "80%",
      "description": "Disk usage is within normal ranges but trending upward.",
      "recommended_action": "Monitor usage trends and plan for cleanup if needed",
      "dashboard_url": "https://monitoring.company.com/storage",
      "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
      "alert_id": "DISK-'$(date +%s)'"
    }
  }'

echo ""
echo ""
echo "✅ All data alert tests completed!"
echo ""
echo "📊 Summary:"
echo "- 4 alerts sent to: $SUBSCRIBER"
echo "- 2 email alerts (Template ID: 5)"
echo "- 2 Slack alerts (Template ID: 6)"
echo "- Severity levels tested: CRITICAL, WARNING, INFO"
echo ""
echo "🔧 Template Data Fields Available:"
echo "  - alert_type, severity, metric_name, current_value"
echo "  - threshold, affected_records, dataset, description"
echo "  - recommended_action, dashboard_url, timestamp, alert_id"
