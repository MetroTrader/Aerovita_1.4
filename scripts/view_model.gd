extends Camera3D

@onready var weapons_manager = $Weapons_Manager

@onready var fps_rig = $Weapons_Manager/fps_rig


var initial_fps_rig_transform = Transform3D()
var sway_accumulator = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	initial_fps_rig_transform = fps_rig.transform.origin

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	fps_rig.transform.origin = lerp(fps_rig.transform.origin, initial_fps_rig_transform, delta * 6)
	fps_rig.transform.origin.x += sway_accumulator.x
	fps_rig.transform.origin.y += sway_accumulator.y

func sway(sway_amount):
	sway_accumulator.x = -sway_amount.x * 0.00005
	sway_accumulator.y = sway_amount.y * 0.00005

