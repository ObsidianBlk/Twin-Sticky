extends Spatial



# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var target_group : String = ""
export var height : float = 0.0


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _target : WeakRef = null

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
		var target : Spatial = _target.get_ref()
		if target:
			transform.origin = target.transform.origin
		else:
			_target = null
	else:
		_UpdateTargetNode()

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _UpdateTargetNode() -> void:
	if target_group != "":
		var _tg : String = target_group
		if get_tree().has_network_peer():
			var remote_pid = get_tree().get_network_unique_id()
			_tg = "%s_%s"%[_tg, remote_pid]
		#print("Target Group: ", _tg)
		var nodes : Array = get_tree().get_nodes_in_group(_tg)
		if nodes.size() > 0:
			_target = weakref(nodes[0])
	else:
		_target = null
