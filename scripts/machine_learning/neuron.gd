#class_name MLNeuron extends Node
#
#var neuron_type:int
#var func_type:int
#
#var output_value:float
#var input_weights:float
#
#func _notification(what):
#	if what == NOTIFICATION_PREDELETE:
#		# destructor logic
#		pass
#
#func _init(n_type:int, n_func:int, output_size:int):
#	print("[MLNeuron] Init")
#	neuron_type = n_type
#	func_type = n_func
#	pass
#
#func rand_weight(rand_max:float):
#	return randf_range(0, rand_max)
