extends "res://UI/BaseUI.gd"


# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var slide_out : bool = true
export var slide_duration : float = 0.25		setget set_slide_duration
export var print_to_console : bool = false

export var text_color : Color = Color.gray
export var timestamp_color : Color = Color.blanchedalmond
export var info_color : Color = Color.cadetblue
export var debug_color : Color = Color.coral
export var warning_color : Color = Color.darkorange
export var error_color : Color = Color.crimson

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _on_screen : bool = false
var _entry_handled : bool = false

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var tween_node : Tween = $Tween
onready var rtl_node : RichTextLabel = $RichTextLabel

# -----------------------------------------------------------------------------
# Setters / Getters
# -----------------------------------------------------------------------------
func set_slide_duration(d : float) -> void:
	if d >= 0.0:
		slide_duration = d

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	var _res : int = connect("resized", self, "_on_resized")
	_res = Log.connect("entry_logged", self, "_on_entry_logged")
	_res = Log.connect("log_changed", self, "_on_log_changed")
	_UpdateSizePosition(OS.window_size)


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _UpdateSizePosition(win_size : Vector2) -> void:
	if tween_node.is_active():
		var dest : Vector2 = Vector2.ZERO if _on_screen else Vector2(0, -rect_min_size.y)
		var dist : float = dest.distance_to(rect_position)
		var trans_percent : float = dist / rect_min_size.y
		
		rect_min_size = Vector2(win_size.x, win_size.y * 0.5)
		rect_position = Vector2(0, -(rect_min_size.y * trans_percent))
		dest = Vector2.ZERO if _on_screen else Vector2(0, -rect_min_size.y)
		
		var dur : float = slide_duration * (1.0 - trans_percent)
		var _res : int = tween_node.reset_all()
		_res = tween_node.interpolate_property(
			self, "rect_position",
			rect_position, dest,
			dur,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		_res = tween_node.start()
	else:
		rect_min_size = Vector2(win_size.x, win_size.y * 0.5)
		rect_position = Vector2.ZERO if _on_screen else Vector2(0, -rect_min_size.y)
		#print("Size: ", rect_min_size)

func _ToggleOnScreen(instant : bool = false) -> void:
	if instant:
		var _res : int = tween_node.stop_all()
		rect_position = Vector2.ZERO if not _on_screen else Vector2(0, -rect_min_size.y)
		_on_screen = not _on_screen
	else:
		var trans_percent : float = 0.0
		if tween_node.is_active():
			var dest : Vector2 = Vector2.ZERO if _on_screen else Vector2(0, -rect_min_size.y)
			var dist : float = dest.distance_to(rect_position)
			trans_percent = dist / rect_min_size.y
		
		var dur : float = slide_duration * (1.0 - trans_percent)
		var dest : Vector2 = Vector2.ZERO if not _on_screen else Vector2(0, -rect_min_size.y)
		var _res : int = tween_node.reset_all()
		_res = tween_node.interpolate_property(
			self, "rect_position",
			rect_position, dest,
			dur,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		_res = tween_node.start()
		_on_screen = not _on_screen

func _GetPriorityColor(p : int) -> Color:
	match p:
		1: # Info
			return info_color
		2: # Debug
			return debug_color
		4: # Warning
			return warning_color
		8: # Error
			return error_color
	return text_color

func _Print(entry : Dictionary) -> void:
	var time : Dictionary = OS.get_datetime_from_unix_time(entry.timestamp)
	var timestr : String = "{hour}:{minute}:{second}".format(time)
	if print_to_console:
		if entry.priority == Log.PRIORITY.Warning or entry.priority == Log.PRIORITY.Error:
			printerr("[", timestr, "] ", entry.priority_name, ": ", entry.message)
		else:
			print("[", timestr, "] ", entry.priority_name, ": ", entry.message)
	if rtl_node.get_line_count() > 0:
		rtl_node.newline()
	rtl_node.push_color(text_color)
	rtl_node.add_text("[")
	rtl_node.push_color(timestamp_color)
	rtl_node.add_text(timestr)
	rtl_node.push_color(text_color)
	rtl_node.add_text("] ")
	rtl_node.push_color(_GetPriorityColor(entry.priority))
	rtl_node.add_text(entry.priority_name + ": ")
	rtl_node.push_color(text_color)
	rtl_node.add_text(entry.message)
	if rtl_node.get_line_count() > Log.get_max_entries():
		var _res : int = rtl_node.remove_line(0)
	
	

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_resized() -> void:
	_UpdateSizePosition(OS.window_size)

func _on_entry_logged(entry : Dictionary) -> void:
	_Print(entry)
	_entry_handled = true

func _on_log_changed() -> void:
	if not _entry_handled:
		rtl_node.clear()
		var sf : bool = rtl_node.scroll_following
		rtl_node.scroll_following = true
		for entry in Log.get_entries():
			_Print(entry)
		rtl_node.scroll_following = sf
	else:
		_entry_handled = false

func _on_menu_requested(ui_name : String) -> void:
	if self.name == ui_name:
		_ToggleOnScreen()

