class_name Player extends CharacterBody3D

@export_category("Player")
@export_range(1, 35, 1) var speed: float = 10 # m/s
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1

var jumping: bool = false
var mouse_captured: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

var lantern_interact = false

@onready var camera: Camera3D = $Camera3D
@onready var player_arms: Node3D = $Player_Arms

# Zones
@onready var zone_1: Area3D = $"../Whisper Zones/Zone1"
@onready var zone_2: Area3D = $"../Whisper Zones/Zone2"
@onready var zone_3: Area3D = $"../Whisper Zones/Zone3"

# Lantern
@onready var lantern: MeshInstance3D = $"../cryptid_camping/Farol"



func _ready() -> void:
	capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()
	
	#if Input.is_action_just_pressed("exit"): get_tree().quit()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and lantern_interact and lantern.visible:
		lantern.queue_free()
		player_arms.visible = true

func _physics_process(delta: float) -> void:
	velocity = _walk(delta) + _gravity(delta) 
	move_and_slide()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(sens_mod: float = 1.0) -> void:
	
	camera.rotation.y -= look_dir.x * camera_sens * sens_mod
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)
	player_arms.rotation.y -= look_dir.x * camera_sens * sens_mod



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
	if body.name == "Player":
		print("Wants to sleep")
	pass # Replace with function body.

# dead animal
func _on_animal_body_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		print("Sees dead animal")
	pass # Replace with function body.


func _on_zone_1_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		print("Zone 1 passed, increased whispers")
		zone_1.queue_free()
	pass # Replace with function body.


func _on_zone_2_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		print("Zone 2 passed, increased whispers")
		zone_1.queue_free()
	pass # Replace with function body.


func _on_zone_3_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		print("Zone 3 passed, stopped whispers")
		zone_1.queue_free()
	pass # Replace with function body.

# handle lantern pickup
func _on_lantern_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		print("wants to pick up lantern")
		lantern_interact = true
		
	pass # Replace with function body.


func _on_lantern_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		lantern_interact = false
