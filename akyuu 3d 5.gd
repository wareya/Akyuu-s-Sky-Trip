extends Node

func move_toward_angle(from : float, to: float, delta : float):
    var ans = fposmod(to - from, TAU)
    if ans > PI:
        ans -= TAU
    if delta > abs(ans):
        return to
    #if abs(ans) < delta/get_process_delta_time()*0.05:
    #    delta *= 0.25
    return from + sign(ans) * min(1.0, abs(ans)) * delta

var prev_velocity = Vector3()
var forwards_tilt = 0.0

func handle_animation(parent : CharacterBody3D, delta : float):
    var animation_player = parent.get_node("AnimationPlayer")
    var holder : Node3D = parent.get_node("Armature") as Node3D
    
    var floor_velocity = parent.velocity * Vector3(1,0,1)
    var speed = floor_velocity.length()
    var speed_intent = parent.wish_dir.length()
    
    var next_prev_velocity = prev_velocity.lerp(floor_velocity, 1.0 - pow(0.5, delta*8.0))
    var accel = (next_prev_velocity - prev_velocity) / delta
    
    
    var prev_dir : Vector3 = Vector3()
    forwards_tilt = lerp(forwards_tilt, speed, 1.0 - pow(0.5, delta * 5.0))
    var sideways_accel : float = 0.0
    if prev_velocity.length() > 0.0 and next_prev_velocity.length() > 0.0:
        prev_dir = prev_velocity.normalized().normalized()
        sideways_accel = accel.slide(prev_dir).length()
        #print(prev_velocity.cross(next_prev_velocity).y)
        sideways_accel *= 1.0 if prev_velocity.cross(next_prev_velocity).y < 0.0 else -1.0
    
    prev_velocity = next_prev_velocity
    holder.rotation.x = -clamp(forwards_tilt * 0.01, -1.5, 1.5)
    holder.rotation.z = -clamp(sideways_accel * 0.002, -0.5, 0.5)
    
    if speed_intent > 0.0:
        var new_basis : Basis = holder.global_transform.basis.looking_at(parent.wish_dir)
        var new_y = new_basis.get_euler().y
        #print(new_y)
        holder.global_rotation.y = move_toward_angle(holder.global_rotation.y, new_y, delta * PI * 6.0)
        #holder.global_transform.basis = holder.global_transform.basis.slerp(new_basis, 1.0 - pow(0.5, delta*20.0))
    
    if parent.is_on_floor():
        if speed > 4.0:
            play_anim(animation_player, "Run", speed_intent*2.0)
        elif speed_intent > 0.0:
            play_anim(animation_player, "Walk", min(2.0, speed_intent*4.0))
        else:
            play_anim(animation_player, "Idle", 1.0)
    else:
        if !animation_player.is_playing():
            play_anim(animation_player, "JumpLoop", 1.0, 0.05)

func play_anim(animation_player : AnimationPlayer, anim : String, speed : float, blend_time : float = 0.2, force : bool = false):
    if animation_player.current_animation != anim or force:
        if animation_player.current_animation == anim and force:
            blend_time = 0.0
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

func _ready() -> void:
    play_anim(get_parent().get_node("AnimationPlayer"), "Idle", 1.0)
    
