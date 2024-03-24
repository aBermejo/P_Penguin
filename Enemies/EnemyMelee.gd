extends Enemy

@onready var attack_Zone_Collision := $AttackZone/AttackArea/CollisionShape2D
 


func _ready():
	if MetSys.register_storable_object(self): # Calls queue_free() if already opened.
		return
	attack_Zone_Collision.disabled = true
	animatedSprite.sprite_frames = sprite_Frames
	state = states.WALK

func _process(delta):
	if state == states.ATTACK:
		attack_control()
	
func _physics_process(delta):
	update_face_direction()
	match state:
		states.WALK:
			modulate = Color(255,255,255)
			if not is_on_floor():
				velocity.y += gravity * delta
			patrullar()
			move_and_slide()
			timers(delta)
		states.CHASE:
			modulate = Color(255,255,255)
			var target = Vector2(player.position.x, position.y)
			velocity = position.direction_to(target) * speed
			if position.distance_to(target) > 60:
				move_and_slide()
			else:
				attack()
		states.ATTACK:
			modulate = Color(255,0,0)
		states.DEATH:
			$CollisionShape2D.disabled = true
			$BodyArea/CollisionShape2D.disabled = true
			MetSys.store_object(self)
			queue_free()


func _on_detection_area_area_entered(area):
	if area.owner is Player and state != states.ATTACK:
		state = states.CHASE

func attack():
	state = states.ATTACK
	attack_Zone_Collision.disabled = false
	animatedSprite.play("attack")

func attack_control():
	if animatedSprite.animation_finished and animatedSprite.frame != 0:
		attack_Zone_Collision.disabled = true
		animatedSprite.play("idle")
		state = states.CHASE
