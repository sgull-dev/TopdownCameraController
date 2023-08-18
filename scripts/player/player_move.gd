extends CharacterBody3D

const fall_gravity = 9.8


#export variables for movement changes
@export var running_movement_speed := 400
@export var max_step_height : float
@export var dash_duration : float = 0.2
@export var dash_force_multiplier : float = 2.0
#dash variables
@export var dash_power_gain : float = 25.0
var dash_power : float = 100
var is_dashing := false
var speed_mult : float = 1.0
#identifier for collisions
var is_player = true

@onready var ground = $GroundCast
@onready var dash_timer = $JumpTimer
@onready var stepper = $CSGCombiner3D/StepCast
@onready var model = $CSGCombiner3D
@onready var attack_manager = $AttackManager

func _physics_process(delta):
	#variables to track movement state
	dash_power += delta *dash_power_gain
	dash_power = clamp(dash_power,0, 100)
	var dashing = Input.is_action_just_pressed("dash") and dash_power >= 50
	#input into a vector
	var input_dir = Vector3(0,0,0)
	input_dir.x += Input.get_axis("move_l","move_r")
	input_dir.z += Input.get_axis("move_f","move_b")
	#rotate input vector based on camera rotation
	input_dir = input_dir.rotated(Vector3.UP, GameData.cam_rotation)
	#apply gravity
#	if is_jumping and Input.is_action_just_released("jump"):
#		velocity.y = velocity.y /2
	if ground.is_colliding() and !is_dashing:
		#print("on ground, stopping y-velocity")
		velocity.y = 0.0
	
	velocity.y -= fall_gravity * delta
	#handle dashing
	if dashing:
		dash()
		#velocity.y = -jump_velocity
	#handle steps
	if input_dir.length() > 0.01:
		check_for_steps(input_dir)
	
	#apply movement in direction of input
	var move_dir = input_dir.normalized() * get_move_speed(input_dir.length())  * delta * speed_mult
	velocity.x = lerp(velocity.x,move_dir.x, 0.2)
	velocity.z = lerp(velocity.z,move_dir.z, 0.2)
	#NOTE: this is if I want dash to shoot an impulse like force right away
#	if dashing:
#		var dash_dir = get_dash_direction(input_dir) * 320 *  0.05
#		velocity.x += dash_dir.x
#		velocity.z += dash_dir.z
	move_and_slide()
	
	$CSGCombiner3D.rotate_to_movement(input_dir.normalized())
	#send  data
	GameData.player_position = global_position
	GameData.player_move_direction = input_dir.normalized()

func dash():
	dash_power -= 50.0
	is_dashing = true
	speed_mult = dash_force_multiplier
	dash_timer.start(dash_duration)
	await dash_timer.timeout
	
	speed_mult = 1.0
	#dash_timer.start(dash_duration)
	#await dash_timer.timeout 
	is_dashing = false

#system to allow char to step up on small ledges
func check_for_steps(input_dir):
	if is_on_wall():
		var step_height = get_step_height()
		
		if step_height > 0:
			if step_height < max_step_height:
				var move_direction = input_dir
				var angle_to_wall = (move_direction * -1).angle_to(get_wall_normal())
				if rad_to_deg(angle_to_wall) < 70 and !stepper.is_colliding():
					step_up(step_height)
				else:
					#print_debug("Is the stepper colliding:"+ str(stepper.is_colliding()))
					pass

func get_step_height():
	var step : float = 0.0
	var i = 0
	while i < get_slide_collision_count():
		var collision_data = get_slide_collision(i)
		if collision_data.get_position().y > global_position.y:
			var ib = 0 
			while ib < collision_data.get_collision_count():
				if step < collision_data.get_position(ib).y - global_position.y:
					step = collision_data.get_position(ib).y - global_position.y
				ib += 1
		i +=1
	return step

func step_up(height):
	#print_debug("Stepping up step.")
	position.y += height * 1.01

#move speed varying on input length
func get_move_speed(input_length):
	var speed :float
	if input_length >= 0.75:
		speed = running_movement_speed
	else:
		speed =  (running_movement_speed+50) * input_length +50
	
	if attack_manager.is_casting_spell:
		speed = speed *0.5
	return speed

func get_dash_direction(input_dir):
	if input_dir.length()>0.1:
		return input_dir.normalized()
	else:
		return model.look_dir.normalized()
