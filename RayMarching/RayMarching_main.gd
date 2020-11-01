extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var controlGroup = $Objects
onready var tracer = $Control/ColorRect.material
onready var player = $Player/Player

const max_objs = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var t = 0
func _process(delta):
	$Objects/CSGBox.translation = Vector3(0, sin(t/100.0), 0)
	var ind = 1
	for i in controlGroup.get_children():
		if i.visible:
			if i.get_class() == "CSGBox":
				var na = "item" + str(ind)
				tracer.set_shader_param(na + "_t", 1)
				tracer.set_shader_param(na + "_loc", i.global_transform.origin)
				tracer.set_shader_param(na + "_scale", i.scale)
	#			print("object #" + str(ind) + " set")
				ind += 1
				ind = ind % max_objs
				t += 1
			elif i.get_class() == "CSGSphere":
				var na = "item" + str(ind)
				tracer.set_shader_param(na + "_t", 1)
				tracer.set_shader_param(na + "_loc", i.global_transform.origin)
				tracer.set_shader_param(na + "_scale", i.scale)
	#			print("object #" + str(ind) + " set")
				ind += 1
				ind = ind % max_objs
				t += 1
#	tracer.set_shader_param("cameraPos", player.global_transform.origin)
