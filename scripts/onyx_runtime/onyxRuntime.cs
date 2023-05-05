using BERTTokenizers;
using Microsoft.ML.Data;
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using System;


using System.Numerics.Tensors;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using Godot;
using System.Collections.Generic;
//using Image<Rgb24> image = Image.Load<Rgb24>(imageFilePath, out IImageFormat format);


public partial class onyxRuntime : Node
{
	public override void _Ready()
	{
		GD.Print("[onyxRuntime] Hello from C# to Godot :)");

		//Main("C:\\SYNC_folder\\Sync\\windows\\programming\\game_dev\\godot\\ChatGPT_client\\scripts\\onyx_runtime\\FasterRCNN-10.onnx", "C:\\SYNC_folder\\Sync\\windows\\programming\\game_dev\\godot\\ChatGPT_client\\scripts\\onyx_runtime\\demo.jpg", "C:\\SYNC_folder\\Sync\\windows\\programming\\game_dev\\godot\\ChatGPT_client\\scripts\\onyx_runtime\\output.jpg");
	}


	/*static void Main(string[] args)
		{
			// Load the ONNX model from a file
			string modelPath = "res://scripts/onyx_runtime/mnist-1.onnx";
			using var session = new InferenceSession(modelPath);

			// Prepare input data (replace this with your actual input)
			var inputData = new float[] { 1.0f, 2.0f, 3.0f };
			var inputTensor = new DenseTensor<float>(inputData, new[] { 1, inputData.Length });

			// Wrap input in NamedOnnxValue
			var input = new List<NamedOnnxValue>()
			{
				NamedOnnxValue.CreateFromTensor(session.InputMetadata.Keys.First(), inputTensor)
			};

			// Run inference using the ONNX Runtime session
			using var results = session.Run(input);

			// Extract output data
			var outputTensor = results.First().AsTensor<float>();
			float[] outputData = outputTensor.ToArray();

			// Display the output (replace this with your preferred handling of the output)
			Console.WriteLine("Output:");
			foreach (float value in outputData)
			{
				Console.WriteLine(value);
			}
		}*/
	
	

}
