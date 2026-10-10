#!/bin/bash
# set -e

source /opt/venv/bin/activate
source /opt/ros/jazzy/setup.bash
source /opt/autoware/setup.bash
ros2 launch autoware_dummy_perception_publisher dummy_perception_publisher.launch.xml use_sim_time:=True
