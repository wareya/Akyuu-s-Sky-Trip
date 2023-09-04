extends Camera3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var player = get_tree().get_first_node_in_group("Player")
    var camera = null
    if player:
        camera = player.get_camera()
    if !camera:
        global_transform = camera.global_transform
        previous_camera_xform = global_transform


var smooth_strength = 30.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
var previous_camera_xform = null
var xform_inertia = Vector3()
func _process(delta: float) -> void:
    var player = get_tree().get_first_node_in_group("Player")
    var camera = null
    if player:
        camera = player.get_camera()
    if !camera:
        global_transform.origin += xform_inertia*delta
        #print(xform_inertia)
        #xform_inertia = xform_inertia.move_toward(Vector3(), delta*30.0)
        xform_inertia = xform_inertia.lerp(Vector3(), 1.0 - pow(0.5, delta*10.0))
        previous_camera_xform = null
        smooth_strength = lerp(smooth_strength, 30.0, 1.0 - pow(0.5, delta*3.0))
    else:
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.get_last_mouse_velocity().length() > 0.0:
            smooth_strength = lerp(smooth_strength, 300.0, 1.0 - pow(0.5, delta*1.0))
        else:
            smooth_strength = lerp(smooth_strength, 30.0, 1.0 - pow(0.5, delta*3.0))
        global_transform = global_transform.interpolate_with(camera.global_transform, 1.0 - pow(0.5, delta*smooth_strength))
        #if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.get_last_mouse_velocity().length() > 0.0:
        #    global_transform.basis = camera.global_transform.basis
        if previous_camera_xform != null:
            xform_inertia = (camera.global_transform.origin - previous_camera_xform.origin)/delta
        previous_camera_xform = camera.global_transform
