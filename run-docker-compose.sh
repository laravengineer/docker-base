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

# Obtain host IP dynamically
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    HOST_IP=$(ip route get 1 | awk '{print $7; exit}')
elif [[ "$OSTYPE" == "darwin"* ]]; then
    HOST_IP=$(ipconfig getifaddr en0)
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    HOST_IP=$(ipconfig | grep "IPv4 Address" | awk '{print $NF}' | head -n 1)
else
    echo "Unsupported OS type: $OSTYPE"
    exit 1
fi

export HOST_IP

# Add xdebug.client_host to environment
echo "xdebug.client_host set to: $HOST_IP"

# Function to check if the container exists
check_container_exists() {
  container_name="${APP_NAME}_app"
  docker ps -a --format '{{.Names}}' | grep -Eq "^${container_name}\$"
}

# If the container exists, bring it down and exit the script
if check_container_exists; then
  echo "Container ${APP_NAME}_app already exists. Bringing it down..."
  docker compose down
  echo "Container ${APP_NAME}_app has been stopped and removed."
  exit 0
fi

# Start the Docker container
docker compose up -d --build

# Function to check if the container is running
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

# Function to check if the Laravel project directory exists inside the container
check_laravel_project_exists() {
  container_name="${APP_NAME}_app"
  docker exec "$container_name" bash -c "[ -f /var/www/artisan ] && [ -f /var/www/composer.json ]"
}

# Check if Laravel project already exists
if check_laravel_project_exists; then
  echo "Laravel project already exists in the container. Exiting..."
  exit 0
fi

# Create Laravel project in a temporary folder
docker exec -it "${APP_NAME}_app" bash -c "composer create-project --prefer-dist laravel/laravel /tmp/${APP_NAME}"

# Move the project files from /tmp/laravel_project to the current working directory inside the container
docker exec -it "${APP_NAME}_app" bash -c "mv /tmp/${APP_NAME}/* /tmp/${APP_NAME}/.* ./ 2>/dev/null || true"

# Clean up the temporary folder
docker exec -it "${APP_NAME}_app" bash -c "rm -rf /tmp/${APP_NAME}"

# Finish
echo "Laravel project successfully created in the container!"
