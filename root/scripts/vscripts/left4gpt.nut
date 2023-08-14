//------------------------------------------------------
//     Author : smilzo
//     https://steamcommunity.com/id/smilz0
//------------------------------------------------------

Msg("Including left4gpt...\n");

if (!IncludeScript("left4lib_users"))
	error("[L4GPT][ERROR] Failed to include 'left4lib_users', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");
if (!IncludeScript("left4lib_timers"))
	error("[L4GPT][ERROR] Failed to include 'left4lib_timers', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");

//IncludeScript("left4gpt_requirements");

// Log levels
const LOG_LEVEL_NONE = 0; // Log always
const LOG_LEVEL_ERROR = 1;
const LOG_LEVEL_WARN = 2;
const LOG_LEVEL_INFO = 3;
const LOG_LEVEL_DEBUG = 4;

::Left4GPT <- {
	Events = {}
	SelectedBot = null
	LastInteracted = 0
	Settings =
	{
		thinker_interval = 0.1
		reset_idle_time = 90
		msg_delay_factor = 0.045
		min_user_level = 1 // Friend
		loglevel = 3
	}
};

::Left4GPT.Log <- function (level, text)
{
	if (level > Left4GPT.Settings.loglevel)
		return;
	
	if (level == LOG_LEVEL_DEBUG)
		printl("[L4GPT][DEBUG] " + text);
	else if (level == LOG_LEVEL_INFO)
		printl("[L4GPT][INFO] " + text);
	else if (level == LOG_LEVEL_WARN)
		error("[L4GPT][WARNING] " + text + "\n");
	else if (level == LOG_LEVEL_ERROR)
		error("[L4GPT][ERROR] " + text + "\n");
	else
		error("[L4GPT][" + level + "] " + text + "\n");
}

::Left4GPT.GetBotByName <- function (name)
{
	local n = name.tolower();
	foreach (bot in Left4Utils.GetBotSurvivors())
	{
		if (bot.GetPlayerName().tolower() == n)
			return bot;
	}
	return null;
}

::Left4GPT.SayText <- function (bot, text)
{
	if (!bot || !bot.IsValid() || !text || text == "")
		return;
	
	Say(bot, text, false);
}

::Left4GPT.HandleReply <- function (bot)
{
	// Read the AI reply from the OUT file
	local outFile = "left4gpt/" + bot.GetPlayerName().tolower() + "_out.txt";
	local outText = FileToString(outFile);
	if (outText && outText != "")
	{
		// We received a reply from the AI
		
		Left4GPT.Log(LOG_LEVEL_DEBUG, bot.GetPlayerName() + ": " + outText);
		
		// StringToFile is very slow so calling it for every bot will likely make the addon spam the console with "script took too long" messages
		// One solution might be to make one thinker for each bot but that means that more entities will be created
		StringToFile(outFile, "");
		
		local delay = 0;
		while (outText != "")
		{
			local txt = outText;
			if (txt.len() > 127)
			{
				// If the reply is longer that the max length of a single chat message, split it into multiple messages trying not to cut the words
				local i = 126;
				while (txt[i] != 32 && i > 0) // 32 = " "
					i--;
				
				txt = txt.slice(0, i);
			}
			outText = outText.slice(txt.len());
			
			Left4GPT.Log(LOG_LEVEL_DEBUG, "txt: " + txt + " - outText: " + outText + " - delay: " + delay);
			
			// Pretend the bot is 'typing' the message by adding a delay based on the message length
			delay += txt.len() * Left4GPT.Settings.msg_delay_factor;
			Left4Timers.AddTimer(null, delay, @(params) Left4GPT.SayText(params.bot, params.text), { bot = bot, text = txt }, false);
		}
	}
}

::Left4GPT.OnThinker <- function (params)
{
	foreach (bot in Left4Utils.GetBotSurvivors())
		Left4GPT.HandleReply(bot);
	
	if (Left4GPT.SelectedBot && ((Time() - Left4GPT.LastInteracted) >= Left4GPT.Settings.reset_idle_time || !Left4GPT.SelectedBot.IsValid()))
	{
		// Reset the active bot if no messages have been received for more Left4GPT.Settings.reset_idle_time time
		
		Left4GPT.Log(LOG_LEVEL_DEBUG, "SelectedBot reset");
		Left4GPT.SelectedBot = null;
	}
}

Left4GPT.Log(LOG_LEVEL_DEBUG, "Loading settings...");
Left4Utils.LoadSettingsFromFile("left4gpt/cfg/settings.txt", "Left4GPT.Settings.", Left4GPT.Log);
Left4Utils.SaveSettingsToFile("left4gpt/cfg/settings.txt", ::Left4GPT.Settings, Left4GPT.Log);
Left4Utils.PrintSettings(::Left4GPT.Settings, Left4GPT.Log, "[Settings] ");

Left4Timers.AddThinker("L4GPT", Left4GPT.Settings.thinker_interval, Left4GPT.OnThinker);

::Left4GPT.Events.OnGameEvent_player_say <- function (params)
{
	local player = null;
	if ("userid" in params)
		player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	
	if (!player || !player.IsValid() || IsPlayerABot(player) || Left4Users.GetOnlineUserLevel(player.GetPlayerUserId()) < Left4GPT.Settings.min_user_level)
		return;
	
	local text = params["text"];
	
	Left4GPT.Log(LOG_LEVEL_DEBUG, "OnGameEvent_player_say - " + player.GetPlayerName() + ": " + text);
	
	Left4GPT.LastInteracted = Time();
	
	local tmp = split(text, " ");
	if (tmp.len() > 1)
	{
		// Remove 'botname'/'hey botname' triggers from the message
		
		local remove = "";
		local botname = "";
		if (tmp[0].tolower() == "hey")
		{
			botname = tmp[1];
			remove = "hey " + botname;
		}
		else
		{
			botname = tmp[0];
			remove = botname;
		}
		
		local bot = Left4GPT.GetBotByName(botname);
		if (bot)
		{
			// Active bot has been selected
			
			text = strip(text.slice(remove.len()));
			Left4GPT.SelectedBot = bot;
		}
	}
	
	if (Left4GPT.SelectedBot && Left4GPT.SelectedBot.IsValid() && text != "")
	{
		// Write the player's message to the IN file
		
		Left4GPT.Log(LOG_LEVEL_DEBUG, "OnGameEvent_player_say - " + Left4GPT.SelectedBot.GetPlayerName() + " <- " + text);
		
		StringToFile("left4gpt/" + Left4GPT.SelectedBot.GetPlayerName().tolower() + "_in.txt", text);
	}
}

__CollectEventCallbacks(::Left4GPT.Events, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
