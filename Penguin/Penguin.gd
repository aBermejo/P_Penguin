extends CharacterBody2D

const SPEED = 300.0
const THROW_SPEED = 1000.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var player = get_tree().get_nodes_in_group("Player")[0]
var grabbed: bool = false
var isBeingThrowed: bool = false
var throwTarget: Vector2 = Vector2(0,0)


func _ready():
	await get_tree().create_timer(20).timeout
	queue_free()
	player.penguins -= 1
	


func _physics_process(delta):
	# Add the gravity.
	if isBeingThrowed == false:
		if not is_on_floor():
			velocity.y += gravity * delta
		var target = player.position
		velocity = position.direction_to(target) * SPEED
		if position.distance_to(target) > 50 and grabbed == false:
			move_and_slide()
	else:
		throw(throwTarget)
		move_and_slide()
	
	if grabbed == true:
		position = player.get_node("Marker2D").global_position

func _input(event):
	var bodies = $Area2D.get_overlapping_bodies()
	if player in bodies and Input.is_action_just_pressed("grab") and player.canGrab and grabbed == false:
		grabbed = true
		player.canGrab = false
	if Input.is_action_just_pressed("throw") and grabbed == true:
		grabbed = false
		player.canGrab = true
		isBeingThrowed = true
		if player.face_direction == 1:
			throwTarget = Vector2(position.x + 250, position.y)
		else:
			throwTarget = Vector2(position.x - 250, position.y)		
		throw(throwTarget)

func throw(target):
	velocity = position.direction_to(target) * THROW_SPEED
	if position.distance_to(throwTarget) < 5:
		isBeingThrowed = false
	
