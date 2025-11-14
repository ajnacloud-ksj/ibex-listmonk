#!/bin/bash
set -e

echo "🚀 Listmonk Startup Script (Environment-Only Mode)"

cd /listmonk

# Install database schema ONLY if not already initialized
echo "🗄️ Checking if database is initialized..."
if ! PGPASSWORD="${LISTMONK_db__password}" psql -h "${LISTMONK_db__host}" -p "${LISTMONK_db__port}" -U "${LISTMONK_db__user}" -d "${LISTMONK_db__database}" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_name='settings';" 2>/dev/null | grep -q "1"; then
    echo "📦 Database not initialized. Running first-time installation..."
    ./listmonk --install --yes --config ''
    echo "✅ Database initialized"
else
    echo "✅ Database already initialized, skipping installation"
fi

# Start listmonk using environment-only configuration (no config.toml)
echo "🎯 Starting Listmonk server with environment configuration..."
exec ./listmonk --config ''

