extends CharacterBody2D
## This character controller was created with the intent of being a decent starting point for Platformers.
## 
## Instead of teaching the basics, I tried to implement more advanced considerations.
## That's why I call it 'Movement 2'. This is a sequel to learning demos of similar a kind.
## Beyond coyote time and a jump buffer I go through all the things listed in the following video:
## https://www.youtube.com/watch?v=2S3g8CgBG1g
## Except for separate air and ground acceleration, as I don't think it's necessary.
class_name Player
#region Variables


# BASIC MOVEMENT VARIABLES ---------------- #
var face_direction := 1
var x_dir := 1

@export var max_speed: float = 560
@export var acceleration: float = 2880
@export var turning_acceleration : float = 9600
@export var deceleration: float = 3200
# ------------------------------------------ #

# GRAVITY ----- #
@export var gravity_acceleration : float = 3840
@export var gravity_max : float = 1020
# ------------- #

# JUMP VARIABLES ------------------- #
@export var jump_force : float = 1400
@export var jump_cut : float = 0.25
@export var jump_gravity_max : float = 500
@export var jump_hang_treshold : float = 2.0
@export var jump_hang_gravity_mult : float = 0.1
# Timers
@export var jump_coyote : float = 0.08
@export var jump_buffer : float = 0.1

var jump_coyote_timer : float = 0
var jump_buffer_timer : float = 0
var is_jumping := false
# ----------------------------------- #

# DASH VARIABLES ------------------- #
var can_dash := true
var is_dashing := false
@export var dash_buffer : float = 0.5
var dash_buffer_timer : float = 0
@export var dash_duration : float = 0.05
var dash_duration_timer : float = 0
var dash_speed : float = 1.2
# ----------------------------------- #

var reset_position: Vector2
var abilities: Array[StringName]
var is_attacking := false
@onready var animatedSprite := $AnimatedSprite2D
@onready var attack_Zone_Collision := $AttackZone/Area2D/CollisionShape2D
@onready var altura_Centro_Inicial := position.y
var penguin_scene = preload("res://Penguin/Penguin.tscn")
@onready var max_penguins: int = 0
var penguins: int = 0
var canGrab: bool = true
@onready var collision_shape := $CollisionShape2D
var health: int = 5
#endregion

# All iputs we want to keep track of
func get_input() -> Dictionary:
	return {
		"x": int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")),
		"y": int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up")),
		"just_jump": Input.is_action_just_pressed("jump") == true,
		"jump": Input.is_action_pressed("jump") == true,
		"released_jump": Input.is_action_just_released("jump") == true,
		"dash": Input.is_action_just_pressed("dash"),
		"action": Input.is_action_just_pressed("action"),
		"grab": Input.is_action_just_pressed("grab"),
		"attack": Input.is_action_just_pressed("attack")
	}

func _process(delta):
	if get_input()["action"] and penguins < max_penguins:
		penguin()
	if is_attacking == false and get_input()["attack"]:
		attack()
	if is_attacking:
		attack_control()
	timers(delta)

func _physics_process(delta: float) -> void:
	x_movement(delta)
	jump_logic(delta)
	dash_logic(delta)
	apply_gravity(delta)
	move_and_slide()


#region Funciones de movimiento

func dash_logic(delta: float) -> void:
	if dash_buffer_timer <= 0:
		can_dash = true
	if get_input()["dash"]:
		dash_buffer_timer = dash_buffer
	
	if dash_buffer_timer > 0 and can_dash:
		can_dash = false
		is_dashing = true
		dash_duration_timer = dash_duration		
		
	if dash_duration_timer > 0:
		is_dashing = true
		velocity.x *= dash_speed
	else:
		is_dashing = false
		velocity.x /= dash_speed

func x_movement(delta: float) -> void:
	x_dir = get_input()["x"]
	
	# Stop if we're not doing movement inputs.
	if x_dir == 0: 
		velocity.x = Vector2(velocity.x, 0).move_toward(Vector2(0,0), deceleration * delta).x
		animatedSprite.play("idle")
		
		return
	
	animatedSprite.play("run")
	
	# Are we turning?
	# Deciding between acceleration and turn_acceleration
	var accel_rate : float = acceleration if sign(velocity.x) == x_dir else turning_acceleration
	
	# Accelerate
	velocity.x += x_dir * accel_rate * delta
	
	## If we are doing movement inputs and above max speed, don't accelerate nor decelerate
	## Except if we are turning
	## (This keeps our momentum gained from outside or slopes)
	if abs(velocity.x) >= max_speed and sign(velocity.x) == x_dir:
		return
		
	set_direction(x_dir) # This is purely for visuals

func set_direction(hor_direction) -> void:
	# This is purely for visuals
	# Turning relies on the scale of the player
	# To animate, only scale the sprite
	if hor_direction == 0:
		return
	apply_scale(Vector2(hor_direction * face_direction, 1)) # flip
	face_direction = hor_direction # remember direction

func jump_logic(_delta: float) -> void:
	# Reset our jump requirements
	if is_on_floor():
		jump_coyote_timer = jump_coyote
		is_jumping = false
	if get_input()["just_jump"]:
		jump_buffer_timer = jump_buffer
	
	# Jump if grounded, there is jump input, and we aren't jumping already
	if jump_coyote_timer > 0 and jump_buffer_timer > 0 and not is_jumping:
		is_jumping = true
		jump_coyote_timer = 0
		jump_buffer_timer = 0
		# If falling, account for that lost speed
		if velocity.y > 0:
			velocity.y -= velocity.y
		
		velocity.y = -jump_force
	
	# We're not actually interested in checking if the player is holding the jump button
#	if get_input()["jump"]:pass
	
	# Cut the velocity if let go of jump. This means our jumpheight is varaiable
	# This should only happen when moving upwards, as doing this while falling would lead to
	# The ability to studder our player mid falling
	if get_input()["released_jump"] and velocity.y < 0:
		velocity.y -= (jump_cut * velocity.y)
	
	# This way we won't start slowly descending / floating once hit a ceiling
	# The value added to the treshold is arbritary,
	# But it solves a problem where jumping into 
	if is_on_ceiling(): velocity.y = jump_hang_treshold + 100.0

func apply_gravity(delta: float) -> void:
	var applied_gravity : float = 0
	
	# No gravity if we are grounded
	if jump_coyote_timer > 0:
		return
	
	# Normal gravity limit
	if velocity.y <= gravity_max:
		applied_gravity = gravity_acceleration * delta
	
	# If moving upwards while jumping, the limit is jump_gravity_max to achieve lower gravity
	if (is_jumping and velocity.y < 0) and velocity.y > jump_gravity_max:
		applied_gravity = 0
	
	# Lower the gravity at the peak of our jump (where velocity is the smallest)
	if is_jumping and abs(velocity.y) < jump_hang_treshold:
		applied_gravity *= jump_hang_gravity_mult
	
	velocity.y += applied_gravity

func timers(delta: float) -> void:
	# Using timer nodes here would mean unnececary functions and node calls
	# This way everything is contained in just 1 script with no node requirements
	jump_coyote_timer -= delta
	jump_buffer_timer -= delta
	dash_buffer_timer -= delta
	dash_duration_timer -= delta

#endregion

func on_enter():
	# Position for kill system. Assigned when entering new room (see Game.gd).
	reset_position = position

func penguin():
	var pingu = penguin_scene.instantiate()
	penguins += 1
	if face_direction == 1:
		pingu.position.x = position.x - (100*penguins)
	else:
		pingu.position.x = position.x + (100*penguins)
	pingu.position.y = position.y
	get_tree().root.add_child(pingu)

func attack():
	is_attacking = true
	attack_Zone_Collision.disabled = false
	animatedSprite.play("attack")

func attack_control():
	if animatedSprite.animation_finished and animatedSprite.frame != 0:
		attack_Zone_Collision.disabled = true
		animatedSprite.play("idle")
		is_attacking = false


func _on_area_2d_area_entered(area):
	if area.owner is Enemy:
		health -= area.get_node("..").damage
		if health == 0:
			pass #TODO: Reiniciar al último save
