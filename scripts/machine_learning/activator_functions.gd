func binary_step(x, threshold = 0):
	return 1 if x > threshold else threshold

func sigmoid(x):
	return 1 / (1 + pow(2.71828, -x))

func tanh(x):
	return (pow(2.71828, x) - pow(2.71828, -x)) / (pow(2.71828, x) + pow(2.71828, -x))

func relu(x):
	return x if x > 0 else 0

func leaky_relu(x):
	return max(0.1 * x, x)
