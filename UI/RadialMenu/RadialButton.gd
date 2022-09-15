extends ColorRect
tool

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal pressed()
signal button_down()
signal button_up()

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
enum BUTTON_STATE {Normal=0, Hover=1, Pressed=2}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var icon : Texture = null							setget set_icon
export var start_degree : float = 0.0						setget set_start_degree
export var end_degree : float = 45.0						setget set_end_degree
export var outer_radius : float = 10.0						setget set_outer_radius
export var inner_radius : float = 5.0						setget set_inner_radius
export var pressed : bool = false
export var color_normal : Color = Color.darkblue			setget set_color_normal
export var color_hover : Color = Color.blue					setget set_color_hover
export var color_pressed : Color = Color.blueviolet			setget set_color_pressed
export var trim_color_normal : Color = Color.darkmagenta	setget set_trim_color_normal
export var trim_color_hover : Color = Color.blueviolet		setget set_trim_color_hover
export var trim_color_pressed : Color = Color.blue			setget set_trim_color_pressed

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _in_focus : bool = false
var _btn_state : int = BUTTON_STATE.Normal

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_icon(ico : Texture) -> void:
	icon = ico
	_UpdateShaderParams("icon", icon)

func set_start_degree(d : float) -> void:
	d = fmod(d, 360.0)
	if d < end_degree:
		start_degree = d
		_UpdateShaderParams("angle_start", start_degree)

func set_end_degree(d : float) -> void:
	d = fmod(d, 360.0)
	if d > start_degree:
		end_degree = d
		_UpdateShaderParams("angle_end", end_degree)

func set_outer_radius(r : float) -> void:
	if r > inner_radius:
		outer_radius = r
		rect_size = Vector2(outer_radius, outer_radius)
		_UpdateShaderParams("base_size", outer_radius)
		_UpdateShaderParams("radius_inner", inner_radius)

func set_inner_radius(r : float) -> void:
	if r < outer_radius:
		inner_radius = r
		_UpdateShaderParams("radius_outer", outer_radius)

func set_pressed(p : bool) -> void:
	pressed = p
	if pressed:
		_btn_state = BUTTON_STATE.Pressed
	else:
		_btn_state = BUTTON_STATE.Hover if _in_focus else BUTTON_STATE.Normal
	_UpdateShaderColors()

func set_color_normal(c : Color) -> void:
	color_normal = c
	_UpdateShaderColors()

func set_color_hover(c : Color) -> void:
	color_hover = c
	_UpdateShaderColors()

func set_color_pressed(c : Color) -> void:
	color_pressed = c
	_UpdateShaderColors()

func set_trim_color_normal(c : Color) -> void:
	trim_color_normal = c
	_UpdateShaderColors()

func set_trim_color_hover(c : Color) -> void:
	trim_color_hover = c
	_UpdateShaderColors()

func set_trim_color_pressed(c : Color) -> void:
	trim_color_pressed = c
	_UpdateShaderColors()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if not Engine.editor_hint:
		mouse_filter = Control.MOUSE_FILTER_PASS
		connect("gui_input", self, "_on_gui_input")
		connect("focus_entered", self, "_on_focus_entered")
		connect("focus_exited", self, "_on_focus_exited")


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateShaderParams(param : String, value) -> void:
	var mat : ShaderMaterial = get_material()
	if mat != null:
		match param:
			"icon":
				mat.set_shader_param("icon", value)
			"base_size":
				mat.set_shader_param("base_size", value)
			"angle_start":
				mat.set_shader_param("angle_start", value)
			"angle_end":
				mat.set_shader_param("angle_end", value)
			"radius_inner":
				mat.set_shader_param("radius_inner", value)
			"radius_outer":
				mat.set_shader_param("radius_outer", value)

func _UpdateShaderColors() -> void:
	var mat : ShaderMaterial = get_material()
	if mat != null:
		match (_btn_state):
			BUTTON_STATE.Normal:
				mat.set_shader_param("color_body", color_normal)
				mat.set_shader_param("color_trim", trim_color_normal)
			BUTTON_STATE.Hover:
				mat.set_shader_param("color_body", color_hover)
				mat.set_shader_param("color_trim", trim_color_hover)
			BUTTON_STATE.Pressed:
				mat.set_shader_param("color_body", color_pressed)
				mat.set_shader_param("color_trim", trim_color_pressed)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _on_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		pass
	if event.is_action_pressed("ui_select"):
		pass

func _on_focus_entered() -> void:
	_in_focus = true
	if _btn_state != BUTTON_STATE.Pressed:
		_btn_state = BUTTON_STATE.Hover
	_UpdateShaderColors()

func _on_focus_exited() -> void:
	_in_focus = false
	if _btn_state != BUTTON_STATE.Pressed:
		_btn_state = BUTTON_STATE.Normal
	_UpdateShaderColors()
