extends Control

func _ready():
	hide()
	get_tree().paused = false

func _process(_delta):
	if Input.is_action_just_pressed("esc"):
		if get_tree().paused:
			resume()
		else:
			pause()

func pause():
	get_tree().paused = true
	show()
	$AnimationPlayer.play("blur")

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	hide()

func _on_resume_pressed() -> void:
	resume()

func _on_quit_pressed() -> void:
	get_tree().quit()
