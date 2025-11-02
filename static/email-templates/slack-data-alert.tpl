{
  "text": "🚨 {{ .Tx.Data.alert_type | default "Data Alert" }} - {{ .Tx.Data.severity | default "MEDIUM" }}",
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "🚨 {{ .Tx.Data.alert_type | default "Data Alert" }}"
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*Severity:*\n{{ if eq .Tx.Data.severity "CRITICAL" }}🔴{{ else if eq .Tx.Data.severity "WARNING" }}🟡{{ else }}🔵{{ end }} {{ .Tx.Data.severity | default "MEDIUM" }}"
        },
        {
          "type": "mrkdwn",
          "text": "*User:*\najna"
        }{{ if .Tx.Data.metric_name }},
        {
          "type": "mrkdwn",
          "text": "*Metric:*\n{{ .Tx.Data.metric_name }}"
        }{{ end }}{{ if .Tx.Data.current_value }},
        {
          "type": "mrkdwn",
          "text": "*Current Value:*\n`{{ .Tx.Data.current_value }}`"
        }{{ end }}{{ if .Tx.Data.threshold }},
        {
          "type": "mrkdwn",
          "text": "*Threshold:*\n`{{ .Tx.Data.threshold }}`"
        }{{ end }}{{ if .Tx.Data.affected_records }},
        {
          "type": "mrkdwn",
          "text": "*Affected Records:*\n{{ .Tx.Data.affected_records }}"
        }{{ end }}{{ if .Tx.Data.dataset }},
        {
          "type": "mrkdwn",
          "text": "*Dataset:*\n{{ .Tx.Data.dataset }}"
        }{{ end }}
      ]
    }{{ if .Tx.Data.description }},
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*📋 Description:*\n{{ .Tx.Data.description }}"
      }
    }{{ end }}{{ if .Tx.Data.recommended_action }},
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*💡 Recommended Action:*\n{{ .Tx.Data.recommended_action }}"
      }
    }{{ end }}{{ if .Tx.Data.dashboard_url }},
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View Dashboard"
          },
          "style": "primary",
          "url": "{{ .Tx.Data.dashboard_url }}"
        }
      ]
    }{{ end }},
    {
      "type": "context",
      "elements": [
        {
          "type": "mrkdwn",
          "text": "⏰ {{ .Tx.Data.timestamp | default "now" }} | Alert ID: {{ .Tx.Data.alert_id | default "auto-generated" }} | Ajna Data Pipeline"
        }
      ]
    }
  ]
}
