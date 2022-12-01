extends Spatial


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal explosion_completed()

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var fire : Particles = $Fire
onready var smoke : Particles = $Smoke


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	fire.emitting = true
	smoke.emitting = true
	var timer : SceneTreeTimer = get_tree().create_timer(1.0)
	timer.connect("timeout", self, "_on_timer_timeout")


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_timer_timeout() -> void:
	print("Done going boom")
	var parent = get_parent()
	if parent != null:
		parent.remove_child(self)
		queue_free()
		emit_signal("explosion_completed")

