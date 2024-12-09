extends CharacterBody2D
class_name Bullet

@onready var screen_size = get_viewport_rect().size

var speed = 20000
var direction = 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity.x = speed * delta * direction
	move_and_slide()


func _on_end_time_timeout() -> void:
	queue_free()
