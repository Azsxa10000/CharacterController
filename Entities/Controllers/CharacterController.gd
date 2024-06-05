extends CharacterBody3D


@export_category("Movement")
@export var speed := 5
## max speed reached with lerp at delta * accleration
@export var acceleration := 10
@export var airspeed_modifier := 1.3
@export var crouch_speed_modifier := .7
@export var gravity_toggle := true ## likely unnecessary but might be convient
@export var sprint_speed := 1.3
@export var movement_enabled := true

@export_category("Jumping")
@export var jump_height : float
@export var time_to_peak: float 
@export var time_to_fall: float


var force_fall := false #activates when jump key released, resets on touching floor
@onready var jump_velocity = (2.0* jump_height) / time_to_peak
@onready var jump_gravity  = (-2.0* jump_height) / pow(time_to_peak,2.)
@onready var fall_gravity  = (-2.0* jump_height) / pow(time_to_fall,2.)

func jump():
	velocity.y = jump_velocity

func get_gravity() -> float:
	if force_fall:
		print('working')
		return fall_gravity
		
	else:
		return jump_gravity if velocity.y > 0 else fall_gravity


@export_category("Camera")
@export var sprint_fov_modifier := 1.1
@export var camera_controller : Node


@export_category("mesh")
@export var collision_shape: CollisionShape3D 
@export var mesh: MeshInstance3D
@export var crouch_height := .7
@export var target_height := 1.8
var height = target_height

func set_height() ->void:
	mesh.mesh.set_height(height)
	collision_shape.shape.set_height(height)

func toggle_movement() ->void :
	movement_enabled =  !movement_enabled
	



func _physics_process(delta: float) -> void:

	var sprint_modifier = 1.0
	var crouch_speed = 1.0
	var camera_basis = camera_controller.basis
	
	## player horizontal movement
	var input_direction = Input.get_vector("move_left","move_right","move_forward","move_backward") if movement_enabled else Vector2.ZERO
	var direction = (camera_basis * Vector3(input_direction.x,0,input_direction.y)).normalized()
	
	## Sprint / crouch code 
	# crouch
	if Input.is_action_pressed("crouch") and movement_enabled:
		height = lerp(height,crouch_height,delta*acceleration)
		crouch_speed = crouch_speed_modifier 
		
	else:
		height = lerp(height,target_height,delta*acceleration)
	
	# sprint
	# cannot sprint while crouching or moving backwards
	if Input.is_action_pressed("sprint") and direction and not input_direction.y > 0 and not Input.is_action_pressed("crouch") and movement_enabled:
		sprint_modifier = sprint_speed
		camera_controller.lerp_fov(delta, [sprint_fov_modifier])
	else: 
		camera_controller.lerp_fov(delta,[])
	
	
	## horizontal velocity code
	if is_on_floor():
		velocity.x = lerp(velocity.x, direction.x * speed * sprint_modifier * crouch_speed, delta * acceleration)
		velocity.z = lerp(velocity.z, direction.z * speed * sprint_modifier * crouch_speed, delta * acceleration)
	else: # faster in air
		velocity.x = lerp(velocity.x, direction.x * speed * airspeed_modifier * sprint_modifier * crouch_speed, delta * acceleration)
		velocity.z = lerp(velocity.z, direction.z * speed * airspeed_modifier * sprint_modifier * crouch_speed, delta * acceleration)


	## jump / falling logic
	if Input.is_action_just_pressed("jump") and is_on_floor() and movement_enabled:
		force_fall = false
		jump()
	if Input.is_action_just_released("jump"):
		force_fall = true
		print("relased")
	if is_on_floor():
		force_fall = false

	# gravity almost always active
	if gravity_toggle :
		velocity.y += get_gravity() * delta

	
	set_height()
	move_and_slide()		










