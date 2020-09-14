extends KinematicBody2D

onready var right_check = $RightCheck
onready var low_mid_check = $LowMidCheck
onready var high_mid_check = $HighMidCheck
onready var left_check = $LeftCheck
onready var left_lift_check = $LiftCheckLeft
onready var right_lift_check = $LiftCheckRight

onready var right_legs = $Right_Legs.get_children()
onready var left_legs = $Left_Legs.get_children()

export var speed_y = 40
var step_rate = 0.2 # Good speed for 0.2 is 30, that means step_rate = 150/speed
var time_since_last_step = 0
var cur_r_leg = 0
var cur_l_leg = 0
var use_right = false
var leg_dist = 45

var is_moving = false
var speed_limit = 100
var cur_speed = 0.0
var accel = 1.75

func _ready():
	leg_dist = $RightCheck.position.x / (right_legs.size() + left_legs.size())
	leg_dist -= leg_dist*0.15 # 15% buffers
	right_check.force_raycast_update()
	left_check.force_raycast_update()
	for i in range(6):
		step()

func _physics_process(delta):
	if Input.is_action_pressed("ui_right"):
		cur_speed = speed_limit if cur_speed >= speed_limit else cur_speed+accel
		var speed_x = cur_speed
		_move(delta, speed_x)
	elif Input.is_action_pressed("ui_left"):
		cur_speed = speed_limit if cur_speed >= speed_limit else cur_speed+accel
		var speed_x = -cur_speed
		_move(delta, speed_x)
	else:
		is_moving = false
		cur_speed = 0

func _move(delta, speed_x):
	is_moving = true
	step_rate = abs(leg_dist/speed_x)
	var move_vect = Vector2(speed_x, 0)
	
	if high_mid_check.is_colliding():
		move_vect.y = -speed_y
	elif !low_mid_check.is_colliding():
		move_vect.y = speed_y
	
	if left_lift_check.is_colliding() or right_lift_check.is_colliding():
		move_vect.y = -speed_y
	
	move_and_collide(move_vect * delta)

func _process(delta):
	if is_moving:
		time_since_last_step += delta
		if time_since_last_step >= step_rate:
			time_since_last_step = 0
			step()

func step():
	var leg = null
	var sensor = null
	if use_right:
		leg = right_legs[cur_r_leg]
		cur_r_leg += 1
		cur_r_leg %= right_legs.size()
		sensor = right_check
	else:
		leg = left_legs[cur_l_leg]
		cur_l_leg += 1
		cur_l_leg %= left_legs.size()
		sensor = left_check
	
	use_right = !use_right
	var target = sensor.get_collision_point()
	leg.step(target, step_rate)
