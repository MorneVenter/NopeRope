extends RigidBody2D

var x_speed = 4.0
var jump_power = 250.0


func _physics_process(delta):
	if Input.is_action_pressed("ui_right") and abs(linear_velocity.x) <= 150.0:
		linear_velocity.x += x_speed
	elif Input.is_action_pressed("ui_left") and abs(linear_velocity.x) <= 150.0:
		linear_velocity.x -= x_speed
	
	if $RightCheck.is_colliding():
		_land(-90)
	elif $LeftCheck.is_colliding():
		_land(90)
	elif $DownCheck.is_colliding():
		_land(0)
	elif $UpCheck.is_colliding():
		_land(-180)

func jump(dir):
	var direction = Vector2(cos(deg2rad(dir)), sin(deg2rad(dir)))
	var movement_vect = direction * -jump_power
	linear_velocity += movement_vect
	
func _land(dir):
	EventSystem.emit_signal("airborne_landed", position.x, position.y, dir)


func _on_Timer_timeout():
	$RightCheck.enabled = true
	$LeftCheck.enabled = true
	$DownCheck.enabled = true
	$UpCheck.enabled = true
