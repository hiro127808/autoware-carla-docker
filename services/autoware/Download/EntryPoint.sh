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
