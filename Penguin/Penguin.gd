extends CharacterBody2D

const SPEED = 300.0
const THROW_SPEED = 1000.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var player = get_tree().get_nodes_in_group("Player")[0]
@onready var animatedSprite := $AnimatedSprite2D
var grabbed: bool = false
var isBeingThrowed: bool = false
var throwTarget: Vector2 = Vector2(0,0)
@export var duration : float = 10
var duration_timer : float = 0
var posicionDeLaCola
var state
enum states{
	FOLLOWING,
	THROWED,
	GRABBED
}

func _ready():
	duration_timer = duration
	state = states.FOLLOWING
	posicionDeLaCola = player.penguins
	
func _process(delta):
	timers(delta)
	if posicionDeLaCola > player.penguins:
		posicionDeLaCola -= 1
	if duration_timer <= 0:
		delete()

func _physics_process(delta):
	match state:
		states.FOLLOWING:
			animatedSprite.play("idle")
			set_collision_shape_standing()
			var target = Vector2(player.position.x, player.position.y - player.altura_Centro_Inicial)
			velocity = position.direction_to(target) * SPEED
			if not is_on_floor():
				velocity.y += gravity * delta
			if position.distance_to(target) > (40 * posicionDeLaCola) and grabbed == false:
				move_and_slide()
			if velocity.x > 0:
				animatedSprite.flip_h = false
			elif velocity.x < 0:
				animatedSprite.flip_h = true
		states.THROWED:
			animatedSprite.play("throwed")
			set_collision_shape_lying()
			duration_timer = duration
			throw(throwTarget)
			move_and_slide()
			if velocity.x > 0:
				animatedSprite.flip_h = false
			elif velocity.x < 0:
				animatedSprite.flip_h = true
		states.GRABBED:
			animatedSprite.play("throwed")
			set_collision_shape_lying()
			duration_timer = duration
			position = player.get_node("Marker2D").global_position
			if player.face_direction > 0:
				animatedSprite.flip_h = false
			elif player.face_direction < 0:
				animatedSprite.flip_h = true
			

func _input(event):
	var bodies = $Area2D.get_overlapping_bodies()
	if player in bodies and Input.is_action_just_pressed("grab") and player.canGrab and state != states.GRABBED:
		state = states.GRABBED
		player.canGrab = false
	if Input.is_action_just_pressed("throw") and state == states.GRABBED:
		player.canGrab = true
		state = states.THROWED
		if player.face_direction == 1:
			throwTarget = Vector2(position.x + 250, position.y)
		else:
			throwTarget = Vector2(position.x - 250, position.y)		
		throw(throwTarget)

func throw(target):
	velocity = position.direction_to(target) * THROW_SPEED
	if position.distance_to(throwTarget) < 5:
		state = states.FOLLOWING

func delete():
	player.penguins -= 1
	queue_free()

func timers(delta: float) -> void:
	duration_timer -= delta

func set_collision_shape_standing():
	$CollisionShape2D.shape.extents = Vector2(8,19)
	$CollisionShape2D.position = Vector2(0,-1.5)
	$CollisionShape2D.scale = Vector2(0.5,0.5)
	$Area2D/CollisionShape2D.shape.extents = Vector2(8,19)
	$Area2D/CollisionShape2D.position = Vector2(0,-1.5)
	$Area2D/CollisionShape2D.scale = Vector2(0.5,0.5)

func set_collision_shape_lying():
	$CollisionShape2D.shape.extents = Vector2(23,9)
	$CollisionShape2D.position = Vector2(0.5,2.5)
	$CollisionShape2D.scale = Vector2(0.5,0.5)
	$Area2D/CollisionShape2D.shape.extents = Vector2(23,9)
	$Area2D/CollisionShape2D.position = Vector2(0.5,2.5)
	$Area2D/CollisionShape2D.scale = Vector2(0.5,0.5)
