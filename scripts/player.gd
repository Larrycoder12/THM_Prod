extends CharacterBody2D


const ACCELERATION = 200
const MAX_VELOCITY = 200
const BOUNCE = 40
const JETPACK_VELOCITY = -80.0
const SPEED = 100.0
const JUMP_VELOCITY = -150.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_pressed("up"):
		velocity.y = JETPACK_VELOCITY

	if Input.is_action_pressed("left"):
		if velocity.x > -1 * MAX_VELOCITY:
			velocity.x -= ACCELERATION * delta
	elif Input.is_action_pressed("right"):
		if velocity.x < MAX_VELOCITY:
			velocity.x += ACCELERATION * delta
	else:
		velocity.x -= sign(velocity.x) * ACCELERATION * delta
	
	if velocity.x < 0:
		$Sprite2D.flip_h = true
	elif velocity.x > 0:
		$Sprite2D.flip_h = false

	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
	
		var n := col.get_normal()
		if abs(n.x) > abs(n.y):
			# side hit
			if n.x > 0: # hit left
				velocity.x += BOUNCE
			else: # hit right
				velocity.x -= BOUNCE
		else:
			# vertical hit
			if n.y > 0: # hit ceiling
				velocity.y += BOUNCE
			else: # hit floor
				velocity.y = -1 * BOUNCE * 4
