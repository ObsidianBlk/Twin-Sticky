extends Node

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal entry_logged(entry)
signal log_changed()

# -----------------------------------------------------------------------------
# Constants and ENUMs
# -----------------------------------------------------------------------------
enum PRIORITY {Info=1, Debug=2, Warning=4, Error=8}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _entries : Array = []
var _max_entries : int = 5000
var _enabled_priority = 15

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _PriorityNameFromCode(p : int) -> String:
	for key in PRIORITY.keys():
		if PRIORITY[key] == p:
			return key
	return ""

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func set_max_entries(me : int) -> void:
	if me > 0:
		_max_entries = me
		if _entries.size() >= _max_entries:
			var start : int = _entries.size() - _max_entries
			var end : int = _entries.size() - 1
			_entries = _entries.slice(start, end)
			emit_signal("log_changed")

func get_max_entries() -> int:
	return _max_entries

func get_entry_count() -> int:
	return _entries.size()

func get_entry(idx : int) -> Dictionary:
	var re : Dictionary = {}
	if idx >= 0 and idx < _entries.size():
		var entry : Dictionary = _entries[idx]
		for key in entry.keys():
			re[key] = entry[key]
	return re

func get_entries(start : int = 0, count : int = -1) -> Array:
	if count < 0:
		count = _entries.size()
	
	var ent : Array = []
	var size : int = _entries.size()
	if start >= 0 and start < size:
		for i in range(count):
			if start + i >= size:
				break
			ent.append(get_entry(start + i))
	return ent

func entry(priority : int, message : String, metadata = null) -> void:
	if PRIORITY.values().find(priority) < 0:
		return
	if (priority & _enabled_priority) <= 0:
		return
	
	var e : Dictionary = {
		"timestamp": OS.get_unix_time(),
		"priority": priority,
		"priority_name": _PriorityNameFromCode(priority),
		"message": message,
		"meta": metadata
	}
	_entries.append(e)
	if _entries.size() >= _max_entries:
		_entries.pop_front()
	emit_signal("entry_logged", e)
	emit_signal("log_changed")

func info(message : String, metadata = null) -> void:
	entry(PRIORITY.Info, message, metadata)

func debug(message : String, metadata = null) -> void:
	entry(PRIORITY.Debug, message, metadata)

func warning(message : String, metadata = null) -> void:
	entry(PRIORITY.Warning, message, metadata)

func error(message : String, metadata = null) -> void:
	entry(PRIORITY.Error, message, metadata)

func remove(idx : int) -> void:
	if idx >= 0 and idx < _entries.size():
		_entries.remove(idx)
		emit_signal("log_changed")

func clear() -> void:
	_entries.clear()
	emit_signal("log_changed")


