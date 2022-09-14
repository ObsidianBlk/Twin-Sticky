extends ColorRect

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal pressed()
signal button_down()
signal button_up()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var start_degree : float = 0.0				setget set_start_degree
export var end_degree : float = 45.0				setget set_end_degree
export var outer_radius : float = 10.0				setget set_outer_radius
export var inner_radius : float = 5.0				setget set_inner_radius
export var color_normal : Color = Color.darkblue
export var color_hover : Color = Color.blue
export var color_pressed : Color = Color.blueviolet

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_start_degree(d : float) -> void:
	d = fmod(d, 360.0)
	if d < end_degree:
		start_degree = d

func set_end_degree(d : float) -> void:
	d = fmod(d, 360.0)
	if d > start_degree:
		end_degree = d

func set_outer_radius(r : float) -> void:
	if r > inner_radius:
		outer_radius = r

func set_inner_radius(r : float) -> void:
	if r < outer_radius:
		inner_radius = r

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	connect("gui_input", self, "_on_gui_input")


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _on_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		pass
	if event.is_action_pressed("ui_select"):
		pass

