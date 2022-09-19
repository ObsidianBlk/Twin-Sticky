tool
extends Popup
class_name RadialMenu

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var outer_radius : float = 42.0							setget set_outer_radius
export var inner_radius : float = 20.0							setget set_inner_radius
export (float, 0.0, 360.0) var offset_angle : float = 0.0		setget set_offset_angle
export (float, 0.0, 10.0, 0.001) var gap_degrees : float = 0.2	setget set_gap_degrees
export var force_neighboring : bool = true

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _relative_coords : Vector2 = Vector2.ZERO

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_outer_radius(r : float) -> void:
	if r > inner_radius and outer_radius != r:
		outer_radius = r
		#_AdjustSize()
		_AdjustRadialButtons()

func set_inner_radius(r : float) -> void:
	if r < outer_radius and inner_radius != r:
		inner_radius = r
		#_AdjustSize()
		_AdjustRadialButtons()

func set_offset_angle(a : float) -> void:
	if a > 360.0:
		a = fmod(a, 360.0)
	offset_angle = a
	_AdjustRadialButtons()

func set_gap_degrees(g : float) -> void:
	if g >= 0.0 and g <= 10.0 and gap_degrees != g:
		gap_degrees = g
		_AdjustRadialButtons()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_focus_mode(Control.FOCUS_ALL)
	get_tree().get_root().connect("size_changed", self, "_on_screen_size_changed")
	connect("child_entered_tree", self, "_on_child_entered")
	connect("child_exiting_tree", self, "_on_child_exited")
	connect("about_to_show", self, "_on_about_to_show")
	#_AdjustSize()
	_AdjustRadialButtons()

#func _notification(what : int) -> void:
#	match what:
#		NOTIFICATION_POST_POPUP:
#			grab_focus()
#			print("Focused Control: ", get_focus_owner())

func _gui_input(event : InputEvent) -> void:
	var processed : bool = false
	for child in get_children():
		if child is RadialButton:
			if not processed:
				processed = child._ProcessGUIInput(event)
			else:
				child._ProcessGUIInput(event, true)
	if processed:
		accept_event()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
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
		var arc : float = (360.0 - (gap_degrees * float(count))) / float(count)
		var hgap : float = 0 if count <= 1 else gap_degrees * 0.5
		
		var start_degree : float = hgap
		var first_child = null
		var last_child = null
		for child in get_children():
			if child is RadialButton:
				child.set_radii(inner_radius, outer_radius)
				child.set_arc_degrees(start_degree, start_degree + arc)
				child.offset_degree = offset_angle
				start_degree += arc + gap_degrees
				if force_neighboring:
					if first_child == null:
						first_child = child
					else:
						_SetNeighbors(last_child, child)
					last_child = child
		if first_child != null and last_child != null:
			_SetNeighbors(last_child, first_child)

func _RecalcScreenSize() -> void:
	rect_size = get_viewport_rect().size
	_AdjustRadialButtonPosition()

func _AdjustRadialButtonPosition() -> void:
	var cpos : Vector2 = (rect_size * _relative_coords) - Vector2(outer_radius, outer_radius)
	for child in get_children():
		if child is RadialButton:
			child.rect_position = cpos
#func _AdjustSize() -> void:
#	rect_size = Vector2(outer_radius * 2, outer_radius * 2)


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func popup(rect : Rect2 = Rect2(0,0,0,0)) -> void:
	.popup(Rect2(0,0,0,0))
	if rect_size.x > 0.0 and rect_size.y > 0.0:
		_relative_coords = Vector2(
			rect.position.x / rect_size.x,
			rect.position.y / rect_size.y
		)
	else:
		_relative_coords = Vector2.ZERO
	_AdjustRadialButtonPosition()

func popup_centered(size : Vector2 = Vector2.ZERO) -> void:
	.popup_centered(Vector2.ZERO)
	_relative_coords = Vector2(0.5, 0.5)
	_AdjustRadialButtonPosition()

func add_radial_button(btn_name : float) -> void:
	if not Engine.editor_hint:
		var btn = RadialButton.new()
		btn.name = btn_name
		add_child(btn)

func has_focus() -> bool:
	for child in get_children():
		if child is RadialButton:
			if child.has_focus():
				return true
	return false

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_screen_size_changed() -> void:
	# Have to defer the call or the screen doesn't adjust properly.
	call_deferred("_RecalcScreenSize")


func _on_child_entered(child : Node) -> void:
	if child is RadialButton:
		_AdjustRadialButtons()

func _on_child_exited(child : Node) -> void:
	if child is RadialButton:
		_AdjustRadialButtons()

func _on_about_to_show() -> void:
	if not has_focus():
		for child in get_children():
			if child is RadialButton:
				print("Setting focus")
				child.grab_focus()
				grab_focus()
				break
