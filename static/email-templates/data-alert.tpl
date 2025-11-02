<!doctype html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, minimum-scale=1">
        <base target="_blank">

        <style>
            body {
                background-color: #F0F1F3;
                font-family: 'Helvetica Neue', 'Segoe UI', Helvetica, sans-serif;
                font-size: 15px;
                line-height: 26px;
                margin: 0;
                color: #444;
            }

            .wrap {
                background-color: #fff;
                padding: 30px;
                max-width: 600px;
                margin: 0 auto;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }

            .alert-header {
                background: linear-gradient(135deg, #ff4757, #ff3838);
                color: white;
                padding: 20px;
                border-radius: 8px 8px 0 0;
                margin: -30px -30px 20px -30px;
                text-align: center;
            }

            .alert-header.warning {
                background: linear-gradient(135deg, #ffa502, #ff6348);
            }

            .alert-header.info {
                background: linear-gradient(135deg, #3742fa, #2f3542);
            }

            .alert-header h1 {
                margin: 0;
                font-size: 24px;
                font-weight: bold;
            }

            .alert-meta {
                background: #f8f9fa;
                padding: 15px;
                border-radius: 6px;
                margin: 20px 0;
                border-left: 4px solid #ff4757;
            }

            .alert-meta.warning {
                border-left-color: #ffa502;
            }

            .alert-meta.info {
                border-left-color: #3742fa;
            }

            .metric-row {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 8px 0;
                border-bottom: 1px solid #e1e5e9;
            }

            .metric-row:last-child {
                border-bottom: none;
            }

            .metric-label {
                font-weight: 600;
                color: #2c3e50;
            }

            .metric-value {
                font-family: 'Monaco', 'Consolas', monospace;
                background: #ecf0f1;
                padding: 4px 8px;
                border-radius: 4px;
                font-size: 14px;
            }

            .metric-value.critical {
                background: #fee;
                color: #c0392b;
                font-weight: bold;
            }

            .button {
                background: #0055d4;
                border-radius: 6px;
                text-decoration: none !important;
                color: #fff !important;
                font-weight: bold;
                padding: 12px 24px;
                display: inline-block;
                margin: 20px 0;
                transition: background 0.3s ease;
            }

            .button:hover {
                background: #0041a3;
            }

            .footer {
                text-align: center;
                font-size: 12px;
                color: #888;
                margin-top: 30px;
                padding-top: 20px;
                border-top: 1px solid #e1e5e9;
            }

            .footer a {
                color: #888;
                margin-right: 5px;
            }

            .gutter {
                padding: 30px;
            }

            .timestamp {
                font-size: 13px;
                color: #7f8c8d;
                text-align: center;
                margin-top: 15px;
            }

            @media screen and (max-width: 600px) {
                .wrap {
                    max-width: auto;
                    margin: 10px;
                }
                .gutter {
                    padding: 10px;
                }
                .metric-row {
                    flex-direction: column;
                    align-items: flex-start;
                }
                .metric-value {
                    margin-top: 5px;
                }
            }
        </style>
    </head>
<body style="background-color: #F0F1F3;font-family: 'Helvetica Neue', 'Segoe UI', Helvetica, sans-serif;font-size: 15px;line-height: 26px;margin: 0;color: #444;">
    <div class="gutter">&nbsp;</div>
    <div class="wrap">
        <div class="alert-header {{ if eq .Tx.Data.severity "CRITICAL" }}critical{{ else if eq .Tx.Data.severity "WARNING" }}warning{{ else }}info{{ end }}">
            <h1>🚨 {{ .Tx.Data.alert_type | default "Data Alert" }}</h1>
        </div>

        <div class="alert-meta {{ if eq .Tx.Data.severity "CRITICAL" }}critical{{ else if eq .Tx.Data.severity "WARNING" }}warning{{ else }}info{{ end }}">
            <div class="metric-row">
                <span class="metric-label">Alert Type:</span>
                <span class="metric-value">{{ .Tx.Data.alert_type | default "Data Quality Alert" }}</span>
            </div>
            <div class="metric-row">
                <span class="metric-label">Severity:</span>
                <span class="metric-value {{ if eq .Tx.Data.severity "CRITICAL" }}critical{{ end }}">{{ .Tx.Data.severity | default "MEDIUM" }}</span>
            </div>
            {{ if .Tx.Data.metric_name }}
            <div class="metric-row">
                <span class="metric-label">Metric:</span>
                <span class="metric-value">{{ .Tx.Data.metric_name }}</span>
            </div>
            {{ end }}
            {{ if .Tx.Data.current_value }}
            <div class="metric-row">
                <span class="metric-label">Current Value:</span>
                <span class="metric-value {{ if eq .Tx.Data.severity "CRITICAL" }}critical{{ end }}">{{ .Tx.Data.current_value }}</span>
            </div>
            {{ end }}
            {{ if .Tx.Data.threshold }}
            <div class="metric-row">
                <span class="metric-label">Threshold:</span>
                <span class="metric-value">{{ .Tx.Data.threshold }}</span>
            </div>
            {{ end }}
            {{ if .Tx.Data.affected_records }}
            <div class="metric-row">
                <span class="metric-label">Affected Records:</span>
                <span class="metric-value {{ if gt (int .Tx.Data.affected_records) 1000 }}critical{{ end }}">{{ .Tx.Data.affected_records }}</span>
            </div>
            {{ end }}
            {{ if .Tx.Data.dataset }}
            <div class="metric-row">
                <span class="metric-label">Dataset:</span>
                <span class="metric-value">{{ .Tx.Data.dataset }}</span>
            </div>
            {{ end }}
        </div>

        {{ if .Tx.Data.description }}
        <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 6px; padding: 15px; margin: 20px 0;">
            <h3 style="margin: 0 0 10px 0; color: #856404;">📋 Description</h3>
            <p style="margin: 0; color: #856404;">{{ .Tx.Data.description }}</p>
        </div>
        {{ end }}

        {{ if .Tx.Data.recommended_action }}
        <div style="background: #d1ecf1; border: 1px solid #bee5eb; border-radius: 6px; padding: 15px; margin: 20px 0;">
            <h3 style="margin: 0 0 10px 0; color: #0c5460;">💡 Recommended Action</h3>
            <p style="margin: 0; color: #0c5460;">{{ .Tx.Data.recommended_action }}</p>
        </div>
        {{ end }}

        {{ if .Tx.Data.dashboard_url }}
        <div style="text-align: center; margin: 25px 0;">
            <a href="{{ .Tx.Data.dashboard_url }}" class="button">View Dashboard</a>
        </div>
        {{ end }}

        <div class="timestamp">
            Alert triggered: {{ .Tx.Data.timestamp | default "now" }}
        </div>

        <div class="footer">
            <p>
                This is an automated data alert from <strong>Ajna Data Pipeline</strong><br>
                User: <strong>ajna</strong> | Alert ID: {{ .Tx.Data.alert_id | default "auto-generated" }}
            </p>
            <p>{{ L.T "public.poweredBy" }} <a href="https://listmonk.app" target="_blank" rel="noreferrer">listmonk</a></p>
        </div>
    </div>
</body>
</html>
