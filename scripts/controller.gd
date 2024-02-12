extends CharacterBody3D

# Player Nodes
@onready var head = $Neck/Head
@onready var standingBody = $Standing_Body
@onready var crouchingBody = $Crouching_Body
@onready var checkHead = $Check_Head
@onready var neck = $Neck
@onready var camera3d = $Neck/Head/Camera3D


# Speed vars
var currentSpeed = 5.0
@export var wankingSpeed = 5.0
@export var sprintingSpeed = 9.0
@export var crouchingSpeed = 3.0

# States
var walking = false
var sprinting = false
var crouching = false
var freeLook = false
var sliding = false

# Movemant vars
var crouchDepth = -0.5
const jumpVelocity = 4.5
var lerpSpeed = 10
var freeLookTilt = 8

# Input vars
var direction = Vector3.ZERO
@export var mouseSens = 0.25

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Lock mouse
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
# Rotate head with mouse
func _input(event):
	if event is InputEventMouseMotion:
		if freeLook:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouseSens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouseSens))
			head.rotate_x(deg_to_rad(-event.relative.y * mouseSens))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	#check if crouching (Crouching is more important to check then sprint)
	if Input.is_action_pressed("Crouch"):
		currentSpeed = crouchingSpeed
		head.position.y = lerp(head.position.y,crouchDepth, delta * lerpSpeed)
		#Change Collider so we can fit whole body
		standingBody.disabled = true
		crouchingBody.disabled = false
				
				
		walking = false
		sprinting = false
		crouching = true
		
	elif !checkHead.is_colliding():
		standingBody.disabled = false
		crouchingBody.disabled = true
		head.position.y = lerp(head.position.y, 0.0, delta * lerpSpeed)
		#sprint
		if Input.is_action_pressed("Sprint"):
			currentSpeed = sprintingSpeed
			walking = false
			sprinting = true
			crouching = false
		else:
			currentSpeed = wankingSpeed
			walking = true
			sprinting = false
			crouching = false
			
	#Handle free look
	if Input.is_action_pressed("Free_Look"):
		freeLook = true
		camera3d.rotation.z = deg_to_rad(neck.rotation.y * freeLookTilt)
	else:
		freeLook = false
		neck.rotation.y = lerp(neck.rotation.y,0.0, delta * lerpSpeed)
		camera3d.rotation.z = lerp(camera3d.rotation.z,0.0, delta * lerpSpeed)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jumpVelocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerpSpeed)
	
	
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()
