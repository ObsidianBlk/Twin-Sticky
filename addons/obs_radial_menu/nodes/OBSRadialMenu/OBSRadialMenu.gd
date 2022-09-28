tool
extends Popup
class_name OBSRadialMenu, "res://addons/obs_radial_menu/assets/icons/icon_obsradialmenu.svg"

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CLASS_NAME : String = "OBSRadialMenu"
const PROP_CHANGE_NOTE_DEBOUNCE : float = 0.5

enum CLAMP {NoClamp=0, ExpandOnly=1, Sticky=2, FixedSticky=3}

# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _max_arc_degrees : float = 360.0
var _outer_radius : float = 1.0
var _inner_radius : float = 0.25
var _offset_angle : float = 0.0
var _gap_degrees : float = 0.2
var _force_neighboring : bool = true
#var _clamp_to_parent : bool = true

var _clamp_type : int = CLAMP.NoClamp
var _sticky_thickness : float = 64.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _prop_debounce_timer : SceneTreeTimer = null

var _is_subradial : bool = false

var _relative_coords : Vector2 = Vector2.ZERO
var _radius_override : Vector2 = Vector2.ZERO

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_outer_radius(r : float) -> void:
	r = _ClampOuterRadii(r)
	if _outer_radius != r:
		_outer_radius = r
		if _is_subradial:
			_inner_radius = _ClampInnerRadii(_inner_radius)
		_NotifySubmenuRadialUpdate()
		_AdjustRadialButtonSizeAndPos()

func set_outer_radius_pixels(r : float) -> void:
	var base_size : float = min(rect_size.x, rect_size.y) * 0.5
	if base_size > 0.0:
		set_outer_radius(r / base_size)

func set_inner_radius(r : float) -> void:
	r = _ClampInnerRadii(r)
	if _inner_radius != r:
		_inner_radius = r
		_AdjustRadialButtonSizeAndPos()

func set_inner_radius_pixels(r : float) -> void:
	var base_size : float = min(rect_size.x, rect_size.y) * 0.5
	if base_size > 0.0:
		var outer : float = base_size * _outer_radius
		if outer > 0.0:
			set_inner_radius(r / outer)

func set_offset_angle(a : float) -> void:
	if a > 360.0:
		a = fmod(a, 360.0)
	_offset_angle = a
	_AdjustRadialButtons()

func set_gap_degrees(g : float) -> void:
	if g >= 0.0 and g <= 10.0 and _gap_degrees != g:
		_gap_degrees = g
		_AdjustRadialButtons()

func set_clamp_type(c : int) -> void:
	if CLAMP.values().find(c) >= 0:
		_clamp_type = c
		if _is_subradial and _clamp_type != CLAMP.NoClamp:
			_AdjustToParent()

func set_sticky_thickness(t : float) -> void:
	if t >= 0.0:
		_sticky_thickness = t
		if _is_subradial:
			_AdjustToParent()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_focus_mode(Control.FOCUS_ALL)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	anchor_right = 1.0
	var _res : int = 0
	if not Engine.editor_hint:
		_res = get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	else:
		# This is to keep the popup filling the viewport as I want it to and prevents the editor
		# from defying me... damnit! Shouldn't be needed at runtime.
		_res = connect("item_rect_changed", self, "_on_item_rect_changed")
	_res = connect("child_entered_tree", self, "_on_child_entered")
	_res = connect("child_exiting_tree", self, "_on_child_exited")
	_res = connect("about_to_show", self, "_on_about_to_show")
	_relative_coords = Vector2(0.5, 0.5)
	_RecalcScreenSize()
	_AdjustRadialButtons()

func _enter_tree() -> void:
	_RecalcScreenSize()
	var parent = get_parent()
	if parent.get_class() == CLASS_NAME:
		_is_subradial = true

func _gui_input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()
	else:
		var processed : bool = false
		for child in get_children():
			if child is OBSRadialButton:
				if not processed:
					processed = child._ProcessGUIInput(event)
				else:
					child._ProcessGUIInput(event, true)
	accept_event()

func _get(property : String):
	match property:
		"max_arc_degrees":
			return _max_arc_degrees
		"outer_radius":
			return _outer_radius
		"outer_radius_pixels":
			return _CalcOuterRadiusPixels()
		"inner_radius":
			return _inner_radius
		"inner_radius_pixels":
			return _CalcInnerRadiusPixels()
		"offset_angle":
			return _offset_angle
		"gap_degrees":
			return _gap_degrees
		"force_neighboring":
			return _force_neighboring
		"clamp_type":
			return _clamp_type
		"sticky_thickness":
			return _sticky_thickness
	return null

func _set(property : String, value) -> bool:
	var success : bool = true
	
	match property:
		"max_arc_degrees":
			if typeof(value) == TYPE_REAL:
				if value >= 0.0 and value <= 360.0:
					_max_arc_degrees = value
					_AdjustRadialButtons()
				else : success = false
			else : success = false
		"outer_radius":
			if typeof(value) == TYPE_REAL:
				set_outer_radius(value)
			else : success = false
		"outer_radius_pixels":
			if typeof(value) == TYPE_REAL:
				set_outer_radius_pixels(value)
			else : success = false
		"inner_radius":
			if typeof(value) == TYPE_REAL:
				set_inner_radius(value)
			else : success = false
		"inner_radius_pixels":
			if typeof(value) == TYPE_REAL:
				set_inner_radius_pixels(value)
			else : success = false
		"offset_angle":
			if typeof(value) == TYPE_REAL:
				set_offset_angle(value)
			else : success = false
		"gap_degrees":
			if typeof(value) == TYPE_REAL:
				if value >= 0.0 and value <= 10.0 and _gap_degrees != value:
					_gap_degrees = value
					_AdjustRadialButtons()
				else : success = false
			else : success = false
		"force_neighboring":
			if typeof(value) == TYPE_BOOL:
				_force_neighboring = value
			else : success = false
		"clamp_type":
			if typeof(value) == TYPE_INT:
				set_clamp_type(value)
			else : success = false
		"sticky_thickness":
			if typeof(value) == TYPE_REAL:
				set_sticky_thickness(value)
			else : success = false
		"theme":
			call_deferred("_NotifyButtonsThemeChanged")
			# The assignment of this value doesn't happen here, we just need to notify that it's
			# coming.
			success = false 
		_:
			success = false
	
	if success:
		_PropertyChangedNotify()
	
	return success

func _get_property_list() -> Array:
	var arr : Array = [
		{
			name = CLASS_NAME,
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = "max_arc_degrees",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 360.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "outer_radius",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 1.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "outer_radius_pixels",
			type = TYPE_REAL,
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
			name = "inner_radius_pixels",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "offset_angle",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 360.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "gap_degrees",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 10.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "force_neighboring",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		}
	]
	
	if _is_subradial:
		arr.append({
			name = "clamp_type",
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string=_GetCLAMPEnumString(),
			usage = PROPERTY_USAGE_DEFAULT
		})
		if _clamp_type == CLAMP.FixedSticky:
			arr.append({
				name = "sticky_thickness",
				type = TYPE_REAL,
				usage = PROPERTY_USAGE_DEFAULT
			})
	
	return arr

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetCLAMPEnumString() -> String:
	var s : String = ""
	for key in CLAMP.keys():
		if s == "":
			s = "%s:%s"%[key, CLAMP[key]]
		else:
			s = "%s,%s:%s"%[s, key, CLAMP[key]]
	return s


func _PropertyChangedNotify() -> void:
	if not is_inside_tree() or not Engine.editor_hint:
		return # Don't bother doing anything if we're not in the tree or in the Godot Editor
	
	if _prop_debounce_timer == null:
		_prop_debounce_timer = get_tree().create_timer(PROP_CHANGE_NOTE_DEBOUNCE)
		var _res : int = _prop_debounce_timer.connect("timeout", self, "_on_property_changed_notify")
	else:
		_prop_debounce_timer.time_left = PROP_CHANGE_NOTE_DEBOUNCE

func _NotifySubmenuRadialUpdate() -> void:
	for child in get_children():
		if child.get_class() == CLASS_NAME:
			if child.clamp_type != CLAMP.NoClamp:
				child._AdjustToParent()

func _NotifyButtonsThemeChanged() -> void:
	for child in get_children():
		if child is OBSRadialButton:
			child._UpdateThemeChanges()

func _GetBaseSize() -> float:
	return min(rect_size.x, rect_size.y) * 0.5

func _GetOuterRadius() -> float:
	if _radius_override.x > 0.0 and _radius_override.x < 1.0:
		return _radius_override.x
	return _outer_radius

func _GetInnerRadius() -> float:
	if _radius_override.y > 0.0 and _radius_override.y < 1.0:
		return _radius_override.y
	return _inner_radius

func _CalcOuterRadiusPixels() -> float:
	return _GetBaseSize() * _GetOuterRadius()

func _CalcInnerRadiusPixels() -> float:
	return _CalcOuterRadiusPixels() * _GetInnerRadius()

func _ClampOuterRadii(value : float) -> float:
	value = max(0.0, min(1.0, value))
	if _is_subradial and _clamp_type != CLAMP.NoClamp:
		var parent = get_parent()
		if parent.get_class() == CLASS_NAME:
			var base_size : float = _GetBaseSize()
			var parent_outer_pixels = parent.get("outer_radius_pixels")
			var radius : float = base_size * value
			if radius < parent_outer_pixels:
				value = max(0.0, min(1.0, parent_outer_pixels / base_size))
			if _clamp_type == CLAMP.FixedSticky and radius < parent_outer_pixels + _sticky_thickness:
				value = max(0.0, min(1.0, (parent_outer_pixels + _sticky_thickness) / base_size))
	return value

func _ClampInnerRadii(value : float) -> float:
	value = max(0.0, min(1.0, value))
	if _is_subradial and _clamp_type != CLAMP.NoClamp:
		var parent = get_parent()
		if parent.get_class() == CLASS_NAME:
			var parent_outer_pixels = parent._CalcOuterRadiusPixels()
			var outer_pixels = _CalcOuterRadiusPixels()
			var inner_pixels  = outer_pixels * value
			if inner_pixels < parent_outer_pixels or _clamp_type == CLAMP.Sticky:
				inner_pixels = parent_outer_pixels
				return inner_pixels / outer_pixels
	return value

func _RecalcScreenSize() -> void:
	rect_size = get_viewport_rect().size
	if _is_subradial and _clamp_type != CLAMP.NoClamp:
		_AdjustToParent()
	else:
		_AdjustRadialButtonSizeAndPos()

func _SetNeighbors(from_neighbour : OBSRadialButton, to_neighbour : OBSRadialButton) -> void:
	var path : NodePath = to_neighbour.get_path_to(from_neighbour)
	to_neighbour.focus_neighbour_left = path
	to_neighbour.focus_neighbour_top = path
	to_neighbour.focus_previous = path
	path = from_neighbour.get_path_to(to_neighbour)
	from_neighbour.focus_neighbour_right = path
	from_neighbour.focus_neighbour_bottom = path
	from_neighbour.focus_next = path

func _AdjustToParent() -> void:
	var parent = get_parent()
	if parent.get_class() == CLASS_NAME:
		var parent_outer_pixels : float = parent.get("outer_radius_pixels")
		var inner_pixels : float = get("inner_radius_pixels")
		if inner_pixels < parent_outer_pixels or _clamp_type == CLAMP.Sticky or _clamp_type == CLAMP.FixedSticky:
			var base_size : float = _GetBaseSize()
			var outer_pixels : float = get("outer_radius_pixels")
			var thickness : float = outer_pixels - inner_pixels
			if _clamp_type == CLAMP.FixedSticky:
				thickness = _sticky_thickness
			inner_pixels = parent_outer_pixels
			outer_pixels = inner_pixels + thickness
			if outer_pixels > base_size:
				outer_pixels = base_size
			set_outer_radius_pixels(outer_pixels)
			set_inner_radius_pixels(inner_pixels)

func _AdjustRadialButtons() -> void:
	var count : int = 0
	for child in get_children():
		if child is OBSRadialButton:
			count += 1
	
	if count > 0:
		var arc : float = (_max_arc_degrees - (_gap_degrees * float(count))) / float(count)
		var hgap : float = 0.0 if count <= 1 else _gap_degrees * 0.5
		
		var start_degree : float = hgap
		var first_child = null
		var last_child = null
		for child in get_children():
			if child is OBSRadialButton:
				child.set_arc_degrees(start_degree, start_degree + arc, _offset_angle)
				#child.offset_degree = _offset_angle
				start_degree += arc + _gap_degrees
				if _force_neighboring and not Engine.editor_hint:
					if first_child == null:
						first_child = child
					else:
						_SetNeighbors(last_child, child)
					last_child = child
		if first_child != null and last_child != null:
			_SetNeighbors(last_child, first_child)

func _AdjustRadialButtonSizeAndPos() -> void:
	var cpos : Vector2 = (rect_size * _relative_coords) #+ Vector2(_outer_radius, _outer_radius)
	for child in get_children():
		if child is OBSRadialButton:
			var outer : float = _CalcOuterRadiusPixels()
			var inner : float = _CalcInnerRadiusPixels()
			child.set_radii(inner, outer)
			child.rect_position = cpos - Vector2(outer, outer)

func _GetFocusedChild() -> OBSRadialButton:
	for child in get_children():
		if child is OBSRadialButton:
			if child.has_focus():
				return child
	return null

func _GrabButtonFocus(btn : OBSRadialButton) -> void:
	if btn != null:
		if is_a_parent_of(btn):
			var child : OBSRadialButton = _GetFocusedChild()
			if child != btn:
				child.release_focus()
				btn.grab_focus()
				grab_focus()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func popup(rect : Rect2 = Rect2(0,0,0,0)) -> void:
	.popup(Rect2(0,0,0,0))
	if rect_size.x > 0.0 and rect_size.y > 0.0:
		var base_size : float = _GetBaseSize()
		if rect.size.x > 0.0:
			_radius_override.x = rect.size.x / base_size
		if rect.size.y > 0.0:
			_radius_override.y = rect.size.y / base_size
		
		var outer : float = _CalcOuterRadiusPixels()
		var pos : Vector2 = Vector2(
			clamp(rect.position.x, outer, rect_size.x - outer),
			clamp(rect.position.y, outer, rect_size.y - outer)
		)
		
		_relative_coords = Vector2(
			pos.x / rect_size.x,
			pos.y / rect_size.y
		)
	else:
		_relative_coords = Vector2.ZERO
	_AdjustRadialButtonSizeAndPos()

func popup_centered(size : Vector2 = Vector2.ZERO) -> void:
	.popup_centered(Vector2.ZERO)
	var base_size : float = _GetBaseSize()
	if base_size > 0.0:
		if size.x > 0.0:
			_radius_override.x = size.x / base_size
		if size.y > 0.0:
			_radius_override.y = size.y / base_size
	_relative_coords = Vector2.ONE * 0.5
	_AdjustRadialButtonSizeAndPos()

func popup_centered_ratio(ratio : float = 0.75) -> void:
	# This custom vector will only ratio the outer radius leaving the inner radius to it's
	# original relative size.
	popup_centered(Vector2((rect_size.x * 0.5) * ratio, 0.0))

func hide() -> void:
	.hide()
	_radius_override = Vector2.ZERO

func has_focus() -> bool:
	return _GetFocusedChild() != null

func get_class() -> String:
	return CLASS_NAME

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_property_changed_notify() -> void:
	_prop_debounce_timer = null
	property_list_changed_notify()


func _on_viewport_size_changed() -> void:
	if not Engine.editor_hint:
		_RecalcScreenSize()

func _on_item_rect_changed() -> void:
	# This exists because the Editor keeps trying to do something with my size and it's... upsetting
	_RecalcScreenSize()

func _on_child_entered(child : Node) -> void:
	if child is OBSRadialButton:
		if not Engine.editor_hint:
			if not child.is_connected("focus_entered", self, "_on_child_focus_entered"):
				var _res : int = child.connect("focus_entered", self, "_on_child_focus_entered")
		call_deferred("_AdjustRadialButtons")
		call_deferred("_AdjustRadialButtonSizeAndPos")

func _on_child_exited(child : Node) -> void:
	if child is OBSRadialButton:
		if not Engine.editor_hint:
			if child.is_connected("focus_entered", self, "_on_child_focus_entered"):
				child.disconnect("focus_entered", self, "_on_child_focus_entered")
		call_deferred("_AdjustRadialButtons")
		call_deferred("_AdjustRadialButtonSizeAndPos")

func _on_child_focus_entered() -> void:
	grab_focus()

func _on_about_to_show() -> void:
	_RecalcScreenSize()
	if not has_focus():
		for child in get_children():
			if child is OBSRadialButton:
				child.grab_focus()
				grab_focus()
				break

