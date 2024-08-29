extends Control

@onready var container = $Container
@onready var credits = $Credits

@onready var color_rect = $ColorRect
@onready var slash_screen = $SlashScreen

@onready var animation_player = $AnimationPlayer
@onready var music = $AudioStreamPlayer2D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Global.credits_from_final_death:
		color_rect.visible = false
		slash_screen.visible = false
		_on_credits_button_up()
		music.play()
	elif not Global.main_from_death and not Global.credits_from_final_death and not Global.main_from_pause:
		animation_player.play("splash")
	elif Global.main_from_pause:
		slash_screen.visible = false
		Global.main_from_pause = false
		music.play()
	else:
		Global.main_from_death = false
		music.play()

func _on_start_button_up():
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_credits_button_up():
	container.visible = false
	credits.visible = true
	Global.credits_from_final_death = false


func _on_exit_button_up():
	get_tree().quit()


func _on_back_button_up():
	credits.visible = false
	container.visible = true
	


func _on_animation_player_animation_finished(anim_name):
	color_rect.visible = false
	slash_screen.visible = false
	music.play()
