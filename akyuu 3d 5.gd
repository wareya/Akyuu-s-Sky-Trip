extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 9.0

var gravity = 20.0

var time = 0.0
func _process(delta: float) -> void:
    time += delta
    # Add the gravity.
    if not is_on_floor():
        velocity.y -= gravity * delta
        velocity.y = lerp(velocity.y, 0.0, 1.0 - pow(0.5, delta*2.0))
        
        #print(velocity.y)
    
    var on_floor = is_on_floor()
    
    # Handle Jump.
    if Input.is_action_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY
        play_anim("Jump", 1.0, 0.05, true)

    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var camera = get_viewport().get_camera_3d()
    var direction := (Vector3(input_dir.x, 0, input_dir.y)).normalized()
    direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
    
    var actual_speed = SPEED*0.5 if Input.is_key_pressed(KEY_SHIFT) else SPEED
    
    if direction:
        velocity.x = direction.x * actual_speed
        velocity.z = direction.z * actual_speed
    else:
        velocity.x = move_toward(velocity.x, 0, actual_speed)
        velocity.z = move_toward(velocity.z, 0, actual_speed)
    
    var floor_velocity = velocity * Vector3(1,0,1)
    
    var speed = floor_velocity.length()
    #print(speed)
    
    var blend_time = 0.2
    
    var holder = $Armature
    
    if speed > 0.5:
        var new_basis = holder.global_transform.basis.looking_at(floor_velocity)
        holder.global_transform.basis = holder.global_transform.basis.slerp(new_basis, 1.0 - pow(0.5, delta*20.0))

    move_and_slide()
        
    if is_on_floor():
        if speed > 3.0:
            play_anim("Run", speed/actual_speed * 1.5)
        elif speed > 0.5:
            play_anim("Walk", speed/actual_speed * 1.5)
        else:
            play_anim("Idle", 1.0)
    else:
        if !animation_player.is_playing():
            play_anim("JumpLoop", 1.0, 0.05)

func play_anim(anim : String, speed : float, blend_time : float = 0.2, force : bool = false):
    if animation_player.current_animation != anim or force:
        if animation_player.current_animation == anim and force:
            print("koasdioawrg")
            #animation_player.play("Null", blend_time, 1.0)
            #animation_player.advance(0.0)
            animation_player.stop(true)
        animation_player.play(anim, blend_time, speed)
        animation_player.advance(0.0)
    

@onready var animation_player : AnimationPlayer = $AnimationPlayer

func _ready():
    animation_player.get_animation("Run").loop_mode = Animation.LOOP_LINEAR
    animation_player.get_animation("JumpLoop").loop_mode = Animation.LOOP_LINEAR
    animation_player.get_animation("Walk").loop_mode = Animation.LOOP_LINEAR
    animation_player.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
    
