#!/bin/bash
set -e
MAP_DEST="${AUTOWARE_DATA_PATH}/maps"
ML_DEST="${AUTOWARE_DATA_PATH}/ml_models"
ML_ORIGIN="/tmp/ml_models_origin"
WORKDIR="/tmp/autoware_setup"
LIDAR_VERSION=v3.0
ANSIBLE_TAGS="universe"
ANSIBLE_SKIP_TAGS="nvidia,cuda,tensorrt,spconv,acados,qt5ct_setup,demo_artifacts"
PCD_DIR="$WORKDIR"/autoware-contents/maps/point_cloud_maps
OSM_DIR="$WORKDIR"/autoware-contents/maps/vector_maps/lanelet2
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
    git clone https://github.com/autowarefoundation/autoware.git
    cd "$WORKDIR/autoware"
    ansible-galaxy collection install -f -r ansible-galaxy-requirements.yaml
    ansible-playbook ansible/playbooks/install_dev_env.yaml \
        --tags $ANSIBLE_TAGS \
        --skip-tags $ANSIBLE_SKIP_TAGS \
        -e data_dir="$ML_ORIGIN"
else
    echo "autoware repository already exists. Skipping clone. & ansible-playbook."
fi
if [ ! -d "$ML_DEST/traffic_light_classifier" ]; then
    echo "cp traffic_light_classifier to $ML_DEST"
    cp -r "$ML_ORIGIN/traffic_light_classifier" "$ML_DEST/"
    chown -R 1000:1000 "$ML_DEST/traffic_light_classifier"
    chmod -R 777 "$ML_DEST/traffic_light_classifier"
fi
if [ ! -d "$ML_DEST/traffic_light_fine_detector" ]; then
    echo "cp traffic_light_fine_detector to $ML_DEST"
    cp -r "$ML_ORIGIN/traffic_light_fine_detector" "$ML_DEST/"
    chown -R 1000:1000 "$ML_DEST/traffic_light_fine_detector"
    chmod -R 777 "$ML_DEST/traffic_light_fine_detector"
fi

if [ ! -d "$WORKDIR/lidar_centerpoint/.git" ]; then
    echo "lidar_centerpoint repository clone. $LIDAR_VERSION"
    LIDAR_URL="https://huggingface.co/AutowareFoundation/lidar_centerpoint"
    cd "$WORKDIR"
    git clone "$LIDAR_URL" -b $LIDAR_VERSION "$WORKDIR/lidar_centerpoint"
else
    echo "lidar_centerpoint repository already exists. Skipping clone."
fi
if [ ! -d "$ML_DEST/lidar_centerpoint/" ]; then
    echo "cp lidar_centerpoint models to $ML_DEST"
    mkdir -p "$ML_DEST/lidar_centerpoint"
    cp "$WORKDIR/lidar_centerpoint/"*.yaml "$ML_DEST/lidar_centerpoint/"
    cp "$WORKDIR/lidar_centerpoint/"*.onnx "$ML_DEST/lidar_centerpoint/"
    cp "$WORKDIR/lidar_centerpoint/"*.engine "$ML_DEST/lidar_centerpoint/"
    cp "$WORKDIR/lidar_centerpoint/"*.json "$ML_DEST/lidar_centerpoint/"
    chown -R 1000:1000 "$ML_DEST/lidar_centerpoint"
    chmod -R 777 "$ML_DEST/lidar_centerpoint"
fi
if [ ! -d "$WORKDIR/autoware-contents/.git" ]; then
    echo "autoware-contents repository clone."
    cd "$WORKDIR"
    git clone https://bitbucket.org/carla-simulator/autoware-contents.git
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
    chown -R 1000:1000 "$TOWN_DIR"
    chmod -R 777 "$TOWN_DIR"
    echo "${TOWN_DIR} copy done."
done
