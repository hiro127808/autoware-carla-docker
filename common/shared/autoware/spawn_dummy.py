import carla
import time
import random

def spawn_random_vehicles(world, n=20):
    blueprint_library = world.get_blueprint_library()
    vehicle_bps = blueprint_library.filter('vehicle.*')
    
    spawn_points = world.get_map().get_spawn_points()
    random.shuffle(spawn_points)
    
    spawned_count = 0
    for transform in spawn_points:
        if spawned_count >= n:
            break
        bp = random.choice(vehicle_bps)
        vehicle = world.try_spawn_actor(bp, transform)
        if vehicle:
            vehicle.set_autopilot(True)
            spawned_count += 1
            
    print(f'Spawned {spawned_count} vehicles.')
    return spawned_count

def spawn_random_walkers(world, n=10):
    blueprint_library = world.get_blueprint_library()
    walker_bps = blueprint_library.filter('walker.pedestrian.*')
    walker_controller_bp = blueprint_library.find('controller.ai.walker')
    
    spawned_walkers = []
    controller_list = []
    
    for _ in range(n):
        loc = world.get_random_location_from_navigation()
        if loc is None:
            continue
            
        transform = carla.Transform(loc)
        transform.location.z += 0.2  
        
        bp = random.choice(walker_bps)
        if bp.has_attribute('is_invincible'):
            bp.set_attribute('is_invincible', 'false')
            
        walker = world.try_spawn_actor(bp, transform)
        if walker:
            controller = world.try_spawn_actor(walker_controller_bp, carla.Transform(), walker)
            if controller:
                spawned_walkers.append(walker)
                controller_list.append(controller)
                
    for controller in controller_list:
        controller.start()
        controller.go_to_location(world.get_random_location_from_navigation())
        controller.set_max_speed(float(random.uniform(1.0, 2.0)))
        
    print(f'Spawned {len(spawned_walkers)} walkers.')
    return len(spawned_walkers)

max_attempts = 2048
world = None

for i in range(1, max_attempts + 1):
    try:
        client = carla.Client('localhost', 2000)
        client.set_timeout(2.0) 
        world = client.get_world()
        
        print(f'\nConnected successfully on attempt {i}! Current map: {world.get_map().name}')
        break
    except Exception as e:
        print(f'\rAttempt {i}/{max_attempts}: CARLA is not ready yet... ({e})', end='')
        time.sleep(1)
else:
    print('\nFailed to connect after 100 attempts.')
    exit(1)

if world:

    try:
        spawn_random_vehicles(world, n=10)
        spawn_random_walkers(world, n=5)
        print("Starting simulation tick loop. Press Ctrl+C to exit.")
        frame_count = 0
        while True:
            # world.tick()
            world.wait_for_tick()
            frame_count += 1
            
            # 例: 100フレームに1回だけ現在フレームを出力する
            if frame_count % 100 == 0:
                print(f"Current CARLA frame: {frame_count}")

    except KeyboardInterrupt:
        print("\nStopping simulation by user...")
    except Exception as e:
        print(f"\nAn error occurred during simulation: {e}")
