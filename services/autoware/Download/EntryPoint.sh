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

CARLA_MAP_URL="https://bitbucket.org/carla-simulator/autoware-contents.git"
MAP_DIR="/tmp/maps/Town01"

git clone "$CARLA_MAP_URL"
mkdir -p "$MAP_DIR"
cp ./autoware-contents/maps/point_cloud_maps/Town01.pcd "$MAP_DIR/pointcloud_map.pcd"
cp ./autoware-contents/maps/vector_maps/lanelet2/Town01.osm "$MAP_DIR/lanelet2_map.osm"

cat << 'EOF' > "$MAP_DIR"/map_projector_info.yaml
projector_type: Local
EOF

cd "$ML_DEST"

git lfs install
LIDAR_URL="https://huggingface.co/AutowareFoundation/lidar_centerpoint"
git clone "$LIDAR_URL" -b v3.0
