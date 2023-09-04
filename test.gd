extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    $testmesh/Armature/Skeleton3D.physical_bones_start_simulation()
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
