extends Node

var sounds = {
    "rockstep_a" : preload("res://sfx/rockstep_a.wav"),
    "rockstep_b" : preload("res://sfx/rockstep_b.wav"),
    "rockstep_c" : preload("res://sfx/rockstep_c.wav"),
    "rockstep_d" : preload("res://sfx/rockstep_d.wav"),
    
    "crunch_a" : preload("res://sfx/crunch_a.wav"),
    "crunch_b" : preload("res://sfx/crunch_b.wav"),
    "crunch_c" : preload("res://sfx/crunch_c.wav"),
    
    "puff" : preload("res://sfx/puff.wav"),
    "jump" : preload("res://sfx/jump.wav"),
    "respawn" : preload("res://sfx/respawn.wav"),
    "squeak" : preload("res://sfx/squeak.wav"),
    "land" : preload("res://sfx/land.wav"),
    
    "doorslide" : preload("res://sfx/doorslide.wav"),
    "spawnbeep" : preload("res://sfx/spawnbeep.wav"),
}

func amp_to_db(x : float) -> float:
    return 20.0*log(x)/log(10.0)

class Emitter3D extends AudioStreamPlayer3D:
    func emit(parent : Node3D, sound, arg_position, channel, detached = false, volume : float = 1.0):
        if detached:
            arg_position = parent.to_global(arg_position)
            parent = null
        
        if !parent:
            parent = Engine.get_main_loop().current_scene
        
        parent.add_child(self)
        position = arg_position
        
        stream = sound
        bus = channel
        
        attenuation_model = ATTENUATION_INVERSE_DISTANCE
        #print(EmitterFactory.amp_to_db(volume))
        volume_db = 0 + EmitterFactory.amp_to_db(volume)
        max_db = 6
        
        attenuation_filter_cutoff_hz = 22000.0
        attenuation_filter_db = -0.001
        
        finished.connect(self.queue_free)
        
        play()
        
        return self

class Emitter extends AudioStreamPlayer:
    func emit(parent : Node, sound, channel, volume : float = 1.0):
        parent.add_child(self)
        
        stream = sound
        bus = channel
        
        volume_db = -3 + EmitterFactory.amp_to_db(volume)
        play()
        
        finished.connect(self.queue_free)
        
        return self

func emit(sound, parent = null, arg_position = Vector3(), channel = "SFX", detached = false, volume : float = 1.0):
    var stream = null
    if sound is String and sound in sounds:
        stream = sounds[sound]
    elif sound is AudioStream:
        stream = sound
    if parent or arg_position != Vector3():
        if !parent:
            parent = get_tree().current_scene
        return Emitter3D.new().emit(parent, stream, arg_position, channel, detached, volume)
    else:
        return Emitter.new().emit(self, stream, channel, volume)
