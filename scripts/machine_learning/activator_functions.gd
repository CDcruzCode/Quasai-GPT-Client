func binary_step(x, threshold = 0):
	return 1 if x > threshold else threshold

#func sigmoid(x):
#	return 1 / (1 + pow(2.71828, -x))

func sigmoid(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))

func tanh(x: float) -> float:
	var e = 2.71828
	return (pow(e, x) - pow(e, -x)) / (pow(e, x) + pow(e, -x))

func relu(x:float) -> float:
	return x if x > 0 else 0

#func leaky_relu(x):
#	return max(0.1 * x, x)

func leaky_relu(x: float, alpha: float = 0.01) -> float:
	return x if x >= 0 else alpha * x

func swish(x: float, beta: float = 1.0) -> float:
	return x * sigmoid(beta * x)

func softmax(values: Array) -> Array:
	var max_value = max(values)
	var sum = 0.0
	for value in values:
		sum += exp(value - max_value)

	var result = []
	for value in values:
		result.append(exp(value - max_value) / sum)
	return result

func SELU(x: float, alpha: float = 1.67326, scale: float = 1.0507) -> float:
	return scale * x if x > 0 else scale * (alpha * (exp(x) - 1))

static func ELU(x: float, alpha: float = 1.0) -> float:
	return x if x > 0 else alpha * (exp(x) - 1)

func prelu(x: float, alpha: float = 0.25) -> float:
	return x if x >= 0 else alpha * x
