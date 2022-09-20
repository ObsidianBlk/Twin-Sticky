tool
extends Control
class_name RadialButton

# TODO: This redo of the origin RadialButton node is far from complete!! Must be finished!!

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal pressed()
signal button_down()
signal button_up()

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
enum BUTTON_STATE {Normal=0, Focused=1, Hover=2, Pressed=3}
const THEME_TYPE_NAME = "RadialButton"
const DEFAULT_ICON : Texture = preload("res://Assets/Textures/black_16x16.png")
const DEFAULT_COLORS : Dictionary = {
	"normal" : Color("#37343e"),
	"hover" : Color("#4d4057"),
	"focused" : Color("#37343e"),
	"pressed" : Color("#141317"),
	"trim_normal" : Color("#4d4957"),
	"trim_hover" : Color("#37343e"),
	"trim_focused" : Color("#141317"),
	"trim_pressed" : Color("#37343e")
}

# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _icon : Texture = null
var _arc_start_degree : float = 0.0
var _arc_end_degree : float = 45.0
var _arc_offset_degree : float = 0.0
var _inner_radius : float = 0.25
var _trim_width : float = 1.0
var _pressed : bool = false
var _override_colors : Dictionary = {
	"normal" : null,
	"hover" : null,
	"focused" : null,
	"pressed" : null,
	"trim_normal" : null,
	"trim_hover" : null,
	"trim_focused" : null,
	"trim_pressed" : null
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _in_focus : bool = false
var _mouse_over : bool = false
var _btn_state : int = BUTTON_STATE.Normal

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var _crect_node : ColorRect = $ColorRect

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_icon(i : Texture) -> void:
	_icon = i
	_UpdateShaderParams("icon", _icon)

func set_arc_start_degree(d : float) -> void:
	if d > 360.0:
		d = fmod(d, 360.0)
	_arc_start_degree = d
	_UpdateShaderParams("angle_start", _arc_start_degree)

func set_arc_end_degree(d : float) -> void:
	if d > 360.0:
		d = fmod(d, 360.0)
	_arc_end_degree = d
	_UpdateShaderParams("angle_end", _arc_end_degree)

func set_arc_offset_degree(d : float) -> void:
	if d > 360.0:
		d = fmod(d, 360.0)
	_arc_offset_degree = d
	_UpdateShaderParams("angle_offset", _arc_offset_degree)

func set_trim_width(w : float) -> void:
	w = max(0.0, min(1.0, w))
	_trim_width = w
	_UpdateShaderParams("trim_width", _trim_width)

func set_inner_radius(r : float) -> void:
	r = max(0.0, min(1.0, r))
	_inner_radius = r
	_UpdateShaderRadii()

func set_pressed(p : bool) -> void:
	_pressed = p

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------

func _get(property : String):
	match property:
		"icon":
			return _icon
		"arc_start_degree":
			return _arc_start_degree
		"arc_end_degree":
			return _arc_end_degree
		"arc_offset_degree":
			return _arc_offset_degree
		"inner_radius":
			return _inner_radius
		"trim_width":
			return _trim_width
		"pressed":
			return _pressed
	return null


func _set(property : String, value) -> bool:
	var success : bool = true
	
	match property:
		"icon":
			if value is Texture:
				set_icon(value)
			else : success = false
		"arc_start_degree":
			if typeof(value) == TYPE_REAL:
				set_arc_start_degree(value)
			else : success = false
		"arc_end_degree":
			if typeof(value) == TYPE_REAL:
				set_arc_end_degree(value)
			else : success = false
		"arc_offset_degree":
			if typeof(value) == TYPE_REAL:
				set_arc_offset_degree(value)
			else : success = false
		"inner_radius":
			if typeof(value) == TYPE_REAL:
				set_inner_radius(value)
			else : success = false
		"trim_width":
			if typeof(value) == TYPE_REAL:
				set_trim_width(value)
			else : success = false
		"pressed":
			if typeof(value) == TYPE_BOOL:
				set_pressed(value)
			else : success = false
		_:
			success = false
	
	if success:
		property_list_changed_notify()
	return success

func _get_property_list() -> Array:
	var arr : Array = [
		{
			name = "icon",
			type = TYPE_OBJECT,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			hint_string = "Texture",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "arc_start_degree",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 360.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "arc_end_degree",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 360.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "arc_offset_degree",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 360.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "inner_radius",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 1.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "trim_width",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 1.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "pressed",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},
	]
	for key in _override_colors.keys():
		arr.append({
			name = "custom_colors/%s"%key,
			type = TYPE_COLOR,
			usage = 51 if _override_colors[key] != null else 18
		})
	return arr

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _FullShaderUpdate() -> void:
	if not _crect_node:
		return
	
	var mat : ShaderMaterial = _crect_node.get_material()
	if mat != null:
		if _icon != null:
			mat.set_shader_param("icon", _icon)
			mat.set_shader_param("use_icon", true)
		else:
			mat.set_shader_param("icon", DEFAULT_ICON)
			mat.set_shader_param("use_icon", false)
		mat.set_shader_param("angle_start", _arc_start_degree)
		mat.set_shader_param("angle_end", _arc_end_degree)
		mat.set_shader_param("angle_offset", _arc_offset_degree)
		mat.set_shader_param("trim_width", _trim_width)
		_UpdateShaderRadii()
		_UpdateShaderColors()

func _UpdateShaderRadii() -> void:
	if not _crect_node:
		return
	
	var mat : ShaderMaterial = _crect_node.get_material()
	if mat != null:
		var outer : float = min(rect_size.x, rect_size.y) * 0.5
		var inner : float = outer * _inner_radius
		mat.set_shader_param("base_size", outer)
		mat.set_shader_param("radius_outer", outer)
		mat.set_shader_param("radius_inner", inner)

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
			"angle_offset":
				mat.set_shader_param("angle_offset", value)
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
				mat.set_shader_param("color_body", get_color("normal"))
				mat.set_shader_param("color_trim", get_color("trim_normal"))
			BUTTON_STATE.Hover:
				mat.set_shader_param("color_body", get_color("hover"))
				mat.set_shader_param("color_trim", get_color("trim_hover"))
			BUTTON_STATE.Pressed:
				mat.set_shader_param("color_body", get_color("pressed"))
				mat.set_shader_param("color_trim", get_color("trim_pressed"))

# ------------------------------------------------------------------------------
# Public Override Methods
# ------------------------------------------------------------------------------
func add_color_override(color_name : String, color : Color) -> void:
	if color_name in _override_colors:
		_override_colors[color_name] = color
		_UpdateShaderColors()

func remove_color_override(color_name : String) -> void:
	if color_name in _override_colors:
		_override_colors[color_name] = null
		_UpdateShaderColors()

func has_color_override(color_name : String) -> bool:
	if color_name in _override_colors:
		return _override_colors[color_name] != null
	return false

func has_color(color_name : String, type_name : String = "") -> bool:
	if type_name == "":
		type_name = THEME_TYPE_NAME
		if color_name in _override_colors:
			if _override_colors[color_name] != null:
				return true
	return .has_color(color_name, type_name)

func get_color(color_name : String, type_name : String = "") -> Color:
	if type_name == "":
		if color_name in _override_colors:
			if _override_colors[color_name] != null:
				return _override_colors[color_name]
		type_name = THEME_TYPE_NAME
		if not .has_color(color_name, type_name):
			if color_name in DEFAULT_COLORS:
				return DEFAULT_COLORS[color_name]
			return Color.black
	return .get_color(color_name, type_name)



