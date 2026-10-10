#!/bin/bash
# set -e

# docker exec -it c_autoware bash
# root@galleria:/home/aw# ros2 service call /control/vehicle_cmd_gate/clear_external_emergency_stop autoware_adapi_v1_msgs/srv/ClearEmergencyStop "{}"
# The passed service type is invalid
# root@galleria:/home/aw# ros2 service call /control/vehicle_cmd_gate/clear_external_emergency_stop 
# Display all 198 possibilities? (y or n)
# root@galleria:/home/aw# ros2 service call /control/vehicle_cmd_gate/clear_external_emergency_stop autoware_adapi_v1_msgs/srv/ClearEmergencyStop "{}"
# The passed service type is invalid
# root@galleria:/home/aw# ros2 service call /control/vehicle_cmd_gate/clear_external_emergency_stop autoware_adapi_v1_msgs/srv/ClearEmergencyStop "{}"
# The passed service type is invalid
# root@galleria:/home/aw# ros2 service call /control/vehicle_cmd_gate/clear_external_emergency_stop std_srvs/srv/Trigger "{}"
# waiting for service to become available...
# requester: making request: std_srvs.srv.Trigger_Request()

# response:
# std_srvs.srv.Trigger_Response(success=True, message='external_emergency_stop state was cleared.')

source /opt/venv/bin/activate
source /opt/ros/jazzy/setup.bash
source /opt/autoware/setup.bash
ros2 service call /control/vehicle_cmd_gate/clear_external_emergency_stop std_srvs/srv/Trigger "{}"