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

docker compose up --build
