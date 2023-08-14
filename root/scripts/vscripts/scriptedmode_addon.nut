Msg("scriptedmode_addon L4GPT\n");

Left4L4GPT_ScriptMode_Init <- ScriptMode_Init;
//=========================================================
// called from C++ when you try and kick off a mode to 
// decide whether scriptmode wants to handle it
//=========================================================
function ScriptMode_Init( modename, mapname )
{
	local bScriptedModeValid = true;
	try
	{
		bScriptedModeValid = Left4L4GPT_ScriptMode_Init( modename, mapname );
	}
	catch(exception)
	{
		//bScriptedModeValid = false;
		
		printl("ScriptMode_Init EXCEPTION: " + exception);
	}
	
	if ( !bScriptedModeValid )
	{
		printl( "Enabled ScriptMode for " + modename + " and now Initializing" );
		
		IncludeScript( mapname + "_" + modename, g_MapScript );

		// Add to the spawn array
		MergeSessionSpawnTables();
		MergeSessionStateTables();

		SessionState.MapName <- mapname;
		SessionState.ModeName <- modename;

		// If not specified, start active by default
		if ( !( "StartActive" in SessionState ) )
		{
			SessionState.StartActive <- true;
		}

		if ( SessionState.StartActive )
		{
			MergeSessionOptionTables();
		}
		
		// Sanitize the map
		if ( "SanitizeTable" in this )
		{
			SanitizeMap( SanitizeTable );
		}
		
		if ( "SessionSpawns" in getroottable() )
		{
			EntSpawn_DoIncludes( ::SessionSpawns );
		}

		// include all helper stuff before building the help
		IncludeScript( "sm_stages", g_MapScript );

		// check for any scripthelp_<funcname> strings and create help entries for them
		AddToScriptHelp( getroottable() );
		AddToScriptHelp( g_MapScript );
		AddToScriptHelp( g_ModeScript );
		
		// go ahead and call all the precache elements - the MapSpawn table ones then any explicit OnPrecache's
		ScriptedPrecache();
		ScriptMode_SystemCall("Precache");
	}
	
	IncludeScript("left4gpt");
	
	return true;
}
