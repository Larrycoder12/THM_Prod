extends Node2D

@onready var tile_layer: TileMapLayer = $TileMapLayer
@onready var bg_layer: TileMapLayer = $TileMapLayer2

const CHUNK_SIZE = 16
const SEED = 12345
const WORLD_WIDTH_CHUNKS = 10
const WORLD_DEPTH_CHUNKS = 15

const SURFACE_LEVEL = 40
const DIRT_DEPTH = 15
const CAVERN_LEVEL = 80

var surface_noise = FastNoiseLite.new()
var cave_noise = FastNoiseLite.new()

func _ready():
	# Ensure the background is visually behind the foreground
	bg_layer.z_index = -1
	# Darken the background layer slightly so it looks like a wall
	bg_layer.self_modulate = Color(0.4, 0.4, 0.4)
	
	setup_visual_bg()
	setup_noises()
	create_stars(300)
	
	for x in range(-WORLD_WIDTH_CHUNKS, WORLD_WIDTH_CHUNKS):
		for y in range(0, WORLD_DEPTH_CHUNKS):
			generate_chunk(Vector2i(x, y))

func setup_visual_bg():
	var canvas_bg = CanvasLayer.new()
	canvas_bg.layer = -100
	var black_rect = ColorRect.new()
	black_rect.color = Color.BLACK
	black_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_bg.add_child(black_rect)
	add_child(canvas_bg)

func setup_noises():
	surface_noise.seed = SEED
	surface_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	surface_noise.frequency = 0.005
	surface_noise.fractal_octaves = 4
	
	cave_noise.seed = SEED + 7
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.frequency = 0.02
	cave_noise.fractal_octaves = 3

func generate_chunk(chunk_pos: Vector2i):
	var start_x = chunk_pos.x * CHUNK_SIZE
	var start_y = chunk_pos.y * CHUNK_SIZE
	
	for x in range(CHUNK_SIZE):
		var global_x = start_x + x
		# The exact Y coordinate where the air ends and the ground begins
		var terrain_height = SURFACE_LEVEL + int(surface_noise.get_noise_1d(global_x) * 25)
		
		for y in range(CHUNK_SIZE):
			var global_y = start_y + y
			var map_pos = Vector2i(global_x, global_y)
			
			# ONLY generate walls and blocks IF we are at or below the terrain surface
			if global_y >= terrain_height:
				
				# 1. Background Wall Generation
				var bg_atlas = Vector2i(0, 2) # Dirt Wall
				if global_y > CAVERN_LEVEL:
					bg_atlas = Vector2i(0, 1) # Stone Wall
				
				# This fills the entire space below ground, including caves
				bg_layer.set_cell(map_pos, 0, bg_atlas)
				
				# 2. Foreground Block Generation
				var c_val = cave_noise.get_noise_2d(global_x, global_y)
				
				# Only place a solid block if we are NOT inside a 'worm' cave
				if abs(c_val) > 0.15: 
					var block_atlas = Vector2i(1, 0) # Dirt Block
					if global_y > terrain_height + DIRT_DEPTH:
						block_atlas = Vector2i(1, 1) # Stone Block
					
					tile_layer.set_cell(map_pos, 0, block_atlas)
			else:
				# This is the sky area. Ensure it is empty.
				tile_layer.erase_cell(map_pos)
				bg_layer.erase_cell(map_pos)

func create_stars(count: int):
	var pb = ParallaxBackground.new()
	var pl = ParallaxLayer.new()
	pl.motion_scale = Vector2(0.01, 0.01)
	var screen_size = Vector2(1920, 1080)
	pl.motion_mirroring = screen_size
	add_child(pb)
	pb.add_child(pl)
	
	for i in range(count):
		var star = ColorRect.new()
		var size = randf_range(0.8, 2.5)
		star.size = Vector2(size, size)
		star.position = Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y))
		pl.add_child(star)
		var duration = randf_range(1.0, 4.0)
		var tween = star.create_tween().set_loops()
		tween.tween_property(star, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
		tween.tween_property(star, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
