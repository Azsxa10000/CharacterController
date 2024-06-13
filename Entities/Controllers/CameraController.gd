extends Node3D

enum CameraTypes {THIRD_PERSON,FIRST_PERSON,FREECAM}


@export_category("Camera_Data")
@export var camera_sensitivity := 0.003
@export var camera_speed = 10 # used for movement, lerp, etc
@export var default_fov := 80.0

@export_category("Camera_Positioning")
@export var third_person_camera_position : Vector3:
	set(val):
		third_person_camera_position = val
		
		if third_person_camera_position.x >= 0:
			spring_arm_side.rotation_degrees.y = 90
			camera.rotation_degrees.y = -90
		else:
			spring_arm_side.rotation_degress.y = -90
			camera.rotation_degrees.y = 90
			
@export var auto_length : bool = true: # automatically handles spring arm length with third_person_camera_position
	set(val):
		auto_length = val
		update_spring_length()

func update_spring_length():
	if auto_length:
			spring_arm_out.spring_length = third_person_camera_position.z
			spring_arm_side.spring_length = third_person_camera_position.x		

@export var first_person_camera_height : float = third_person_camera_position.y
@export_range(0,2)
var camera_type := CameraTypes.THIRD_PERSON:
	# 0 == third person
	# 1 == first person
	# 2 == freecam
	set(val):
		if camera_type == CameraTypes.THIRD_PERSON:
			pass
		else:
			camera_override.emit()
		camera_type = val # toggle freecam overriding movement keys
		connect("camera_override",func():print())


@export_category("Nodes")
@export var camera: Camera3D
@export var spring_arm_out : SpringArm3D
@export var spring_arm_side : SpringArm3D



@onready var character_controller = $"../CharacterController"

## emit signal to prevent inputs from reaching anything other than freecam and ui
signal camera_override


## camera_rotation
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("toggle_camera_type") and DebugMode and character_controller:
			if camera_type >= 2:
				camera_type = CameraTypes.FIRST_PERSON
			else: 
				camera_type += 1
			
		
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			basis = basis.rotated(basis.y,-event.relative.x * camera_sensitivity).orthonormalized()
			spring_arm_out.basis = spring_arm_out.basis.rotated(spring_arm_out.basis.x,-event.relative.y * camera_sensitivity).orthonormalized()
			spring_arm_out.rotation.x =  clampf(spring_arm_out.rotation.x,deg_to_rad(-80),deg_to_rad(80))



## fov change over time
func lerp_fov(delta:float, modifiers:Array,):	
	var targetted_fov = default_fov
	if not modifiers.is_empty():
		for f in modifiers:
			targetted_fov *= f
	camera.fov = lerp(camera.fov,targetted_fov,delta * camera_speed)


## camera types
#activated in _process() function,
func _third_person(delta:float):
	global_position = lerp(global_position, character_controller.global_position, delta * camera_speed)
	spring_arm_out.spring_length = lerp(spring_arm_out.spring_length,third_person_camera_position.z,delta* camera_speed)
	spring_arm_out.position.y = third_person_camera_position.y
	spring_arm_side.spring_length = lerp(spring_arm_side.spring_length,abs(third_person_camera_position.x),delta* camera_speed)
	
func _first_person(delta:float):
	spring_arm_out.global_position = character_controller.global_position + Vector3(0.,first_person_camera_height,0.)
	# resetting springs
	if spring_arm_out.spring_length >= 0.0 and spring_arm_side.spring_length >= 0.0:
		spring_arm_out.spring_length = lerp(spring_arm_out.spring_length,0.,delta* camera_speed)
		spring_arm_side.spring_length = lerp(spring_arm_side.spring_length,0.,delta* camera_speed)
		
	
func _free_cam(delta:float):
	# resetting springs + resetting spring height
	if spring_arm_out.spring_length >= 0.0 and spring_arm_side.spring_length >= 0.0:
		spring_arm_out.spring_length = lerp(spring_arm_out.spring_length,0.,delta* camera_speed)
		spring_arm_side.spring_length = lerp(spring_arm_side.spring_length,0.,delta* camera_speed)
	if not spring_arm_out.position.is_zero_approx():
		spring_arm_out.position = lerp(spring_arm_out.position,Vector3.ZERO,delta*camera_speed)
		
		#basic camera movement 
	var z = Input.get_axis("move_forward","move_backward")
	var x = Input.get_axis("move_left",'move_right')
	var y = Input.get_axis("crouch","jump")
	
	if Input.is_action_pressed("sprint"):
		global_position += Vector3(x,y,z).rotated(Vector3.UP,rotation.y) * camera_speed * delta * 2
	else:
		global_position += Vector3(x,y,z).rotated(Vector3.UP,rotation.y) * camera_speed * delta
	


func _ready(): # IF NO CHARACTER CONTROLLER, CAMERA WILL BE LOCKED IN FREECAM MODE
	if not third_person_camera_position:
		third_person_camera_position = camera.position
	if not character_controller:
		camera_type = CameraTypes.FREECAM



## camera following player
func _physics_process(delta: float) -> void:
	match camera_type:
		CameraTypes.THIRD_PERSON:
			_third_person(delta)
		CameraTypes.FIRST_PERSON:
			_first_person(delta)
		CameraTypes.FREECAM:
			_free_cam(delta)
	print(spring_arm_side.global_rotation_degrees)
