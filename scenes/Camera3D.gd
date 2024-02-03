extends Camera3D

@onready var fps_rig = $fps_rig

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	fps_rig.position.x = lerp(fps_rig.position.x,0,delta*5)
	fps_rig.position.y = lerp(fps_rig.position.y,0,delta*5)
	
func sway (sway_amount):
	fps_rig.position.x += sway_amount.x*0.0005
	fps_rig.position.y += sway_amount.y*0.0005
