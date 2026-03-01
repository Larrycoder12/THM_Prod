extends Node2D

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if Input.is_action_pressed("up"):
		$CPUParticles2D.emitting = true
		var sway = rng.randi_range(-100, 100)
		$CPUParticles2D.gravity.x = sway
	else:
		$CPUParticles2D.emitting = false
