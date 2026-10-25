#!/bin/bash
set -e
ML_ORIGIN="/tmp/ml_models_origin"
ML_DEST="/tmp/ml_models"

ansible-playbook ansible/playbooks/install_dev_env.yaml \
    --tags universe \
    --skip-tags nvidia,cuda \
    -e data_dir="$ML_ORIGIN"

cp -r "$ML_ORIGIN/traffic_light_classifier" "$ML_DEST/"
cp -r "$ML_ORIGIN/traffic_light_fine_detector" "$ML_DEST/"

CARLA_URL="https://bitbucket.org/carla-simulator/autoware-contents/raw/master/maps"
MAP_DIR="/tmp/maps/Town01"

mkdir -p "$MAP_DIR"
curl -o "$MAP_DIR/pointcloud_map.pcd" "$CARLA_URL"/point_cloud_maps/Town01.pcd
curl -o "$MAP_DIR"/lanelet2_map.pcd "$CARLA_URL"/vector_maps/lanelet2/Town01.osm

cat << 'EOF' > "$MAP_DIR"/map_projector_info.yaml
projector_type: Local
EOF

