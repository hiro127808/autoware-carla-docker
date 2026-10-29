#!/bin/bash
set -e
sudo rm -rf common/autoware_data/maps/Town*
sudo rm -rf common/autoware_data/ml_models/traffic_*
sudo rm -rf common/autoware_data/ml_models/lidar_centerpoint
docker system prune -a --volumes -f
docker compose up --build
