extends Node

func move_toward_angle(from : float, to: float, delta : float):
    var ans = fposmod(to - from, TAU)
    if ans > PI:
        ans -= TAU
    return from + ans * delta

func handle_animation(parent : CharacterBody3D, delta : float):
    var animation_player = parent.get_node("AnimationPlayer")
    var holder : Node3D = parent.get_node("Armature")
    
    var floor_velocity = parent.velocity * Vector3(1,0,1)
    var speed = floor_velocity.length()
    var speed_intent = parent.wish_dir.length()
    if speed_intent > 0.0:
        var new_basis : Basis = holder.global_transform.basis.looking_at(parent.wish_dir)
        var new_y = new_basis.get_euler().y
        #print(new_y)
        holder.global_rotation.y = move_toward_angle(holder.global_rotation.y, new_y, delta * PI * 4.0 )
        #holder.global_transform.basis = holder.global_transform.basis.slerp(new_basis, 1.0 - pow(0.5, delta*20.0))
    
    if parent.is_on_floor():
        if speed > 5.0:
            play_anim(animation_player, "Run", speed_intent*2.0)
        elif speed_intent > 0.0:
            play_anim(animation_player, "Walk", speed_intent*2.0)
        else:
            play_anim(animation_player, "Idle", 1.0)
    else:
        if !animation_player.is_playing():
            play_anim(animation_player, "JumpLoop", 1.0, 0.05)

func play_anim(animation_player : AnimationPlayer, anim : String, speed : float, blend_time : float = 0.2, force : bool = false):
    if animation_player.current_animation != anim or force:
        if animation_player.current_animation == anim and force:
            animation_player.stop(true)
        animation_player.play(anim, blend_time)
        animation_player.speed_scale = speed
        animation_player.advance(0.0)
    animation_player.speed_scale = speed
    
func fix_animations(animation_player : AnimationPlayer):
    animation_player.get_animation("Run").loop_mode = Animation.LOOP_LINEAR
    animation_player.get_animation("JumpLoop").loop_mode = Animation.LOOP_LINEAR
    animation_player.get_animation("Walk").loop_mode = Animation.LOOP_LINEAR
    animation_player.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
