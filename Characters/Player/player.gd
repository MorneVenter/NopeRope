extends Node2D

onready var player_body = preload("res://Characters/Player/player_body.tscn")
onready var player_airborne = preload("res://Characters/Player/player_airborne.tscn")
onready var player_camera = $PlayerCamera
onready var current_body = $Player_State/player_airborne

func _ready():
	EventSystem.connect("airborne_landed", self, "_landPlayerOnGround")
	EventSystem.connect("jump", self, "_jumpPlayer")

func _process(delta):
	player_camera.position = lerp(player_camera.position, current_body.position, 0.1)

func _landPlayerOnGround(x,y,dir):
	for n in $Player_State.get_children():
		n.queue_free()
	var new_body = player_body.instance()
	current_body = new_body
	new_body.position.x = x;
	new_body.position.y = y;
	new_body.rotation_degrees = dir
	$Player_State.add_child(new_body)
	new_body.init()

func _jumpPlayer(x,y, dir):
	for n in $Player_State.get_children():
		n.queue_free()
	var new_body = player_airborne.instance()
	current_body = new_body
	new_body.position.x = x;
	new_body.position.y = y;
	$Player_State.add_child(new_body)
	new_body.jump(dir)
