extends Control


export var uid : int = 0


func _input(event : InputEvent) -> void:
	if not MUI.is_user_event(uid, event):
		print("Not My Event! ", uid)
		accept_event()
	else:
		print("Yum yum! ", uid)
