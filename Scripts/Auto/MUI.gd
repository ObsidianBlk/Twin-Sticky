extends Node


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const UI_ACTION_BASE_NAME : String = "ui_"
enum DEVICE_TYPE {Keyboard=0, Joypad=1}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _mu_ui_action_names : Array = []
var _mu_input_action_names : Array = []
var _users : Array = []


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	pass


func _input(event : InputEvent) -> void:
	for ui in _mu_ui_action_names:
		if _users[ui.uid].ui_control != null:
			if event.is_action_pressed(ui.action):
				var success : bool = true
				match ui.core_action:
					"ui_accept":
						pass
					"ui_select":
						pass
					"ui_cancel":
						pass
					"ui_focus_next":
						pass
					"ui_focus_prev":
						pass
					"ui_left":
						pass
					"ui_right":
						pass
					"ui_up":
						pass
					"ui_down":
						pass
					"ui_page_up":
						pass
					"ui_page_down":
						pass
					"ui_home":
						pass
					"ui_end":
						pass
				var st : SceneTree = get_tree()
				if st and success:
					st.set_input_as_handled()


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------

func register_action_name(action_name : String) -> int:
	if not InputMap.has_action(action_name):
		return ERR_DOES_NOT_EXIST
	if _mu_input_action_names.find(action_name) < 0:
		_mu_input_action_names.append(action_name)
	return OK

func set_user_count(count : int) -> int:
	if count <= 0:
		return ERR_PARAMETER_RANGE_ERROR
	if _users.size() > 0:
		return ERR_ALREADY_IN_USE
	for _i in range(count):
		_users.append(null)
	return OK

func get_user_count() -> int:
	return _users.size()

func clear_user_count() -> void:
	for i in range(_users.size()):
		var _res : int = clear_user_input_device(i)
	_users.clear()

func is_uid_valid(uid : int) -> bool:
	return uid >= 0 and uid < _users.size()

func is_user_assigned_device(uid : int) -> bool:
	if uid >= 0 and uid < _users.size():
		return _users[uid] != null
	return false

func get_user_device_type(uid : int) -> int:
	if uid >= 0 and uid < _users.size():
		if _users[uid] != null:
			return _users[uid].device_type
	return -1

func get_user_device_id(uid : int) -> int:
	if uid >= 0 and uid < _users.size():
		if _users[uid] != null:
			return _users[uid].device_id
	return -1

func get_user_device_info(uid : int) -> Dictionary:
	if uid >= 0 and uid < _users.size():
		if _users[uid] != null:
			return {
				"device_type":_users[uid].device_type,
				"device_id":_users[uid].device_id
			}
	return {"device_type": -1, "device_id": -1}

func get_unassigned_user_id() -> int:
	for uid in range(_users.size()):
		if _users[uid] == null:
			return uid
	return -1

func device_user(device_type : int, device_id : int = 0) -> int:
	for i in range(_users.size()):
		if _users[i] != null and _users[i].device_type == device_type:
			if device_type == DEVICE_TYPE.Joypad:
				if _users[i].device_id == device_id:
					return i
			else:
				return i
	return -1

func joypad_device_in_use(device_id : int) -> bool:
	return device_user(DEVICE_TYPE.Joypad, device_id) >= 0

func keyboard_device_in_use() -> bool:
	return device_user(DEVICE_TYPE.Keyboard) >= 0

func assign_user_input_device(uid : int, device_type : int, device_id : int = 0) -> int:
	# Is user ID valid
	if not (uid >= 0 and uid < _users.size()):
		return ERR_PARAMETER_RANGE_ERROR
	# Is Device type valid
	if DEVICE_TYPE.values().find(device_type) < 0:
		return ERR_DOES_NOT_EXIST
	# If device is joypad is the device_id valid
	if device_type == DEVICE_TYPE.Joypad:
		if Input.get_joy_name(device_id) == "":
			return ERR_DOES_NOT_EXIST
	# Check to see if user already assigned device
	var duid : int = device_user(device_type, device_id)
	if duid >= 0: # If user is assigned
		if duid != uid: # and assigned user is not the given user
			return ERR_ALREADY_IN_USE
		# Otherwise given user already assigned device, nothing to do
		return OK
	# Check if given user is currently assigned a device
	if _users[uid] != null:
		# Clear user device assignment
		var _res : int = clear_user_input_device(uid)
	
	_users[uid] = {
		"device_type":device_type,
		"device_id":device_id,
		"ui_control":null
	}
	
	for action_name in InputMap.get_actions():
		var naction_name : String = "%s_%s"%[action_name, String(uid+1)]
		if action_name.begins_with(UI_ACTION_BASE_NAME) or _mu_input_action_names.find(action_name) >= 0:
			for input in InputMap.get_action_list(action_name):
				match device_type:
					DEVICE_TYPE.Keyboard:
						if input.get_class() == "InputEventKey":
							var kinput : InputEventKey = input.duplicate()
							if not InputMap.has_action(naction_name):
								InputMap.add_action(naction_name)
							InputMap.action_add_event(naction_name, kinput)
							if naction_name.begins_with(UI_ACTION_BASE_NAME):
								_mu_ui_action_names.append({"action":naction_name, "core_action":action_name, "uid":uid})
					DEVICE_TYPE.Joypad:
						var icls = input.get_class()
						if icls == "InputEventJoypadButton" or icls == "InputEventJoypadMotion":
							var jinput = input.duplicate()
							jinput.device = device_id
							if not InputMap.has_action(naction_name):
								InputMap.add_action(naction_name)
							InputMap.action_add_event(naction_name, jinput)
							if naction_name.begins_with(UI_ACTION_BASE_NAME):
								_mu_ui_action_names.append({"action":naction_name, "core_action":action_name, "uid":uid})
	return OK


func clear_user_input_device(uid : int) -> int:
	if not (uid >= 0 and uid < _users.size()):
		return ERR_PARAMETER_RANGE_ERROR
	if _users[uid] != null:
		for action_name in InputMap.get_actions():
			var naction_name : String = "%s_%s"%[action_name, String(uid+1)]
			if naction_name.begins_with(UI_ACTION_BASE_NAME) or _mu_input_action_names.find(action_name) >= 0:
				if InputMap.has_action(naction_name):
					InputMap.erase_action(naction_name)
					if naction_name.begins_with(UI_ACTION_BASE_NAME):
						for i in range(_mu_ui_action_names.size()):
							if _mu_ui_action_names[i].action == naction_name:
								_mu_ui_action_names.remove(i)
								break
	return OK

func clear_all_user_input_devices() -> void:
	for uid in range(_users.size()):
		var _res : int = clear_user_input_device(uid)





