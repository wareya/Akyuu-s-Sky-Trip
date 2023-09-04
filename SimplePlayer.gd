extends CharacterBody3D
class_name SimplePlayer

const mouse_sens = 0.022 * 2.5

const gravity = 15.0
const jumpvel = 10.0

const max_speed = 4.0
const max_speed_air = 4.0

const sprint_speed = 8.0

const accel = 30.0
const accel_air = 5.0
const friction = 60.0
const air_friction = 1.0

var wish_dir = Vector3()

var original_fov = 90.0

func kill():
    $CameraHolder/Camera3D.current = false
    $CameraHolder.queue_free()
    $AnimationPlayer.stop()
    var bones = []
    for child in $Armature/Skeleton3D.get_children():
        if child is PhysicalBone3D:
            bones.push_back(child)
        elif child.has_method("get_bone_forward_local"):
            child.queue_free()
    for bone in bones:
        bone.process_mode = Node.PROCESS_MODE_INHERIT
        bone.set_collision_layer_value(4, false)
        bone.set_collision_layer_value(3, true)
        for bone2 in bones:
            if bone2 != bone:
                bone.add_collision_exception_with(bone2)
            
    
    var skele = $Armature/Skeleton3D
    
    var armature = $Armature
    var pos = armature.global_position
    remove_child(armature)
    get_parent().add_child(armature)
    armature.global_position = pos
    print(armature.global_position)
    
    skele.clear_bones_global_pose_override()
    skele.physical_bones_start_simulation()
    
    queue_free()

var animation_script = null
func _ready():
    animation_script = preload("res://akyuu 3d 5.gd").new()
    animation_script.fix_animations($AnimationPlayer)
    add_child(animation_script)
    original_fov = $CameraHolder/Camera3D.fov
    floor_constant_speed = true

func _friction(_velocity : Vector3, delta : float) -> Vector3:
    _velocity *= pow(0.5, delta)
    
    if wish_dir == Vector3():
        _velocity = _velocity.move_toward(Vector3(), delta)
    else:
        var forwards = wish_dir.normalized()
        forwards = _velocity.project(forwards)
        var newvel = _velocity.move_toward(forwards, delta)
        _velocity.x = newvel.x
        _velocity.z = newvel.z
    
    #print((_velocity*Vector3(1,0,1)).length())
    return _velocity

func handle_friction(delta):
    var oldvel = velocity
    if is_on_floor():
        velocity = _friction(velocity, delta * friction)
    else:
        velocity = _friction(velocity, delta * air_friction)
    if !is_on_floor():
        velocity.y = oldvel.y


var sprint_strength = 0.0

func handle_accel(delta):
    var actual_maxspeed = max_speed if is_on_floor() else max_speed_air
    var wish_dir_length = wish_dir.length()
    var actual_accel = (accel if is_on_floor() else accel_air) * actual_maxspeed * wish_dir_length
    
    if !Input.is_action_pressed("sprint"):
        actual_maxspeed *= sprint_speed/max_speed
        actual_accel *= sprint_speed/max_speed
        sprint_strength = move_toward(sprint_strength, 1.0, delta*16.0)
    else:
        sprint_strength = move_toward(sprint_strength, 0.0, delta*16.0)
        
    if wish_dir != Vector3():
        var floor_velocity = Vector3(velocity.x, 0, velocity.z)
        var speed_in_wish_dir = floor_velocity.dot(wish_dir.normalized())
        var speed = floor_velocity.length()
        if speed_in_wish_dir < actual_maxspeed:
            var add_limit = actual_maxspeed - speed_in_wish_dir
            var add_amount = min(add_limit, actual_accel*delta)
            velocity += wish_dir.normalized() * add_amount
            if speed > actual_maxspeed:
                floor_velocity = velocity * Vector3(1.0, 0.0, 1.0)
                floor_velocity = floor_velocity.normalized() * speed
                velocity.x = floor_velocity.x
                velocity.z = floor_velocity.z

func handle_friction_and_accel(delta):
    handle_friction(delta)
    handle_accel(delta)

@export var do_camera_smoothing : bool = true
@export var do_stairs : bool = true
@export var do_skipping_hack : bool = false
@export var stairs_cause_floor_snap : bool = false
@export var skipping_hack_distance : float = 0.08
@export var step_height : float = 0.5

var started_process_on_floor = false

func check_and_attempt_skipping_hack(distance : float, floor_normal : float):
    # try again with a certain minimum horizontal step distance if there was no wall collision and the wall trace was close
    if !found_stairs and (wall_test_travel * Vector3(1,0,1)).length() < distance:
        # go back to where we were at the end of the ceiling collision test
        global_position = ceiling_position
        # calculate a new path for the wall test: horizontal only, length of our fallback distance
        var floor_velocity = Vector3(velocity.x, 0.0, velocity.z)
        var factor = distance / floor_velocity.length()
        
        # step 2, skipping hack version
        wall_test_travel = floor_velocity * factor
        var info = move_and_collide_n_times(floor_velocity, factor, 2)
        velocity = info[0]
        wall_remainder = info[1]
        wall_collision = info[2]
        
        # step 3, skipping hack version
        floor_collision = move_and_collide(Vector3.DOWN * (ceiling_travel_distance + (step_height if started_process_on_floor else 0.0)))
        if floor_collision and floor_collision.get_collision_count() > 0 and floor_collision.get_normal(0).y > floor_normal:
            found_stairs = true

var found_stairs = false
var wall_test_travel = Vector3()
var wall_remainder = Vector3()
var ceiling_position = Vector3()
var ceiling_travel_distance = Vector3()
var ceiling_collision : KinematicCollision3D = null
var wall_collision : KinematicCollision3D = null
var floor_collision : KinematicCollision3D = null

var slide_snap_offset = Vector3()

func move_and_collide_n_times(vector : Vector3, delta : float, slide_count : int, skip_reject_if_ceiling : bool = true):
    var collision = null
    var remainder = vector
    var adjusted_vector = vector * delta
    var _floor_normal = cos(floor_max_angle)
    for _i in slide_count:
        var new_collision = move_and_collide(adjusted_vector)
        if new_collision:
            collision = new_collision
            remainder = collision.get_remainder()
            adjusted_vector = remainder
            if !skip_reject_if_ceiling or collision.get_normal().y >= -_floor_normal:
                adjusted_vector = adjusted_vector.slide(collision.get_normal())
                vector = vector.slide(collision.get_normal())
        else:
            remainder = Vector3()
            break
    
    return [vector, remainder, collision]

func move_and_climb_stairs(delta : float, allow_stair_snapping : bool):
    var start_position = global_position
    var start_velocity = velocity
    
    found_stairs = false
    wall_test_travel = Vector3()
    wall_remainder = Vector3()
    ceiling_position = Vector3()
    ceiling_travel_distance = Vector3()
    ceiling_collision = null
    wall_collision = null
    floor_collision = null
    
    # do move_and_slide and check if we hit a wall
    wall_min_slide_angle = 0.0
    move_and_slide()
    
    var slide_velocity = velocity
    var slide_position = global_position
    var hit_wall = false
    var floor_normal = cos(floor_max_angle)
    var max_slide = get_slide_collision_count()
    var accumulated_position = start_position
    var wall_position = start_position
    for slide in max_slide:
        var collision = get_slide_collision(slide)
        var y = collision.get_normal().y
        accumulated_position += collision.get_travel()
        if y < floor_normal and y > -floor_normal:
            hit_wall = true
            wall_position = accumulated_position
    slide_snap_offset = accumulated_position - global_position
    
    var really_do_stairs = do_stairs
    if !is_on_floor() and wish_dir == Vector3():
        really_do_stairs = false
    if !is_on_floor() and velocity.y > 0.0:
        really_do_stairs = false
    # if we hit a wall, check for simple stairs; three steps
    if hit_wall and really_do_stairs and (start_velocity.x != 0.0 or start_velocity.z != 0.0):
        var original_wall_dist = ((wall_position - accumulated_position)*Vector3(1,0,1)).length_squared()
        
        global_position = start_position
        velocity = start_velocity
        # step 1: upwards trace
        var up_height = probe_probable_step_height() # NOT NECESSARY. can just be step_height.
        
        ceiling_collision = move_and_collide(up_height * Vector3.UP)
        ceiling_travel_distance = step_height if not ceiling_collision else abs(ceiling_collision.get_travel().y)
        ceiling_position = global_position
        # step 2: "check if there's a wall" trace
        wall_test_travel = velocity * delta
        var info = move_and_collide_n_times(velocity, delta, 2)
        velocity = info[0]
        wall_remainder = info[1]
        wall_collision = info[2]
        
        var wall_test_dist = ((wall_collision.get_travel() if wall_collision else wall_test_travel)*Vector3(1,0,1)).length_squared()
        var went_further = wall_test_dist - 0.00001 > original_wall_dist
        
        # step 3: downwards trace
        floor_collision = move_and_collide(Vector3.DOWN * (ceiling_travel_distance + (step_height if started_process_on_floor else 0.0)))
        if went_further and floor_collision:
            if floor_collision.get_normal(0).y > floor_normal:
                found_stairs = true
            # NOTE: NOT NECESSARY
            # try to skip over small sloped walls if we failed to find a stair and the skipping hack is enabled
            if !floor_collision or floor_collision.get_normal(0).y < floor_normal:
                check_and_attempt_skipping_hack(0.01, floor_normal)
            if !floor_collision or floor_collision.get_normal(0).y < floor_normal and do_skipping_hack:
                check_and_attempt_skipping_hack(skipping_hack_distance, floor_normal)
    
    # (this section is more complex than it needs to be, because of move_and_slide taking velocity and delta for granted)
    # if we found stairs, climb up them
    if found_stairs:
        if allow_stair_snapping and stairs_cause_floor_snap:
            velocity.y = 0.0
        var oldvel = velocity
        velocity = wall_remainder / delta
        move_and_slide()
        velocity = oldvel
    # no stairs, do "normal" non-stairs movement
    else:
        global_position = slide_position
        velocity = slide_velocity
    
    return found_stairs

func probe_probable_step_height():
    const hull_height = 1.75 # edit me
    const center_offset = 0.875 # edit to match the offset between your origin and the center of your hitbox
    const hull_width = 0.625 # approximately the full width of your hull
    
    var heading = (velocity * Vector3(1, 0, 1)).normalized()
    
    var offset = Vector3()
    var test = move_and_collide(heading * hull_width, true)
    if test and abs(test.get_normal().y) < 0.8:
        offset = (test.get_position(0) - test.get_travel() - global_position) * Vector3(1, 0, 1)
    
    var raycast = ShapeCast3D.new()
    var shape = CylinderShape3D.new()
    shape.radius = hull_width/2.0
    shape.height = max(0.01, hull_height - step_height*2.0 - 0.1)
    raycast.shape = shape
    raycast.max_results = 1
    add_child(raycast)
    raycast.collision_mask = collision_mask
    raycast.position = Vector3(0.0, center_offset, 0.0)
    if offset != Vector3():
        raycast.target_position = heading * hull_width * 0.22 + offset
    else:
        raycast.target_position = heading * hull_width * 0.72
    #raycast.force_raycast_update()
    raycast.force_shapecast_update()
    if raycast.is_colliding():
        #raycast.position = raycast.get_collision_point(0)
        raycast.global_position = raycast.get_collision_point(0)
    else:
        raycast.global_position += raycast.target_position
    
    var up_distance = 50.0
    raycast.target_position = Vector3(0.0, 50.0, 0.0)
    #raycast.force_raycast_update()
    raycast.force_shapecast_update()
    if raycast.is_colliding():
        up_distance = raycast.get_collision_point(0).y - raycast.position.y
    
    var down_distance = center_offset
    raycast.target_position = Vector3(0.0, -center_offset, 0.0)
    #raycast.force_raycast_update()
    raycast.force_shapecast_update()
    if raycast.is_colliding():
        down_distance = raycast.position.y - raycast.get_collision_point(0).y
    
    raycast.queue_free()
    
    if up_distance + down_distance < hull_height:
        return step_height
    else:
        var highest = up_distance - center_offset
        var lowest = center_offset - down_distance
        return clamp(highest/2.0 + lowest/2.0, 0.0, step_height)

var time = 0.0
var want_to_jump = false
func _process(delta: float) -> void:
    if time > 5.0:
        #print(scene_file_path)
        get_parent().add_child(load(scene_file_path).instantiate())
        kill()
        return
    
    time += delta
    
    started_process_on_floor = is_on_floor()
    # for controller camera control
    handle_stick_input(delta)
    
    var allow_stair_snapping = started_process_on_floor
    if Input.is_action_just_pressed("ui_accept"):
        want_to_jump = true
    elif !Input.is_action_pressed("ui_accept"):
        want_to_jump = false
    
    if want_to_jump and started_process_on_floor:
        want_to_jump = false
        animation_script.play_anim($AnimationPlayer, "Jump", 1.0, 0.05, true)
        allow_stair_snapping = false
        velocity.y = jumpvel
        floor_snap_length = 0.0
    elif started_process_on_floor:
        floor_snap_length = step_height + safe_margin
    
    var input_dir := Input.get_vector("left", "right", "forward", "backward") + Input.get_vector("stick_left", "stick_right", "stick_forward", "stick_backward")
    wish_dir = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, $CameraHolder.global_rotation.y)
    
    handle_friction_and_accel(delta)
    
    var grav_mod = 1.0
    var drag = 0.98
    
    if !Input.is_action_pressed("ui_accept") and !is_on_floor() and velocity.y > 0.0:
        grav_mod *= 2.0
    
    var start_pos = global_position
    var start_vel = velocity
    
    actually_handle_movement(delta, drag, grav_mod, allow_stair_snapping)
    
    animation_script.handle_animation(self, delta)
    
    handle_camera_adjustment(start_pos, delta)
    
    handle_movement_sound(started_process_on_floor, is_on_floor(), start_vel, delta)


static var prev_which = ""
static func generate_sound(vox, kind, parent, where : Vector3 = Vector3(), channel = "SFX"):
    pass

var step_progress = 0.0
const step_rate_modifier = 0.6
var prev_in_water = false
func handle_movement_sound(started_process_on_floor : bool, now_on_floor : bool, start_vel : Vector3, delta : float):
    var speed = start_vel.length()
        
    if is_on_floor() and !started_process_on_floor:
        step_progress = 0.5
    
    if !is_on_floor():
        pass
    else:
        if speed == 0.0:
            step_progress = 0.85
        else:
            step_progress += delta * min(7.0, speed) * step_rate_modifier
            if !started_process_on_floor and now_on_floor and start_vel.y < -1.0:
                step_progress = 0.0
                #generate_step_sound()
            else:
                if step_progress > 1.0:
                    #generate_step_sound()
                    step_progress = fmod(step_progress, 1.0)

func actually_handle_movement(delta, drag, grav_mod, allow_stair_snapping):
    if not is_on_floor():
        velocity.y -= gravity * delta * 0.5 * grav_mod
        velocity.y *= pow(drag, delta*10.0)
    
    # CHANGE ME: replace this with your own movement-and-stair-climbing code
    move_and_climb_stairs(delta, allow_stair_snapping)
    
    #print(global_position.y)
    
    if not is_on_floor(): 
        velocity.y -= gravity * delta * 0.5 * grav_mod
        velocity.y *= pow(drag, delta*10.0)

const stick_camera_speed = 240.0
func handle_stick_input(delta):
    var camera_dir := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down", 0.15)
    var tilt = camera_dir.length()
    var acceleration = lerp(0.25, 1.0, tilt)
    camera_dir *= acceleration
    $CameraHolder.rotation_degrees.y -= camera_dir.x * stick_camera_speed * delta
    $CameraHolder.rotation_degrees.x -= camera_dir.y * stick_camera_speed * delta
    $CameraHolder.rotation_degrees.x = clamp($CameraHolder.rotation_degrees.x, -90.0, 90.0)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            $CameraHolder.rotation_degrees.y -= event.relative.x * mouse_sens
            $CameraHolder.rotation_degrees.x -= event.relative.y * mouse_sens
            $CameraHolder.rotation_degrees.x = clamp($CameraHolder.rotation_degrees.x, -90.0, 90.0)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.pressed and event.keycode in [KEY_ESCAPE, KEY_Z]:
            if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
                Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            else:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

@export var third_person : bool = true
@export var camera_smoothing_meters_per_sec : float = 3.0
# used to smooth out the camera when climbing stairs
var camera_offset_y = 0.0
func handle_camera_adjustment(start_position, delta):
    #$CameraHolder/Camera3D.fov = rad_to_deg(atan(sprint_strength*0.1 + tan(deg_to_rad(original_fov/2.0))))*2.0
    
    # first/third-person adjustment
    $CameraHolder.position.y = 1.2 if third_person else 1.625
    $CameraHolder/Camera3D.position.z = 4.0 if third_person else 0.0
    
    if do_camera_smoothing:
        # NOT NEEDED: camera smoothing
        var stair_climb_distance = 0.0
        if found_stairs:
            stair_climb_distance = global_position.y - start_position.y
        elif is_on_floor():
            stair_climb_distance = -slide_snap_offset.y
        
        camera_offset_y -= stair_climb_distance
        camera_offset_y = clamp(camera_offset_y, -step_height, step_height)
        camera_offset_y = move_toward(camera_offset_y, 0.0, delta * camera_smoothing_meters_per_sec)
        
        $CameraHolder/Camera3D.position.y = 0.0
        $CameraHolder/Camera3D.position.x = 0.0
        $CameraHolder/Camera3D.global_position.y += camera_offset_y
