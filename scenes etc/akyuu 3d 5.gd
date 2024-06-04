extends Node

func move_toward_angle(from : float, to: float, delta : float):
    var ans = fposmod(to - from, TAU)
    if ans > PI:
        ans -= TAU
    if delta > abs(ans):
        return to
    return from + sign(ans) * min(1.0, abs(ans)) * delta

var prev_velocity = Vector3()
var forwards_tilt = 0.0
var sideways_tilt = 0.0

func clampdown(x : float, cutoff : float = 0.15):
    x = abs(x)
    return max(0.0, (x-cutoff)/(1.0-cutoff))

func handle_animation(parent : CharacterBody3D, delta : float):
    var animation_player = parent.get_node("AnimationPlayer") as AnimationPlayer
    var holder : Node3D = parent.get_node("Armature") as Node3D
    
    var floor_velocity = parent.velocity * Vector3(1,0,1)
    var speed = floor_velocity.length()
    var speed_intent = parent.wish_dir.length()
    
    
    var tilt_speed = speed
    if !parent.is_on_floor():
        tilt_speed *= 0.5
        
    forwards_tilt = clamp(lerp(forwards_tilt, tilt_speed*0.2, 1.0 - pow(0.5, delta * 40.0)), -1.0, 1.0)
    
    var next_prev_velocity = prev_velocity.lerp(floor_velocity, 1.0 - pow(0.5, delta*8.0))
    var accel = (next_prev_velocity - prev_velocity) / delta
    var prev_dir : Vector3 = Vector3()
    var sideways_accel : float = 0.0
    if prev_velocity.length() > 0.0 and next_prev_velocity.length() > 0.0 and parent.is_on_floor():
        prev_dir = prev_velocity.normalized().normalized()
        sideways_accel = accel.slide(prev_dir).length()
        #print(prev_velocity.cross(next_prev_velocity).y)
        sideways_accel *= 1.0 if prev_velocity.cross(next_prev_velocity).y < 0.0 else -1.0
    
    prev_velocity = next_prev_velocity
    
    holder.rotation.x = -forwards_tilt*0.2
    sideways_tilt = clamp(lerp(sideways_tilt, sideways_accel*0.015, 1.0 - pow(0.5, delta * 40.0)), -0.4, 0.4)
    #print(sideways_tilt)
    holder.rotation.z = -sideways_tilt*0.4
    
    if speed_intent > 0.0:
        var new_basis : Basis = holder.global_transform.basis.looking_at(parent.wish_dir)
        var new_y = new_basis.get_euler().y
        holder.global_rotation.y = move_toward_angle(holder.global_rotation.y, new_y, delta * PI * 6.0)
    
    var f = Vector3.FORWARD.rotated(Vector3.UP, holder.global_rotation.y) * holder.rotation.x*2.0
    holder.global_position.z += f.z
    holder.global_position.x += f.x
    
    var f2 = Vector3.FORWARD.rotated(Vector3.UP, holder.global_rotation.y + PI/2) * -holder.rotation.z*2.0
    holder.global_position.z += f2.z
    holder.global_position.x += f2.x
    #print(holder.position.z)
    
    if parent.is_on_floor() or parent.velocity.length() < 0.3:
        if speed > 4.0:
            play_anim(animation_player, "Run", speed_intent*2.0)
        elif speed_intent > 0.0:
            play_anim(animation_player, "Walk", min(2.0, speed_intent*3.5))
        else:
            play_anim(animation_player, "Idle", 1.0)
    else:
        if animation_player.current_animation != "Jump":
            play_anim(animation_player, "JumpLoop", 1.0, 0.2)
        elif !animation_player.is_playing():
            play_anim(animation_player, "JumpLoop", 1.0, 0.05)
    
    #if animation_player.current_animation == "Run":
    #    forwards_tilt = lerp(forwards_tilt, 5.0, 1.0 - pow(0.5, delta * 5.0))
    #else:
    #    forwards_tilt = lerp(forwards_tilt, 0.0, 1.0 - pow(0.5, delta * 5.0))

func play_anim(animation_player : AnimationPlayer, anim : String, speed : float, blend_time : float = 0.2, force : bool = false):
    if animation_player.current_animation != anim or force:
        if animation_player.current_animation == anim and force:
            #blend_time = 0.0
            #animation_player.stop(true)
            animation_player.seek(0.0, true)
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
    
