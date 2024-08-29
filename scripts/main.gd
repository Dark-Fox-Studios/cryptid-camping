extends Node3D
class_name Main

@onready var cut_scene_cam = $SubViewportContainer/SubViewport/CutsceneVan/CutSceneCam
@onready var cutscene_van = $SubViewportContainer/SubViewport/CutsceneVan
@onready var parked_van_clean = $SubViewportContainer/SubViewport/ParkedVan_Clean
@onready var player = $SubViewportContainer/SubViewport/Player
@onready var campsite = $SubViewportContainer/SubViewport/cryptid_camping/Campsite
@onready var ambient_noise = $SubViewportContainer/SubViewport/AudioStreamers/AmbientNoise
@onready var deer = $SubViewportContainer/SubViewport/deer_1
@onready var camp_boundary = $SubViewportContainer/SubViewport/Boundaries/CampBoundaries/Camp
@onready var dead_boundary = $SubViewportContainer/SubViewport/Boundaries/CampBoundaries/DeadBody
@onready var deadman = $SubViewportContainer/SubViewport/deadman
@onready var animal_body = $SubViewportContainer/SubViewport/AnimalBody
@onready var car_scratched = $SubViewportContainer/SubViewport/Car4Scratched
@onready var car_alarm = $SubViewportContainer/SubViewport/Car4Scratched/AudioStreamPlayer3D
@onready var scratched_van = $SubViewportContainer/SubViewport/Car4Scratched/ScratchedVan
@onready var scratched_van_col = $SubViewportContainer/SubViewport/Car4Scratched/ScratchedVan/ScratchedVan_col
@onready var cutscene_van_audio: AudioStreamPlayer3D = $SubViewportContainer/SubViewport/CutsceneVan/AudioStreamPlayer3D

@onready var left_light = $SubViewportContainer/SubViewport/Car4Scratched/SpotLight3D
@onready var left_bulb = $SubViewportContainer/SubViewport/Car4Scratched/SpotLight3D/MeshInstance3D
@onready var right_light = $SubViewportContainer/SubViewport/Car4Scratched/SpotLight3D2
@onready var right_bulb = $SubViewportContainer/SubViewport/Car4Scratched/SpotLight3D2/MeshInstance3D2

@onready var decal: Decal = $SubViewportContainer/SubViewport/cryptid_camping/Plane/Decal

@onready var lantern_wall_collision = $SubViewportContainer/SubViewport/Boundaries/CampBoundaries/LanternWall/NeedLantern/CollisionShape3D2
@onready var lantern = $SubViewportContainer/SubViewport/Lantern

@onready var crash_sound: AudioStreamPlayer3D = $SubViewportContainer/SubViewport/Car4Scratched/CrashSound

@onready var pause_menu: Control = $Control
@onready var deer_2: Node3D = $SubViewportContainer/SubViewport/deer_2

static var section = 0
static var sleepable = false
static var lantern_interactable = false
static var whispers = false
var rotation_speed: float = 3.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	section = 0
	whispers = false
	lantern_wall_collision.disabled = false
	decal.visible = false
	scratched_van_col.disabled = true
	player.visible = false
	car_scratched.visible = false
	deadman.visible = false
	camp_boundary.visible = true
	dead_boundary.visible = false
	cut_scene_cam.current = true
	ambient_noise.playing = true

var time_passed := 0.0
var interval := 1.0
var light_state = true


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("exit"): 
		pause_menu.show()
		get_tree().paused = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var direction_to_player = (player.global_position - deer.global_position).normalized()


	direction_to_player.y = 0

	var target_rotation = direction_to_player.angle_to(Vector3.LEFT)
	
	deer.rotation.y = lerp_angle(deer.rotation.y, -target_rotation, rotation_speed * delta)
	# getting out of van and making campsite appear
	if section == 1:
		section += 1
		
	# allowing for sleeping in tent. camp gets closed in
	if section == 2:
		
		sleepable = true
		
	# investigate scream
	if section == 3:
		
		decal.visible = true
		if camp_boundary:
			camp_boundary.queue_free()
			camp_boundary = null
		dead_boundary.visible = true
		sleepable = false
		lantern_interactable = true
		# show blood
		# reveal dead body
		deadman.visible = true
		# relocate deer
		deer.position = Vector3(0.018, -4.169, -11.657)
	if section == 4:
		parked_van_clean.visible = false
		car_scratched.visible = true
		deer.visible = false
		scratched_van_col.disabled = false
		time_passed += delta
		if time_passed >= interval:
			toggle_lights()
			time_passed = 0.0
	if section == 5:
		whispers = true
	

func toggle_lights():
	if light_state:
		left_light.visible = false
		right_light.visible = false
		light_state = false
	else:
		left_light.visible = true
		right_light.visible = true
		light_state = true

func _on_animal_body_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		animal_body.queue_free()
		player.dialogue.text = "They're dead... What the fuck is going on?"
		await get_tree().create_timer(3).timeout
		car_alarm.play()
		crash_sound.play()
		section += 1
		await get_tree().create_timer(1).timeout
		player.dialogue.text = "Is that my van??"
		await get_tree().create_timer(2).timeout
		player.dialogue.text = "* Investigate van *"
		await get_tree().create_timer(3).timeout
		player.dialogue.text = ""

func _on_animation_player_animation_finished(anim_name):
	print("intro finsihed")
	cut_scene_cam.current = false
	cutscene_van.visible = false
	parked_van_clean.visible = true
	player.visible = true
	
func _on_scratched_van_body_entered(body):
	if body.name == "Player":
		print("sees car")
		whispers = true
		car_alarm.stop()
		scratched_van.queue_free()
		section += 1
		dead_boundary.queue_free()


func _on_van_drive_player_finished() -> void:
	cutscene_van_audio.stop()
