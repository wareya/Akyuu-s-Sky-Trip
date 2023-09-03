@tool
extends CharacterBody3D

@onready var animation_player : AnimationPlayer = $AnimationPlayer

func _ready():
    #animation_player.play("Idle")
    var walk_anim = animation_player.get_animation("Walk")
    walk_anim.loop_mode = Animation.LOOP_LINEAR
    
    #animation_player.play("Walk")

func tri(x : float) -> float:
    x = fmod(x, 2.0)
    return min(x, 2.0-x)

var time = 0.0
func _process(delta):
    animation_player.play("Walk")
    time += delta
    var p = cos(time*PI)
    var p2 = sin(time*PI/2.0)
    #p2 = abs(p2)*2.0-1.0
    #global_position.z = p
    
    #global_position.x = p2
    #rotation_degrees.y -= delta*30.0
    
    #global_position.y = abs(p)
    #global_position.z = tri(time+0.5)
    
