class_name MLNeuralNet extends Node

enum N_TYPE {
	INPUT,
	OUTPUT,
	BIAS,
	FUNCTION
}

enum ACTIVATOR {
	INPUT,
	OUTPUT,
	SIGMOID,
	RELU
}

class Network:
	var topology:PackedVector2Array
	var error_accumulation:float = 0.0
	var net_size:int
	var layers_container:Array
	
	var it_results:Array
	
	func _init(layers:PackedVector2Array):
		print("[MLNeuralNet] Init")
		topology = layers
		net_size = topology.size()
		
		print(topology)
		
		for l in topology.size():
			
			var new_layer:Array = []
			for n in topology[l][0]+1: #Neuron Size. Plus 1 for the Bias Node
				if(l == 0):
					#INPUT LAYER NEURONS
					var input_n = Neuron.new( N_TYPE.INPUT, ACTIVATOR.INPUT )
					input_n.output_weight = randf_range(-1.0, 1.0)
					new_layer.append( input_n )
					continue
				
				if(l == topology.size()-1 && n == topology[l][0]):
					#When setting up Output layer, skip adding the Bias neuron.
					continue
				
				if(n == topology[l][0]): #Last neuron to add in layer. Does not add a bias to the output layer
					#ADD BIAS NEURON
					var input_n = Neuron.new( N_TYPE.BIAS, ACTIVATOR.INPUT )
					input_n.output_weight = 0.0
					new_layer.append( input_n )
					continue
				
				#ALL OTHER NEURONS
				var input_n = Neuron.new( N_TYPE.FUNCTION, topology[l][1] ) 
				input_n.output_weight = randf_range(-1.0, 1.0)
				new_layer.append( input_n )
			
			layers_container.append(new_layer)
	
	
	func train(input_arr:Array, target_arr:Array, cycles:int = 1) -> Error:
		if(typeof(input_arr[0]) != TYPE_ARRAY || typeof(target_arr[0]) != TYPE_ARRAY):
			printerr("INPUT ARRAY MUST BE A 2D ARRAY")
			return FAILED
		
		if(input_arr[0].size() != layers_container[0].size()-1): #Minus 1 because all layers have an extra Bias node
			printerr("INPUT SIZE DOES NOT MATCH INPUT NEURONS SIZE. INPUT: "+str(input_arr.size())+" | NEURONS: "+str(layers_container[0].size()-1))
			return FAILED
		
		if(target_arr[0].size() != layers_container[layers_container.size()-1].size()):
			printerr("TARGET SIZE DOES NOT MATCH OUTPUT NEURONS SIZE. INPUT: "+str(target_arr[0].size())+" | NEURONS: "+str(layers_container[layers_container.size()-1].size()))
			return FAILED
		
		for c in cycles:
			for d in input_arr.size():
				feed_forward(input_arr[d])
				back_propagation(target_arr[d])
				get_output_values()
				print(it_results)
		
		return OK
	
	func feed_forward(input_arr:Array) -> void:
		
		#Setting input nodes
		for i in input_arr.size():
			layers_container[0][i].output_value = input_arr[i]

		#Processing hidden layers
		for l in range( 1, net_size): #Skip input layer
			
			for n in layers_container[l].size():
				if(layers_container[l][n].neuron_type == N_TYPE.BIAS):
					continue #Skip changing Bias Node's output in this section
				layers_container[l][n].activate(layers_container[l-1])
	
	
	func back_propagation(target_arr) -> void:
		var iteration_error:float = 0.0
		#Calculate overall net error (Using Root Mean Squared function)
		var output_layer:Array = layers_container[layers_container.size()-1]
		for n in output_layer.size(): #Not including Bias Node
			var delta:float = target_arr[n] - output_layer[n].output_value
			iteration_error += delta*delta
		
		iteration_error = iteration_error / output_layer.size() #Get average error squared
		iteration_error = sqrt(iteration_error) #RMS
		print("It Error: "+str(iteration_error))
		
		#Implement a recent average measurement
		
#		var recent_average_error:float = 
		
		#calculate output layer gradients
		for n in output_layer.size()-1:
			output_layer[n].calc_output_gradients(target_arr[n])
		
		#calculate hidden layer gradients
		for l in range( 1, layers_container.size()-2):
			var hidden_layer:Array = layers_container[l]
			var next_layer:Array = layers_container[l+1]
			
			for n in hidden_layer.size():
				hidden_layer[n].calc_hidden_gradients(next_layer)
		
		
		#Update all connection weights
		for l in range( 1, layers_container.size()-1):
			var layer:Array = layers_container[l]
			var prev_layer:Array = layers_container[l-1]
			
			for n in layer.size()-1:
				layer[n].update_input_weights(prev_layer)
	
	
	func get_output_values() -> void:
		var output_layer:Array = layers_container[layers_container.size()-1]
		var output_arr:PackedFloat64Array = []
		for n in output_layer.size():
			output_arr.append( output_layer[n].output_value )
		
		it_results = output_arr









class Neuron:
	var neuron_type:int
	var func_type:int

	var output_value:float = 0.0
	var output_weight:float = 0.0
	var delta_weight:float = 0.1
	
	var gradient:float = 0.0
	var eta:float = 0.15 #overall net learning rate
	var alpha:float = 0.5 #momentum, multipler of last delta weights

	func _init(n_type:int, n_func:int):
		print("[Neuron] Init.")
		neuron_type = n_type
		func_type = n_func
		pass
	
	func activate(prev_layer:Array) -> void:
		var sum:float = 0.0
		
		#Sum the previous lawyer's outputs (This layers inputs)
		#Include the bias node from previous layer
		
		for n in prev_layer.size()-1:
			sum += prev_layer[n].output_value * prev_layer[n].output_weight
		
		output_value = ActivatorFuncs.tanh(sum)
		return
	
	
	func calc_output_gradients(target_value:float):
		var delta:float = target_value - output_value
		var gradient:float = delta * ActivatorFuncs.tanh_d(output_value)
	
	func calc_hidden_gradients(next_layer:Array):
		var dow:float = sum_DOW(next_layer)
		gradient = dow * ActivatorFuncs.tanh_d(output_value)
	
	
	func sum_DOW(next_layer:Array):
		var sum:float = 0.0
		
		#Sum our contributions of the errors at the nodes we feed
		for n in next_layer.size()-1:
			sum += output_weight * next_layer[n].gradient
		
		return sum
	
	
	func update_input_weights(prev_layer:Array):
		for n in prev_layer.size(): #Including bias
			var this_neuron:Neuron = prev_layer[n]
			var old_delta_weight:float = this_neuron.delta_weight
			var new_delta_weight:float = eta * this_neuron.output_value * gradient + alpha * old_delta_weight
			
#			print("DELTA: "+str(new_delta_weight))
			this_neuron.delta_weight = old_delta_weight
			this_neuron.output_weight += new_delta_weight




class ActivatorFuncs:
	static func scale_value(old_value: float, old_min: float, old_max: float, new_min: float, new_max: float) -> float:
		return ((old_value - old_min) / (old_max - old_min)) * (new_max - new_min) + new_min
	
	
	static func binary_step(x, threshold = 0):
		return 1 if x > threshold else threshold
	
	static func sigmoid(x: float) -> float:
		return 1.0 / (1.0 + exp(-x))
	
	static func tanh(x: float) -> float:
		var e = 2.71828
		return (pow(e, x) - pow(e, -x)) / (pow(e, x) + pow(e, -x))
	
	static func tanh_d(x:float) -> float:
		#A quick approximation of the Tanh Derivative
		return 1.0 - x*x
	
	static func relu(x:float) -> float:
		return x if x > 0 else 0
	
	static func leaky_relu(x: float, alpha: float = 0.01) -> float:
		return x if x >= 0 else alpha * x
	
	static func swish(x: float, beta: float = 1.0) -> float:
		return x * sigmoid(beta * x)
	
	static func softmax(values: Array) -> Array:
		var max_value = max(values)
		var sum = 0.0
		for value in values:
			sum += exp(value - max_value)
	
		var result = []
		for value in values:
			result.append(exp(value - max_value) / sum)
		return result
	
	static func SELU(x: float, alpha: float = 1.67326, scale: float = 1.0507) -> float:
		return scale * x if x > 0 else scale * (alpha * (exp(x) - 1))
	
	static func ELU(x: float, alpha: float = 1.0) -> float:
		return x if x > 0 else alpha * (exp(x) - 1)
	
	static func prelu(x: float, alpha: float = 0.25) -> float:
		return x if x >= 0 else alpha * x
