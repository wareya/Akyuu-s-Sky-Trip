extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.

@export var require_switch = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    var enabled = !require_switch or is_on
    $Beams.visible = enabled
    if !$AudioStreamPlayer3D.playing or !enabled:
        $AudioStreamPlayer3D.playing = enabled
    if enabled:
        for body in get_overlapping_bodies():
            if body.is_in_group("Player"):
                body.trigger_death()

var is_on = false
func inform_switch(new_state : bool):
    is_on = new_state
