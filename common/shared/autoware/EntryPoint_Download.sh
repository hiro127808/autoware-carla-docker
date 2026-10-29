#!/bin/bash
set -e
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
CONTENTS_DIR="$WORKDIR"/autoware-contents
PCD_DIR="$CONTENTS_DIR"/maps/point_cloud_maps
OSM_DIR="$CONTENTS_DIR"/maps/vector_maps/lanelet2
CP_EXTENSIONS="yaml onnx engine json txt"
SRC_CLASSIFIER="$ML_ORIGIN/traffic_light_classifier"
DST_CLASSIFIER="$ML_DEST/traffic_light_classifier"
SRC_DETECTOR="$ML_ORIGIN/traffic_light_fine_detector"
DST_DETECTOR="$ML_DEST/traffic_light_fine_detector"
SRC_LIDAR="$WORKDIR/lidar_centerpoint"
DST_LIDAR="$ML_DEST/lidar_centerpoint"
mkdir -p "$ML_ORIGIN"
mkdir -p "$WORKDIR"

cd "$WORKDIR"
INFO_YAML_NAME=map_projector_info.yaml
cat << 'EOF' > $INFO_YAML_NAME
projector_type: Local
EOF
INFO_YAML_PATH="$WORKDIR"/$INFO_YAML_NAME

if [ ! -d "$WORKDIR/autoware/.git" ]; then
    echo "autoware repository clone. & ansible-playbook."
    cd "$WORKDIR"
    git clone "$AUTOWARE_URL"
    cd "$WORKDIR/autoware"
    ansible-galaxy collection install -f -r ansible-galaxy-requirements.yaml
    ansible-playbook ansible/playbooks/install_dev_env.yaml \
        --tags $ANSIBLE_TAGS \
        --skip-tags $ANSIBLE_SKIP_TAGS \
        -e data_dir="$ML_ORIGIN"
else
    echo "autoware repository already exists. Skipping clone. & ansible-playbook."
fi
if [ ! -d "$DST_CLASSIFIER" ]; then
    mkdir -p "$DST_CLASSIFIER"
    for ext in $CP_EXTENSIONS; do
        cp "$SRC_CLASSIFIER"/*."$ext" "$DST_CLASSIFIER"/
    done
fi
if [ ! -d "$DST_DETECTOR" ]; then
    mkdir -p "$DST_DETECTOR"
    for ext in $CP_EXTENSIONS; do
        cp "$SRC_DETECTOR"/*."$ext" "$DST_DETECTOR"/
    done
fi

if [ ! -d "$WORKDIR/lidar_centerpoint/.git" ]; then
    cd "$WORKDIR"
    git clone "$LIDAR_URL" -b $LIDAR_VERSION "$SRC_LIDAR"
else
    echo "lidar_centerpoint repository already exists. Skipping clone."
fi
if [ ! -d "$DST_LIDAR" ]; then
    mkdir -p "$DST_LIDAR"
    for ext in $CP_EXTENSIONS; do
        cp "$SRC_LIDAR"/*."$ext" "$DST_LIDAR"/
    done
fi
if [ ! -d "$WORKDIR/autoware-contents/.git" ]; then
    echo "autoware-contents repository clone."
    cd "$WORKDIR"
    git clone "$CONTENTS_URL"
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