class_name Player extends CharacterBody3D

@export_category("Player")
@export_range(1, 35, 1) var walk_speed: float = 10 # m/s
@export_range(1, 35, 1) var sprint_speed: float = 10 # m/s
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1

var jumping: bool = false
var mouse_captured: bool = false

var speed: float = walk_speed
var stamina: float = 3
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

var lantern_interact = false
var sleep = false
var whispers_started = false

var camp_setup_trigger = false
@onready var camp_setup: Area3D = $"../cryptid_camping/Campsite/bonfire/CampSetup"


@onready var effect_anim = $EffectAnim

@onready var camera: Camera3D = $Camera3D
@onready var player_arms: Node3D = $Player_Arms

# Zones
@onready var zone_1: Area3D = $"../Whisper Zones/Zone1"
@onready var zone_2: Area3D = $"../Whisper Zones/Zone2"
@onready var zone_3: Area3D = $"../Whisper Zones/Zone3"

# Dead person audio
@onready var dead_audio = $"../AnimalBody/AudioStreamPlayer3D"

# Whispers audio
@onready var whispers = $Whispers

# Lantern
@onready var lantern: MeshInstance3D = $"../cryptid_camping/Campsite/Farol"

@onready var label = $CanvasLayer/InteractLabel
@onready var dialogue = $CanvasLayer/DialogueLabel
@onready var color_rect = $CanvasLayer/ColorRect
@onready var animation_player = $AnimationPlayer
@onready var death_animation = $"Taken Hostage - Villain/AnimationPlayer"
@onready var demon = $"Taken Hostage - Villain"
@onready var animal_body = $"../AnimalBody"
@onready var death = $Death
@onready var ambient_noise = $"../AudioStreamers/AmbientNoise"
@onready var footstep1 = $Footstep1
@onready var footstep2 = $Footstep2
@onready var campsite: Node3D = $"../cryptid_camping/Campsite"
@onready var sun: DirectionalLight3D = $"../DirectionalLight3D"
@onready var run: AudioStreamPlayer3D = $Run
@onready var chase_music: AudioStreamPlayer3D = $ChaseMusic
@onready var lantern_wall = $"../Boundaries/CampBoundaries/LanternWall"
@onready var lantern_global = $"../Lantern"
@onready var lantern_pos = $Lantern


var whisper_bus_index: int
var ambient_bus_index: int

var cutscene_done = false

var step_toggle = false

var elapsed_time := 0.0
var target_time = 0.7

func _ready() -> void:
	player_arms.visible = false
	player_arms.position = Vector3(0, 0.356, 0)
	set_process_input(false)
	whisper_bus_index = AudioServer.get_bus_index(whispers.bus)
	ambient_bus_index = AudioServer.get_bus_index(ambient_noise.bus)
	
	speed = walk_speed
	color_rect.visible = false
	capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and cutscene_done:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()
	
	#if Input.is_action_just_pressed("exit"): get_tree().quit()

func _process(delta: float) -> void:
	if cutscene_done:
		if Input.is_action_pressed("ui_accept"):
			final_death()
		
		if Input.is_action_just_released("sprint"):
			speed = walk_speed
		
		stamina += delta * 0.5 if stamina < 3 else 0
		
		if stamina <= 0:
			speed = walk_speed
			await get_tree().create_timer(3).timeout
		else:
			if Input.is_action_pressed("sprint"):
				speed = sprint_speed
				stamina -= delta 
			
		if not whispers_started and Main.whispers:
			whispers.play()
			whispers_started = true
			
		if camp_setup_trigger and Input.is_action_just_pressed("interact"):
			camp_setup.queue_free()
			effect_anim.play("camp_setup")
			await get_tree().create_timer(2).timeout
			label.text = ""
			for child in campsite.get_children():
				child.visible = true
			await get_tree().create_timer(2).timeout
			camp_setup_trigger = false
			Main.section += 1
			dialogue.text = "Time for bed, I'm tired..."
			await get_tree().create_timer(2).timeout
			dialogue.text = ""
			
			
		if Input.is_action_just_pressed("interact") and lantern_interact and lantern.visible:
			lantern.queue_free()
			lantern_wall.queue_free()
			player_arms.visible = true
		
		if Input.is_action_just_pressed("interact") and Main.sleepable and sleep:
			set_process_input(false)
			color_rect.visible = true
			Main.section += 1
			Main.sleepable = false
			label.text = ""
			effect_anim.play("sleep")
			sun.light_energy = 0.1
			await get_tree().create_timer(5).timeout
			dead_audio.play()
			await get_tree().create_timer(2).timeout
			effect_anim.play("wake")
			await get_tree().create_timer(0.2).timeout
			color_rect.visible = false
			dialogue.text = "What the hell?"
			set_process_input(true)
			await get_tree().create_timer(2).timeout
			dialogue.text = ""
			await get_tree().create_timer(0.2).timeout
			dialogue.text = "* Go investigate the source of the scream. You should probably grab a lantern *"
			await get_tree().create_timer(4).timeout
			dialogue.text = ""

		
func _physics_process(delta: float) -> void:
	if cutscene_done:
		velocity = _walk(delta) + _gravity(delta) 
		if velocity != Vector3.ZERO:
			
			elapsed_time += delta
			if elapsed_time >= target_time:
				step_toggle = !step_toggle
				if step_toggle:
					footstep1.play()
				else:
					footstep2.play()
				elapsed_time = 0
			
		move_and_slide()

func kill():
	set_process_input(false)
	death_animation.play("mixamo_com")
	await get_tree().create_timer(1).timeout
	death.play()
	await get_tree().create_timer(1.2).timeout
	effect_anim.play("death")

func final_death():
	lantern_global.global_position = lantern_pos.global_position
	lantern_global.global_rotation = lantern_pos.global_rotation
	lantern_global.visible = true
	lantern_global.gravity_scale = 1
	animation_player.play("final_death")
	

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(sens_mod: float = 1.0) -> void:
	rotation.y -= look_dir.x * camera_sens * sens_mod
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)

func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

# tent for sleeping
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player" and Main.sleepable:
		label.text = "Sleep"
		sleep = true
		print("Wants to sleep")
	pass # Replace with function body.

# tent move away
func _on_area_3d_body_exited(body):
	if body.name == "Player":
		label.text = ""


func _on_zone_1_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		var current_w_db = AudioServer.get_bus_volume_db(whisper_bus_index)
		AudioServer.set_bus_volume_db(whisper_bus_index, current_w_db + 7.0)
		var current_a_db = AudioServer.get_bus_volume_db(ambient_bus_index)
		AudioServer.set_bus_volume_db(ambient_bus_index, current_a_db + 5.0)
		print("Zone 1 passed, increased whispers")
		zone_1.queue_free()

func _on_zone_2_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		var current_w_db = AudioServer.get_bus_volume_db(whisper_bus_index)
		AudioServer.set_bus_volume_db(whisper_bus_index, current_w_db + 7.0)
		var current_a_db = AudioServer.get_bus_volume_db(ambient_bus_index)
		AudioServer.set_bus_volume_db(ambient_bus_index, current_a_db + 5.0)
		print("Zone 2 passed, increased whispers")
		zone_2.queue_free()


func _on_zone_3_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		whispers.stop()
		ambient_noise.stop()
		print("Zone 3 passed, stopped whispers")
		zone_3.queue_free()
		await get_tree().create_timer(5).timeout
		run.play()
		await get_tree().create_timer(1).timeout
		chase_music.play()
		await get_tree().create_timer(10).timeout
		final_death()
		
		
# handle lantern pickup
func _on_lantern_body_entered(body: Node3D) -> void:
	if body.name == "Player" and Main.lantern_interactable:
		print("wants to pick up lantern")
		lantern_interact = true
		label.text = "Pickup"



func _on_lantern_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		lantern_interact = false
		label.text = ""


func _on_cutscene_animation_finished(anim_name):
	cutscene_done = true
	set_process_input(true)
	dialogue.text = "I really should set up camp... it's late"
	await get_tree().create_timer(3).timeout
	dialogue.text = ""


func _on_scratched_van_body_entered(body):
	if body.name == "Player":
		dialogue.text = "What the fuck is going on!?"
		await get_tree().create_timer(2).timeout
		dialogue.text = "There is a ranger tower up the road, I need to get help!"
		await get_tree().create_timer(3).timeout
		dialogue.text = ""
	


func _on_camp_setup_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		label.text = "Setup camp"
		camp_setup_trigger = true
		


func _on_camp_setup_body_exited(body: Node3D) -> void:
	label.text = ""


func _on_death_boundary_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		kill()
		await get_tree().create_timer(.7).timeout
		chase_music.stop()


func _on_final_death_animation_finished(anim_name):
	Global.credits_from_final_death = true
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_effect_anim_animation_finished(anim_name):
	if anim_name == "death":
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_need_lantern_body_entered(body):
	if body.name == "Player":
		dialogue.text = "It's dark, I should really grab my lantern..."


func _on_need_lantern_body_exited(body):
	if body.name == "Player":
		dialogue.text = ""
