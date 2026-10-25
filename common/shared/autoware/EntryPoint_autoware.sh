#!/bin/bash
# set -e
source /opt/venv/bin/activate
source /opt/ros/jazzy/setup.bash
source /opt/autoware/setup.bash
# これはCUDAのエラー箇所を正確に特定するためのデバッグ用設定ですが、
# GPUの処理を同期（同期待ち）させるため、動作が非常に重くなり、
# 処理落ちやフリーズの大きな原因になります。
# export CUDA_LAUNCH_BLOCKING=1

python3 -c "
import carla, time

max_attempts = 2048
for i in range(1, max_attempts + 1):
    try:
        client = carla.Client('localhost', 2000)
        client.set_timeout(2.0)
        world = client.load_world('Town01')
        print(f'\nConnected successfully on attempt {i}! Current map: {world.get_map().name}')
        break
    except Exception as e:
        print(f'\rAttempt {i}/{max_attempts}: CARLA is not ready yet... ({e})', end='')
        time.sleep(1)
else:
    print('\nFailed to connect after 100 attempts.')
"
ros2 launch autoware_launch e2e_simulator.launch.xml \
    map_path:=/root/autoware_data/maps/Town01 \
    data_path:=/root/autoware_data/ml_models \
    vehicle_model:=sample_vehicle \
    sensor_model:=carla_sensor_kit \
    simulator_type:=carla \
    use_sim_time:=True \
    2>&1 \
    | tee /shared/autoware/autoware_launch.log.txt

    # use_light_weight_sensor_mapping:=True \
    # use_sim_time:=true \
    # perception_mode:=lidar \
    # launch_sensing_driver:=true \
    # map_path:=/root/autoware_data/maps/Town10HD \
