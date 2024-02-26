extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var player = get_tree().get_nodes_in_group("Player")[0]

func _ready():
	await get_tree().create_timer(10).timeout
	queue_free()


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	var target = player.position
	velocity = position.direction_to(target) * SPEED
	# look_at(target)
	if position.distance_to(target) > 50:
		move_and_slide()
