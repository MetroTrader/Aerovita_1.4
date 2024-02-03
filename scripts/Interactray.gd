extends RayCast3D

@onready var prompt = $Prompt

func _ready():
	add_exception(owner)
