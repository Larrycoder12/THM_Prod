extends Node2D

@onready var tile_layer: TileMapLayer = $TileMapLayer
@onready var bg_layer: TileMapLayer = $TileMapLayer2

const CHUNK_SIZE = 16
const TILE_SIZE = 16
const SURFACE_LEVEL = 30
const DIRT_DEPTH = 30
const CAVERN_LEVEL = 100
const MAX_DEPTH = 2000 # Extended depth for longer progression

const DIRT_BLOCK = Vector2i(1, 0)
const STONE_BLOCK = Vector2i(1, 1)
const RARE_ORE = Vector2i(0, 0)
const COMMON_ORE = Vector2i(0, 1)
const PAIR_ORE_L = Vector2i(0, 2)
const PAIR_ORE_R = Vector2i(1, 2)

const DIRT_BG = Vector2i(0, 1)
const STONE_BG = Vector2i(0, 0)

const LOAD_RADIUS_X = 14 
const LOAD_RADIUS_Y = 25 

var surface_noise = FastNoiseLite.new()
var cave_noise = FastNoiseLite.new()
var ore_noise = FastNoiseLite.new()

var generated_chunks = {}
var current_seed = 0

func _ready():
	randomize()
	current_seed = randi()
	bg_layer.z_index = -1
	bg_layer.self_modulate = Color(0.35, 0.35, 0.35)
	
	setup_visual_bg()
	setup_noises()
	create_stars(300)
	
	var cam = Camera2D.new()
	cam.make_current()
	cam.zoom = Vector2(0.5, 0.5)
	add_child(cam)

func _process(_delta):
	var cam_pos = get_viewport().get_camera_2d().global_position
	var center_chunk_x = int(cam_pos.x / (CHUNK_SIZE * TILE_SIZE))
	var center_chunk_y = int(cam_pos.y / (CHUNK_SIZE * TILE_SIZE))
	
	for x in range(center_chunk_x - LOAD_RADIUS_X, center_chunk_x + LOAD_RADIUS_X):
		for y in range(max(0, center_chunk_y - 8), center_chunk_y + LOAD_RADIUS_Y): 
			var chunk_pos = Vector2i(x, y)
			if not generated_chunks.has(chunk_pos):
				generate_chunk(chunk_pos)
				generated_chunks[chunk_pos] = true

func setup_visual_bg():
	var canvas_bg = CanvasLayer.new()
	canvas_bg.layer = -100
	var black_rect = ColorRect.new()
	black_rect.color = Color.BLACK
	black_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_bg.add_child(black_rect)
	add_child(canvas_bg)

func setup_noises():
	surface_noise.seed = current_seed
	surface_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	surface_noise.frequency = 0.0008 
	
	cave_noise.seed = current_seed + 1
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.frequency = 0.035 
	
	ore_noise.seed = current_seed + 2
	ore_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	ore_noise.frequency = 0.2 # Dense, frequent clusters

func generate_chunk(chunk_pos: Vector2i):
	var start_x = chunk_pos.x * CHUNK_SIZE
	var start_y = chunk_pos.y * CHUNK_SIZE
	
	for x in range(CHUNK_SIZE):
		var gx = start_x + x
		var th = SURFACE_LEVEL + int(surface_noise.get_noise_1d(gx) * 10)
		
		for y in range(CHUNK_SIZE):
			var gy = start_y + y
			var pos = Vector2i(gx, gy)
			
			if gy >= th:
				# Generate BG first (the "Wall")
				var bg_tile = DIRT_BG if gy < CAVERN_LEVEL else STONE_BG
				bg_layer.set_cell(pos, 0, bg_tile)
				
				if tile_layer.get_cell_source_id(pos) != -1:
					continue

				var depth_factor = clampf(float(gy - th) / MAX_DEPTH, 0.0, 1.0)
				
				# SOLIDIFICATION MATH
				# We increase the requirement for "Air" (caves) to exist.
				# At surface (0.0), any noise value < 0.15 is air (lots of space).
				# At max depth (1.0), only values < 0.01 are air (almost zero space).
				var cave_air_threshold = lerpf(0.15, 0.01, depth_factor) 
				var cv = cave_noise.get_noise_2d(gx, gy)
				
				# If noise is OUTSIDE the shrinking air threshold, it's solid ground
				if abs(cv) > cave_air_threshold:
					var ov = ore_noise.get_noise_2d(gx, gy)
					var block = DIRT_BLOCK if gy <= th + DIRT_DEPTH else STONE_BLOCK
					
					# MASSIVE ORE FREQUENCY
					# At depth, these thresholds become so wide that ore is everywhere.
					var rare_thresh = lerpf(0.55, 0.1, depth_factor)
					var common_thresh = lerpf(0.25, -0.1, depth_factor) # Below 0 = very high chance
					var pair_thresh = lerpf(-0.5, -0.2, depth_factor)

					if ov > rare_thresh:
						block = RARE_ORE
					elif ov > common_thresh:
						block = COMMON_ORE
					elif ov < pair_thresh:
						var nx = gx + 1
						var ncv = cave_noise.get_noise_2d(nx, gy)
						# Ensure pair isn't floating in air
						if abs(ncv) > cave_air_threshold:
							tile_layer.set_cell(pos, 0, PAIR_ORE_L)
							tile_layer.set_cell(Vector2i(nx, gy), 0, PAIR_ORE_R)
							continue
					
					tile_layer.set_cell(pos, 0, block)
			else:
				tile_layer.erase_cell(pos)
				bg_layer.erase_cell(pos)

func create_stars(count: int):
	var pb = ParallaxBackground.new()
	var pl = ParallaxLayer.new()
	pl.motion_scale = Vector2(0.01, 0.01)
	pl.motion_mirroring = Vector2(1920, 1080)
	add_child(pb)
	pb.add_child(pl)
	for i in range(count):
		var s = ColorRect.new()
		var sz = randf_range(1, 3)
		s.size = Vector2(sz, sz)
		s.position = Vector2(randf_range(0, 1920), randf_range(0, 1080))
		pl.add_child(s)
		var t = s.create_tween().set_loops()
		t.tween_property(s, "modulate:a", 0.1, randf_range(1, 4))
		t.tween_property(s, "modulate:a", 1.0, randf_range(1, 4))
