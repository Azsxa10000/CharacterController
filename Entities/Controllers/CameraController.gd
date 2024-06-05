extends Node3D


@export_category("Camera_Data")
@export var camera_sensitivity := 0.003
@export var third_person_camera_position : Vector3
@export var auto_length : bool = false:
	set(val):
		auto_length = val
		update_spring_length()
@export var spring_arm_length : float:
	set(val):
		spring_arm_length = val
		update_spring_length()
@export var first_person_camera_height : float
@export var default_fov := 80.0
@export var fov_change_speed := 10.0
@export var camera: Camera3D
@export_range(0,2)
var camera_type := 0:
	# 0 == third person
	# 1 == first person
	# 2 == freecam
	set(val):

		if camera_type == 1 or camera_type == 2:
			camera_override.emit()
		camera_type = val # toggle freecam overriding movement keys
		connect("camera_override",func():print())

@export var camera_speed = 10

@export var spring_arm : SpringArm3D
func update_spring_length():
	if auto_length:
			spring_arm.spring_length =third_person_camera_position.length()
	else:
		spring_arm.spring_length = spring_arm_length

@onready var character_controller = $"../CharacterController"

## emit signal to prevent inputs from reaching anything other than freecam and ui
signal camera_override


## camera_rotation
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("toggle_camera_type") and DebugMode and character_controller:
			camera.position = third_person_camera_position
			if camera_type >= 2:
				camera_type = 0
			else: 
				camera_type += 1
			
		
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			basis = basis.rotated(basis.y,-event.relative.x * camera_sensitivity).orthonormalized()
			spring_arm.basis = spring_arm.basis.rotated(spring_arm.basis.x,-event.relative.y * camera_sensitivity).orthonormalized()
			spring_arm.rotation.x =  clampf(spring_arm.rotation.x,deg_to_rad(-80),deg_to_rad(80))
			print(spring_arm.transform.basis.x)



## fov change over time
func lerp_fov(delta:float, modifiers:Array,):	
	var targetted_fov = default_fov
	if not modifiers.is_empty():
		for f in modifiers:
			targetted_fov *= f
	camera.fov = lerp(camera.fov,targetted_fov,delta * fov_change_speed)


## camera types
#activated in _process() function,
func _third_person(delta:float):
	global_position = lerp(global_position, character_controller.global_position, delta * camera_speed)
	spring_arm.position = third_person_camera_position
	spring_arm.spring_length = lerp(spring_arm.spring_length,spring_arm_length,delta* camera_speed)
	#position = lerp(position,default_position_third_person_cam.rotated(Vector3(0,1,0),-rotation.y),delta * camera_speed  )
	#character_controller.look_at(raycast,co)
	
func _first_person(delta:float):
	spring_arm.global_position = character_controller.global_position + Vector3(0.,first_person_camera_height,0.)
	spring_arm.spring_length = lerp(spring_arm.spring_length,0.,delta* camera_speed)
func _free_cam(delta:float):
	spring_arm.spring_length = lerp(spring_arm.spring_length,0.,delta* camera_speed)
	var z = Input.get_axis("move_forward","move_backward")
	var x = Input.get_axis("move_left",'move_right')
	var y = Input.get_axis("crouch","jump")
	
	if Input.is_action_pressed("sprint"):
		global_position += Vector3(x,y,z).rotated(Vector3.UP,rotation.y) * camera_speed * delta * 2
	else:
		global_position += Vector3(x,y,z).rotated(Vector3.UP,rotation.y) * camera_speed * delta
	


func _ready():
	if not third_person_camera_position:
		third_person_camera_position = camera.position
	if not character_controller:
		camera_type = 2



## camera following player
func _physics_process(delta: float) -> void:
	match camera_type:
		0:
			_third_person(delta)
		1:
			_first_person(delta)
		2:
			_free_cam(delta)
