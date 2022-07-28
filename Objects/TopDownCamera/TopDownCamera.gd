extends Spatial



# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var target_group : String = ""
export var height : float = 0.0


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _target : Spatial = null

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var camera_node : Camera = $Camera


# -----------------------------------------------------------------------------
# Setters
# -----------------------------------------------------------------------------
func set_target_group(g : String) -> void:
	target_group = g
	_UpdateTargetNode()

func set_height(h : float) -> void:
	if h >= 0.0:
		height = h
		if camera_node:
			camera_node.transform.origin.y = height


# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	camera_node.transform.origin.y = height
	_UpdateTargetNode()

func _physics_process(_delta : float) -> void:
	if _target != null:
		transform.origin = _target.transform.origin
	else:
		_UpdateTargetNode()

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _UpdateTargetNode() -> void:
	if target_group != "":
		var nodes : Array = get_tree().get_nodes_in_group(target_group)
		if nodes.size() > 0:
			_target = nodes[0]
	else:
		_target = null
