extends CharacterBody2D
class_name Enemy

@export var speed = 150.0
@export var jump_Velocity = -400.0
@export var sprite_Frames: SpriteFrames
@onready var animatedSprite := $AnimatedSprite2D
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var player = get_tree().get_nodes_in_group("Player")[0]
var dead := false
var face_direction := -1
@export var walk_buffer : float = 5
var walk_buffer_timer : float = 0
@export var health := 2
@export var damage := 1
var hor_direction := -1

var state
enum states{
	WALK,
	CHASE,
	ATTACK,
	DEATH
}

func _ready():
	if MetSys.register_storable_object(self): # Calls queue_free() if already opened.
		return
	animatedSprite.sprite_frames = sprite_Frames
	state = states.WALK


func _physics_process(delta):
	update_face_direction()
	match state:
		states.WALK:
			if not is_on_floor():
				velocity.y += gravity * delta
			patrullar()
			move_and_slide()
			timers(delta)
		states.DEATH:
			$CollisionShape2D.disabled = true
			$BodyArea/CollisionShape2D.disabled = true
			MetSys.store_object(self)
			queue_free()
			
func update_face_direction():
	if velocity.x > 0:
		hor_direction = 1
		apply_scale(Vector2(face_direction * hor_direction,1))		
	elif velocity.x < 0:
		hor_direction = -1
		apply_scale(Vector2(face_direction * hor_direction,1))
	face_direction = hor_direction

func patrullar():
	if walk_buffer_timer <= 0:
		hor_direction *= -1
		walk_buffer_timer = walk_buffer
	animatedSprite.play("walk")
	velocity.x = speed * hor_direction

func _on_area_2d_area_entered(area):
	if area == player.get_node("./AttackZone/Area2D"):
		health -= 1
	elif area.owner is Penguin and area.get_node("..").state == 1:#estado de lanzado
		health -= 1
	if health == 0:
		state = states.DEATH

func timers(delta: float) -> void:
	walk_buffer_timer -= delta
