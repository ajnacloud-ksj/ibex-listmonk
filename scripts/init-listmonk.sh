#!/bin/bash
set -e

echo "🚀 Starting Ajna Enhanced Listmonk initialization..."

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be available..."
until pg_isready -h $LISTMONK_db__host -p $LISTMONK_db__port -U $LISTMONK_db__user; do
  echo "PostgreSQL is not ready yet, waiting..."
  sleep 2
done

echo "✅ PostgreSQL is ready!"

# Run listmonk installation/migration if needed
echo "🔧 Running listmonk installation..."
/listmonk/listmonk --install --yes || echo "Installation already exists, continuing..."

echo "🎯 Starting listmonk server..."
exec /listmonk/listmonk
