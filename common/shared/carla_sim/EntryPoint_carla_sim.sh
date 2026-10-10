#!/bin/bash
set -e

./CarlaUE4.sh \
    -prefernvidia \
    -carla-rpc-port=${CARLA_PORT:-2000} \
    -quality-level=Low \
    -fixed-step-seconds=0.1 \
    -RenderOffscreen \
    -nosound
    # -ResX=320 \
    # -ResY=240 \
      # --ros2 \
    # -opengl \
    # -vulkan \
    # -nullrhi \
