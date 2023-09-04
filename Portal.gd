extends Area3D

@export_file("*.tscn", "*.scn") var target_stage = null

func _process(delta: float) -> void:
    $CSGCylinder3D.material.uv1_offset.x += delta
    $CSGCylinder3D.material.uv1_offset.z += delta

    for body in get_overlapping_bodies():
        if body.is_in_group("Player"):
            if target_stage != null and ResourceLoader.exists(target_stage):
                get_tree().change_scene_to_file(target_stage)
