tool
extends Control
class_name OBSRadialButton, "res://addons/obs_radial_menu/assets/icons/icon_obsradialbutton.svg"

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
const THEME_TYPE_NAME = "OBSRadialButton"
const DEFAULT_ICON : Texture = preload("res://addons/obs_radial_menu/assets/misc/black_16x16.png")
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
const DEFAULT_CONSTANTS : Dictionary = {
	"trim_width" : 100
}

# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _icon : Texture = null
var _arc_start_degree : float = 0.0
var _arc_end_degree : float = 45.0
var _arc_offset_degree : float = 0.0
var _inner_radius : float = 0.25
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
var _override_constants : Dictionary = {
	"trim_width" : null
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _property_updated : bool = false
var _in_focus : bool = false
var _btn_state : int = BUTTON_STATE.Normal
var _last_mouse_pos : Vector2 = Vector2.ZERO

var _crect_node : ColorRect = null


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

func set_inner_radius(r : float) -> void:
	r = max(0.0, min(1.0, r))
	_inner_radius = r
	_UpdateShaderRadii()

func set_pressed(p : bool) -> void:
	_pressed = p
	if _pressed:
		_btn_state = BUTTON_STATE.Pressed
	else:
		if _MousePositionOver(_last_mouse_pos):
			_btn_state = BUTTON_STATE.Hover
		else:
			_btn_state = BUTTON_STATE.Focused if _in_focus else BUTTON_STATE.Normal
	_UpdateShaderColors()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	# Building the material here because if this node is spawned via the editor "Add Child Node"
	# option, or via duplicating an already instanced OBSRadialButton, the underlaying material and
	# shader will not be unique to the newly created OBSRadialButton. Therefore, I have to assume
	# all OBSRadialButton instances have this little issue, and create a new material for all instances.
	# At least until I figure out a better way.
	var mat : ShaderMaterial = ShaderMaterial.new()
	mat.shader = preload("res://addons/obs_radial_menu/shaders/Arc.shader")
	mat.resource_local_to_scene = true

	var crect = get_node_or_null("ColorRect")
	if crect == null:
		crect = ColorRect.new()
		crect.material = mat
		crect.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(crect)
	_crect_node = crect
	_crect_node.material = mat

	var _res : int = connect("resized", self, "_on_resized")
	if not Engine.editor_hint:
		#set_focus_mode(Control.FOCUS_ALL)
		_res = connect("focus_entered", self, "_SetFocusMode", [true])
		_res = connect("focus_exited", self, "_SetFocusMode", [false])
	_FullShaderUpdate()

func _enter_tree():
	var parent = get_parent()
	if parent != null:
		if parent.get_class() == "OBSRadialMenu": # My Cheat to see if we're under the RadialMenu class.
			set_focus_mode(Control.FOCUS_NONE)
			mouse_filter = Control.MOUSE_FILTER_PASS
		else:
			set_focus_mode(Control.FOCUS_ALL)
			mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event : InputEvent) -> void:
	if _ProcessGUIInput(event):
		accept_event()

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
		"pressed":
			return _pressed
		_:
			var prop_split : Array = property.split("/")
			match prop_split[0]:
				"custom_constants":
					if prop_split[1] in _override_constants:
						return get_constant(prop_split[1])
				"custom_colors":
					if prop_split[1] in _override_colors:
						return get_color(prop_split[1])
	return null


func _set(property : String, value) -> bool:
	var success : bool = true
	
	match property:
		"icon":
			if value is Texture or value == null:
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
		"pressed":
			if typeof(value) == TYPE_BOOL:
				set_pressed(value)
			else : success = false
		"theme":
			call_deferred("_UpdateThemeChanges")
			success = false
		_:
			var prop_split : Array = property.split("/")
			match prop_split[0]:
				"custom_constants":
					success = _SetCheckCustomConstant(prop_split[1], value)
				"custom_colors":
					success = _SetCheckCustomColor(prop_split[1], value)
				_:
					success = false
	
	# TODO: Do I NEED to called property_list_changed_notify? Seems unneeded
	#if success:
	#	pass
		#call_deferred("property_list_changed_notify")
		#property_list_changed_notify()
	return success

func _get_property_list() -> Array:
	var arr : Array = [
		{
			name = THEME_TYPE_NAME,
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
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
			name = "pressed",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "Theme Overrides",
			type = TYPE_NIL,
			hint_string="custom_",
			usage = PROPERTY_USAGE_GROUP
		},
		{
			name = "custom_constants/trim_width",
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0, 1000",
			usage = 51 if _override_constants["trim_width"] else 18
		}
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
func _SetCheckCustomConstant(property : String, value) -> bool:
	var success : bool = false
	
	if property in _override_constants:
		match property:
			"trim_width":
				if typeof(value) == TYPE_INT:
					value = max(0, min(1000, value))
		
		if typeof(value) == typeof(DEFAULT_CONSTANTS[property]):
			success = true
			_override_constants[property] = value
		elif value == null:
			success = true
			_override_constants[property] = null

	if success:
		match property:
			"trim_width": # NOTE: This will only work if the we get past the first 2 if statements above.
				_UpdateShaderRadii()

	return success

func _SetCheckCustomColor(property : String, value) -> bool:
	var success : bool = false
	
	if property in _override_colors:
		if typeof(value) == TYPE_COLOR:
			_override_colors[property] = value
			success = true
		elif value == null:
			_override_colors[property] = null
			success = true
	
	if success:
		_UpdateShaderColors()
	
	return success


func _MousePositionOver(mpos : Vector2) -> bool:
	var outer : float = min(rect_size.x, rect_size.y) * 0.5
	var inner : float = outer * _inner_radius
	var center : Vector2 = mpos - rect_position # +  Vector2(outer, outer))
	var dist :float = center.distance_to(Vector2(outer, outer))
	if dist >= inner and dist <= outer:
		var angle = rad2deg(center.angle_to_point(Vector2(outer, outer)) + PI)
		var sd : float = fmod(_arc_start_degree + _arc_offset_degree, 360.0)
		var ed : float = fmod(_arc_end_degree + _arc_offset_degree, 360.0)
		if ed > sd:
			return angle >= sd and angle <= ed
		else:
			return (angle >= 0 and angle < ed) or (angle >= sd and angle <= 360.0)
	return false

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
		mat.set_shader_param("trim_width", get_constant("trim_width"))
		_UpdateShaderRadii()
		_UpdateShaderColors()

func _UpdateThemeChanges() -> void:
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
		mat.set_shader_param("trim_width", float(get_constant("trim_width")) / 1000.0)

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
			BUTTON_STATE.Focused:
				mat.set_shader_param("color_body", get_color("focused"))
				mat.set_shader_param("color_trim", get_color("trim_focused"))
			BUTTON_STATE.Hover:
				mat.set_shader_param("color_body", get_color("hover"))
				mat.set_shader_param("color_trim", get_color("trim_hover"))
			BUTTON_STATE.Pressed:
				mat.set_shader_param("color_body", get_color("pressed"))
				mat.set_shader_param("color_trim", get_color("trim_pressed"))

func _SetFocusMode(enable : bool = true, emit : bool = false) -> void:
	if _in_focus == enable:
		return # Nothing to do.
	
	_in_focus = enable
	if _btn_state != BUTTON_STATE.Pressed:
		if _MousePositionOver(_last_mouse_pos):
			_btn_state = BUTTON_STATE.Hover
		else:
			_btn_state = BUTTON_STATE.Focused if _in_focus else BUTTON_STATE.Normal
	_UpdateShaderColors()
	if emit:
		emit_signal("focus_entered" if _in_focus else "focus_exited")

func _GiveFocusTo(dir : int) -> void:
	var np : NodePath = get_focus_neighbour(dir)
	var ctrl : Control = get_node_or_null(np)
	if ctrl != null:
		release_focus()
		ctrl.grab_focus()

func _EmitList(emit_list : Array) -> void:
	for item in emit_list:
		if item is Array:
			callv("emit_signal", item)


func _UpdateMouseOut() -> void:
	if _btn_state in [BUTTON_STATE.Hover, BUTTON_STATE.Pressed]:
		_btn_state = BUTTON_STATE.Focused if _in_focus else BUTTON_STATE.Normal
		_UpdateShaderColors()

func _ProcessGUIInput(event : InputEvent, processed : bool = false, notify_immediate : bool = false) -> bool:
	if event is InputEventMouseMotion:
		_last_mouse_pos = event.position
	
	if processed:
		_UpdateMouseOut()
		return processed
	
	if event is InputEventMouseMotion:
		if _MousePositionOver(event.position):
			if _btn_state != BUTTON_STATE.Pressed and _btn_state != BUTTON_STATE.Hover:
				_btn_state = BUTTON_STATE.Hover
				_UpdateShaderColors()
				processed = true
		else:
			_UpdateMouseOut()
	
	if not processed:
		match _btn_state:
			BUTTON_STATE.Focused:
				if event.is_action_pressed("ui_select"):
					set_pressed(true)
					processed = true
					if notify_immediate:
						_EmitList([["button_down"], ["pressed"]])
					else:
						call_deferred("_EmitList", [["button_down"], ["pressed"]])
				elif event.is_action_pressed("ui_up"):
					_GiveFocusTo(MARGIN_TOP)
					processed = true
				elif event.is_action_pressed("ui_down"):
					_GiveFocusTo(MARGIN_BOTTOM)
					processed = true
				elif event.is_action_pressed("ui_left"):
					_GiveFocusTo(MARGIN_LEFT)
					processed = true
				elif event.is_action_pressed("ui_right"):
					_GiveFocusTo(MARGIN_RIGHT)
					processed = true
			BUTTON_STATE.Hover:
				if event is InputEventMouseButton and _MousePositionOver(event.position):
					if event.button_index == BUTTON_LEFT and event.pressed == true:
#						var parent = get_parent()
#						if parent:
#							if parent.has_method("_GrabButtonFocus"):
#								parent._GrabButtonFocus(self)
						grab_focus()
						set_pressed(true)
						processed = true
						if notify_immediate:
							_EmitList([["button_down"], ["pressed"]])
						else:
							call_deferred("_EmitList", [["button_down"], ["pressed"]])
			BUTTON_STATE.Pressed:
				if event is InputEventMouseButton and _MousePositionOver(event.position):
					if event.button_index == BUTTON_LEFT and event.pressed == false:
						set_pressed(false)
				if event.is_action_released("ui_select"):
					set_pressed(false)
			
				if not _pressed:
					processed = true
					call_deferred("emit_signal", "button_up")
	
	return processed

# ------------------------------------------------------------------------------
# Public Override Methods
# ------------------------------------------------------------------------------
func add_color_override(color_name : String, color : Color) -> void:
	if color_name in _override_colors:
		_override_colors[color_name] = color
		_UpdateShaderColors()

func add_constant_override(const_name : String, value) -> void:
	if const_name in _override_constants:
		if typeof(value) == typeof(DEFAULT_CONSTANTS[const_name]):
			_override_constants[const_name] = value
			match const_name:
				"trim_width":
					_UpdateShaderRadii()

func remove_color_override(color_name : String) -> void:
	if color_name in _override_colors:
		_override_colors[color_name] = null
		_UpdateShaderColors()

func remove_constant_override(const_name : String) -> void:
	if const_name in _override_constants:
		_override_constants[const_name] = null
		match const_name:
			"trim_width":
				_UpdateShaderRadii()

func has_color_override(color_name : String) -> bool:
	if color_name in _override_colors:
		return _override_colors[color_name] != null
	return false

func has_constant_override(const_name : String) -> bool:
	if const_name in _override_constants:
		return _override_constants[const_name] != null
	return false

func has_color(color_name : String, type_name : String = "") -> bool:
	if type_name == "":
		type_name = THEME_TYPE_NAME
		if color_name in _override_colors:
			if _override_colors[color_name] != null:
				return true
	return .has_color(color_name, type_name)

func has_constant(const_name : String, type_name : String = "") -> bool:
	if type_name == "":
		type_name = THEME_TYPE_NAME
		if const_name in _override_constants:
			if _override_constants[const_name] != null:
				return true
	return .has_constant(const_name, type_name)

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

func get_constant(const_name : String, type_name : String = ""):
	if type_name == "":
		if const_name in _override_constants:
			if _override_constants[const_name] != null:
				return _override_constants[const_name]
		type_name = THEME_TYPE_NAME
		if not .has_constant(const_name, type_name):
			if const_name in DEFAULT_CONSTANTS:
				return DEFAULT_CONSTANTS[const_name]
			return null
	return .get_constant(const_name, type_name)

func has_focus() -> bool:
	return _in_focus

func grab_focus() -> void:
	if focus_mode != Control.FOCUS_NONE:
		.grab_focus()
	_SetFocusMode(true)

func release_focus() -> void:
	if focus_mode != Control.FOCUS_NONE:
		.release_focus()
	_SetFocusMode(false)

func get_class() -> String:
	return "OBSRadialButton"

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_arc(start_angle : float, end_angle : float) -> void:
	set_arc_degrees(rad2deg(start_angle), rad2deg(end_angle))

func set_arc_degrees(start_angle_degree : float, end_angle_degree : float, offset_degrees : float = -1.0) -> void:
	if start_angle_degree > 360.0:
		start_angle_degree = fmod(start_angle_degree, 360.0)
	if end_angle_degree > 360.0:
		end_angle_degree = fmod(end_angle_degree, 360.0)
	if end_angle_degree > start_angle_degree:
		set_arc_start_degree(start_angle_degree)
		set_arc_end_degree(end_angle_degree)
	if offset_degrees >= 0.0:
		set_arc_offset_degree(offset_degrees)
	property_list_changed_notify()

func set_radii(radius_inner : float, radius_outer : float) -> void:
	if radius_inner < radius_outer:
		rect_size = Vector2(radius_outer * 2, radius_outer * 2)
		if _crect_node:
			_crect_node.rect_size = rect_size
		set_inner_radius(radius_inner / radius_outer)
		_UpdateShaderRadii()
		property_list_changed_notify()



# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_resized() -> void:
	_UpdateShaderRadii()
	if _crect_node:
		_crect_node.rect_size = rect_size

