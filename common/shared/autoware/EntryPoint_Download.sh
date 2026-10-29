#!/bin/bash
set -e
MAP_DEST="${AUTOWARE_DATA_PATH}/maps"
ML_DEST="${AUTOWARE_DATA_PATH}/ml_models"
mkdir -p "$MAP_DEST"
mkdir -p "$ML_DEST"

WORKDIR="/tmp/autoware_setup"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

INFO_YAML_NAME=map_projector_info.yaml
cat << 'EOF' > $INFO_YAML_NAME
projector_type: Local
EOF
INFO_YAML_PATH="$WORKDIR"/$INFO_YAML_NAME

ML_ORIGIN="/tmp/ml_models_origin"
if [ -d "autoware/.git" ]; then
    echo "autoware repository already exists. Skipping clone."
else
    git clone https://github.com/autowarefoundation/autoware.git
    cd autoware
    ansible-galaxy collection install -f -r ansible-galaxy-requirements.yaml
    ansible-playbook ansible/playbooks/install_dev_env.yaml \
        --tags universe \
        --skip-tags nvidia,cuda,tensorrt,spconv,acados,qt5ct_setup,demo_artifacts \
        -e data_dir="$ML_ORIGIN"
    cp -r "$ML_ORIGIN/traffic_light_classifier" "$ML_DEST/"
    cp -r "$ML_ORIGIN/traffic_light_fine_detector" "$ML_DEST/"
    chown -R ${HOST_UID}:${HOST_GID} "$ML_DEST/traffic_light_classifier"
    chown -R ${HOST_UID}:${HOST_GID} "$ML_DEST/traffic_light_fine_detector"
fi
cd "$ML_DEST"
if [ -d "lidar_centerpoint/.git" ]; then
    echo "lidar_centerpoint repository already exists. Skipping clone."
else
    git lfs install
    LIDAR_URL="https://huggingface.co/AutowareFoundation/lidar_centerpoint"
    git clone "$LIDAR_URL" -b v3.0
    chown -R ${HOST_UID}:${HOST_GID} "$ML_DEST/lidar_centerpoint"
fi

cd "$WORKDIR"
if [ -d "autoware-contents/.git" ]; then
    echo "autoware-contents repository already exists. Skipping clone."
else
    git clone https://bitbucket.org/carla-simulator/autoware-contents.git
    cd "$WORKDIR"/autoware-contents/maps/point_cloud_maps
    for file in *; do
        if [ -d "$file" ] || [ "$file" = "README.md" ]; then
            continue
        fi
        filename_no_ext="${file%.*}"
        TOWN_DIR="${MAP_DEST}/${filename_no_ext}"
        if [ -d "${TOWN_DIR}" ]; then
            rm -rf "${TOWN_DIR}"
        fi
        mkdir -p "${TOWN_DIR}"
        chown -R ${HOST_UID}:${HOST_GID} "${TOWN_DIR}"
        cp "$file" "${TOWN_DIR}/pointcloud_map.pcd"
        cp "$INFO_YAML_PATH" "${TOWN_DIR}/${INFO_YAML_NAME}"
    done
    cd "$WORKDIR"/autoware-contents/maps/vector_maps/lanelet2
    for file in *; do
        if [ -d "$file" ]; then
            continue
        fi
        filename_no_ext="${file%.*}"
        TOWN_DIR="${MAP_DEST}/${filename_no_ext}"
        cp "$file" "${TOWN_DIR}/lanelet2_map.osm"
    done
fi

