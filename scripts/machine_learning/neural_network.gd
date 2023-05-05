#extends Node
#
##var Activator = preload("res://modules/activation_functions.gd")
##var Tools = preload("res://modules/tool_functions.gd")
##var Cost = preload("res://modules/cost_functions.gd")
##var Backprop = preload("res://modules/backpropagation.gd")
#
#func _ready():
#	var multiplied = []
#
#	print(multiplied)
#
#	const LEARN_RATE = -0.01
#	var correct_count = 0
#	const EPOCHS = 1
#
#	var training_data = [
#	[0.3, 0.4, 1, 0.3, 0.1],
#	[0.1, 1, 0.2, 0.4, 0.9],
#	[1, 0.2, 0.4, 0.5, 0.2]
#	]
#
#	var training_labels = [
#	[1, 0, 0],
#	[0, 1, 0],
#	[0, 0, 1]
#	]
#
#	if training_data.size() != training_labels.size():
#		printerr("ERROR: Training data/labels mismatch. Both arrays must be of same size.")
#	if training_labels[0] == null or training_data[0] == null:
#		printerr("ERROR: Training Labels and Training Data must be in a 2D array!")
#
#	var input_node_size = training_data[0].size()
#	var hidden_node_size = [10]
#	var output_node_size = training_labels[0].size()
#	var layer_types = ["sigmoid", "sigmoid", "sigmoid"]
#
#	if layer_types.size() != hidden_node_size.size() + 2:
#		printerr("ERROR: Node size and layer types array do not match!")
#
#	var weights_matrix = []
#	var bias_matrix = []
#	var node_matrix = []
#
#
#
##	weights_matrix = init_weights_size(input_node_size, hidden_node_size, output_node_size)
##	bias_matrix = init_bias_size(input_node_size, hidden_node_size, output_node_size)
#
#	print(weights_matrix)
#	print(bias_matrix)
#
#	var loop_count = 0
#	for i in range(EPOCHS):
#		print("EPOCH: %d" % (i + 1))
#		for a in range(training_data.size()):
#			loop_count += 1
#			node_matrix = []
#
#		for b in range(hidden_node_size.size()):
#			node_matrix.append(
#			Tools.matrix_multiply_to_node(
#			weights_matrix[b],
#			[training_data[a]] if b == 0 else [node_matrix[node_matrix.size() - 1]]
#			)
#		)
#			node_matrix[b] = Tools.add_bias(node_matrix[b], bias_matrix[b])
#			node_matrix[b] = Tools.process_activators(node_matrix[b], layer_types[b])
#
#		var output_nodes = Tools.matrix_multiply_to_node(weights_matrix[hidden_node_size.size()], [node_matrix[node_matrix.size() - 1]])
#		output_nodes = Tools.add_bias(output_nodes, bias_matrix[hidden_node_size.size()])
#		output_nodes = Tools.process_activators(output_nodes, layer_types[hidden_node_size.size()])
#		node_matrix.append(output_nodes)
#
#		if Tools.approxeq(node_matrix[node_matrix.size() - 1][0], training_data[a][0], 0.1):
#			correct_count += 1
#
#	print("Loop Total: %d" % loop_count)
#	print("Correct Guesses: %d" % correct_count)
#	print(weights_matrix)
#	print(bias_matrix)
#	print(node_matrix)
#
#
##	func init_bias_size(input_size, hidden_size, output_size):
##		bias_matrix = [Tools.init_bias(size) for size in hidden_size]
##		bias_matrix.append(Tools.init_bias(output_size))
##		return bias_matrix
##
##	func init_weights_size(input_size, hidden_size, output_size):
##		weights_matrix = [Tools.init_weights(size, input_size if idx == 0 else hidden_size[idx - 1]) for idx in range(hidden_size.size())]
##		weights_matrix.append(Tools.init_weights(output_size, hidden_size[hidden_size.size() - 1]))
##		return weights_matrix
