extends StaticBody2D

@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D

var neededBodies: int = 3
var actualBodies: int = 0
var isBroken: bool = false

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player") or body.is_in_group("Penguins"):
		actualBodies += 1
		#ejecutar animación correspondiente
		if actualBodies == neededBodies and !isBroken:
			breakFloor()

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player") or body.is_in_group("Penguins"):
		actualBodies -= 1

func breakFloor():
	isBroken = true
	set_collision_layer_value(2, false)
	animatedSprite.hide()
