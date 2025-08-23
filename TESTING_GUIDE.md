# 🧪 Ajna Listmonk Testing Guide

## 🎯 Testing the Multi-Channel Enhancements

This guide shows how to test the new multi-channel and PayloadTemplate features.

## 📋 Prerequisites

1. **Upgraded Go Version**: Ensure Go 1.21+ is installed
2. **Running Listmonk**: Build and start the enhanced Listmonk
3. **Test Webhooks**: Set up test endpoints for Slack/Teams

## 🔧 Setup Test Environment

### 1. Build Enhanced Listmonk
```bash
cd /Users/parameshnalla/ajna/ajna-expriements/data-pipeline-stack/listmonk
go mod tidy
go build -o listmonk cmd/*.go
```

### 2. Configure Test Messengers

Add to your Listmonk settings via UI or database:

#### Slack Test Messenger
```sql
UPDATE settings SET value = '[
  {
    "enabled": true,
    "name": "slack-rich",
    "root_url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
    "username": "",
    "password": "",
    "max_conns": 1,
    "timeout": "5s",
    "max_msg_retries": 2,
    "payload_template": "{\"text\": \"{{ .Subject }}\", \"blocks\": [{\"type\": \"header\", \"text\": {\"type\": \"plain_text\", \"text\": \"🚨 {{ .Subject }}\"}}, {\"type\": \"section\", \"text\": {\"type\": \"mrkdwn\", \"text\": \"{{ .Body }}\"}}]}"
  },
  {
    "enabled": true,
    "name": "teams-cards",
    "root_url": "https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK",
    "username": "",
    "password": "",
    "max_conns": 1,
    "timeout": "5s", 
    "max_msg_retries": 2,
    "payload_template": "{\"@type\": \"MessageCard\", \"summary\": \"{{ .Subject }}\", \"text\": \"{{ .Body }}\", \"themeColor\": \"FF0000\", \"sections\": [{\"activityTitle\": \"{{ .Subject }}\", \"activityText\": \"{{ .Body }}\"}]}"
  }
]' WHERE key = 'messengers';
```

## 🧪 Test Cases

### Test 1: Single Channel (Backward Compatibility)
```bash
curl -X POST http://localhost:9000/api/tx \
  -u "ajna:y42MWx0dWWf7SX1aIQc5LXnUjkY1SDZ5" \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_emails": ["test@example.com"],
    "template_id": 5,
    "messenger": "slack-rich",
    "data": {
      "alert_type": "Test Alert",
      "severity": "Low"
    }
  }'
```

**Expected**: Single Slack message with rich formatting

### Test 2: Multi-Channel Delivery
```bash
curl -X POST http://localhost:9000/api/tx \
  -u "ajna:y42MWx0dWWf7SX1aIQc5LXnUjkY1SDZ5" \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_emails": ["test@example.com"],
    "template_id": 5,
    "messengers": ["slack-rich", "teams-cards"],
    "data": {
      "alert_type": "Multi-Channel Test",
      "severity": "Medium"
    }
  }'
```

**Expected**: 
- ✅ Slack message with Block Kit formatting
- ✅ Teams message with MessageCard formatting

### Test 3: PayloadTemplate Validation
```bash
# Test with invalid template
curl -X POST http://localhost:9000/api/tx \
  -u "ajna:y42MWx0dWWf7SX1aIQc5LXnUjkY1SDZ5" \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_emails": ["test@example.com"],
    "template_id": 5,
    "messenger": "invalid-template-messenger",
    "data": {"test": "data"}
  }'
```

**Expected**: Error logged but processing continues

## 🔍 Monitoring and Debugging

### 1. Check Listmonk Logs
```bash
tail -f listmonk.log | grep -E "(error|payload|template)"
```

### 2. Verify Template Rendering
Create a test capture server:
```go
// test-capture-server.go
package main

import (
    "fmt"
    "io"
    "net/http"
    "log"
)

func handler(w http.ResponseWriter, r *http.Request) {
    body, _ := io.ReadAll(r.Body)
    fmt.Printf("Received payload:\n%s\n\n", string(body))
    w.WriteHeader(200)
    w.Write([]byte("OK"))
}

func main() {
    http.HandleFunc("/", handler)
    log.Println("Test capture server running on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

Configure test messenger:
```json
{
  "name": "test-capture",
  "root_url": "http://localhost:8080",
  "payload_template": "{\"test\": true, \"subject\": \"{{ .Subject }}\", \"body\": \"{{ .Body }}\"}"
}
```

### 3. Database Verification
```sql
-- Check messenger configuration
SELECT value FROM settings WHERE key = 'messengers';

-- Check template content
SELECT id, name, body FROM templates WHERE type = 'tx';
```

## 🎪 Advanced Tests

### Test Rich Slack Formatting
```json
{
  "payload_template": "{\"text\": \"{{ .Subject }}\", \"blocks\": [{\"type\": \"header\", \"text\": {\"type\": \"plain_text\", \"text\": \"🚨 Alert\"}}, {\"type\": \"section\", \"fields\": [{\"type\": \"mrkdwn\", \"text\": \"*Type:*\\n{{ .Subscriber.Name }}\"}, {\"type\": \"mrkdwn\", \"text\": \"*Severity:*\\nHigh\"}]}, {\"type\": \"actions\", \"elements\": [{\"type\": \"button\", \"text\": {\"type\": \"plain_text\", \"text\": \"View Dashboard\"}, \"url\": \"https://dashboard.company.com\"}]}]}"
}
```

### Test Teams Adaptive Cards
```json
{
  "payload_template": "{\"@type\": \"MessageCard\", \"summary\": \"{{ .Subject }}\", \"themeColor\": \"FF0000\", \"sections\": [{\"activityTitle\": \"{{ .Subject }}\", \"activityText\": \"{{ .Body }}\", \"facts\": [{\"name\": \"Subscriber\", \"value\": \"{{ .Subscriber.Email }}\"}, {\"name\": \"Time\", \"value\": \"Now\"}]}], \"potentialAction\": [{\"@type\": \"OpenUri\", \"name\": \"View Details\", \"targets\": [{\"os\": \"default\", \"uri\": \"https://dashboard.company.com\"}]}]}"
}
```

## ✅ Success Criteria

1. **Backward Compatibility**: Existing single messenger calls work unchanged
2. **Multi-Channel**: Single API call sends to multiple messengers  
3. **Rich Formatting**: Slack Block Kit and Teams cards render correctly
4. **Error Handling**: Failed messengers don't stop others
5. **Template Processing**: PayloadTemplate renders with correct data
6. **Performance**: No significant latency increase

## 🚨 Troubleshooting

### Common Issues

1. **Template Parse Error**: Check JSON escaping in payload_template
2. **Webhook 400 Error**: Verify payload format matches channel requirements
3. **Missing Data**: Ensure template variables exist in data structure
4. **Authentication**: Verify webhook URLs and credentials

### Debug Commands
```bash
# Test template parsing
echo '{"Subject":"Test","Body":"Content"}' | jq '.'

# Validate JSON payload
curl -X POST http://localhost:8080 -d '{"test": "{{ .Subject }}"}'

# Check messenger connectivity
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK -d '{"text":"test"}'
```
