extends CharacterBody3D

@export var speed = 5
@export var jump_velocity = 4.5
@onready var camera:Camera3D = $Camera3D
@export var immersif=true

@export var look_sensitivity = 0.002
@export var look_sensitivity_joystick = 3.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity_y = 0

#----------------------------------------------------------------------------
# PROCESS PHYSIC
#----------------------------------------------------------------------------
func _physics_process(delta):
	# deplacement du personnage
	var horizontal_velocity = Input.get_vector("move_left","move_right","move_forward","move_backward") * speed
	velocity = horizontal_velocity.x * global_transform.basis.x + horizontal_velocity.y * global_transform.basis.z
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity_y = jump_velocity 
		else:
			velocity_y = 0
	else: 
		velocity_y -= gravity * delta
	
	velocity.y = velocity_y
	var collide = move_and_slide()
	
	_physics_processCol(delta,collide)
	#---------------------------------------------------------------
	# Gestion de la vue
	var view = Input.get_vector("view_left","view_right","view_up","view_down")
	rotate_y(-view.x * 0.01 * look_sensitivity_joystick)
	camera.rotate_x(-view.y * 0.01 * look_sensitivity_joystick)
	camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	#---------------------------------------------------------------
	# Gestion de la sortie du curseur exclusif
	if Input.is_action_just_pressed("ui_cancel"): 
			immersif=!immersif
	if immersif:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
	else: 
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	#---------------------------------------------------------------
	# use fullscreen or not
	if Input.is_action_just_pressed("fullscreen"):
		if(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	#---------------------------------------------------------------
	# screenshot
	if Input.is_action_just_pressed("capture"):
		var timeStamp = Time.get_datetime_string_from_system()
		timeStamp = timeStamp.replace(":","_")
		print(timeStamp)
		var image = get_viewport().get_texture().get_image()
		image.save_png("captures/screenshot_"+timeStamp+".png")
	
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
#---------------------------------------------------------------
# recuparation de la souris
func _input(event):
	if event is InputEventMouseMotion:
		if immersif:
			rotate_y(-event.relative.x * look_sensitivity)
			camera.rotate_x(-event.relative.y * look_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)


	# This represents the player's inertia.
var push_force = 4.0

func _physics_processCol(delta,collide):
	# after calling move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			if collide:
				print("collide")
			var imp:Vector3 = (-c.get_normal())
			imp = imp.normalized()
			imp=imp*push_force
			c.get_collider().apply_central_impulse(imp)
