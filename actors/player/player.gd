extends CharacterBody2D


# player States
enum PlayerState {
	IDLE,
	RUN,
	FIRE,
	RUN_FIRE,
	JUMP,
	RUN_FIRE_DOWN,
	RUN_FIRE_UP
}

@onready var anim = $AnimatedSprite2D
@onready var stateLabel = $State
@onready var bulletStart = $BulletStartPoint
@onready var joystick = $HUD/Joystick
@onready var jumpButton = $HUD/Jump
@onready var fireButton = $HUD/Fire

@onready var bulletScene = preload("res://objects/bullet/bullet.tscn")


@export var SPEED = 80.0
const JUMP_VELOCITY = -300.0

var _state: PlayerState
var facing_direction = 1
var in_fire: bool = false


func _ready() -> void:
	_changeState(PlayerState.IDLE)
	stateLabel.hide()


func _physics_process(delta: float) -> void:
	_applyGravity(delta)

	stateLabel.text = str(PlayerState.keys()[_state])

	_manageInputs()
	move_and_slide()
	_manageState()


func _manageInputs():
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") or jumpButton.is_pressed() and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	print(direction)
	if direction != 0:
		facing_direction = direction

	anim.flip_h = facing_direction < 0

	_toggleFire()


func _toggleFire() -> void:
	in_fire = false

	if Input.is_action_pressed("fire") or fireButton.is_pressed():
		in_fire = true
	

func _applyGravity(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

func _manageState() -> void:
	if is_on_floor() and velocity.x == 0.0 and not in_fire:
		_changeState(PlayerState.IDLE)

	elif is_on_floor() and velocity.x != 0.0 and not in_fire:
		_changeState(PlayerState.RUN)

	elif not is_on_floor():
		_changeState(PlayerState.JUMP)

	elif is_on_floor() and velocity.x != 0.0 and in_fire:
		_changeState(PlayerState.RUN_FIRE)

	elif is_on_floor() and in_fire:
		_changeState(PlayerState.FIRE)

	
func _changeState(state: PlayerState) -> void:
	if state != _state:
		print("change state ", PlayerState.keys()[_state], "->", PlayerState.keys()[state])

		_state = state
		_updateAnim(state)


func _updateAnim(state: PlayerState) -> void:
	match state:
		PlayerState.IDLE:
			anim.play("idle")
		PlayerState.RUN:
			anim.play("run")
		PlayerState.FIRE:
			anim.play("fire")
		PlayerState.RUN_FIRE:
			anim.play("run_fire")
		PlayerState.JUMP:
			anim.play("jump")
		PlayerState.RUN_FIRE_DOWN:
			anim.play("run_fire_down")
		PlayerState.RUN_FIRE_UP:
			anim.play("run_fire_up")

func _on_bullet_timer_timeout() -> void:
	if not in_fire:
		return

	var bullet = bulletScene.instantiate()
	bullet.global_position = bulletStart.global_position

	if facing_direction < 0:
		bullet.global_position.x -= 50

	bullet.direction = facing_direction
	get_parent().add_child(bullet)
