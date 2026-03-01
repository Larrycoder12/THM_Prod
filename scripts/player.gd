extends CharacterBody2D

const ACCELERATION = 500
const MAX_VELOCITY = 200
const VERT_BOUNCE = 40
const HORIZ_BOUNCE = 80
const JETPACK_VELOCITY = -80.0
const SPEED = 100.0
const JUMP_VELOCITY = -150.0
const BREAK_THRESHOLD = 120.0 
const DEFAULT_HEALTH = 100.0
const SLAM_VELOCITY = 300
var player_resources = {};
var tile_health = {}
var slamming = false
const GRAVITY = 400

var m_coins = 0
var u_coins = 0
var ram = 0


@onready var label: Label = $"../CanvasLayer/Label"
func _physics_process(delta: float) -> void:
	var pre_collision_velocity = velocity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor():
		slamming = false
		
		
	if not slamming:

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
		
		if Input.is_action_just_pressed("dash"):
			if is_on_floor():
				velocity.x += sign(velocity.x) * SLAM_VELOCITY
			else:
				velocity.y += SLAM_VELOCITY
				slamming = true
	
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
			var impact_force = abs(pre_collision_velocity.dot(n))
			
			if impact_force > BREAK_THRESHOLD:
				var hit_point = col.get_position()
				var map_pos = collider.local_to_map(collider.to_local(hit_point - n * 4))
				
				if collider.get_cell_source_id(map_pos) != -1:
					var damage = impact_force - BREAK_THRESHOLD
					take_tile_damage(collider, map_pos, damage)
		
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

func take_tile_damage(layer: TileMapLayer, map_pos: Vector2i, damage: float):
	if not tile_health.has(map_pos):
		tile_health[map_pos] = DEFAULT_HEALTH
	
	tile_health[map_pos] -= damage
	
	if tile_health[map_pos] <= 0:
		var atlas_coords = layer.get_cell_atlas_coords(map_pos)
		layer.erase_cell(map_pos)
		tile_health.erase(map_pos)
		print(atlas_coords)
		match atlas_coords:
			Vector2i(0, 0): 
				u_coins += 1
				print("U coin added")
			Vector2i(0, 1): 
				m_coins += 1
				print("M coin added")
			Vector2i(0, 2), Vector2i(1, 2): 
				ram += 1
				print("RAM coin added") 
		label.text = "M Coins: " + str(m_coins) + "\nU Coins: " + str(u_coins) + "\nRAM: " + str(ram)

		
		## Assuming the script is attached to the parent of the Label node
#func update_score(new_score):
 #   $LabelNodeName.text = "Score: " + str(new_score) #
