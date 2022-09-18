tool
extends Control
class_name RadialButton

# TODO: MAJOR
# Add variables for scaling the icon (if defined) relative to the thickness of the arc
# This will require adjustments to the Arc.shader code as well!

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
const DEFAULT_ICON : Texture = preload("res://Assets/Textures/black_16x16.png")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var icon : Texture = null							setget set_icon
export var start_degree : float = 0.0						setget set_start_degree
export var end_degree : float = 45.0						setget set_end_degree
export var outer_radius : float = 42.0						setget set_outer_radius
export var inner_radius : float = 20.0						setget set_inner_radius
export var trim_width : float = 1.0							setget set_trim_width
export var pressed : bool = false							setget set_pressed
export var color_normal : Color = Color("#37343e")			setget set_color_normal
export var color_hover : Color = Color("#4d4057")			setget set_color_hover
export var color_pressed : Color = Color("#141317")			setget set_color_pressed
export var trim_color_normal : Color = Color("#4d4957")		setget set_trim_color_normal
export var trim_color_hover : Color = Color("#37343e")		setget set_trim_color_hover
export var trim_color_pressed : Color = Color("#37343e")		setget set_trim_color_pressed

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _in_focus : bool = false
var _btn_state : int = BUTTON_STATE.Normal

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var _crect_node : ColorRect = $ColorRect

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_icon(ico : Texture) -> void:
	icon = ico
	_UpdateShaderParams("icon", icon)

func set_start_degree(d : float) -> void:
	if d > 360.0:
		d = fmod(d, 360.0)
	if d < end_degree:
		start_degree = d
		_UpdateShaderParams("angle_start", start_degree)

func set_end_degree(d : float) -> void:
	if d > 360.0:
		d = fmod(d, 360.0)
	if d > start_degree:
		end_degree = d
		_UpdateShaderParams("angle_end", end_degree)

func set_outer_radius(r : float) -> void:
	if r > inner_radius:
		outer_radius = r
		#set_size(Vector2(outer_radius * 2, outer_radius * 2))
		_UpdateShaderParams("base_size", outer_radius)
		_UpdateShaderParams("radius_outer", outer_radius)
		call_deferred("_UpdateRectSize")

func set_inner_radius(r : float) -> void:
	if r < outer_radius:
		inner_radius = r
		_UpdateShaderParams("radius_inner", inner_radius)

func set_trim_width(w : float) -> void:
	if w >= 0.0:
		trim_width = w
		_UpdateShaderParams("trim_width", trim_width)

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
	#mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not Engine.editor_hint:
		connect("focus_entered", self, "_on_focus_entered")
		connect("focus_exited", self, "_on_focus_exited")
	_UpdateRectSize()
	_FullShaderUpdate()

func _enter_tree():
	var parent = get_parent()
	if parent != null:
		if parent.has_method("add_radial_button"): # My Cheat to see if we're under the RadialMenu class.
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event : InputEvent) -> void:
	if _ProcessGUIInput(event):
		accept_event()


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _MousePositionOnButton(mpos : Vector2) -> bool:
	var dist :float = mpos.distance_to(Vector2(outer_radius, outer_radius))
	var reset : bool = true
	if dist >= inner_radius and dist <= outer_radius:
		var angle = rad2deg(mpos.angle_to_point(Vector2(outer_radius, outer_radius)) + PI)
		if angle >= start_degree and angle <= end_degree:
			return true
	return false

func _EmitList(emit_list : Array) -> void:
	for item in emit_list:
		if item is Array:
			callv("emit_signal", item)

func _ProcessGUIInput(event : InputEvent, processed : bool = false) -> bool:
	if event is InputEventMouseMotion:
		var reset : bool = true
		if not processed:
			if _MousePositionOnButton(event.position - rect_position):
				if _btn_state != BUTTON_STATE.Pressed:
					_btn_state = BUTTON_STATE.Hover
					_UpdateShaderColors()
					processed = true
				reset = false
		if reset and _btn_state != BUTTON_STATE.Normal:
			_btn_state = BUTTON_STATE.Normal
			_UpdateShaderColors()
	if not processed:
		match _btn_state:
			BUTTON_STATE.Hover:
				var pressed : bool = false
				if event is InputEventMouseButton:
					if event.button_index == BUTTON_LEFT and event.pressed == true:
						pressed = true
				elif event.is_action_pressed("ui_select"):
					pressed = true
				elif event.is_action_pressed("ui_up"):
					_GiveFocusTo(Control.MARGIN_UP)
					processed = true
				elif event.is_action_pressed("ui_down"):
					_GiveFocusTo(Control.MARGIN_DOWN)
					processed = true
				elif event.is_action_pressed("ui_left"):
					_GiveFocusTo(Control.MARGIN_LEFT)
					processed = true
				elif event.is_action_pressed("ui_right"):
					_GiveFocusTo(Control.MARGIN_RIGHT)
					processed = true
					
				if pressed:
					_btn_state = BUTTON_STATE.Pressed
					_UpdateShaderColors()
					processed = true
					call_deferred("_EmitList", [["button_down"],["pressed"]])
			BUTTON_STATE.Pressed:
				var released = false
				var focused : bool = _in_focus
				if event is InputEventMouseButton:
					if event.button_index == BUTTON_LEFT and event.pressed == false:
						focused = _MousePositionOnButton(event.position)
						released = true
				if event.is_action_released("ui_select"):
					released = true
			
				if released:
					_btn_state = BUTTON_STATE.Hover if focused else BUTTON_STATE.Normal
					_UpdateShaderColors()
					processed = true
					call_deferred("emit_signal", "button_up")
	return processed


func _UpdateRectSize() -> void:
	rect_size = Vector2(outer_radius * 2, outer_radius * 2)
	if Engine.editor_hint and not _crect_node:
		_crect_node = get_node_or_null("ColorRect")
	if _crect_node:
		_crect_node.rect_size = Vector2(outer_radius * 2, outer_radius * 2)
		_crect_node.update()

func _FullShaderUpdate() -> void:
	if not _crect_node:
		return
	
	var mat : ShaderMaterial = _crect_node.get_material()
	if mat != null:
		if icon != null:
			mat.set_shader_param("icon", icon)
			mat.set_shader_param("use_icon", true)
		else:
			mat.set_shader_param("icon", DEFAULT_ICON)
			mat.set_shader_param("use_icon", false)
		mat.set_shader_param("base_size", outer_radius)
		mat.set_shader_param("angle_start", start_degree)
		mat.set_shader_param("angle_end", end_degree)
		mat.set_shader_param("radius_inner", inner_radius)
		mat.set_shader_param("radius_outer", outer_radius)
		mat.set_shader_param("trim_width", trim_width)
		_UpdateShaderColors()


func _UpdateShaderParams(param : String, value) -> void:
	if Engine.editor_hint and not _crect_node:
		_crect_node = get_node_or_null("ColorRect")
	if not _crect_node:
		return
	var mat : ShaderMaterial = _crect_node.get_material()
	if mat != null:
		match param:
			"icon":
				if value is Texture:
					mat.set_shader_param("icon", value)
					mat.set_shader_param("use_icon", true)
				else:
					mat.set_shader_param("icon", DEFAULT_ICON)
					mat.set_shader_param("use_icon", false)
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
			"trim_width":
				mat.set_shader_param("trim_width", value)

func _UpdateShaderColors() -> void:
	if Engine.editor_hint and not _crect_node:
		_crect_node = get_node_or_null("ColorRect")
	if not _crect_node:
		return
	var mat : ShaderMaterial = _crect_node.get_material()
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

func _GiveFocusTo(dir : int) -> void:
	var np : NodePath = get_focus_neighbour(dir)
	var ctrl : Control = get_node_or_null(np)
	if ctrl != null:
		release_focus()
		ctrl.grab_focus()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_arc(start_angle : float, end_angle : float) -> void:
	set_arc_degrees(rad2deg(start_angle), rad2deg(end_angle))

func set_arc_degrees(start_angle_degree : float, end_angle_degree : float) -> void:
	if start_angle_degree > 360.0:
		start_angle_degree = fmod(start_angle_degree, 360.0)
	if end_angle_degree > 360.0:
		end_angle_degree = fmod(end_angle_degree, 360.0)
	if end_angle_degree > start_angle_degree:
		start_degree = start_angle_degree
		end_degree = end_angle_degree
		_UpdateShaderParams("angle_start", start_degree)
		_UpdateShaderParams("angle_end", end_degree)

func set_radii(radius_inner : float, radius_outer : float) -> void:
	if radius_inner < radius_outer:
		inner_radius = radius_inner
		outer_radius = radius_outer
		_UpdateShaderParams("base_size", outer_radius)
		_UpdateShaderParams("radius_outer", outer_radius)
		_UpdateShaderParams("radius_inner", inner_radius)
		call_deferred("_UpdateRectSize")

func grab_focus() -> void:
	.grab_focus()
	_on_focus_entered()

func release_focus() -> void:
	.release_focus()
	_on_focus_exited()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------

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
