# Timestamp Issue Fix Guide

## 🚨 **Problem**
The `{{$isoTimestamp}}` in your Postman requests shows up literally in emails instead of being replaced with actual timestamps.

## ✅ **Solutions**

### **Option 1: Postman Pre-request Script (Recommended)**

1. **In Postman Collection/Request:**
   - Go to **Pre-request Script** tab
   - Add this code:
   ```javascript
   pm.environment.set("current_timestamp", new Date().toISOString());
   ```

2. **Update your JSON payload:**
   ```json
   {
     "data": {
       "timestamp": "{{current_timestamp}}"
     }
   }
   ```

### **Option 2: Manual Timestamp Replacement**

Replace `{{$isoTimestamp}}` with actual ISO timestamp in your requests:
```json
{
  "data": {
    "timestamp": "2025-08-24T13:47:00Z"
  }
}
```

### **Option 3: Using curl with Dynamic Timestamp**
```bash
curl -u "ajna:password" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": {
      \"timestamp\": \"$(date -u +\"%Y-%m-%dT%H:%M:%SZ\")\"
    }
  }" \
  http://localhost:9000/api/tx
```

## 📧 **Adding Missing Subscribers**

If you get `"Subscriber not found"` errors:

```bash
curl -u "ajna:password" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "name": "Your Name",
    "status": "enabled",
    "lists": [3],
    "preconfirm_subscriptions": true
  }' \
  http://localhost:9000/api/subscribers
```

## 🎯 **Working Example**

```json
{
  "subscriber_emails": ["techmanforhelp@gmail.com"],
  "data": {
    "alert_type": "DISK_FULL",
    "severity": "CRITICAL",
    "description": "Disk usage reached 95% on production server",
    "timestamp": "{{current_timestamp}}",
    "current_value": "95.8%",
    "threshold": "90%"
  },
  "channels": [
    {
      "channel": "email",
      "template_id": 7
    }
  ]
}
```

This will show the actual timestamp in your emails instead of the literal `{{$isoTimestamp}}` text.
