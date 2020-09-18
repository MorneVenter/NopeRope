extends KinematicBody2D

onready var right_check = $CollisionShape/RightCheck
onready var low_mid_check = $CollisionShape/LowMidCheck
onready var high_mid_check = $CollisionShape/HighMidCheck
onready var left_check = $CollisionShape/LeftCheck
onready var left_lift_check = $CollisionShape/LiftCheckLeft
onready var right_lift_check = $CollisionShape/LiftCheckRight
onready var right_rotate_check = $CollisionShape/RightRotateCheck
onready var left_rotate_check = $CollisionShape/LeftRotateCheck
onready var left_wall_rotate_check = $CollisionShape/LeftWallRotateCheck
onready var right_wall_rotate_check = $CollisionShape/RightWallRotateCheck

onready var right_legs = $Right_Legs.get_children()
onready var left_legs = $Left_Legs.get_children()

var speed_y = 40
var step_rate = 0.02
var time_since_last_step = 0
var cur_r_leg = 0
var cur_l_leg = 0
var use_right = false
var leg_dist = 45

var is_moving = false
var speed_limit = 150
var accel = 2.2
var speed_x = 150 #same as limit to init leg position

var is_in_transition = false
var degrees_to_transition = 0.0
var position_to_transition = Vector2()
var x_dir = 1


func init():
	leg_dist = $CollisionShape/RightCheck.position.x / (right_legs.size())
	right_check.force_raycast_update()
	left_check.force_raycast_update()
	for i in range(6):
		step()

func _physics_process(delta):
	if not(is_in_transition):
		_moveBody(delta)
	elif is_in_transition:
		transition_process()

func _process(delta):
	if is_moving:
		time_since_last_step += delta
		if time_since_last_step >= step_rate:
			time_since_last_step = 0
			step()

	if not(is_in_transition):
		_setBodyRotation()
		if Input.is_action_just_pressed("player_jump"):
			_jump()

func transition_process():
	if !(round(rotation_degrees) == degrees_to_transition and round(position.x) == round(position_to_transition.x)  and round(position.y) == round(position_to_transition.y)):
		position = lerp(position, position_to_transition, 0.25)
		rotation_degrees = lerp(rotation_degrees, degrees_to_transition, 0.25)
	else:
		rotation_degrees = round(degrees_to_transition)
		position = position_to_transition
		speed_x = speed_limit/2.0
		for i in range(6):
			step()
		is_in_transition = false

func _setBodyRotation():
	if is_moving:
		if !(right_rotate_check.is_colliding()):
			#rotate +90 and move down
			is_in_transition = true
			degrees_to_transition = round(rotation_degrees + 90.0)
			var xcor = 1.0
			var ycor = 1.0
			if rotation_degrees == -90.0:
				ycor = -1.0
			elif rotation_degrees == 90.0:
				xcor = -1.0
			elif abs(round(rotation_degrees)) == 180.0:
				xcor = -1.0
				ycor = -1.0
			position_to_transition = Vector2(position.x + (40.0*xcor), position.y + (40.0*ycor))
		elif !(left_rotate_check.is_colliding()):
			#rotate -90 and move down
			is_in_transition = true
			degrees_to_transition = round(rotation_degrees - 90.0)
			var xcor = 1.0
			var ycor = 1.0
			if rotation_degrees == -90.0:
				xcor = -1.0
			elif rotation_degrees == 90.0:
				ycor = -1.0
			elif abs(round(rotation_degrees)) == 180.0:
				xcor = -1.0
				ycor = -1.0
			position_to_transition = Vector2(position.x - (40.0*xcor), position.y + (40.0*ycor))
		elif right_wall_rotate_check.is_colliding():
			#rotate -90 and move up
			is_in_transition = true
			degrees_to_transition = round(rotation_degrees - 90.0)
			var xcor = 1.0
			var ycor = 1.0
			if rotation_degrees == -90.0:
				xcor = -1.0
			elif rotation_degrees == 90.0:
				ycor = -1.0
			elif abs(round(rotation_degrees)) == 180.0:
				xcor = -1.0
				ycor = -1.0
			position_to_transition = Vector2(position.x + (10.0*xcor), position.y - (10.0*ycor))
		elif left_wall_rotate_check.is_colliding():
			#rotate +90 and move up
			is_in_transition = true
			degrees_to_transition = round(rotation_degrees + 90.0)
			var xcor = 1.0
			var ycor = 1.0
			if rotation_degrees == -90.0:
				ycor = -1.0
			elif rotation_degrees == 90.0:
				xcor = -1.0
			elif abs(round(rotation_degrees)) == 180.0:
				xcor = -1.0
				ycor = -1.0
			position_to_transition = Vector2(position.x - (10.0*xcor), position.y - (10.0*ycor))


func _computeNormAngle():
	var plane = int(abs(rotation_degrees)/45.0)
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
	var reach = rand_range(1.0,20.0) * x_dir
	var ang = _computeNormAngle()
	if ang == 0.0:
		target.x += reach
	if ang == 180.0 or ang == -180.0:
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
	var upsidedown = false
	if round(abs(rotation_degrees)) == 180.0:
		upsidedown = true
	leg.step(target, rate, upsidedown)

func _jump():
	EventSystem.emit_signal("jump", position.x, position.y, _computeNormAngle()+90.0)
	
func _moveBody(delta):
	
	var moveVect = Vector2();
	if Input.is_action_pressed("player_right"):
		moveVect.x += 1.0
	elif Input.is_action_pressed("player_left"):
		moveVect.x -= 1.0
	elif Input.is_action_pressed("player_up"):
		moveVect.y -= 1.0
	elif Input.is_action_pressed("player_down"):
		moveVect.y += 1.0
	var norm_angle = _computeNormAngle()
	moveVect = moveVect.rotated(deg2rad(norm_angle))
	if norm_angle == 90.0 or norm_angle == -90.0:
		moveVect *= -1
	
	if moveVect != Vector2.ZERO:
		is_moving = true
		speed_x = speed_limit if abs(speed_x) >= speed_limit else abs(speed_x)+accel
		step_rate = abs(leg_dist/speed_x)
		x_dir = moveVect.x
		moveVect *= speed_x
		var origin = high_mid_check.global_transform.origin
		var collision_point = high_mid_check.get_collision_point()
		var distance = origin.distance_to(collision_point)
		if distance >= 22.0 and moveVect.y < 0.0:
			moveVect.y = 0.0
		if !high_mid_check.is_colliding():
			moveVect.y = 5.0*speed_y
		if left_lift_check.is_colliding() or right_lift_check.is_colliding():
			moveVect.y = -speed_y*5.0
		
		moveVect = moveVect.rotated(deg2rad(norm_angle))
		move_and_collide(moveVect  * delta)
	else:
		if !high_mid_check.is_colliding():
			moveVect.y = 5.0*speed_y
			move_and_collide(moveVect.rotated(deg2rad(norm_angle))  * delta)
		is_moving = false
		speed_x = 0
