extends Camera3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    var player = get_tree().get_first_node_in_group("Player")
    if !player:
        return
    
    var camera = player.get_camera()
    if !camera:
        return
    
    global_transform = global_transform.interpolate_with(camera.global_transform, 1.0 - pow(0.5, delta*30.0))
