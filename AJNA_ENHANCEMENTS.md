# 🚀 Ajna Listmonk Enhancements

## 📋 Overview

This fork adds **multi-channel support** and **template-driven payload formatting** to Listmonk, enabling rich notifications to Slack, Teams, and other channels through a single API call.

## 🔥 Features Added

### 1. **PayloadTemplate Support for Messengers**
- **File**: `internal/messenger/postback/postback.go`
- **Feature**: Custom payload formatting per messenger
- **Benefit**: Send rich Slack Block Kit, Teams Adaptive Cards, etc.

### 2. **Multi-Channel TX API**
- **File**: `models/models.go` + `cmd/tx.go`  
- **Feature**: Send to multiple messengers in single API call
- **Benefit**: One call → Slack + Teams + Email delivery

### 3. **Backward Compatibility**
- All existing functionality remains unchanged
- Optional fields with `omitempty` tags
- Default fallback behavior

## 🎯 Usage Examples

### Multi-Channel TX API Call
```bash
curl -X POST http://listmonk:9000/api/tx \
  -u "ajna:y42MWx0dWWf7SX1aIQc5LXnUjkY1SDZ5" \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_emails": ["ops@company.com"],
    "template_id": 5,
    "messengers": ["slack-rich", "teams-cards", "email"],
    "data": {
      "alert_type": "Critical Data Anomaly",
      "severity": "High",
      "affected_records": 1247
    }
  }'
```

### Messenger Configuration with PayloadTemplate

#### Slack Rich Notifications
```json
{
  "name": "slack-rich",
  "root_url": "https://hooks.slack.com/services/...",
  "payload_template": "{\"text\": \"{{ .Subject }}\", \"blocks\": [{\"type\": \"section\", \"text\": {\"type\": \"mrkdwn\", \"text\": \"*{{ .Subject }}*\\n\\n{{ .Body }}\"}}]}"
}
```

#### Teams Adaptive Cards
```json
{
  "name": "teams-cards",
  "root_url": "https://outlook.office.com/webhook/...",
  "payload_template": "{\"@type\": \"MessageCard\", \"summary\": \"{{ .Subject }}\", \"text\": \"{{ .Body }}\", \"themeColor\": \"FF0000\"}"
}
```

## 🏗️ Implementation Details

### Changes Made

#### 1. Enhanced Postback Messenger (`postback.go`)
```go
type Options struct {
    // ... existing fields ...
    PayloadTemplate string `json:"payload_template,omitempty"`
}

func (p *Postback) Push(m models.Message) error {
    if p.o.PayloadTemplate != "" {
        return p.pushWithTemplate(m)
    }
    return p.pushDefault(m)  // Backward compatibility
}
```

#### 2. Multi-Channel TxMessage (`models.go`)
```go
type TxMessage struct {
    // ... existing fields ...
    Messenger   string   `json:"messenger"`
    Messengers  []string `json:"messengers,omitempty"`  // NEW
}
```

#### 3. TX Handler Enhancement (`tx.go`)
```go
// Determine messengers to use (multi-channel support)
messengers := []string{}
if len(m.Messengers) > 0 {
    messengers = m.Messengers       // Multi-channel
} else if m.Messenger != "" {
    messengers = []string{m.Messenger}  // Single-channel (backward compatible)
} else {
    messengers = []string{"email"}      // Default
}

// Send to all specified messengers
for _, messenger := range messengers {
    // ... create and send message for each messenger ...
}
```

## 🎪 Template Data Available

When using `payload_template`, the following data is available:

```go
{
    Subject     string              // "Data Quality Alert"
    FromEmail   string              // "alerts@company.com"
    ContentType string              // "html" or "plain"
    Body        string              // Rendered template content
    Subscriber  models.Subscriber   // Subscriber details
    Campaign    *models.Campaign    // Campaign data (if available)
}
```

## 🚀 Benefits

1. **Single API Call** → Multiple channels (Slack + Teams + Email)
2. **Rich Formatting** → Block Kit, Adaptive Cards, HTML
3. **Template-Driven** → No hardcoding, fully configurable
4. **Backward Compatible** → Existing code works unchanged
5. **Easy Maintenance** → Clean, minimal changes
6. **Upstream Compatible** → Easy merging of Listmonk updates

## 📊 Upgrade Path from Upstream

```bash
# Update from upstream Listmonk
git fetch upstream
git checkout ajna-enhanced
git rebase upstream/master

# Resolve any conflicts in our 3 files:
# - internal/messenger/postback/postback.go
# - models/models.go  
# - cmd/tx.go

git push origin ajna-enhanced
```

## 🎯 Example Use Cases

### Data Evaluation Alerts
```json
{
  "template_id": 5,
  "messengers": ["slack-rich", "teams-cards", "email"],
  "data": {
    "alert_type": "{{ .alert_type }}",
    "dataset": "{{ .dataset_name }}",
    "severity": "{{ .severity }}"
  }
}
```

**Result**: 
- ✅ Rich Slack message with buttons and formatting
- ✅ Teams card with sections and actions  
- ✅ HTML email with styling
- **All from one API call!**
