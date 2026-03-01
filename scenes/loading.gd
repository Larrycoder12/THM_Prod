extends Control


const MAIN_SCENE_PATH = "res://node_2d.tscn"
const WAIT_TIME = 3 

func _ready():
	# We call the method "change_scene" on 'self' deferred
	call_deferred("change_scene", "res://scenes/Loading.tscn")

# Define the function clearly at the script level
func change_scene(path: String):
	get_tree().change_scene_to_file(path)
