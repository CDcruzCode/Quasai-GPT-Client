extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	var net = MLNeuralNet.Network.new([
	Vector2(3,MLNeuralNet.ACTIVATOR.INPUT),
	Vector2(5,MLNeuralNet.ACTIVATOR.SIGMOID),
	Vector2(10,MLNeuralNet.ACTIVATOR.SIGMOID),
	Vector2(1,MLNeuralNet.ACTIVATOR.OUTPUT),
	])
	net.train([[0.1,0.1,3.2]], [[0.2]], 50)
	print( net.it_results )
