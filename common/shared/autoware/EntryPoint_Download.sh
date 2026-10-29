#!/bin/bash
set -e
source /opt/venv/bin/activate
source /opt/ros/jazzy/setup.bash
source /opt/autoware/setup.bash

AUTOWARE_URL="https://github.com/autowarefoundation/autoware.git"
LIDAR_URL="https://huggingface.co/AutowareFoundation/lidar_centerpoint"
CONTENTS_URL="https://bitbucket.org/carla-simulator/autoware-contents.git"
MAP_DEST="${AUTOWARE_DATA_PATH}/maps"
ML_DEST="${AUTOWARE_DATA_PATH}/ml_models"
ML_ORIGIN="/tmp/ml_models_origin"
WORKDIR="/tmp/autoware_setup"
LIDAR_VERSION=v3.0
ANSIBLE_TAGS="universe"
ANSIBLE_SKIP_TAGS="nvidia,cuda,tensorrt,spconv,acados,qt5ct_setup,demo_artifacts"
SRC_CONTENTS="$WORKDIR"/autoware-contents
PCD_DIR="$SRC_CONTENTS"/maps/point_cloud_maps
OSM_DIR="$SRC_CONTENTS"/maps/vector_maps/lanelet2
CP_EXTENSIONS="yaml onnx engine json txt"
SRC_CLASSIFIER="$ML_ORIGIN"/traffic_light_classifier
DST_CLASSIFIER="$ML_DEST"/traffic_light_classifier
SRC_DETECTOR="$ML_ORIGIN"/traffic_light_fine_detector
DST_DETECTOR="$ML_DEST"/traffic_light_fine_detector
SRC_LIDAR="$WORKDIR"/lidar_centerpoint
DST_LIDAR="$ML_DEST"/lidar_centerpoint
SRC_AUTOWARE="$WORKDIR"/autoware
mkdir -p "$ML_ORIGIN"
mkdir -p "$WORKDIR"

cd "$WORKDIR"
INFO_YAML_NAME=map_projector_info.yaml
cat << 'EOF' > $INFO_YAML_NAME
projector_type: Local
EOF
INFO_YAML_PATH="$WORKDIR"/$INFO_YAML_NAME

if [ ! -d "$SRC_AUTOWARE/.git" ]; then
    echo "$SRC_AUTOWARE"
    cd "$WORKDIR"
    git clone "$AUTOWARE_URL" "$SRC_AUTOWARE"
    cd "$SRC_AUTOWARE"
    ansible-galaxy collection install -f -r ansible-galaxy-requirements.yaml
    ansible-playbook ansible/playbooks/install_dev_env.yaml \
        --tags $ANSIBLE_TAGS \
        --skip-tags $ANSIBLE_SKIP_TAGS \
        -e data_dir="$ML_ORIGIN"
else
    echo "autoware repository already exists. Skipping clone. & ansible-playbook."
fi
if [ ! -d "$DST_CLASSIFIER" ]; then
    echo "$DST_CLASSIFIER"
    mkdir -p "$DST_CLASSIFIER"
    for ext in $CP_EXTENSIONS; do
        for file in "$SRC_CLASSIFIER"/*."$ext"; do
            if [ -f "$file" ]; then
                cp "$file" "$DST_CLASSIFIER"/
            fi
        done
    done
fi
if [ ! -d "$DST_DETECTOR" ]; then
    echo "$DST_DETECTOR"
    mkdir -p "$DST_DETECTOR"
    for ext in $CP_EXTENSIONS; do
        for file in "$SRC_DETECTOR"/*."$ext"; do
            if [ -f "$file" ]; then
                cp "$file" "$DST_DETECTOR"/
            fi
        done
    done
fi

if [ ! -d "$SRC_LIDAR/.git" ]; then
    echo "$SRC_LIDAR"
    git clone "$LIDAR_URL" -b $LIDAR_VERSION "$SRC_LIDAR"
else
    echo "lidar_centerpoint repository already exists. Skipping clone."
fi
if [ ! -d "$DST_LIDAR" ]; then
    echo "$DST_LIDAR"
    mkdir -p "$DST_LIDAR"
    for ext in $CP_EXTENSIONS; do
        for file in "$SRC_LIDAR"/*."$ext"; do
            if [ -f "$file" ]; then
                cp "$file" "$DST_LIDAR"/
            fi
        done
    done
    ros2 launch autoware_lidar_centerpoint lidar_centerpoint.launch.xml \
    model_path:="$DST_LIDAR" \
    build_only:=true
fi

if [ ! -d "$SRC_CONTENTS/.git" ]; then
    echo "$SRC_CONTENTS"
    cd "$WORKDIR"
    git clone "$CONTENTS_URL" "$SRC_CONTENTS"
else
    echo "autoware-contents repository already exists. Skipping clone."
fi
cd "$PCD_DIR"
for file in *; do
    if [ -d "$file" ] || [ "$file" = "README.md" ]; then
        continue
    fi
    filename_no_ext="${file%.*}"
    TOWN_DIR="${MAP_DEST}/${filename_no_ext}"
    if [ -d "${TOWN_DIR}" ]; then
        rm -rf "${TOWN_DIR}"
    fi
    echo "${TOWN_DIR} copying..."
    mkdir -p "${TOWN_DIR}"
    cp "$file" "${TOWN_DIR}/pointcloud_map.pcd"
    cp "$INFO_YAML_PATH" "${TOWN_DIR}/${INFO_YAML_NAME}"
    OSM_PATH="${OSM_DIR}/${filename_no_ext}.osm"
    cp "$OSM_PATH" "${TOWN_DIR}/lanelet2_map.osm"
    echo "${TOWN_DIR} copy done."
done
# aw is autoware user in the container.
# This is to avoid permission issues when running Autoware in the container.
chown -R aw:aw "${AUTOWARE_DATA_PATH}/."
chmod -R 777 "${AUTOWARE_DATA_PATH}/."