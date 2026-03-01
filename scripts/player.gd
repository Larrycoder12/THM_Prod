extends CharacterBody2D

const ACCELERATION = 500
const MAX_VELOCITY = 200
const VERT_BOUNCE = 40
const HORIZ_BOUNCE = 120
const JETPACK_VELOCITY = -80.0
const SPEED = 100.0
const JUMP_VELOCITY = -150.0
const BREAK_THRESHOLD = 120.0
const GRAVITY = 300

func _physics_process(delta: float) -> void:
	var pre_collision_velocity = velocity

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_pressed("up"):
		velocity.y = JETPACK_VELOCITY

	if Input.is_action_pressed("left"):
		if velocity.x > -1 * MAX_VELOCITY:
			velocity.x -= ACCELERATION * delta
	elif Input.is_action_pressed("right"):
		if velocity.x < MAX_VELOCITY:
			velocity.x += ACCELERATION * delta
	else:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
	
	if velocity.x < 0:
		$Sprite2D.flip_h = true
	elif velocity.x > 0:
		$Sprite2D.flip_h = false

	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var n := col.get_normal()
		var collider = col.get_collider()
		
		if collider is TileMapLayer:
			var impact_force = pre_collision_velocity.dot(n)
			
			if abs(impact_force) > BREAK_THRESHOLD:
				var hit_point = col.get_position()
				var map_pos = collider.local_to_map(collider.to_local(hit_point - n * 4))
				
				if collider.get_cell_source_id(map_pos) != -1:
					break_block(collider, map_pos)
		
					if abs(n.x) > abs(n.y):
						if n.x > 0: 
							velocity.x += HORIZ_BOUNCE
						else: 
							velocity.x -= HORIZ_BOUNCE
					else:
						if n.y > 0: 
							velocity.y += VERT_BOUNCE
						else: 
							velocity.y = -1 * VERT_BOUNCE * 4

func break_block(layer: TileMapLayer, map_pos: Vector2i):
	layer.erase_cell(map_pos)
