@tool
extends Node3D
enum Axis {
    X_Plus, Y_Plus, Z_Plus, X_Minus, Y_Minus, Z_Minus
}

@export var enabled: bool = true
@export var bone_name: String:
    set(name):
        bone_name = name
        skeleton = get_parent() # Parent must be a Skeleton node
        if skeleton:
            skeleton.clear_bones_global_pose_override()
            var temp_bone_id = skeleton.find_bone(bone_name)
            if temp_bone_id != -1:
                bone_id = temp_bone_id
            
            
@export_range(0.0, 1.5) var air_resistance : float = 1.0
@export var accel_sensitivity : float = 1.0
@export var strength : float = 0.5
#@export var length : float = 0.0
@export_range(0.0,1.0,0.01) var max_deviation : float = 1.0

@export_range(0.01,100,0.01) var stiffness: float = 1
@export_range(0,100,0.01) var damping: float = 0
@export var use_gravity: bool = false
@export var gravity := Vector3(0, -9.81, 0)
@export var forward_axis: Axis = Axis.Z_Minus
@export_node_path("CollisionShape3D") var collision_shape: NodePath 

func softmin(x, limit) -> float:
    return limit - log(1.0+exp(limit-x))

func softclamp(x, limit, sharpness) -> float:
    var amount = clamp(x/limit, 0.0, 1.0)
    x *= sharpness
    limit *= sharpness
    return lerp(x, sign(x) * softmin(abs(x), limit), amount)/sharpness

var skeleton: Skeleton3D
var bone_id: int
var bone_id_child: int
var collision_sphere: CollisionShape3D
var prev_pos: Vector3
var prev_vel: Vector3
var prev_accel: Vector3


func set_collision_shape(path:NodePath) -> void:
    collision_shape = path
    collision_sphere = get_node_or_null(path)
    if collision_sphere:
        assert(collision_sphere is CollisionShape3D and collision_sphere.shape is SphereShape3D, "%s: Only SphereShapes are supported for CollisionShapes" % [ name ])


func _ready() -> void:
    skeleton = get_parent() # Parent must be a Skeleton node
    skeleton.clear_bones_global_pose_override()
    prev_pos = global_position
    set_collision_shape(collision_shape)
    
    assert(! (is_nan(position.x) or is_inf(position.x)), "%s: Bone position corrupted" % [ name ])
    assert(bone_name, "%s: Please enter a bone name" % [ name ])
    bone_id = skeleton.find_bone(bone_name)
    assert(bone_id != -1, "%s: Unknown bone %s - Please enter a valid bone name" % [ name, bone_name ])
    var children = skeleton.get_bone_children(bone_id)
    if children.size() > 0:
        bone_id_child = skeleton.get_bone_children(bone_id)[0]
    else:
        print("no child. using parent as base")
        bone_id = skeleton.get_bone_parent(bone_id)
        bone_id_child = skeleton.get_bone_children(bone_id)[0]

var vel : Vector3

func _process(delta) -> void:
    if not enabled:
        var xform = skeleton.get_bone_global_pose_no_override(bone_id);
        skeleton.set_bone_global_pose_override(bone_id, xform, 1.0, true)
        return
    # Note:
    # Local space = local to the bone
    # Object space = local to the skeleton (confusingly called "global" in get_bone_global_pose)
    # World space = global

    # See https://godotengine.org/qa/7631/armature-differences-between-bones-custom_pose-Transform3D

    var bone_transf_obj: Transform3D = skeleton.get_bone_global_pose_no_override(bone_id) # Object space bone pose
    var bone_transf_world: Transform3D = skeleton.global_transform * bone_transf_obj
    
    var child_bone_transf_obj : Transform3D = skeleton.get_bone_global_pose_no_override(bone_id_child)
    var child_bone_transf_world : Transform3D = skeleton.global_transform * child_bone_transf_obj

    ############### Integrate velocity (Verlet integration) ##############	

    # If not using gravity, apply force in the direction of the bone (so it always wants to point "forward")
    var grav: Vector3 = (bone_transf_world.basis * get_bone_forward_local()).normalized() * 9.81
    
    if vel != vel:
        vel = Vector3()
    if prev_pos != prev_pos:
        prev_pos = Vector3()
    if prev_vel != prev_vel:
        prev_vel = Vector3()
    if prev_accel != prev_accel:
        prev_accel = Vector3()
    if global_position != global_position:
        global_position = Vector3()
    
    var pos = bone_transf_world.origin
    var raw_vel = (pos - prev_pos) / delta
    
    #vel = raw_vel
    vel = lerp(vel, raw_vel, 1.0 - pow(0.5, delta*20.0))
    
    var raw_accel : Vector3 = (vel - prev_vel) / delta
    
    var accel : Vector3 = lerp(prev_accel, raw_accel, 1.0 - pow(0.5, delta*20.0))
    prev_accel = accel
    
    prev_pos = pos
    prev_vel = vel
    
    if bone_name == "HairFront_L" and !Engine.is_editor_hint():
        #print(pos)
        #print(grav)
        #print(accel)
        #print(vel.y, "\t",  accel.y)
        pass
    
    if use_gravity:
        grav += gravity
    
    #vel *= (1.0 - air_resistance)
    #vel *= 0.0
    
    grav *= stiffness * 60.0
    
    var vel_dirty = vel * -air_resistance
    
    vel_dirty += grav * delta
    vel_dirty -= accel * delta * accel_sensitivity * 20.0
    
    if damping >= 0.001:
        vel_dirty *= 1.0 - pow(0.5, delta*60.0/damping)

    global_position += vel_dirty * delta

    ############### Solve distance constraint ##############
    
    var length = (child_bone_transf_world.origin - bone_transf_world.origin).length()
    #print(length)
    
    var goal_pos : Vector3 = skeleton.to_global(skeleton.get_bone_global_pose(bone_id).origin)
    var fixed_pos = goal_pos + (global_transform.origin - goal_pos).normalized() * length
    #var fixed_pos = goal_pos
    global_position = global_position.lerp(fixed_pos, pow(0.5, delta))

    if collision_sphere:
        # If bone is inside the collision sphere, push it out
        var from_sphere : Vector3 = global_position - collision_sphere.global_position
        var surface_distance = from_sphere.length() - collision_sphere.shape.radius
        #if bone_name == "HairFront_L":
        #    print(surface_distance)
        if surface_distance < 0:
            #if bone_name == "HairFront_L":
            #    print(from_sphere.normalized() * surface_distance, surface_distance)
            var adjusted_position = global_position - from_sphere.normalized() * surface_distance
            #global_position = global_position.lerp(adjusted_position, 1.0 - pow(0.5, delta*20.0))
            global_position = adjusted_position

    ############## Rotate the bone to point to this object #############

    var diff_vec_local: Vector3 = (bone_transf_world.affine_inverse() * global_position).normalized()

    # The axis+angle to rotate on, in local-to-bone space
    var bone_forward_local: Vector3 = get_bone_forward_local()
    var bone_rotate_axis: Vector3 = bone_forward_local.cross(diff_vec_local)
    var bone_rotate_angle: float = acos(bone_forward_local.dot(diff_vec_local))
    #bone_rotate_angle = clamp(bone_rotate_angle, -max_deviation*PI, max_deviation*PI)
    bone_rotate_angle = softclamp(bone_rotate_angle, max_deviation*PI, 100.0)

    if bone_rotate_axis.length() < 1e-3:
        return  # Already aligned, no need to rotate

    bone_rotate_axis = bone_rotate_axis.normalized()

    # Bring the axis to object space, WITHOUT position (so only the BASIS is used) since vectors shouldn't be translated
    var bone_rotate_axis_obj: Vector3 = (bone_transf_obj.basis * bone_rotate_axis).normalized().normalized().normalized()
    var bone_new_xform: Transform3D = Transform3D(bone_transf_obj.basis.rotated(bone_rotate_axis_obj, bone_rotate_angle), bone_transf_obj.origin)

    #skeleton.set_bone_global_pose_override(bone_id, bone_new_xform, strength, true)
    
    # Orient this object to the new xform
    global_transform.basis = (skeleton.global_transform * bone_new_xform).basis
    
    # Calculate xform relative to head of bone
    var applied_xform = global_transform
    applied_xform.origin = to_global(-bone_forward_local*length)
    #applied_xform.origin -= child_bone_transf_obj.origin - bone_transf_obj.origin
    
    skeleton.set_bone_global_pose_override(bone_id, skeleton.global_transform.affine_inverse() * applied_xform, strength, true)


func get_bone_forward_local() -> Vector3:
    match forward_axis:
        Axis.X_Plus: return Vector3(1,0,0)
        Axis.Y_Plus: return Vector3(0,1,0)
        Axis.Z_Plus: return Vector3(0,0,1)
        Axis.X_Minus: return Vector3(-1,0,0)
        Axis.Y_Minus: return Vector3(0,-1,0)
        _, Axis.Z_Minus: return Vector3(0,0,-1)
