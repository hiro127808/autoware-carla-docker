#!/bin/bash
# set -e
source /opt/venv/bin/activate
source /opt/ros/jazzy/setup.bash
source /opt/autoware/setup.bash

./EntryPoint_Download.sh

# これはCUDAのエラー箇所を正確に特定するためのデバッグ用設定ですが、
# GPUの処理を同期（同期待ち）させるため、動作が非常に重くなり、
# 処理落ちやフリーズの大きな原因になります。
# export CUDA_LAUNCH_BLOCKING=1
TOWN_NAME=Town01

CARLA_SERVER=localhost
CARLA_PORT=2000
python3 -c "
import carla, time

print(f'\n starting CARLA client to connect to server at "${CARLA_SERVER}":"${CARLA_PORT}" and load world "${TOWN_NAME}"...')
max_attempts = 2048
for i in range(1, max_attempts + 1):
    try:
        print(f'\n Connecting ...')
        client = carla.Client('${CARLA_SERVER}', ${CARLA_PORT})
        client.set_timeout(10.0)
        world = client.load_world('${TOWN_NAME}')
        print(f'Connected successfully on attempt {i}! Current map: {world.get_map().name}')
        traffic_manager = client.get_trafficmanager(8000)
        settings = world.get_settings()
        traffic_manager.set_synchronous_mode(True)
        settings.synchronous_mode = True
        settings.fixed_delta_seconds = 0.05
        world.apply_settings(settings)
        break
    except Exception as e:
        print(f'\rAttempt {i}/{max_attempts}: CARLA is not ready yet... ({e})', end='')
        time.sleep(1)
else:
    print(f'\nFailed to connect after {max_attempts} attempts.')
"
ros2 launch autoware_launch e2e_simulator.launch.xml \
    map_path:=/root/autoware_data/maps/${TOWN_NAME} \
    data_path:=/root/autoware_data/ml_models \
    vehicle_model:=sample_vehicle \
    sensor_model:=carla_sensor_kit \
    simulator_type:=carla \
    use_sim_time:=true \
    2>&1 \
    | tee /shared/autoware/autoware_launch.log.txt
