#!/bin/bash

# Geting username and uid
USER_NAME=$(whoami)
USER_UID=$(id -u)

export USER_NAME
export USER_UID

docker compose up --build
