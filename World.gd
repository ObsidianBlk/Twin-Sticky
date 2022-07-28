extends Node2D


onready var vp2c : ViewportContainer = $GameView/Viewports/VP2C
onready var viewport_p1 : Viewport = $GameView/Viewports/VP1C/Viewport_P1
onready var viewport_p2 : Viewport = $GameView/Viewports/VP2C/Viewport_P2


func _ready() -> void:
	# TODO: Listen for a signal that enables/disabled local player 2
	viewport_p2.world = viewport_p1.world


func _on_local_player2(enable : bool) -> void:
	vp2c.visible = enable
