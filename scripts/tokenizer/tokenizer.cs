using AI.Dev.OpenAI.GPT;
using Godot;
using System.Collections.Generic;
using SharpToken;

public partial class tokenizer : Node
{
	public override void _Ready() {
		GD.Print("Hello from C# to Godot :)");
	}

	public string token_encoder(string text, string model = "gpt-4") {
		var encoding = GptEncoding.GetEncoding("r50k_base");
		switch (model) {
			case "gpt-3":
				encoding = GptEncoding.GetEncoding("r50k_base");
				break;
			case "gpt-4":
				encoding = GptEncoding.GetEncodingForModel("gpt-4");
				break;
			default:
				encoding = GptEncoding.GetEncoding("r50k_base");
				break;
		}
		var encoded = encoding.Encode(text);
		return string.Join(",", encoded);
	}
}
