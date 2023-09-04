extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

var switch_on = false

@export var inform_switch : Array[NodePath] = []

@onready var body_origin = $Plate.global_position
func _physics_process(delta: float) -> void:
    var force = body_origin - $Plate.global_position
    $Plate.apply_central_force(force * 20.0)
    $Plate.global_position.y = clamp($Plate.global_position.y, body_origin.y - 0.2, body_origin.y + 0.2)
    
    switch_on = $Plate.global_position.y < body_origin.y-0.1
    
    for inform in inform_switch:
        if has_node(inform):
            var node = get_node(inform)
            if node.has_method("inform_switch"):
                node.inform_switch(switch_on)
    
    $Light.visible = switch_on
