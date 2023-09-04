extends Area3D

@export var require_switch = false
@export var inverted = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    var enabled = (!require_switch or is_on) != inverted
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
