#!/bin/bash
set -e

WORKDIR="/tmp/workspace"
if [ -d "$WORKDIR" ]; then
    rm -rf "$WORKDIR"
fi
mkdir -p "$WORKDIR"
cd "$WORKDIR"

INFO_YAML_NAME=map_projector_info.yaml
cat << 'EOF' > $INFO_YAML_NAME
projector_type: Local
EOF
INFO_YAML_PATH="$WORKDIR"/$INFO_YAML_NAME

ML_ORIGIN="/tmp/ml_models_origin"
ML_DEST="/tmp/ml_models"
if [ -d "autoware/.git" ]; then
    echo "autoware repository already exists. Skipping clone."
else
    git clone https://github.com/autowarefoundation/autoware.git
    cd autoware
    ansible-galaxy collection install -f -r ansible-galaxy-requirements.yaml
    ansible-playbook ansible/playbooks/install_dev_env.yaml \
        --tags universe \
        --skip-tags nvidia,cuda \
        -e data_dir="$ML_ORIGIN"
fi
cp -r "$ML_ORIGIN/traffic_light_classifier" "$ML_DEST/"
cp -r "$ML_ORIGIN/traffic_light_fine_detector" "$ML_DEST/"

cd "$WORKDIR"
if [ -d "autoware-contents/.git" ]; then
    echo "autoware-contents repository already exists. Skipping clone."
else
    git clone https://bitbucket.org/carla-simulator/autoware-contents.git
fi
cd "$WORKDIR"/autoware-contents/maps/point_cloud_maps

for file in *; do
    if [ -d "$file" ] || [ "$file" = "README.md" ]; then
        continue
    fi
    filename_no_ext="${file%.*}"
    TOWN_DIR=/tmp/maps/"$filename_no_ext"
    if [ -d "$TOWN_DIR" ]; then
        rm -rf "$TOWN_DIR"
    fi
    mkdir -p "$TOWN_DIR"
    cp "$file" "$TOWN_DIR/pointcloud_map.pcd"
    cp "$INFO_YAML_PATH" "$TOWN_DIR"/"$INFO_YAML_NAME"
done
cd "$WORKDIR"/autoware-contents/maps/vector_maps/lanelet2
for file in *; do
    if [ -d "$file" ]; then
        continue
    fi
    filename_no_ext="${file%.*}"
    TOWN_DIR=/tmp/maps/"$filename_no_ext"
    cp "$file" "$TOWN_DIR/lanelet2_map.osm"
done

cd "$ML_DEST"
if [ -d "lidar_centerpoint/.git" ]; then
    echo "lidar_centerpoint repository already exists. Skipping clone."
else
    git lfs install
    LIDAR_URL="https://huggingface.co/AutowareFoundation/lidar_centerpoint"
    git clone "$LIDAR_URL" -b v3.0
fi
