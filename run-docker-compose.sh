#!/bin/bash

# Geting username and uid
USER_NAME=$(whoami)
USER_UID=$(id -u)

# Set the Project Name
APP_NAME="docker_base"
VITE_PORT=5173

export USER_NAME
export USER_UID
export APP_NAME
export VITE_PORT

docker compose up -d

check_container_status() {
  container_name="${APP_NAME}_app"
  status=$(docker inspect -f '{{.State.Running}}' "$container_name" 2>/dev/null)
  
  if [ "$status" == "true" ]; then
    return 0
  else
    return 1
  fi
}

echo "Waiting for the container ${APP_NAME}_app to start..."
while ! check_container_status; do
  echo "Container is not running yet. Retrying in 5 seconds..."
  sleep 5
done

echo "Container ${APP_NAME}_app is now running!"

docker exec -it "${APP_NAME}_app" bash -c "composer create-project laravel/laravel ."