extends "res://UI/BaseUI.gd"

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal close_game()


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var choice_node : Control = $Choice
onready var host_node : Control = $Host
onready var join_node : Control = $Join


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_on_cancel_netop()
	var _res : int = $"%OpCancel".connect("pressed", self, "_on_option_cancel_pressed")
	_res = $"%JoinCancel".connect("pressed", self, "_on_cancel_netop")
	_res = $"%HostCancel".connect("pressed", self, "_on_cancel_netop")
	
	_res = $"%OpHost".connect("pressed", self, "_on_option_host_pressed")
	_res = $"%OpJoin".connect("pressed", self, "_on_option_join_pressed")
	
	_res = $"%Host".connect("pressed", self, "_on_host")
	_res = $"%Join".connect("pressed", self, "_on_join")

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_option_cancel_pressed() -> void:
	emit_signal("close_menu")

func _on_cancel_netop() -> void:
	host_node.visible = false
	join_node.visible = false
	# TODO: Reset all options to their default values. I'm just being lazy right now.
	choice_node.visible = true

func _on_option_host_pressed() -> void:
	choice_node.visible = false
	host_node.visible = true

func _on_option_join_pressed() -> void:
	choice_node.visible = false
	join_node.visible = true

func _on_host() -> void:
	if not $"%HostPort".text.is_valid_integer():
		return
	emit_signal("close_game")
	if Net.host_game($"%PlayerSlider".value, $"%HostPort".text.to_int()) == OK:
		emit_signal("close_menu")

func _on_join() -> void:
	if not $"%JoinAddress".text.is_valid_ip_address():
		return
	if not $"%JoinPort".text.is_valid_integer():
		return
	emit_signal("close_game")
	if Net.join_game($"%JoinAddress".text, $"%JoinPort".text.to_int()) == OK:
		emit_signal("close_menu")



