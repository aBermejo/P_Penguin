extends StaticBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var targetPosition: Vector2
var is_closed: bool = true

func _ready():
	if MetSys.register_storable_object(self): # Calls queue_free() if already opened.
		return
	animated_sprite.play("idle")

func signal_received():
	if is_closed == true:
		is_closed = false
		MetSys.store_object(self)
		animated_sprite.play("open")
		set_collision_layer_value(2, false)
		await animated_sprite.animation_finished
		queue_free()
