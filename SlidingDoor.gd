extends CSGBox3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@onready var start_position = position
func _process(delta: float) -> void:
    if is_open:
        position.y = move_toward(position.y, start_position.y + 2.9, delta*12.0)
    else:
        position.y = move_toward(position.y, start_position.y + 0.0, delta*12.0)

var is_open = false
func inform_switch(new_state : bool):
    if is_open != new_state:
        var sound : AudioStreamPlayer3D = EmitterFactory.emit("doorslide", self) as AudioStreamPlayer3D
        if new_state:
            sound.pitch_scale = 1.2
    is_open = new_state
