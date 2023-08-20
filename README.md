# Left 4 GPT
This was just a test with the ChatGPT API. It makes the L4D2 survivor bots talk with you via chat.

***NOTE: This addon requires an external program to run on the L4D2 server in order to make the bots talk.***

[THIS PROGRAM](https://github.com/smilz0/Dot4GPT)

You must run it on your PC, if you are hosting the game. It must run on the server, in case of dedicated server. It runs on both Windows and Linux (tested on Ubuntu Server 22.04).

***You also need an [OpenAI API Key](https://platform.openai.com/account/api-keys).***


### How it works
This addon listens for chat messages from human players, then writes the message to a text file in the `ems` folder. There are 2 text files for each bot: `botname_in.txt` and `botname_out.txt`. The addon writes the message to the **IN** file of the active bot (you activate the bot by adding its name at the beginning of the message).

The external program ([Dot4GPT](https://github.com/smilz0/Dot4GPT)) will be listening for messages in the **IN** file. When it finds a message, it reads it and truncates the **IN** file (so it doesn't read it again). Then sends the message to ChatGPT via API and waits for the response. Once the response is received, the program writes it to the **OUT** text file of the same bot.

The addon will also be listening for text written into the **OUT** files. Once this text is found, it reads it (and truncates the file) and makes that bot chat the text.

Basically you talk to L4D2, L4D2 talks to this addon, the addon talks to the external program, the external program talks to ChatGPT. ChatGPT replies to the external program, which replies to this addon, which replies to L4D2, which replies to you. :dizzy_face:


### Addon settings
The addon creates the file `ems/left4gpt/cfg/settings.txt` with the default addon settings:
```nut
// Interval of the process that checks for ChatGPT replies in the OUT files
thinker_interval = 0.1

// After you activate the bot to talk to with "botname" or "hey botname" at the beginning of the message, that bot remains active
// and you don't need to add the bot name in the next messages. But the active bot will reset after this amount of time with no messages.
reset_idle_time = 90

// The reply is sent to the chat with a delay which is calculated by multiplying the text length by this number in order to "simulate" the bot typing the reply.
// Increase/Decrease this number to make the bots reply slower/quicker.
msg_delay_factor = 0.045

// Minimum L4U user level to be able to chat with the bots (2 = Admin, 1 = Friend, 0 = Random player, -1 = Griefer)
min_user_level = 1 // Friend

// 0 = No log
// 1 = Only [ERROR] messages are logged
// 2 = [ERROR] and [WARNING]
// 3 = [ERROR], [WARNING] and [INFO]
// 4 = [ERROR], [WARNING], [INFO] and [DEBUG]
loglevel = 3
```
You can edit this file to change the settings.

More info can be found on the [DotGPT GitHub Repository](https://github.com/smilz0/Dot4GPT).
