extends CSGBox3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@onready var start_position = position
@export var inverted = false

func _process(delta: float) -> void:
    var up = transform.basis * Vector3.UP
    print(up)
    if is_open != inverted:
        position = position.move_toward(start_position + 2.9*up, delta*12.0)
    else:
        position = position.move_toward(start_position + 0.0*up, delta*12.0)

var is_open = false
func inform_switch(new_state : bool):
    if is_open != new_state:
        var sound : AudioStreamPlayer3D = EmitterFactory.emit("doorslide", self) as AudioStreamPlayer3D
        if new_state:
            sound.pitch_scale = 1.2
    is_open = new_state
