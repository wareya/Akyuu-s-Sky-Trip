extends Node3D


func _ready() -> void:
    CutsceneStarter.start_cutscene(IntroCutscene.new()._cutscene)

class IntroCutscene extends RefCounted:
    func _cutscene(cutscene : CutsceneInstance):
        var bg_texture = preload("res://art/splash.png")
        var bg_image = cutscene.add_background(bg_texture)
        await bg_image.fade_hide()
        
        await cutscene.set_text("[color=#88F]It's possible to get stuck on this level. Enter the nearby portal to restart the level if you get stuck.[/color]")
        cutscene.finish()

func _process(delta: float) -> void:
    pass
