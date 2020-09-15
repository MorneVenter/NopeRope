extends KinematicBody2D

onready var right_check = $RightCheck
onready var low_mid_check = $LowMidCheck
onready var high_mid_check = $HighMidCheck
onready var left_check = $LeftCheck
onready var left_lift_check = $LiftCheckLeft
onready var right_lift_check = $LiftCheckRight
onready var right_rotate_check = $RightRotateCheck
onready var left_rotate_check = $LeftRotateCheck
onready var left_wall_rotate_check = $LeftWallRotateCheck
onready var right_wall_rotate_check = $RightWallRotateCheck

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
var accel = 1.75
var speed_x = 100 #same as limit to init leg position

func _ready():
	leg_dist = $RightCheck.position.x / (right_legs.size())
	right_check.force_raycast_update()
	left_check.force_raycast_update()
	for i in range(6):
		step()

func _physics_process(delta):
	if Input.is_action_pressed("ui_right"):
		if speed_x < 0:
			speed_x = accel
		speed_x = speed_limit if speed_x >= speed_limit else speed_x+accel
		_move(delta, speed_x)
	elif Input.is_action_pressed("ui_left"):
		if speed_x > 0:
			speed_x = -accel
		speed_x = -speed_limit if speed_x <= -speed_limit else speed_x-accel
		_move(delta, speed_x)
	else:
		is_moving = false
		speed_x = 0

func _process(delta):
	_setBodyRotation()
	if is_moving:
		time_since_last_step += delta
		if time_since_last_step >= step_rate:
			time_since_last_step = 0
			step()

func _move(delta, speed_x):
	if speed_x == 0:
		speed_x = accel
	is_moving = true
	step_rate = abs(leg_dist/speed_x)
	var move_vect = Vector2(speed_x, 0)
	
	if high_mid_check.is_colliding():
		move_vect.y = -speed_y
	elif !low_mid_check.is_colliding():
		move_vect.y = speed_y
	
	if left_lift_check.is_colliding() or right_lift_check.is_colliding():
		move_vect.y = -speed_y
		
	move_and_collide(move_vect.rotated(deg2rad(rotation_degrees)) * delta)

			
func _setBodyRotation():
	if speed_x > 0:
		if !(right_rotate_check.is_colliding()):
			rotation_degrees += 5.0
		elif right_wall_rotate_check.is_colliding():
			rotation_degrees -= 5.0
		else:
			rotation_degrees = lerp(rotation_degrees, _computeNormAngle(), 0.1)
	elif speed_x < 0:
		if !(left_rotate_check.is_colliding()):
			rotation_degrees -= 5.0
		elif left_wall_rotate_check.is_colliding():
			rotation_degrees += 5.0
		else:
			rotation_degrees = lerp(rotation_degrees, _computeNormAngle(), 0.1)
	else:
		rotation_degrees = lerp(rotation_degrees, _computeNormAngle(), 0.1)

func _computeNormAngle():
	var plane = int(abs(rotation_degrees)/45)
	if plane == 7:
		plane = 0
	elif plane % 2 == 1:
		plane += 1
	var ans = plane*45.0
	if rotation_degrees < 0:
		ans = -ans		
	return ans
	
	
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
	var reach = rand_range(1.0,20.0)
	if speed_x < 0:
		reach = -reach
	var ang = _computeNormAngle()
	if ang == 0.0:
		target.x += reach
	elif ang == 180.0 or ang == -180.0:
		target.x -= reach
	elif ang == -90.0:
		target.y -= reach
	elif ang == 90.0:
		target.y += reach
	var rate = 0
	if speed_x == 0.0:
		rate = abs((leg_dist+reach)/0.1)
	else:
		rate = abs((leg_dist+reach)/speed_x)
	leg.step(target, rate)
