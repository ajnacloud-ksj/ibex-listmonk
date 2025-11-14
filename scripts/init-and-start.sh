#!/bin/sh
set -e

echo "🚀 Initializing Listmonk..."

cd /listmonk

# Step 1: Generate default config
if [ ! -f config.toml ]; then
    echo "📝 Generating config.toml..."
    ./listmonk --new-config
fi

# Step 2: Update config with environment variables
echo "🔧 Updating config with database settings..."

# Use environment variables to configure
cat > config.toml << EOF
[app]
address = "${LISTMONK_app__address:-0.0.0.0:9000}"
admin_username = "${LISTMONK_app__admin_username:-admin}"
admin_password = "${LISTMONK_app__admin_password:-listmonk}"
root_url = "${LISTMONK_app__root_url:-http://localhost:9001}"
from_email = "${LISTMONK_app__from_email:-Listmonk <noreply@listmonk.app>}"

[db]
host = "${LISTMONK_db__host:-localhost}"
port = ${LISTMONK_db__port:-5432}
user = "${LISTMONK_db__user:-listmonk}"
password = "${LISTMONK_db__password:-listmonk}"
database = "${LISTMONK_db__database:-listmonk}"
ssl_mode = "${LISTMONK_db__ssl_mode:-disable}"
max_open = 25
max_idle = 25
max_lifetime = "300s"
EOF

echo "✅ Config file created"

# Step 3: Install/migrate database
echo "🗄️ Installing/migrating database..."
./listmonk --install --yes --config config.toml 2>&1 | head -20 || echo "Database already initialized"

# Step 4: Start listmonk
echo "🎯 Starting Listmonk server..."
exec ./listmonk --config config.toml

