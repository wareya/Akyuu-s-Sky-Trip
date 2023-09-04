extends Node3D


func _ready() -> void:
    CutsceneStarter.start_cutscene(IntroCutscene.new()._cutscene)

class IntroCutscene extends RefCounted:
    func _cutscene(cutscene : CutsceneInstance):
        var bg_texture = preload("res://art/splash.png")
        var bg_image = cutscene.add_background(bg_texture)
        await bg_image.fade_hide()
        
        await cutscene.set_text("Akyuu has been struck with a fever.")
        await cutscene.set_text("Show her the way to the end of these blocks so she can recover!")
        await cutscene.set_text("Don't worry about the spikes and plasma fields. She's too cute to die.")
        await cutscene.set_text("...I believe in you. You can make it through this.")
        await cutscene.set_text("[color=#88F]Click to toggle mouse lock to move the camera. Controllers are supported, too. Esc or start to open the options menu.[/color]")
        cutscene.finish()

func _process(delta: float) -> void:
    pass
