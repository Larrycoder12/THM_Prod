extends CharacterBody2D

const ACCELERATION = 500
const MAX_VELOCITY = 300
const VERT_BOUNCE = 10
const HORIZ_BOUNCE = 20
const JETPACK_VELOCITY = -80.0
const SLAM_VELOCITY = 300
const BREAK_THRESHOLD = 170.0 
const DEFAULT_HEALTH = 100.0
const GRAVITY = 400
const MAX_FUEL = 100.0
const FUEL_CONSUMPTION = 50.0
const FUEL_REGEN = 30.0
const DASH_COOLDOWN_TIME = 1.5

var tile_health = {}
var slamming = false
var current_fuel = MAX_FUEL
var dash_cooldown_timer = 0.0
var m_coins = 0
var u_coins = 0
var ram = 0
@onready var timerz: Label = $"../CanvasLayer/Timer"
@onready var label: Label = $"../CanvasLayer/Label"
@onready var status_label: Label = $"../CanvasLayer/StatusLabel"
@onready var spawn_point: Marker2D = $"../Marker2D"

var time_left = 10.0
var timer_active = false
func timer(seconds: float):
	time_left = seconds
	timer_active = true
func _physics_process(delta: float) -> void:
	if timer_active and time_left > 0:
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			timer_active = false
			_on_timer_out()
	update_timer_display()
	
	
	
	var pre_v = velocity
	
	if dash_cooldown_timer > 0: 
		dash_cooldown_timer -= delta
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		slamming = false
		current_fuel = move_toward(current_fuel, MAX_FUEL, FUEL_REGEN * delta)
	
	if not slamming:
		if Input.is_action_pressed("up") and current_fuel > 0:
			velocity.y = JETPACK_VELOCITY
			current_fuel -= FUEL_CONSUMPTION * delta
		
		if Input.is_action_pressed("left"):
			if velocity.x > -MAX_VELOCITY: velocity.x -= ACCELERATION * delta
		elif Input.is_action_pressed("right"):
			if velocity.x < MAX_VELOCITY: velocity.x += ACCELERATION * delta
		else:
			velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
		
		if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
			dash_cooldown_timer = DASH_COOLDOWN_TIME
			if is_on_floor():
				velocity.x += sign(velocity.x) * SLAM_VELOCITY
			else:
				velocity.y += SLAM_VELOCITY
				slamming = true
	
	$Sprite2D.flip_h = velocity.x < 0 if velocity.x != 0 else $Sprite2D.flip_h
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var n = col.get_normal()
		var collider = col.get_collider()
		if collider is TileMapLayer:
			var impact = abs(pre_v.dot(n))
			if impact > BREAK_THRESHOLD:
				var mpos = collider.local_to_map(collider.to_local(col.get_position() - n * 4))
				if collider.get_cell_source_id(mpos) != -1:
					take_tile_damage(collider, mpos, impact - BREAK_THRESHOLD)
				if abs(n.x) > abs(n.y):
					velocity.x += HORIZ_BOUNCE if n.x > 0 else -HORIZ_BOUNCE
				else:
					velocity.y = VERT_BOUNCE if n.y > 0 else -VERT_BOUNCE * 4
	
	# Update Resource Label
	label.text = "M Coins: %d\nU Coins: %d\nRAM: %d" % [m_coins, u_coins, ram]
	
	# Update Status Label (Fuel and Slam)
	var dash_text = "READY" if dash_cooldown_timer <= 0 else str(snapped(dash_cooldown_timer, 0.1)) + "s"
	status_label.text = "FUEL: %d%%\nSLAM: %s" % [int(current_fuel), dash_text]
func take_tile_damage(layer: TileMapLayer, mpos: Vector2i, damage: float):
	if not tile_health.has(mpos): 
		tile_health[mpos] = DEFAULT_HEALTH
	
	tile_health[mpos] -= damage
	
	if tile_health[mpos] <= 0:
		var atlas = layer.get_cell_atlas_coords(mpos)
		layer.erase_cell(mpos)
		tile_health.erase(mpos)
		match atlas:
			Vector2i(0, 0): u_coins += 1
			Vector2i(0, 1): m_coins += 1
			Vector2i(0, 2), Vector2i(1, 2): ram += 1
			

func update_timer_display():
	# Formats seconds into MM:SS
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	# Assuming you have a dedicated label for the timer
	timerz.text = "Time: " + "%02d:%02d" % [minutes, seconds]
func _on_timer_out():
	print("Time is up!")
	tpto(spawn_point.global_position)
func tpto(tpos: Vector2):
	global_position = tpos
	velocity = Vector2.ZERO 
	slamming = false 
func _ready():
	timer(10)
