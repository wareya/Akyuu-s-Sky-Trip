extends Area3D

@export_file("*.tscn", "*.scn") var target_stage = null

class TransitionCutscene extends RefCounted:
    var target_stage : String = ""
    func _init(_target):
        target_stage = _target
        
    func _cutscene(cutscene : CutsceneInstance):
        
        var bg_texture = preload("res://art/white.png")
        var bg_image = cutscene.add_background(bg_texture)
        await bg_image.fade_show()
        
        Engine.get_main_loop().change_scene_to_file(target_stage)
        
        await bg_image.fade_hide()
        
        cutscene.finish()


func _process(delta: float) -> void:
    $CSGCylinder3D.material.uv1_offset.x += delta
    $CSGCylinder3D.material.uv1_offset.z += delta

    for body in get_overlapping_bodies():
        if body.is_in_group("Player"):
            if target_stage != null and ResourceLoader.exists(target_stage):
                CutsceneStarter.start_cutscene(TransitionCutscene.new(target_stage)._cutscene)
