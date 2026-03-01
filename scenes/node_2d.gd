extends Node2D

@onready var tile_layer: TileMapLayer = $TileMapLayer

# Generation Settings
const CHUNK_SIZE = 16
const SEED = 12345
const SURFACE_LEVEL = 20  # The Y coordinate where the ground starts
const DIRT_DEPTH = 10     # How many tiles of dirt before stone starts

var terrain_noise = FastNoiseLite.new()
var cave_noise = FastNoiseLite.new()

func _ready():
	setup_noises()
	# Generate a 3x3 grid of chunks starting from (0,0)
	for x in range(3):
		for y in range(3):
			generate_chunk(Vector2i(x, y))

func setup_noises():
	# Terrain noise creates the wavy surface hills
	terrain_noise.seed = SEED
	terrain_noise.frequency = 0.02
	terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Cave noise creates the holes underground
	cave_noise.seed = SEED + 1
	cave_noise.frequency = 0.06
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN

func generate_chunk(chunk_pos: Vector2i):
	var start_x = chunk_pos.x * CHUNK_SIZE
	var start_y = chunk_pos.y * CHUNK_SIZE
	
	for x in range(CHUNK_SIZE):
		var global_x = start_x + x
		
		var noise_val = terrain_noise.get_noise_1d(global_x)
		var current_surface_y = SURFACE_LEVEL + int(noise_val * 15)
		
		for y in range(CHUNK_SIZE):
			var global_y = start_y + y
			
			if global_y >= current_surface_y:
				
				var c_val = cave_noise.get_noise_2d(global_x, global_y)
				
				if c_val > -0.2 and c_val < 0.2:
					continue
					
				var atlas_coords = Vector2i(1, 0) # Default Dirt
				
				if global_y > current_surface_y + DIRT_DEPTH:
					atlas_coords = Vector2i(1, 0)
					
				tile_layer.set_cell(Vector2i(global_x, global_y), 0, atlas_coords)
