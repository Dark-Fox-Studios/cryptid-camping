extends Control

var paused = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("exit"):
		if not paused:
			paused = true
			get_tree().paused = true
			show()
		else:
			paused = false
			hide()
			get_tree().paused = false
			

func _on_quit_button_up() -> void:
	Global.main_from_pause = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_resume_button_up() -> void:
	paused = false
	hide()
	get_tree().paused = false
