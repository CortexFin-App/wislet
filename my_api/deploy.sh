#!/bin/bash
# Визначаємо ім'я контейнера та образу
CONTAINER_NAME="cortexfin-backend"
IMAGE_NAME="cortexfin-api"

# --- Логіка для --no-cache ---
BUILD_ARGS=""
if [ "$1" == "--no-cache" ]; then
  echo ">>> Build option --no-cache detected. Building without cache."
  BUILD_ARGS="--no-cache"
fi
# --- Кінець логіки ---

echo ">>> Pulling latest changes from Git..."
git pull origin main

echo ">>> Stopping old container if it exists..."
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true

echo ">>> Building new Docker image..."
docker build $BUILD_ARGS -t $IMAGE_NAME .

echo ">>> Starting new container..."
docker run -d --restart always \
  -p 8080:8080 \
  -v /home/vlad/gcp-credentials.json:/app/gcp-credentials.json \
  -e GOOGLE_APPLICATION_CREDENTIALS="/app/gcp-credentials.json" \
  -e SUPABASE_URL="https://xdofjorgomwdyawmwbcj.supabase.co" \
  -e SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhkb2Zqb3Jnb213ZHlhd213YmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMzE0MTcsImV4cCI6MjA2NDkwNzQxN30.2i9ru8fXLZEYD_jNHoHd0ZJmN4k9gKcPOChdiuL_AMY" \
  -e SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhkb2Zqb3Jnb213ZHlhd213YmNqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTMzMTQxNywiZXhwIjoyMDY0OTA3NDE3fQ.EJ_vJroQOUXru7pHzM68Hr-ofNTm3OMi9fAINFfXLZo" \
  --name $CONTAINER_NAME \
  $IMAGE_NAME

echo ">>> Deployment finished successfully!"
