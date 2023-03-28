using AI.Dev.OpenAI.GPT;
using Godot;
using System.Collections.Generic;
public partial class tokenizer : Node
{
	public override void _Ready() {
		GD.Print("Hello from C# to Godot :)");
	}

	public string token_encoder(string text) {
		List<int> tokens = GPT3Tokenizer.Encode(text);
		return string.Join(",", tokens);
	}
}
