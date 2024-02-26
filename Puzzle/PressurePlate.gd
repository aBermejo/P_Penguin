extends StaticBody2D

class_name PressurePlate

@export var mechanism: StaticBody2D

var is_pressed: bool = false

func press_button():
	is_pressed = true
	mechanism.signal_received()

func unpress_button():
	is_pressed = false

func _on_press_detector_body_entered(body):
	if body.is_in_group("Player") or body.is_in_group("Penguins"):
		if is_pressed == false:
			press_button()

func _on_press_detector_body_exited(body):
	if body.is_in_group("Player") or body.is_in_group("Penguins"):
		if is_pressed == true:
			unpress_button()
