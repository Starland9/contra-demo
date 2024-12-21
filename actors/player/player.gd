extends CharacterBody2D


# player States
enum PlayerState {
	IDLE,
	RUN,
	FIRE,
	RUN_FIRE,
	JUMP,
	RUN_FIRE_DOWN,
	RUN_FIRE_UP,
	UP,
	UP_FIRE,
	CROUCH,
	CROUCH_FIRE
}

@onready var anim = $AnimatedSprite2D
@onready var stateLabel = $State
@onready var bulletStart = $BulletStartPoint
@onready var hud = $HUD
@onready var joystick = hud.get_node("Joystick")
@onready var jumpButton = hud.get_node("Jump")
@onready var fireButton = hud.get_node("Fire")

@onready var bulletScene = preload("res://objects/bullet/bullet.tscn")


@export var SPEED = 80.0
const JUMP_VELOCITY = -300.0

var _state: PlayerState
var facing_direction: float = 1
var direction : Vector2
var arm_direction :=  Vector2(1, 0)
var in_fire: bool = false
var in_up: bool = false
var in_crouch: bool = false


func _ready() -> void:
	_changeState(PlayerState.IDLE)
	stateLabel.hide()

	# if is android or ios
	if not (OS.get_name() == "Android" or OS.get_name() == "iOS"):
		hud.hide()


func _physics_process(delta: float) -> void:
	_applyGravity(delta)

	stateLabel.text = str(PlayerState.keys()[_state])

	_manageInputs()
	move_and_slide()
	_manageState()


func _manageInputs():
	# Handle jump.
	if (Input.is_action_just_pressed("ui_accept") or jumpButton.is_pressed()) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	
	in_fire = Input.is_action_pressed("fire") or fireButton.is_pressed()
	in_up = Input.is_action_pressed("ui_up")
	in_crouch = Input.is_action_pressed("ui_down")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if direction.x:
		velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if direction.x != 0.0:
		facing_direction = direction.x


	if facing_direction > 0:
		anim.flip_h = false
	if facing_direction < 0:
		anim.flip_h = true


	

func _applyGravity(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

func _manageState() -> void:
	if is_on_floor():
		if in_up:
			if velocity.x != 0.0:
				_changeState(PlayerState.RUN_FIRE_UP)
			else:
				_changeState(PlayerState.UP)
		elif in_crouch:
			if velocity.x != 0.0:
				_changeState(PlayerState.RUN_FIRE_DOWN)
			else:
				_changeState(PlayerState.CROUCH)
		elif velocity.x == 0.0:
			_changeState(PlayerState.IDLE)
		elif velocity.x != 0.0 and not in_fire:
			_changeState(PlayerState.RUN)
		elif in_fire:
			if velocity.x != 0.0:
				_changeState(PlayerState.RUN_FIRE)
			else:
				_changeState(PlayerState.FIRE)

	elif not is_on_floor():
		_changeState(PlayerState.JUMP)

	

	
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
		PlayerState.UP:
			anim.play("up")
		PlayerState.UP_FIRE:
			anim.play("up_fire")
		PlayerState.CROUCH:
			anim.play("crouch")
		PlayerState.CROUCH_FIRE:
			anim.play("crouch_fire")

func _on_bullet_timer_timeout() -> void:
	if not in_fire:
		return


	if _state == PlayerState.CROUCH:
		arm_direction = Vector2(facing_direction, 0)
	elif direction != Vector2.ZERO:
		arm_direction = direction
	else:
		arm_direction = Vector2(facing_direction, 0)

	var bullet: Bullet = bulletScene.instantiate()
	bullet.global_position = bulletStart.global_position

	if _state == PlayerState.CROUCH:
		bullet.direction = Vector2(facing_direction, 0)
		bullet.position += Vector2(0, 12)

	bullet.position += arm_direction * 25
	bullet.direction = arm_direction
	get_parent().add_child(bullet)

