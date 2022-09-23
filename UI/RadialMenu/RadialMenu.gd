tool
extends Popup
class_name RadialMenu

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const PROP_CHANGE_NOTE_DEBOUNCE : float = 0.25

# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _max_arc_degrees : float = 360.0
var _outer_radius : float = 1.0
var _inner_radius : float = 0.25
var _offset_angle : float = 0.0
var _gap_degrees : float = 0.2
var _force_neighboring : bool = true

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _prop_debounce_timer : SceneTreeTimer = null
var _relative_coords : Vector2 = Vector2.ZERO
var _radius_override : Vector2 = Vector2.ZERO

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_outer_radius(r : float) -> void:
	if r >= 0.0 and r <= 1.0 and _outer_radius != r:
		_outer_radius = r
		#_AdjustSize()
		_AdjustRadialButtons()

func set_inner_radius(r : float) -> void:
	if r >= 0.0 and r <= 1.0 and _inner_radius != r:
		_inner_radius = r
		#_AdjustSize()
		_AdjustRadialButtons()

func set_offset_angle(a : float) -> void:
	if a > 360.0:
		a = fmod(a, 360.0)
	_offset_angle = a
	_AdjustRadialButtons()

func set_gap_degrees(g : float) -> void:
	if g >= 0.0 and g <= 10.0 and _gap_degrees != g:
		_gap_degrees = g
		_AdjustRadialButtons()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_focus_mode(Control.FOCUS_ALL)
	var _res : int = 0
	if not Engine.editor_hint:
		_res = get_tree().get_root().connect("size_changed", self, "_on_screen_size_changed")
	_res = connect("child_entered_tree", self, "_on_child_entered")
	_res = connect("child_exiting_tree", self, "_on_child_exited")
	_res = connect("about_to_show", self, "_on_about_to_show")
	#_AdjustSize()
	if not Engine.editor_hint:
		_RecalcScreenSize()
	_AdjustRadialButtons()
	_AdjustRadialButtonSizeAndPos()


func _gui_input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()
	else:
		var processed : bool = false
		for child in get_children():
			if child is RadialButton:
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
			var base_size : float = min(rect_size.x, rect_size.y) * 0.5
			return base_size * _outer_radius
		"inner_radius":
			return _inner_radius
		"inner_radius_pixels":
			var base_size : float = min(rect_size.x, rect_size.y) * 0.5
			var outer : float = base_size * _outer_radius
			return outer * _inner_radius
		"offset_angle":
			return _offset_angle
		"gap_degrees":
			return _gap_degrees
		"force_neighboring":
			return _force_neighboring
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
				value = max(0.0, min(1.0, value))
				if _outer_radius != value:
					_outer_radius = value
					_AdjustRadialButtonSizeAndPos()
				else : success = false
			else : success = false
		"outer_radius_pixels":
			if typeof(value) == TYPE_REAL:
				var base_size : float = min(rect_size.x, rect_size.y) * 0.5
				if base_size > 0.0:
					value = max(0.0, min(1.0, value / base_size))
					if _outer_radius != value:
						_outer_radius = value
						_AdjustRadialButtonSizeAndPos()
				else : success = false
			else : success = false
		"inner_radius":
			if typeof(value) == TYPE_REAL:
				value = max(0.0, min(1.0, value))
				if _inner_radius != value:
					_inner_radius = value
					_AdjustRadialButtonSizeAndPos()
				else : success = false
			else : success = false
		"inner_radius_pixels":
			if typeof(value) == TYPE_REAL:
				var base_size : float = min(rect_size.x, rect_size.y) * 0.5
				if base_size > 0.0:
					var outer : float = base_size * _outer_radius
					value = max(0.0, min(1.0, value / outer))
					if _inner_radius != value:
						_inner_radius = value
						_AdjustRadialButtonSizeAndPos()
				else : success = false
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
		_:
			success = false
	
	if success:
		_PropertyChangedNotify()
	
	return success

func _get_property_list() -> Array:
	var arr : Array = [
		{
			name = "RadialMenu",
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
	
	return arr

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _PropertyChangedNotify() -> void:
	if not is_inside_tree() or not Engine.editor_hint:
		return # Don't bother doing anything if we're not in the tree or in the Godot Editor
	
	if _prop_debounce_timer == null:
		_prop_debounce_timer = get_tree().create_timer(PROP_CHANGE_NOTE_DEBOUNCE)
		var _res : int = _prop_debounce_timer.connect("timeout", self, "_on_property_changed_notify")
	else:
		_prop_debounce_timer.time_left = PROP_CHANGE_NOTE_DEBOUNCE

func _SetNeighbors(from_neighbour : RadialButton, to_neighbour : RadialButton) -> void:
	var path : NodePath = to_neighbour.get_path_to(from_neighbour)
	to_neighbour.focus_neighbour_left = path
	to_neighbour.focus_neighbour_top = path
	to_neighbour.focus_previous = path
	path = from_neighbour.get_path_to(to_neighbour)
	from_neighbour.focus_neighbour_right = path
	from_neighbour.focus_neighbour_bottom = path
	from_neighbour.focus_next = path

func _AdjustRadialButtons() -> void:
	var count : int = 0
	for child in get_children():
		if child is RadialButton:
			count += 1
	
	if count > 0:
		var arc : float = (_max_arc_degrees - (_gap_degrees * float(count))) / float(count)
		var hgap : float = 0.0 if count <= 1 else _gap_degrees * 0.5
		
		var start_degree : float = hgap
		var first_child = null
		var last_child = null
		for child in get_children():
			if child is RadialButton:
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

func _RecalcScreenSize() -> void:
	# TODO: Why does get_tree().get_root().size return the correct value but
	# get_viewport_rect() does not?
	rect_size = get_tree().get_root().size
	_AdjustRadialButtonSizeAndPos()

func _AdjustRadialButtonSizeAndPos() -> void:
	var outer_rad : float = _outer_radius
	var inner_rad : float = _inner_radius
	if _radius_override.x > 0.0 and _radius_override.x <= 1.0:
		outer_rad = _radius_override.x
	if _radius_override.y > 0.0 and _radius_override.y <= 1.0:
		inner_rad = _radius_override.y
	
	var cpos : Vector2 = (rect_size * _relative_coords) #+ Vector2(_outer_radius, _outer_radius)
	for child in get_children():
		if child is RadialButton:
			var base_size : float = min(rect_size.x, rect_size.y) * 0.5
			var outer : float = base_size * outer_rad
			var inner : float = outer * inner_rad
			child.set_radii(inner, outer)
			child.rect_position = cpos - Vector2(outer, outer)

func _GetFocusedChild() -> RadialButton:
	for child in get_children():
		if child is RadialButton:
			if child.has_focus():
				return child
	return null

func _GrabButtonFocus(btn : RadialButton) -> void:
	if btn != null:
		if is_a_parent_of(btn):
			var child : RadialButton = _GetFocusedChild()
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
		var base_size : float = min(rect_size.x, rect_size.y) * 0.5
		if rect.size.x > 0.0:
			_radius_override.x = rect.size.x / base_size
		if rect.size.y > 0.0:
			_radius_override.y = rect.size.y / base_size
		_relative_coords = Vector2(
			rect.position.x / rect_size.x,
			rect.position.y / rect_size.y
		)
	else:
		_relative_coords = Vector2.ZERO
	_AdjustRadialButtonSizeAndPos()

func popup_centered(size : Vector2 = Vector2.ZERO) -> void:
	.popup_centered(Vector2.ZERO)
	var base_size : float = min(rect_size.x, rect_size.y) * 0.5
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

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_property_changed_notify() -> void:
	_prop_debounce_timer = null
	property_list_changed_notify()


func _on_screen_size_changed() -> void:
	# Have to defer the call or the screen doesn't adjust properly.
	if not Engine.editor_hint:
		call_deferred("_RecalcScreenSize")

func _on_child_entered(child : Node) -> void:
	if child is RadialButton:
		if not Engine.editor_hint:
			if not child.is_connected("focus_entered", self, "_on_child_focus_entered"):
				var _res : int = child.connect("focus_entered", self, "_on_child_focus_entered")
		_AdjustRadialButtons()
		_AdjustRadialButtonSizeAndPos()

func _on_child_exited(child : Node) -> void:
	if child is RadialButton:
		if not Engine.editor_hint:
			if child.is_connected("focus_entered", self, "_on_child_focus_entered"):
				child.disconnect("focus_entered", self, "_on_child_focus_entered")
		_AdjustRadialButtons()
		_AdjustRadialButtonSizeAndPos()

func _on_child_focus_entered() -> void:
	grab_focus()

func _on_about_to_show() -> void:
	_RecalcScreenSize()
	if not has_focus():
		for child in get_children():
			if child is RadialButton:
				child.grab_focus()
				grab_focus()
				break
