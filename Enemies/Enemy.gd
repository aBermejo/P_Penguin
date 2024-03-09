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

var state
enum states{
	WALK,
	DEATH
}

func _ready():
	animatedSprite.sprite_frames = sprite_Frames
	state = states.WALK


func _physics_process(delta):
	match state:
		states.WALK:
			if not is_on_floor():
				velocity.y += gravity * delta
			patrullar()
			move_and_slide()
			timers(delta)
			change_direction()
		states.DEATH:
			$CollisionShape2D.disabled = true
			$Area2D/CollisionShape2D.disabled = true
			queue_free()
			
			
func patrullar():
	animatedSprite.play("walk")
	if face_direction > 0:
		animatedSprite.flip_h = true
	elif face_direction < 0:
		animatedSprite.flip_h = false
	velocity.x = speed * face_direction

func _on_area_2d_area_entered(area):
	if area == player.get_node("./AttackZone/Area2D"):
		health -= 1
		if health == 0:
			state = states.DEATH

func change_direction():
	if walk_buffer_timer <= 0:
		face_direction *= -1
		walk_buffer_timer = walk_buffer

func timers(delta: float) -> void:
	walk_buffer_timer -= delta
