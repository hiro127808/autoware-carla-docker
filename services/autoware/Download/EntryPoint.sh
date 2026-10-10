#!/bin/bash
set -e
ansible-playbook ansible/playbooks/install_dev_env.yaml \
    --tags universe \
    --skip-tags nvidia,cuda \
    -e data_dir=/tmp/ml_models_origin
