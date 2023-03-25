# Quasai - GPT & LLM client
<h1>A ChatGPT client using the OpenAI GPT-3.5 & GPT 4 API built in Godot 4.</h1>

This is a project I'm doing for fun to explore ChatGPT's API and see what I can make it do. You can use this program to connect your own API Key and start chatting with your AI. I have a few features planned to help with context issues and consistency of the AI's output.

An .exe download is now available at my itch.io page https://cdcruz.itch.io/chatgpt-client

<h2>Basic Features:</h2>

<ul>
    <li>Use your own API Key to connect to OpenAI's API</li>
    <li>Has some context awareness and remembers previous messages</li>
    <li>Use pre-processor prompts to instruct the AI on how to respond to your messages.</li>
    <li>Save your chats and load them at a later date to continue your conversation. Your conversations are saved locally to your PC.</li>
    <li>PLANNED - A basic theme selection for different coloured UI and text bubbles</li>
    <li>PLANNED - Optimizations to chat memory and memory of key details in a conversation</li>
    <li>PLANNED - Add more specialized & custom interfaces for different use cases, for example, a recipe generator.</li>
    <li>PLANNED - Add a folder structure for saved conversations so you can organize conversations into groups.</li>
    <li>PLANNED - Support for Google's AI PaLM API</li>
    <li>IDEA - Add Text to Speech for the general chatting feature. This will most likely involve the ElevenLabs API.</li>
    <li>IDEA - Allow for PDF & Word docs to be analyzed and summarized.</li>
    <li>IDEA - Allow for community-made extensions/ modes to extend the program.</li>
</ul>


<h2>Changelog:</h2>

0.2.0
<ul>
<li>I have decided on a new name for my program. It is now called "Quasai," a play on the word "quasi," which means something that is kind of like something else. In this case, it refers to AI trying to be kind of human.</li>
<li>I fixed a major bug that caused problems under the hood and led to crashes. The bug was related to the API class being instanced too many times and not being deleted.</li>
<li>I added a bare-bones implementation of the ElevenLabs API to enable text-to-speech generation. Currently, this implementation is very limited and only works in the General Chatting mode. You also need to supply your own Eleven Labs API in the settings menu.</li>
</ul>

0.1.8:

<ul>
    <li>Added a meal planner mode that generates a complete meal plan for your week, based on your preferred diet and a few other parameters. However, the AI can be unpredictable, so the process might take longer and encounter some issues.</li>
    <li>You can easily save your meal plan to a text file for later use.</li>
    <li>You can select text bubbles in general chatting to make it easier to copy AI responses.</li>
    <li>API requests will now timeout if they take too long. The default time is 40 seconds but some modes have longer or shorter times depending on their use.</li>
</ul>

0.1.7:

<ul>
    <li>Added a code assistant where you can provide code and the AI will attempt to fix it or convert it to a different language. GPT 3.5 does not perform that well at this task currently. But improvements could be made internally.</li>
    <li>Added a GreenText generator that will generate wild greentext stories with simple input prompts. It will display the greentext in the classic greentext format and uses a random image from imgflip.com using their free API.</li>
    <li>In general chatting mode, AI-provided code will appear in a proper code block if the AI formats it correctly.</li>
    <li>Fixed bug reported by Julian4702 and other minor things.</li>
</ul>

0.1.6a:

<ul>
    <li>A very minor release that adds the ability to change GPT models to the newest GPT-4 8K version from the main menu settings. Be aware that GPT-4 is expensive to use compared to GPT-3.5.</li>
    <li>Fixed the cost calculations to calculate cost correctly for GPT-4.</li>
</ul>
0.1.6:

<ul>
<li>Added a translator feature that can translate between major languages and some funny/fake languages. More languages will be supported later.</li>
<li>An experimental companion mode has been added, where the AI can learn more about the user and act as a friend. However, this mode currently consumes an extremely high amount of tokens and is not recommended for use.</li>
<li>The proofreader can now handle .txt files dropped into the input box. Multiple files can be dropped at once and will be pasted into the input box.</li>
<li>Various minor fixes and code refactoring have been performed to make the program more expandable for future language model support.</li>
<li>The internal prompt scripts have also been tweaked to improve AI focus on the given task.</li>
<li>A stats section, which can display the total amount of tokens used, has been added to the main menu settings screen. The stats will persist between sessions.</li>
<li>A waiting indicator has been incorporated into most modes to give feedback to users when the program is waiting for a response from OpenAI servers.</li>
</ul>

0.1.5:

<ul>
<li>Added a tokenizer tool for creating logit bias dictionaries. Due to using a C# library to achieve this, the .exe file needs to be zipped with some .dll files. I may try to port the C# library to Godot so the .exe can be completely standalone again.</li>
<li>Added the ability to save recipes in the recipe creator to a text file.</li>
<li>Added an OpenAI server status indicator to the main menu for easy notifications of possible server issues.</li>
<li>Fixed the chat bubbles to fit text more accurately and not leave as much unneeded space.</li>
<li>Improved some internal preprocessor prompts used for the proofreader.</li>
</ul>

0.1.4:

<ul>
<li>Added a recipe creator with multiple options and parameters including serving size, vegan options, and different instruction styles.</li>
<li>The ability to export the recipe will be added at a later date.</li>
</ul>

0.1.3:

<ul>
<li>Added an image prompter interface that will provide prompts to use in software like Stable Diffusion.</li>
<li>Other minor fixes and changes.</li>
</ul>

0.1.2:

<ul>
<li>Added a new proofreader interface with the ability to fix grammar & spelling, summarize text, analyze sentiment, and change the writing styles of any provided text.</li>
<li>Refactored parts of the code to make it more modular & expandable. There is still some work to do.</li>
<li>Preprocessor prompts for the general chatting feature will now accept JSON format for the preprocessor allowing you to include your own logit bias dictionary for more fine-tuning.</li>
<li>Changed the estimated cost value to reflect the cost I have seen in my usage. $0.000002 seems to be the correct value per 1 token in my testing.</li>
</ul>
0.1.1:

<ul>
<li>Added a new start screen that explains the API and how to get started.</li>
<li>Added a mode selection screen to allow for different features to be added in the future.</li>
<li>Changed the save system for conversations to make it more expandable. Old saved conversations will no longer work.</li>
<li>Minor bug fixes and quality-of-life improvements.</li>
</ul>

0.1.0: Initial release
