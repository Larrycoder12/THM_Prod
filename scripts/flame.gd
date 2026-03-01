extends Node2D

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("up"):
		$CPUParticles2D.emitting = true
		var sway = rng.randi_range(-100, 100)
		$CPUParticles2D.gravity.x = sway
	else:
		$CPUParticles2D.emitting = false
