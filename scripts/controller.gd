extends CharacterBody3D

# Player Nodes
@onready var head = $Neck/Head
@onready var standingBody = $Standing_Body
@onready var crouchingBody = $Crouching_Body
@onready var checkHead = $Check_Head
@onready var neck = $Neck
@onready var camer3d = $Neck/Head/Eyes/Camera3D
@onready var eyes = $Neck/Head/Eyes
@onready var animationPlayer = $Neck/Head/Eyes/AnimationPlayer


# Speed vars
var currentSpeed = 5.0
@export var walkingSpeed = 5.0
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

# Slide Vars
var slideTimer = 0.0
var slideTimerMax = 1.0
var slideVector = Vector2.ZERO
var slideSpeed = 10.0

# Head bobbing var
const sprintingBobSpeed = 22.0
const walkingBobSpeed = 14.0
const crouchingBobSpeed = 10.0

const sprintBobInt = 0.2
const walkingBobInt = 0.1
const crouchingBobInt = 0.05

var bobVector = Vector2.ZERO
var bobIndex = 0.0
var currentBobInt = 0.0

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
	
	# Getting movement input
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	# Check if crouching (Crouching is more important to check then sprint)
	if Input.is_action_pressed("Crouch") || sliding:
		currentSpeed = lerp(currentSpeed, crouchingSpeed, delta * lerpSpeed)
		head.position.y = lerp(head.position.y,crouchDepth, delta * lerpSpeed)
		#Change Collider so we can fit whole body
		standingBody.disabled = true
		crouchingBody.disabled = false
		
		# Slide begin logic
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slideTimer = slideTimerMax
			slideVector = input_dir
			freeLook = true
			print("Start Slide")
			
		
		walking = false
		sprinting = false
		crouching = true
		
	elif !checkHead.is_colliding():
		standingBody.disabled = false
		crouchingBody.disabled = true
		head.position.y = lerp(head.position.y, 0.0, delta * lerpSpeed)
		#sprint
		if Input.is_action_pressed("Sprint"):
			currentSpeed = lerp(currentSpeed, sprintingSpeed, delta * lerpSpeed)
			walking = false
			sprinting = true
			crouching = false
		else:
			currentSpeed = lerp(currentSpeed, walkingSpeed, delta * lerpSpeed)
			walking = true
			sprinting = false
			crouching = false
			
	# Handle free look
	if Input.is_action_pressed("Free_Look") || sliding:
		freeLook = true
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z, deg_to_rad(7.0), delta * lerpSpeed)
		else:
			eyes.rotation.z = deg_to_rad(neck.rotation.y * freeLookTilt)
	else:
		freeLook = false
		neck.rotation.y = lerp(neck.rotation.y,0.0, delta * lerpSpeed)
		eyes.rotation.z = lerp(eyes.rotation.z,0.0, delta * lerpSpeed)
	
	# Handle sliding
	if sliding:
		slideTimer -= delta
		if slideTimer <= 0:
			sliding = false
			freeLook = false
			print("Sliding done!")
			
	# Handle Bobbing
	if sprinting:
		currentBobInt = sprintBobInt
		bobIndex += sprintingBobSpeed * delta
	elif walking:
		currentBobInt = walkingBobInt
		bobIndex += walkingBobSpeed * delta
	elif crouching:
		currentBobInt = crouchingBobInt
		bobIndex += crouchingBobSpeed * delta
	
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		bobVector.y = sin(bobIndex)
		bobVector.x = sin(bobIndex/2)+0.5
		eyes.position.y = lerp(eyes.position.y, bobVector.y * (currentBobInt / 2.0), delta * lerpSpeed )
		eyes.position.x = lerp(eyes.position.x, bobVector.x * currentBobInt, delta * lerpSpeed )
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * lerpSpeed )
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * lerpSpeed )
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jumpVelocity
		sliding = false
		animationPlayer.play("jump")

	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerpSpeed)
	
	if sliding:
		direction = (transform.basis * Vector3(slideVector.x, 0.0, slideVector.y)).normalized()
		currentSpeed = (slideTimer+0.1) * slideSpeed
	
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()
