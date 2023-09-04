extends Node3D


func _ready() -> void:
    CutsceneStarter.start_cutscene(IntroCutscene.new()._cutscene)

class IntroCutscene extends RefCounted:
    func _cutscene(cutscene : CutsceneInstance):
        var bg_texture = preload("res://art/splash.png")
        var bg_image = cutscene.add_background(bg_texture)
        await bg_image.fade_hide()
        
        await cutscene.set_text("Akyuu's fever is all better now! Good work.")
        await cutscene.set_text("[color=#88F]Good heavens, look at the time. I ran out of time to make more than a couple of levels. Sorry! Enter the portal if you want to start over.[/color]")
        cutscene.finish()

func _process(delta: float) -> void:
    pass
