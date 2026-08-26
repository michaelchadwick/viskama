# Viskama

Balatro, but darts. Name is "to throw" in Estonian.

## LLM

Ollama, gpt-oss:20b, "high"

### Prompt

#### V1

I want to make a game in the style of Balatro, but for darts. It should be made using love2d so that I can open up and inspect all the code. To begin with, I want the game to have a title screen, the title “Viskama” (Estonian for “to throw”), and a prompt that says press any key to begin. Once the game begins, the player will have three chances to throw a single dart and get the highest score. The player can throw a dart three different ways: 1) mouse can click and hold a button, move it in a direction to build up force, and then move it the opposite direction to throw it. 2) gamepad does the same thing with a button and an analog stick. 3) phone/tablet uses a finger pressed down and then flicked in the opposite direction. The viewpoint will be first person, with the only thing visible being the dartboard in front of the player. The dart will be held by an invisible hand and can be moved in all 8 directions. Accuracy depends on where the dart’s position is before a button/finger is held down and how much force is used and a small percentage random modifier for fun. Simple graphics are fine for now. Once the three shots are thrown, the game ends and the score is displayed. If it is higher than 200, the player wins, if not they lose

#### V2

Please make the code more modular, and put components for the dart, dartboard, and any other things that make sense into their own files and require them.
