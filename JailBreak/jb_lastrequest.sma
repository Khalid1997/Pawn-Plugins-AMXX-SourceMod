/*
*
*		Jailbreak Last Request
*			
*		H3avY Ra1n (AKA nikhilgupta345)
*
*		Description
*		-----------
*
*			This is a Last Request plugin for jailbreak mod, where 
*			the last terrorists can type /lr and is presented with a 
*			menu, which has numerous options to choose from that interact 
*			with the Counter-Terrorists.
*
*		Last Request Options
*		--------------------
*
*			Knife Battle 	- Fight with knives 1v1
*			Shot for Shot	- Take turns shooting a deagle
*			Deagle Toss		- See who can throw the deagle the farthest
*			Shotgun Battle	- Fight with shotguns 1v1
*			Scout Battle	- Fight with scouts 1v1
*			Grenade Toss	- See who can throw the grenade the farthest
*			Race			- Race across a certain part of the map
*			Spray Contest	- See who can spray closest to the top or bottom border
*			of a wall. Prisoner decides.
*
*
*		Client Commands
*		---------------
*	
*			say/say_team	/lr 			- Opens Last Request Menu
*							!lr
*							/lastrequest
*							!lastrequest
*
*
*		Installation
*		------------
*
*			- Compile this plugin locally
*			- Place jb_lastrequest.amxx in addons/amxmodx/plugins/ folder
*			- Open addons/amxmodx/configs/plugins.ini
*			- Add the line 'jb_lastrequest.amxx' at the bottom
*			- Restart server or change map
*			
*
*		Changelog
*		---------
*		
*			February 15, 2011 	- v1.0 - 	Initial Release
*			February 24, 2011	- v1.0.1 - 	Removed teleporting back to cell
*			March 05, 2011		- v1.1 -	Changed way of allowing a Last Request
*			March 26, 2011		- v1.2 - 	Added Multi-Lingual support.
*			August 10, 2011		- v2.0 -	Completely rewrote plugin
*
*		
*		Credits
*		-------
*		
*			Pastout		-	Used his thread as a layout for mine
*
*		
*		Plugin Thread: http://forums.alliedmods.net/showthread.php?p=1416279
*
*/

// Includes
////////////

#include < amxmodx >
#include < cstrike >
#include < fun >
#include < fakemeta >
#include < fakemeta_util >
#include < hamsandwich >
#include < engine >
//#include < dhudmessage >

// Enums
/////////

#define COMBO

enum
{
	LR_NONE = -1,

	LR_RANDOM,
	
	LR_FREEDAY,
	LR_LONGJUMP,
	LR_S4S,
	LR_SPRAY,
	
	LR_COMBO,

	LR_RACE,
	LR_GUNTOSS,
	LR_KNIFE,
	LR_NADETOSS,
	LR_SCOUT,
	LR_SHOTGUN,
	LR_AWP,
	
	MAX_GAMES
};

enum
{
	GREY = 0,
	RED,
	BLUE,
	NORMAL
};

enum
{
	ALIVE, 
	DEAD, 
	ALL	
};

enum
{
	LR_PRISONER,
	LR_GUARD
};

enum ( += 32 )
{
	TASK_BEACON = 18516,
	TASK_ENDLR,
	TASKID_SHOW_PATTERN,
	TASKID_RANDOM_HUD
};

// Consts
//////////

new const g_szPrefix[ ] = "!g[Jailbreak]!n";

new const g_szBeaconSound[ ] = "buttons/blip1.wav";
new const g_szBeaconSprite[ ] = "sprites/white.spr";

new const g_szGameNames[ MAX_GAMES ][ ] = 
{
	"Random Last Request",
	"Free Day",
	"Long Jump contest",
	"Shot 4 Shot",
	"Spray Contest",
	"Combo Contest",
	"Race",
	"Gun Toss",
	"Knife Battle",
	"Grenade Toss",
	"Scout Battle",
	"Shotgun Battle",
	"Awp Battle"
};

new const g_szDescription[ MAX_GAMES ][ ] = 
{
	"---- DUMP CHAT ----", // DUMP
	"Die and get a freeday next round.",
	"Challenge CT who can get the longest distance!",
	"Take turns shooting a deagle.",
	"Both players spray on a wall, highest or lowest.",

	"Press the buttons shown on screen as fast as you can",

	"Both players race across a part of the map.",
	"See who can throw the deagle the farthest.",
	"Battle it out with knives.",
	"See who can throw the grenade the farthest from a point in the map.",
	"Battle it out with scouts.",
	"Battle it out with shotguns.",
	"Battle it out with AWPs."
};

new const g_szTeamName[ ][ ] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};

new const g_szPlugin[ ] = "Jailbreak Last Request";
new const g_szVersion[ ] = "2.0";
new const g_szAuthor[ ] = "H3avY Ra1n";

// Integers
////////////

new g_iCurrentGame = LR_NONE;
new g_iLastRequest[ 2 ];

new Float:g_fl_LG_Distance[2]

new g_iCurrentPage[ 33 ];
new g_iChosenGame[ 33 ];
new g_iPlayedLastRequest[33];

new g_iSprite;

new g_iMaxPlayers;

// Booleans
///////////

new bool:g_bAlive[ 33 ];
new bool:g_bConnected[ 33 ];

new bool:g_bLastRequestAllowed;

// Messages
////////////

new g_msgTeamInfo;
new g_msgSayText;

// ---- LongJump ----
new g_iLastRequestFreeDay
new g_iLongJumpsDone

// Fd Forward
new g_iFdForward

// Rocket
new blueflare2, mflash, smoke, white


// ---- Combo Contest ----
#define MAX_COMBO_BUTTONS 5
new g_szSeperateChar[] = "-"

new g_szComboButtonNames[9][] = {
	"Duck",
	"Jump",
	"Use",
	"Forward",
	"Back",
	"Right",
	"Left",
	"Mouse 1",
	"Mouse 2"
}

new g_iComboButtons[9] = {
	IN_DUCK,
	IN_JUMP,
	IN_USE,
	IN_FORWARD,
	IN_BACK,
	IN_MOVERIGHT,
	IN_MOVELEFT,
	IN_ATTACK,
	IN_ATTACK2
}

new g_iTurn[2]
new g_iButtons[MAX_COMBO_BUTTONS]
new g_iLastButtons[33] //

new gSyncHud
new g_szPattern[256]

new g_iCmdStartFwd

/// RANDOM LR
new g_iSoundStarted, g_iCounter

new g_szRandomSound[] = "Wheel-of-Fortune-Timer.mp3"

new g_szLrEndSounds[][] = {
	"Pacman-Die.mp3",
	"SuperMarioBrothers-MarioDies.mp3",
	"VideoGame-DigDug-Dies.mp3"
}

/*new g_szLrStartSounds[][] = {
	"",
	"",
	""
}*/

//////// OTHER
#define IsInBit(%0,%1) ( %0 & (1<<%1) )
#define AddToBit(%0,%1) ( %0 |= (1<<%1) )
#define RemoveFromBit(%0,%1) ( %0 &= ~(1<<%1) )

stock PrecacheSound(szFile[], iDefaultDir = 1)
{	
	new szFolderDir[60]
	if(equali(szFile[strlen(szFile) - 4], ".mp3"))
	{
		if(iDefaultDir)
		{
			formatex(szFolderDir, charsmax(szFolderDir), "sound/Jail_Lr/%s", szFile)
		}
		
		if(!file_exists(szFolderDir))
		{
			log_amx("File %s not found", szFolderDir);
			return;
		}
		
		log_amx("Precached %s", szFolderDir);
		precache_generic(szFolderDir)
	}
	
	else
	{
		new szCheckDir[80]
		if(iDefaultDir)
		{
			formatex(szFolderDir, charsmax(szFolderDir), "Jail_Lr/%s", szFile)
		}
		
		else
		{
			formatex(szFolderDir, charsmax(szFolderDir), szFile)
		}
		
		formatex(szCheckDir, charsmax(szCheckDir), "sound/%s", szFolderDir)
		if(!file_exists(szCheckDir))
		{
			log_amx("File %s not found", szCheckDir);
			return;
		}
		
		log_amx("Precached %s", szFolderDir);
		precache_sound(szFolderDir)
	}
}

stock PlaySound(id, szFile[], iDefaultDir = 1)
{
	static iPlayers[32], iNum, iPlayer
	
	if(!id)
	{
		get_players(iPlayers, iNum)
	}
	
	else
	{
		if(!is_user_connected(id))
		{
			return;
		}
		
		iPlayers[0] = id; iNum = 1
	}
	
	if(equali(szFile[strlen(szFile) - 4], ".mp3"))
	{
		for(new i; i < iNum; i++)
		{
			switch(iDefaultDir)
			{
				case 0:
				{
					client_cmd(iPlayer, "mp3 play ^"%s^"", szFile)
				}
				
				default:
				{
					client_cmd(iPlayer, "mp3 play ^"sound/Jail_Lr/%s^"", szFile)
				}
			}
		}
	}
	
	else
	{
		for(new i; i < iNum; i++)
		{
			switch(iDefaultDir)
			{
				case 0:
				{
					client_cmd(iPlayer, "spk ^"%s^"", szFile)
				}
				
				default:
				{
					client_cmd(iPlayer, "spk ^"Jail_Lr/%s^"", szFile)
				}
			}
		}
	}
}

public plugin_precache()
{
	precache_sound( g_szBeaconSound );
	g_iSprite = precache_model( g_szBeaconSprite );
	
	//Rocket
	blueflare2 = precache_model( "sprites/blueflare2.spr")
	mflash = precache_model("sprites/muzzleflash.spr")
	smoke = precache_model("sprites/steam1.spr")
	white = precache_model("sprites/white.spr")
	
	precache_sound("weapons/rocketfire1.wav")
	precache_sound("weapons/rocket1.wav")
	
	PrecacheSound(g_szRandomSound)
	
	for(new i; i < sizeof(g_szLrEndSounds); i++)
	{
		PrecacheSound(g_szLrEndSounds[i])
	}
}

public plugin_init()
{
	register_plugin( g_szPlugin, g_szVersion, g_szAuthor );
	
	register_clcmd( "say /lr", 					"Cmd_LastRequest" );
	register_clcmd( "say !lr", 					"Cmd_LastRequest" );
	register_clcmd( "say /lastrequest", 		"Cmd_LastRequest" );
	register_clcmd( "say !lastrequest", 		"Cmd_LastRequest" );
	
	register_clcmd( "say_team /lr", 			"Cmd_LastRequest" );
	register_clcmd( "say_team !lr", 			"Cmd_LastRequest" );
	register_clcmd( "say_team /lastrequest", 	"Cmd_LastRequest" );
	register_clcmd( "say_team !lastrequest", 	"Cmd_LastRequest" );
	
	register_event( "HLTV", 	"Event_RoundStart", "a", "1=0", "2=0" );
	
	register_logevent( "Logevent_RoundStart", 2, "1=Round_Start" );
	
	RegisterHam( Ham_Spawn, 				"player", 			"Ham_PlayerSpawn_Post", 	1 );
	RegisterHam( Ham_Weapon_PrimaryAttack, 	"weapon_deagle", 	"Ham_DeagleFire_Post", 		1 );
	RegisterHam( Ham_Killed,				"player",			"Ham_PlayerKilled_Post",	1 );
	RegisterHam( Ham_TakeDamage,			"player",			"Ham_TakeDamage_Pre",		0 );
	
	RegisterHam( Ham_TakeHealth, "player", "fw_TakeHealth")
	
	register_forward( FM_Think, "Forward_EntityThink_Pre", 0 );
	
	register_touch("weaponbox", "player", "fw_WeaponTouch")
	register_touch("armoury_entity", "player", "fw_WeaponTouch")
	
	register_message( get_user_msgid( "TextMsg" ), "Message_TextMsg" );
	
	g_msgTeamInfo 	= get_user_msgid( "TeamInfo" );
	g_msgSayText 	= get_user_msgid( "SayText" );
	
	g_iMaxPlayers 	= get_maxplayers();
	
	set_task( 2.0, "StartBeacon", .flags="b" );
	
	g_iFdForward = CreateMultiForward("freeday_set2", ET_CONTINUE, FP_CELL)

	gSyncHud = CreateHudSyncObj(3)
	
	//set_task( 300.0, "Task_Advertise", .flags="b" );
}

public fw_TakeHealth(id, Float:flHealth, iDamageBits)
{
	if(g_iCurrentGame != LR_NONE)
	{
		if(id == g_iLastRequest[LR_GUARD] || id == g_iLastRequest[LR_PRISONER])
		{
			SetHamParamFloat(2, 0.0)
			return HAM_SUPERCEDE
		}
	}
	
	return HAM_IGNORED
}

public fw_WeaponTouch(ent, id)
{
	if(g_iCurrentGame == LR_NONE || g_iCurrentGame == LR_GUNTOSS)
	{
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}

public client_putinserver( id )
{
	g_iCurrentPage[ id ] = 0;
	
	g_bConnected[ id ] = true;
}

public client_disconnect( id )
{
	g_bConnected[ id ] = false;
	
	if( g_bAlive[ id ] )
		g_bAlive[ id ] = false;
	
	if( id == g_iLastRequest[ LR_PRISONER ] || id == g_iLastRequest[ LR_GUARD ] )
	{
		EndLastRequest( id == g_iLastRequest[ LR_PRISONER ] ? g_iLastRequest[ LR_GUARD ] : g_iLastRequest[ LR_PRISONER ], id );
	}
	
	else if( !g_bLastRequestAllowed && cs_get_user_team( id ) == CS_TEAM_T )
	{
		if( get_playercount( CS_TEAM_T, ALIVE ) == 1 )
		{
			ColorChat( 0, NORMAL, "%s !gLast Request!n is now allowed.", g_szPrefix );
			g_bLastRequestAllowed = true;
		}
	}
	
	remove_task( id + TASK_ENDLR );
	
	if(id == g_iLastRequestFreeDay)
	{
		g_iLastRequestFreeDay = 0
	}
}

public Ham_PlayerSpawn_Post( id )
{
	if( !is_user_alive( id ) )
		return HAM_IGNORED;
		
	g_bAlive[ id ] = true;
	
	if(g_iLastRequestFreeDay && g_iLastRequestFreeDay == id)
	{
		new iRet
		ExecuteForward(g_iFdForward, iRet, id)
		
		if(iRet == 1)
		{
			new szName[32]; get_user_name(id, szName, charsmax(szName))
			
			ColorChat(0, NORMAL, "%s ^1Prisoner ^3%s ^1got a ^3FREE DAY ^1from the last request menu!", g_szPrefix, szName)
		}
		
		g_iLastRequestFreeDay = 0
	}
	
	return HAM_IGNORED;
}

public Ham_PlayerKilled_Post( iVictim, iKiller, iShouldGib )
{	
	g_bAlive[ iVictim ] = false;
	
	if( iVictim == g_iLastRequest[ LR_PRISONER ] )
	{
		EndLastRequest( g_iLastRequest[ LR_GUARD ], iVictim );
	}
	
	else if( iVictim == g_iLastRequest[ LR_GUARD ] )
	{
		EndLastRequest( g_iLastRequest[ LR_PRISONER ], iVictim );
	}
	
	if( !g_bLastRequestAllowed && cs_get_user_team( iVictim ) == CS_TEAM_T )
	{
		if( get_playercount( CS_TEAM_T, ALIVE ) == 1 )
		{
			ColorChat( 0, NORMAL, "%s !gLast Request!n is now allowed.", g_szPrefix );
			g_bLastRequestAllowed = true;
		}
	}
}

public Ham_DeagleFire_Post( iEnt )
{
	if( g_iCurrentGame != LR_S4S )
	{
		return;
	}
	
	new id = pev( iEnt, pev_owner );
	new iOpponentEnt;
	
	if( cs_get_weapon_ammo( iEnt ) == 0 )
	{
		if( id == g_iLastRequest[ LR_PRISONER ] )
		{
			iOpponentEnt = fm_find_ent_by_owner( -1, "weapon_deagle", g_iLastRequest[ LR_GUARD ] );
			
			if( pev_valid( iOpponentEnt ) )
				cs_set_weapon_ammo( iOpponentEnt, 1 );
		}
		
		else if( id == g_iLastRequest[ LR_GUARD ] )
		{
			iOpponentEnt = fm_find_ent_by_owner( -1, "weapon_deagle", g_iLastRequest[ LR_PRISONER ] );
			
			if( pev_valid( iOpponentEnt ) )
				cs_set_weapon_ammo( iOpponentEnt, 1 );
		}
	}
}

public Ham_TakeDamage_Pre( iVictim, iInflictor, iAttacker, Float:flDamage, iBits )
{
	if( !( 1 <= iAttacker <= g_iMaxPlayers ) )
		return HAM_IGNORED;
	
	new bool:g_bVictimLR = iVictim == g_iLastRequest[ LR_PRISONER ] || iVictim == g_iLastRequest[ LR_GUARD ];
	new bool:g_bAttackerLR = iAttacker == g_iLastRequest[ LR_PRISONER ] || iAttacker == g_iLastRequest[ LR_GUARD ];
	
	if( g_bVictimLR && !g_bAttackerLR )
	{
		return HAM_SUPERCEDE;
	}
	
	else if( !g_bVictimLR && g_bAttackerLR )
	{
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public Event_RoundStart()
{
	g_bLastRequestAllowed = false;
	g_iCurrentGame = LR_NONE;
	
	arrayset(g_iChosenGame, LR_NONE, 33)
	arrayset(g_iPlayedLastRequest, 0, 33)
}

public Logevent_RoundStart()
{
	if( !g_bLastRequestAllowed && get_playercount( CS_TEAM_T, ALIVE ) == 1 )
	{
		g_bLastRequestAllowed = true;
		ColorChat( 0, NORMAL, "%s !gLast Request!n is now allowed.", g_szPrefix );
	}
}

public Forward_EntityThink_Pre( iEnt )
{
	if( !pev_valid( iEnt ) || g_iCurrentGame != LR_NADETOSS )
		return FMRES_IGNORED;
	
	new id = pev( iEnt, pev_owner );
	
	if( id != g_iLastRequest[ LR_PRISONER ] && id != g_iLastRequest[ LR_GUARD ] )
		return FMRES_IGNORED;
		
	new szModel[ 32 ];
	
	pev( iEnt, pev_model, szModel, charsmax( szModel ) );
	
	if( equal( szModel, "models/w_smokegrenade.mdl" ) )
	{
		set_pev( iEnt, pev_renderfx, kRenderFxGlowShell );
		set_pev( iEnt, pev_renderamt, 125.0 );
		set_pev( iEnt, pev_rendermode, kRenderTransAlpha );
		
		set_pev( iEnt, pev_rendercolor, id == g_iLastRequest[ LR_GUARD ] ? { 0.0, 0.0, 255.0 } : { 255.0, 0.0, 0.0 } );
		
		return FMRES_SUPERCEDE;
	}	
	
	return FMRES_IGNORED;
}	

public Message_TextMsg()
{
	if( g_iCurrentGame == LR_NONE )
	{
		return PLUGIN_CONTINUE;
	}
	
	static szText[ 25 ];
	get_msg_arg_string( 2, szText, charsmax( szText ) );
	
	if( equal( szText, "#Round_Draw" ) || equal( szText, "#Game_will_restart_in" ) || equal( szText, "#Game_Commencing" ) )
	{
		EndLastRequest(0, 0, 1, 0)
		
		// Test
		/*
		g_iCurrentGame = LR_NONE;
		
		strip_user_weapons( g_iLastRequest[ LR_PRISONER ] );
		strip_user_weapons( g_iLastRequest[ LR_GUARD ] );
		
		GiveWeapons( g_iLastRequest[ LR_GUARD ] );
		
		g_iLastRequest[ LR_PRISONER ] = 0;
		g_iLastRequest[ LR_GUARD ] = 0;
		*/
	}
	
	return PLUGIN_CONTINUE;
}

public Cmd_LastRequest( id )
{
	if( !g_bAlive[ id ] )
	{
		ColorChat( id, NORMAL, "%s You must be !talive!n to have a !gLast Request!n.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	else if( cs_get_user_team( id ) != CS_TEAM_T )
	{
		ColorChat( id, NORMAL, "%s You must be a !tprisoner!n to have a !gLast Request!n.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	else if( !g_bLastRequestAllowed )
	{
		ColorChat( id, NORMAL, "%s There are too many !tprisoners!n remaining to have a !gLast Request!n.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	else if( g_iCurrentGame != LR_NONE )
	{
		ColorChat( id, NORMAL, "%s There's a !gLast Request!n already in progress!", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	else LastRequestMenu( id );
	
	return PLUGIN_HANDLED;
}

public LastRequestMenu( id )
{
	new hMenu = menu_create( "\yChoose a Game:", "LastRequestMenu_Handler" );
	
	new szInfo[ 6 ];
	
	for( new i = 0, iAccess = 0; i < MAX_GAMES; i++, iAccess = 0 )
	{
		num_to_str( i, szInfo, charsmax( szInfo ) );
		
		if(i > 0)
		{
			if(g_iPlayedLastRequest[id] & (1<<i))
			{
				iAccess = (1<<26)
			}
		}
		
		menu_additem( hMenu, g_szGameNames[ i ], szInfo, iAccess );
	}
	
	menu_setprop( hMenu, MPROP_NEXTNAME, "Next Page" );
	menu_setprop( hMenu, MPROP_BACKNAME, "Previous Page" );
	
	menu_display( id, hMenu, 0 );
}

public LastRequestMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( hMenu );
		return PLUGIN_HANDLED;
	}
	
	new szData[ 6 ];
	new iAccess, hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szData, charsmax( szData ), _, _, hCallback );
	
	g_iChosenGame[ id ] = str_to_num( szData );
	
	if( g_iCurrentGame != LR_NONE )
	{
		menu_destroy( hMenu );
		g_iChosenGame[ id ] = LR_NONE;
		ColorChat( id, NORMAL, "%s There's already a !gLast Request!n in progress.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	if(g_iChosenGame[ id ] == LR_FREEDAY)
	{
		FreeDay(id)
	}
	
	else
	{
		ShowPlayerMenu( id );
		//StartGame(g_iChosenGame[id], id, id)
	}
	
	menu_destroy( hMenu );
	return PLUGIN_HANDLED;
}
	
public ShowPlayerMenu( id )
{
	new hMenu = menu_create( "\yChoose an Opponent:", "PlayerMenu_Handler" );
	
	new szPlayerName[ 32 ], szInfo[ 6 ];
	
	new i, iPlayers[32], iCount
	get_players(iPlayers, iCount, "ae", "CT")
	
	//////////////////////////
	/*if(iCount == 1)
	{
		StartGame(g_iChosenGame[ id ], id, id)
		return;
	}*/
	//////////////////////////
	
	for( new a; a < iCount; a++ )
	{
		i = iPlayers[a]
		if( !g_bAlive[ i ] || cs_get_user_team( i ) != CS_TEAM_CT )
			continue;
		
		get_user_name( i, szPlayerName, charsmax( szPlayerName ) );
		
		num_to_str( i, szInfo, charsmax( szInfo ) );
		
		menu_additem( hMenu, szPlayerName, szInfo );
	}
	
	menu_setprop( hMenu, MPROP_NEXTNAME, "Next Page" );
	menu_setprop( hMenu, MPROP_BACKNAME, "Previous Page" );
	
	menu_display( id, hMenu, 0 );
}

public PlayerMenu_Handler( id, hMenu, iItem )
{	
	if( iItem == MENU_EXIT || !g_bAlive[ id ] || !g_bLastRequestAllowed || g_iCurrentGame != LR_NONE )
	{
		g_iChosenGame[ id ] = LR_NONE;
		
		menu_destroy( hMenu );
		return PLUGIN_HANDLED;
	}
	
	new szData[ 6 ], szPlayerName[ 64 ];
	new iAccess, hCallback;
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, charsmax( szData ), szPlayerName, charsmax( szPlayerName ), hCallback );
	
	new iGuard = str_to_num( szData );
	
	if( !g_bAlive[ iGuard ] || cs_get_user_team( iGuard ) != CS_TEAM_CT )
	{
		ColorChat( id, NORMAL, "%s That player is no longer available for !gLast Request!n.", g_szPrefix );
		menu_destroy( hMenu );
		
		ShowPlayerMenu( id );
		return PLUGIN_HANDLED;
	}
	
	StartGame( g_iChosenGame[ id ], id, iGuard );
	
	menu_destroy( hMenu );
	return PLUGIN_HANDLED;
}

public DoRandomHud(iArray[3], iTaskId)
{
	if(!g_iSoundStarted)
	{
		g_iSoundStarted = 1
		PlaySound(0, g_szRandomSound)
	}
	
	ClearSyncHud(0, gSyncHud)
	if(g_iCounter == 0)
	{
		client_cmd(0, "stopsound; mp3 stop")
		
		set_hudmessage(255, 255, 255, -1.0, 0.15, 0, 0.0, 1.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(0, gSyncHud, "Random Last Request The last request is: %s", g_szGameNames[iArray[0]])
		
		remove_task(iTaskId)
		
		if(iArray[0] == LR_FREEDAY)
		{
			// Only fix for random LR
			FreeDay(iArray[1])
		}
		
		else StartGame(iArray[0], iArray[1], iArray[2])
		return;
	}
	
	g_iCounter--
	
	static iNewGame
	iNewGame = random_num(1, MAX_GAMES - 1)
	
	set_hudmessage(random(256), random(256), random(256), -1.0, 0.15, 0, 0.0, 1.0, 0.1, 0.1, -1)
	ShowSyncHudMsg(0, gSyncHud, "Random Last Request The last request is: %s", g_szGameNames[iNewGame])
}

stock FreeDay(id)
{
	new szName[32]; get_user_name(id, szName, charsmax(szName))
	ColorChat( 0, NORMAL, "%s ^3%s's ^1last request is to have a freeday next round!", g_szPrefix, szName );
	user_kill(id)
		
	g_iLastRequestFreeDay = id
}

stock StartGame( iGame, iPrisoner, iGuard, bool:iRandom = false )
{
	g_iLastRequest[ LR_PRISONER ] = iPrisoner;
	g_iLastRequest[ LR_GUARD ] = iGuard;
	
	if(iGame == LR_RANDOM)
	{
		while( ( iGame = random(MAX_GAMES) ) )
		{
			if( g_iPlayedLastRequest[iPrisoner] & (1<<iGame) )
			{
				continue;
			}
			
			g_iPlayedLastRequest[iPrisoner] |= (1<<iGame)
			break;
		}
		
		StartGame(iGame, iPrisoner, iGuard, true)
		return;
	}
	
	if(iRandom)
	{
		new iArray[3]
		iArray[0] = iGame; iArray[1] = iPrisoner; iArray[2] = iGuard
		
		g_iCounter = 5
		g_iSoundStarted = 0
		set_task(1.0, "DoRandomHud", TASKID_RANDOM_HUD, iArray, 3, "b")
		return;
	}
	
	if( iGame > 0)
	{
		g_iPlayedLastRequest[iPrisoner] |= (1<<iGame)
	}
	
	new szPrisonerName[ 32 ], szGuardName[ 32 ];
	
	get_user_name( iPrisoner, szPrisonerName, charsmax( szPrisonerName ) );
	get_user_name( iGuard, szGuardName, charsmax( szGuardName ) );
	
	ColorChat( 0, NORMAL, "%s !t%s!n against !t%s!n in a !g%s!n!", g_szPrefix, szPrisonerName, szGuardName, g_szGameNames[ iGame ] );
	
	strip_user_weapons( iPrisoner );
	strip_user_weapons( iGuard );
	
	set_user_health( iPrisoner, 100 );
	set_user_health( iGuard, 100 );
	
	set_user_armor( iPrisoner, 0 );
	set_user_armor( iGuard, 0 );
	
	// Fix for take health in lastrequest
	g_iCurrentGame = iGame;
	
	StartBeacon();
	
	ColorChat( iPrisoner, NORMAL, "%s !tObjective: %s", g_szPrefix, g_szDescription[ iGame ] );
	ColorChat( iGuard, NORMAL, "%s !tObjective: %s", g_szPrefix, g_szDescription[ iGame ] );
	
	switch( iGame )
	{	
		case LR_S4S:
		{
			LR_Shot4Shot( iPrisoner );
			LR_Shot4Shot( iGuard );
		}
		
		case LR_RACE:
		{
			LR_Race( iPrisoner );
			LR_Race( iGuard );
		}
		
		case LR_KNIFE:
		{
			LR_Knife( iPrisoner );
			LR_Knife( iGuard );
		}
		
		case LR_SPRAY:
		{
			LR_Spray( iPrisoner );
			LR_Spray( iGuard );
		}
		
		case LR_GUNTOSS:
		{
			LR_GunToss( iPrisoner );
			LR_GunToss( iGuard );
		}
		
		case LR_NADETOSS:
		{
			LR_NadeToss( iPrisoner );
			LR_NadeToss( iGuard );
		}
		
		case LR_SCOUT:
		{
			LR_Scout( iPrisoner );
			LR_Scout( iGuard );
		}
		
		case LR_SHOTGUN:
		{
			LR_Shotgun( iPrisoner );
			LR_Shotgun( iGuard );
		}
		
		case LR_AWP:
		{
			LR_Awp(iPrisoner)
			LR_Awp(iGuard)
		}
		
		case LR_LONGJUMP:
		{
			give_item(iPrisoner, "weapon_knife")
			give_item(iGuard, "weapon_knife")
			
			new iRet = callfunc_begin("On_JS_Forwards", "jumpstats_long.amxx")
			
			if(iRet != 1)
			{
				log_error(AMX_ERR_NATIVE, "Failed to do callfunc_begin(on)")
				return;
			}
			
			callfunc_end()
			
			ColorChat(0, NORMAL, "%s ^1The one who makes the longest ^3longjump ^1distance ^3WINS!!", g_szPrefix)
			ColorChat(0, NORMAL, "%s ^1The LongJump distance detection is Automaitc! If it doesnt work change jumping place!!", g_szPrefix)
			
			g_fl_LG_Distance[0] = 0.0
			g_fl_LG_Distance[1] = 0.0
			
			g_iLongJumpsDone = 0
		}
		
		case LR_COMBO:
		{
			g_iTurn[0] = 0
			g_iTurn[1] = 0
			
			new iNum = 0
			
			new szPattern[256]
			new iButtonArrayNum
			
			new iLen//, iButtons
			while(iNum < MAX_COMBO_BUTTONS)
			{
				iButtonArrayNum = random(sizeof(g_iComboButtons))
				
				//if( !( iButtons & g_iComboButtons[iButtonArrayNum] ) )
				{
					//iButtons |= g_iComboButtons[iButtonArrayNum]
					
					g_iButtons[iNum] = g_iComboButtons[iButtonArrayNum]
					iLen += formatex(szPattern[iLen], charsmax(szPattern) - iLen,  " %s %s", g_szComboButtonNames[iButtonArrayNum], (iNum + 1) == MAX_COMBO_BUTTONS ? "" : g_szSeperateChar)
					
					iNum++
				}
			}
			
			g_szPattern = "Prisoner chose Cobmo Contest.^nGet ready!^nThe pattern is:^n"
			
			set_hudmessage(170, 0, 170, -1.0, 0.15, 1, 2.5, 2.5, 0.1, 0.1, -1)
			ShowSyncHudMsg(0, gSyncHud, g_szPattern)
			
			formatex(g_szPattern, charsmax(g_szPattern), "Prisoner chose Cobmo Contest.^nGet ready!^nThe pattern is:^n%s", szPattern)
			
			set_task(2.5, "ShowPattern", TASKID_SHOW_PATTERN)
		}
	}
}

public fw_CmdStart(id, iUc, iSeed)
{
	if(g_iCurrentGame != LR_COMBO)
	{
		return;
	}
	
	new iButtons = get_uc(iUc, UC_Buttons)
	
	new iTeam = (id == g_iLastRequest[LR_GUARD] ? LR_GUARD : LR_PRISONER)
	
	if(iButtons & g_iButtons[g_iTurn[iTeam]] )
	{
		// Not the first button
		if(g_iTurn[iTeam] > 0)
		{
			// Prevent them from pressing all at once
			//if(iButtons & g_iButtons[g_iTurn[iTeam] - 1] 
			//&& !( pev(id, pev_oldbuttons) & g_iButtons[g_iTurn[iTeam] - 1]) )
			//&& g_iButtons[g_iTurn[iTeam] - 1] != g_iButtons[g_iTurn[iTeam]])
			
			if(g_iButtons[g_iTurn[iTeam]] == g_iButtons[g_iTurn[iTeam] - 1]
			&& g_iLastButtons[id] & g_iButtons[g_iTurn[iTeam]])
			{
				return;
			}
		}
		
		g_iLastButtons[id] = iButtons
		//set_pev(id, pev_oldbuttons, pev(id, pev_oldbuttons) | g_iButtons[g_iTurn[iTeam]])
		++g_iTurn[iTeam]
		
		
		if(g_iTurn[iTeam] >= MAX_COMBO_BUTTONS)
		{
			new iLoser = iTeam == LR_GUARD ? g_iLastRequest[LR_PRISONER] : g_iLastRequest[LR_GUARD]
			
			// Put it after end for fix
			EndLastRequest(id, iLoser)
			KillPlayer(id)
		}
	}
	
	else
	{
		g_iLastButtons[id] = iButtons
	}
}

public ShowPattern(iTaskId)
{
	g_iCmdStartFwd = register_forward(FM_CmdStart, "fw_CmdStart", 1)
	ClearSyncHud(0, gSyncHud)
	
	set_hudmessage(170, 0, 170, -1.0, 0.15, 1, 0.0, 16.0, 0.1, 0.1, -1)
	ShowSyncHudMsg(0, gSyncHud, g_szPattern)
}

public JS_LongJump(id, Float:flDistance)
{
	switch( ( g_iLastRequest[LR_PRISONER] == id ) )
	{
		case 1:
		{
			if(!g_fl_LG_Distance[LR_PRISONER])
			{
				new szName[32]; get_user_name(id, szName, 31)
				
				g_fl_LG_Distance[LR_PRISONER] = flDistance
				
				ColorChat(0, NORMAL, "%s ^1Prisoner ^3%s ^1did a longjump with ^3%f ^1distance", g_szPrefix, szName, flDistance)
				
				g_iLongJumpsDone++
			}
		}
		
		case 0:
		{
			if(!g_fl_LG_Distance[LR_GUARD])
			{
				g_fl_LG_Distance[LR_GUARD] = flDistance
				new szName[32]; get_user_name(id, szName, 31)
				
				ColorChat(0, NORMAL, "%s ^1Prisoner ^3%s ^1did a longjump with ^3%f ^1distance", g_szPrefix, szName, flDistance)
				
				g_iLongJumpsDone++
			}
		}
	}
	
	if(g_iLongJumpsDone == 2)
	{
		new szName[32], szLoserName[32]
		if(g_fl_LG_Distance[LR_GUARD] < g_fl_LG_Distance[LR_PRISONER])
		{
			get_user_name(g_iLastRequest[LR_PRISONER], szName, 31)
			get_user_name(g_iLastRequest[LR_GUARD], szLoserName, 31)
			
			ColorChat(id, NORMAL, "%s ^1Prisoner ^3%s ^1won the ^3LONGJUMP CHALLANGE!", g_szPrefix, szName)
			ColorChat(id, NORMAL, "%s ^1Player ^3%s ^1will be thrown to the space hahahahaha", g_szPrefix, szLoserName)
			
			//StartRocket(g_iLastRequest[LR_GUARD])
			KillPlayer(id)
			EndLastRequest(g_iLastRequest[LR_PRISONER], g_iLastRequest[LR_GUARD], 0)
			
		}
		
		else if( g_fl_LG_Distance[LR_GUARD] > g_fl_LG_Distance[LR_PRISONER])
		{
			get_user_name(g_iLastRequest[LR_GUARD], szName, 31)
			get_user_name(g_iLastRequest[LR_PRISONER], szLoserName, 31)
			
			ColorChat(id, NORMAL, "%s ^1Gaurd ^3%s ^1Won the ^3LONGJUMP CHALLANGE!", g_szPrefix, szName)
			ColorChat(id, NORMAL, "%s ^1Player ^3%s ^1will be thrown to space hahahahaha", g_szPrefix, szLoserName)
			
			//StartRocket(g_iLastRequest[LR_PRISONER])
			KillPlayer(id)
			EndLastRequest(g_iLastRequest[LR_GUARD], g_iLastRequest[LR_PRISONER], 0)
		}
	}
}

/*
stock EndLongJumpGame()
{
	callfunc_begin("Off_JS_Forwards", "jumpstats_long.amxx")
	callfunc_end()
}*/

//stock StartRocket(id)
//{
	//KillPlayer(id)	
//}

stock KillPlayer(id)
{
	switch(random(2))
	{
		case 1:
		{
			emit_sound(id, CHAN_WEAPON, "Jail_Lr/shoop.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_task(1.2, "StartShoop", id)
			
			
		}
		
		case 0:
		{
			emit_sound(id,CHAN_WEAPON ,"weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_user_maxspeed(id, 0.01)
			set_task(1.2, "rocket_liftoff" , id)
		}
	}
}

public StartShoop(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	set_task(2.5, "ShoopdaWhoop", id)
}

public rocket_liftoff(victim)
{
	if (!is_user_alive(victim)) return
	set_user_gravity(victim,-0.50)
	client_cmd(victim,"+jump;wait;wait;-jump")
	emit_sound(victim, CHAN_VOICE, "weapons/rocket1.wav", 1.0, 0.5, 0, PITCH_NORM)
	rocket_effects(victim)
}

new rocket_z[33]
public rocket_effects(victim)
{
	if (!is_user_alive(victim)) 
	{
		return
	}

	static msgDamage
	if(!msgDamage)
	{
		msgDamage = get_user_msgid("Damage")
	}
	
	new vorigin[3]
	get_user_origin(victim,vorigin)

	message_begin(MSG_ONE, msgDamage, {0,0,0}, victim)
	write_byte(30) // dmg_save
	write_byte(30) // dmg_take
	write_long(1<<16) // visibleDamageBits
	write_coord(vorigin[0]) // damageOrigin.x
	write_coord(vorigin[1]) // damageOrigin.y
	write_coord(vorigin[2]) // damageOrigin.z
	message_end()

	if (rocket_z[victim] == vorigin[2])
	{
		rocket_explode(victim)
	}

	rocket_z[victim] = vorigin[2]

	//Draw Trail and effects

	//TE_SPRITETRAIL - line of moving glow sprites with gravity, fadeout, and collisions
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( 15 )
	write_coord( vorigin[0]) // coord, coord, coord (start)
	write_coord( vorigin[1])
	write_coord( vorigin[2])
	write_coord( vorigin[0]) // coord, coord, coord (end)
	write_coord( vorigin[1])
	write_coord( vorigin[2] - 30)
	write_short( blueflare2 ) // short (sprite index)
	write_byte( 5 ) // byte (count)
	write_byte( 1 ) // byte (life in 0.1's)
	write_byte( 1 )  // byte (scale in 0.1's)
	write_byte( 10 ) // byte (velocity along vector in 10's)
	write_byte( 5 )  // byte (randomness of velocity in 10's)
	message_end()

	//TE_SPRITE - additive sprite, plays 1 cycle
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 17 )
	write_coord(vorigin[0])  // coord, coord, coord (position)
	write_coord(vorigin[1])
	write_coord(vorigin[2] - 30)
	write_short( mflash ) // short (sprite index)
	write_byte( 15 ) // byte (scale in 0.1's)
	write_byte( 255 ) // byte (brightness)
	message_end()

	set_task(0.2, "rocket_effects", victim)
}

public rocket_explode(victim)
{
	if (is_user_alive(victim))
	{
		new vec1[3]
		get_user_origin(victim,vec1)

		// blast circles
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
		write_byte( 21 )
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] - 10)
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] + 1910)
		write_short( white )
		write_byte( 0 ) // startframe
		write_byte( 0 ) // framerate
		write_byte( 2 ) // life
		write_byte( 16 ) // width
		write_byte( 0 ) // noise
		write_byte( 188 ) // r
		write_byte( 220 ) // g
		write_byte( 255 ) // b
		write_byte( 255 ) //brightness
		write_byte( 0 ) // speed
		message_end()

		//Explosion2
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte( 12 )
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2])
		write_byte( 188 ) // byte (scale in 0.1's)
		write_byte( 10 ) // byte (framerate)
		message_end()

		//smoke
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
		write_byte( 5 )
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2])
		write_short( smoke )
		write_byte( 2 )
		write_byte( 10 )
		message_end()

		user_kill(victim,1)
	}

	//stop_sound
	emit_sound(victim, CHAN_VOICE, "weapons/rocket1.wav", 0.0, 0.0, (1<<5), PITCH_NORM)

	set_user_maxspeed(victim,1.0)
	set_user_gravity(victim,1.00)
}

public StartBeacon()
{
	if( g_iCurrentGame == LR_NONE )
	{
		return;
	}
	
	new id;
	
	for( new i = 0; i < 2; i++ )
	{
		id = g_iLastRequest[ i ];
		
		static origin[3]
		emit_sound( id, CHAN_ITEM, g_szBeaconSound, 1.0, ATTN_NORM, 0, PITCH_NORM )
		
		get_user_origin( id, origin )
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
		write_byte( TE_BEAMCYLINDER )
		write_coord( origin[0] )	//position.x
		write_coord( origin[1] )	//position.y
		write_coord( origin[2]-20 )	//position.z
		write_coord( origin[0] )    	//axis.x
		write_coord( origin[1] )    	//axis.y
		write_coord( origin[2]+200 )	//axis.z
		write_short( g_iSprite )	//sprite index
		write_byte( 0 )       	//starting frame
		write_byte( 1 )       	//frame rate in 0.1's
		write_byte( 6 )        	//life in 0.1's
		write_byte( 10 )        	//line width in 0.1's
		write_byte( 1 )        	//noise amplitude in 0.01's
		
		switch( cs_get_user_team( id ) )
		{
			case CS_TEAM_CT:
			{
				write_byte( 0 );
				write_byte( 0 );
				write_byte( 255 );
			}
			
			case CS_TEAM_T:
			{
				write_byte( 255 );
				write_byte( 0 );
				write_byte( 0 );
			}
		}
		
		write_byte( 255 );			// brightness
		write_byte( 0 );			// scroll speed in 0.1's
		message_end();
	}
}
	
stock EndLastRequest( iWinner, iLoser, iJustEnd = 0, iChat = 1 )
{	
	if(!iJustEnd)
	{
		new szWinnerName[ 32 ], szLoserName[ 32 ];
		
		get_user_name( iWinner, szWinnerName, 31 );
		get_user_name( iLoser, szLoserName, 31 );
		
		if(iChat)
		{
			ColorChat( 0, NORMAL, "%s !t%s!n beat !t%s!n in the !gLast Request!n.", g_szPrefix, szWinnerName, szLoserName );
		}
		
		strip_user_weapons( iWinner );
	}
	
	if(task_exists(TASKID_RANDOM_HUD))
	{
		ClearSyncHud(0, gSyncHud)
		
		//server_print("Removed")
		remove_task(TASKID_RANDOM_HUD)
	}
	
	client_cmd(0, "mp3 stop; stopsound")
	PlaySound(0, g_szLrEndSounds[random(sizeof(g_szLrEndSounds))])

	switch(g_iCurrentGame)
	{
		case LR_LONGJUMP:
		{
			new iRet = callfunc_begin("Off_JS_Forwards", "jumpstats_long.amxx")
			
			if(iRet != 1)
			{
				log_amx("Callfunc_begin(Off) error #%d", iRet)
			}
			
			else
			{
				callfunc_end()
			}
		}

		case LR_COMBO:
		{
			unregister_forward(FM_CmdStart, g_iCmdStartFwd, 1)
			g_iCmdStartFwd = -1
			ClearSyncHud(0, gSyncHud)
			
			if(task_exists(TASKID_SHOW_PATTERN))
			{
				remove_task(TASKID_SHOW_PATTERN)
			}
		}
	}
	
	g_iCurrentGame = LR_NONE;
	
	g_iLastRequest[ LR_PRISONER ] = 0;
	g_iLastRequest[ LR_GUARD ] = 0;
	
	set_task( 0.1, "Task_EndLR", TASK_ENDLR + iWinner );
}

public Task_EndLR( iTaskID )
{
	new id = iTaskID - TASK_ENDLR;
	
	if(!is_user_alive(id))
	{
		return;
	}
	
	strip_user_weapons( id );
	set_user_health( id, 100 );
	
	if( cs_get_user_team( id ) == CS_TEAM_CT )
		GiveWeapons( id );
}

//////////////////////////////
//			LR Games		//
//////////////////////////////

LR_Knife( id )
{
	new szMapName[ 32 ], iCTOrigin[ 3 ], iTOrigin[ 3 ];
	
	give_item( id, "weapon_knife" );
	
	get_mapname( szMapName, charsmax( szMapName ) );
	
	if( equali( szMapName, "some1s_jailbreak" ) )
	{
		iCTOrigin = { -759, 1047, 100 };
		iTOrigin = { -585, 867, 100 };
		
		if( id == g_iLastRequest[ LR_PRISONER ] )
			set_user_origin( id, iTOrigin );
		
		else
			set_user_origin( id, iCTOrigin );
	}
}

LR_Shotgun( id )
{
	give_item( id, "weapon_m3" );
	cs_set_user_bpammo( id, CSW_M3, 28 );
}

LR_Scout( id )
{
	new szMapName[ 32 ], iCTOrigin[ 3 ], iTOrigin[ 3 ];

	give_item( id, "weapon_scout" );
	cs_set_user_bpammo( id, CSW_SCOUT, 90 );
	
	get_mapname( szMapName, charsmax( szMapName ) );
	
	if( equali( szMapName, "some1s_jailbreak" ) )
	{
		iCTOrigin = { -2898, -2040, 37 };
		iTOrigin = { -2908, 905, 37 };
		
		if( id == g_iLastRequest[ LR_PRISONER ] )
			set_user_origin( id, iTOrigin );
		
		else
			set_user_origin( id, iCTOrigin );
	}
}

LR_Awp( id )
{
	new szMapName[ 32 ], iCTOrigin[ 3 ], iTOrigin[ 3 ];

	give_item( id, "weapon_awp" );
	cs_set_user_bpammo( id, CSW_AWP, 30 );
	
	get_mapname( szMapName, charsmax( szMapName ) );
	
	if( equali( szMapName, "some1s_jailbreak" ) )
	{
		iCTOrigin = { -2898, -2040, 37 };
		iTOrigin = { -2908, 905, 37 };
		
		if( id == g_iLastRequest[ LR_PRISONER ] )
			set_user_origin( id, iTOrigin );
		
		else
			set_user_origin( id, iCTOrigin );
	}
}

LR_Shot4Shot( id )
{
	new szMapName[ 32 ], iCTOrigin[ 3 ], iTOrigin[ 3 ];
	
	if( id == g_iLastRequest[ LR_PRISONER ] )
	{
		cs_set_weapon_ammo( give_item( id, "weapon_deagle" ), 1 );
	}
	
	else cs_set_weapon_ammo( give_item( id, "weapon_deagle" ), 0 );
	
	get_mapname( szMapName, charsmax( szMapName ) );
	
	if( equali( szMapName, "some1s_jailbreak" ) )
	{
		iCTOrigin = { -1352, 271, 38 };
		iTOrigin = { -1338, -782, 38 };
		
		if( id == g_iLastRequest[ LR_PRISONER ] )
			set_user_origin( id, iTOrigin );
		
		else
			set_user_origin( id, iCTOrigin );
	}
}

LR_Race( id )
{
	give_item( id, "weapon_knife" );
}

LR_Spray( id )
{
	give_item( id, "weapon_knife" );
}

LR_GunToss( id )
{
	give_item( id, "weapon_knife" );
	cs_set_weapon_ammo( give_item( id, "weapon_deagle" ), 0 );
}

LR_NadeToss( id )
{
	give_item( id, "weapon_knife" );
	give_item( id, "weapon_smokegrenade" );
	ColorChat( id, NORMAL, "%s Do not throw the nade until you are doing the toss!", g_szPrefix );
}

public Task_Advertise()
{
	ColorChat( 0, NORMAL, "%s This server is running !tLast Request v%s !nby !tH3avY Ra1n!n.", g_szPrefix, g_szVersion );
}

GiveWeapons( id )
{
	give_item( id, "weapon_m4a1" );
	give_item( id, "weapon_deagle" );
	give_item( id, "weapon_smokegrenade" );
	
	cs_set_user_bpammo( id, CSW_M4A1, 90 );
	cs_set_user_bpammo( id, CSW_DEAGLE, 120 );
}

ColorChat( id, colour, const text[], any:... )
{
	if( !get_playersnum() )
	{
		return;
	}
	
	static message[192];
	
	message[0] = 0x01;
	vformat(message[1], sizeof(message) - 1, text, 4);
	
	replace_all(message, sizeof(message) - 1, "!g", "^x04");
	replace_all(message, sizeof(message) - 1, "!n", "^x01");
	replace_all(message, sizeof(message) - 1, "!t", "^x03");
	
	static index, MSG_Type;
	
	if( !id )
	{
		static i;
		for(i = 1; i <= g_iMaxPlayers; i++)
		{
			if( g_bConnected[i] )
			{
				index = i;
				break;
			}
		}
		
		MSG_Type = MSG_ALL;
	}
	else
	{
		MSG_Type = MSG_ONE;
		index = id;
	}
	
	static bool:bChanged;
	if( colour == GREY || colour == RED || colour == BLUE )
	{
		message_begin(MSG_Type, g_msgTeamInfo, _, index);
		write_byte(index);
		write_string(g_szTeamName[colour]);
		message_end();
		
		bChanged = true;
	}
	
	message_begin(MSG_Type, g_msgSayText, _, index);
	write_byte(index);
	write_string(message);
	message_end();
	
	if( bChanged )
	{
		message_begin(MSG_Type, g_msgTeamInfo, _, index);
		write_byte(index);
		write_string(g_szTeamName[_:cs_get_user_team(index)]);
		message_end();
	}
}

get_playercount( CsTeams:iTeam, iStatus )
{
	new iPlayerCount;
	
	for( new i = 1; i <= g_iMaxPlayers; i++ )
	{
		if( !g_bConnected[ i ] || cs_get_user_team( i ) != iTeam ) continue;
		
		switch( iStatus )
		{
			case DEAD: if( g_bAlive[ i ] ) continue;
			case ALIVE: if( !g_bAlive[ i ] ) continue;
		}
		
		iPlayerCount++;
	}
	
	return iPlayerCount;
}
