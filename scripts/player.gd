extends CharacterBody2D


const ACCELERATION = 5
const MAX_VELOCITY = 400
const JUMP_VELOCITY = -200.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_pressed("up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_pressed("left"):
		if velocity.x > -1 * MAX_VELOCITY:
			velocity.x -= ACCELERATION
	elif Input.is_action_pressed("right"):
		if velocity.x < MAX_VELOCITY:
			velocity.x += ACCELERATION
	else:
		velocity.x -= sign(velocity.x) * ACCELERATION
	
	if velocity.x < 0:
		$Sprite2D.flip_h = true
	elif velocity.x > 0:
		$Sprite2D.flip_h = false

	move_and_slide()
