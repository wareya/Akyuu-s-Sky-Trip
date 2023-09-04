extends TextureRect

func _ready() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    Engine.get_main_loop().change_scene_to_file("res://Level1.tscn")
    
