extends ColorRect

func _ready() -> void:
	custom_minimum_size = get_parent_control().size / 3
