//Size Menu Function implemented by dejan - https://forums.alliedmods.net/member.php?u=49270
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <fdownloader>

// #define CHAT_TAG "[BlockBuilder] "
//#define MESS "[BlockBuilder] %s"

new currentEnt[MAXPLAYERS+1];
new byUnits[MAXPLAYERS+1];
new Unit_Rotation[MAXPLAYERS+1] = false

/*
enum struct BlockConfig
{
	char BlockName[64],
	char ModelPath[256],
	char ModelName[256],
	char ModelNameLarge[256],
	char ModelNamePole[256],
	char SoundPath[256],
	float EffectTime,
	float CooldownTime
}*/

#define MAX_EDICTS MAX_EDICTS
#define MAX_BLOCKS 29

#define SIZE_NORMAL 1
#define SIZE_LARGE	2
#define SIZE_SMALL	3
#define SIZE_POLE 	4

enum BlockConfig
{
	String:BlockName[64],
	String:ModelName[256],
	String:ModelNameLarge[256],
	String:ModelNameSmall[256],
	String:ModelNamePole[256],
	String:SoundPath[256],
	Float:EffectTime,
	Float:CooldownTime
}

#define     HEGrenadeOffset        14    // (14 * 4)
#define     FlashbangOffset        15    // (15 * 4)
#define     SmokegrenadeOffset        16    // (16 * 4)
#define     IncenderyGrenadesOffset    17    // (17 * 4) Also Molotovs
#define     DecoyGrenadeOffset        18    // (18 * 4)

new const String:INVI_SOUND_PATH[] = "*blockbuilder/invincibility.mp3"
new const String:STEALTH_SOUND_PATH[] = "*blockbuilder/stealth.mp3"
new const String:NUKE_SOUND_PATH[] = "*blockbuilder/nuke.mp3"
new const String:BOS_SOUND_PATH[] = "*blockbuilder/bootsofspeed.mp3"
new const String:CAM_SOUND_PATH[] = "*blockbuilder/camouflage.mp3"
new const String:TELE_SOUND_PATH[] = "*blockbuilder/teleport.mp3"

//new DuckHop[MAXPLAYERS+1] = false;
//new DuckHop_Perform[MAXPLAYERS+1] = false;
//new Float:DuckHop_Velocity[MAXPLAYERS+1][3]

new g_iDragEnt[MAXPLAYERS+1];
new g_iBlockSelection[MAXPLAYERS+1]={0, ...};
new g_iBlocks[MAX_EDICTS] = {-1, ...};

new g_iTeleporters[MAX_EDICTS] = {-1, ...};
// new g_iClientBlocks[MAXPLAYERS+1] = {-1, ...};
new g_iGravity[MAXPLAYERS+1]={0,...};
new g_iAmmo;
new g_iPrimaryAmmoType;
new g_iCurrentTele[MAXPLAYERS+1]={-1,...};
new g_iBeamSprite = 0;
new CurrentModifier[MAXPLAYERS+1] = 0
new Float:TrampolineForce[MAX_EDICTS] = 0.0
new Float:SpeedBoostForce_1[MAX_EDICTS] = 0.0
new Float:SpeedBoostForce_2[MAX_EDICTS] = 0.0
//new Float:velocity_duck = 0.0
new Block_Transparency[MAX_EDICTS] = 0
new blocksize[MAXPLAYERS+1];

new bool:g_bNoFallDmg[MAXPLAYERS+1]={false,...};
new bool:g_bInvCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bInv[MAXPLAYERS+1]={false,...};
new bool:g_bStealthCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bBootsCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bLocked[MAXPLAYERS+1]={false,...};
new bool:g_bTriggered[MAX_EDICTS] = {false, ...};
new bool:g_bCamCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bDeagleCanUse[MAXPLAYERS+1]={true,...}; 
new bool:g_bAwpCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bHEgrenadeCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bFlashbangCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bSmokegrenadeCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bSnapping[MAXPLAYERS+1]={false,...};
new bool:g_bGroups[MAXPLAYERS+1][MAX_EDICTS];
new bool:g_bRandomCantUse[MAXPLAYERS+1]

new Handle:Block_Timers[64]
new Block_Touching[MAXPLAYERS+1] = 0;


new Float:g_fSnappingGap[MAXPLAYERS+1]={0.0,...};
new Float:g_fClientAngles[MAXPLAYERS+1][3];
new Float:g_fAngles[MAX_EDICTS][3];

// Skriv antal blocks!
new g_eBlocks[MAX_BLOCKS][BlockConfig]; 

new Handle:g_hClientMenu[MAXPLAYERS+1];
new Handle:g_hBlocksKV = INVALID_HANDLE;
new Handle:g_hTeleSound = INVALID_HANDLE;

new Handle:Cvar_Prefix;
new Handle:Cvar_Height;
new Handle:Cvar_RandomTime;
new Float:TrueForce
new Float:randomblock_time = 0.0;
new String:CHAT_TAG[64];

new RoundIndex = 0; // Quite lazy way yet effective one

public Plugin:myinfo =
{
	name = "Blockmaker",
	author = "x3ro + k0nan",
	description = "Spawn Blocks",
	version = "1.046",
	url = "https://forums.alliedmods.net/showthread.php?t=270733"
}

 
//public Action:Command_velocity_duck(client, args)
//{
//	decl String:argc[18]
//	GetCmdArg(1, argc, sizeof(argc))
	
//	velocity_duck = StringToFloat(argc)
//}

public OnPluginStart()

{

//	new pieces[4];
//	new longip = GetConVarInt(FindConVar("hostip"));
//	
//	pieces[0] = (longip >> 24) & 0x000000FF;
//	pieces[1] = (longip >> 16) & 0x000000FF;
//	pieces[2] = (longip >> 8) & 0x000000FF;
//	pieces[3] = longip & 0x000000FF;
//
//	decl String:NetIP[32]
//	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
//	if(StrEqual(NetIP, "255.255.255.255"))
//	{
	randomblock_time = 60.0;
	g_hTeleSound = CreateConVar("sm_blockbuilder_telesound", "blockbuilder/teleport.mp3");
	Cvar_Height = CreateConVar("sm_blockbuilder_block_height",	"0.0", "Height of block (Can be -10.0 aswell as 15.0")
	HookConVarChange(Cvar_Height, OnHeightConVarChange)

	Format(CHAT_TAG, sizeof(CHAT_TAG), "[BB]")
	Cvar_Prefix = CreateConVar("sm_blockbuilder_prefix",	"[BB]", "A Prefix used by messages within Blockbuilder...")
	HookConVarChange(Cvar_Prefix, OnPrefixChanged)
	
	Cvar_RandomTime = CreateConVar("sm_blockbuilder_random_cooldown", "60", "A cooldown for using random block for player. Example: After you use once random block you need to wait 60 sec.")
	HookConVarChange(Cvar_RandomTime, OnRandomChanged)

	//
	//    ADMIN FLAG "O" FOR USING BLOCKMAKER
	//    ADMIN FLAG "P" FOR SAVING AND LOADING
	//
	
//	RegConsoleCmd("sm_bb", Command_BlockBuilder);
	RegAdminCmd("sm_bb", Command_BlockBuilder, ADMFLAG_CUSTOM1);
//	RegConsoleCmd("sm_bsave", Command_SaveBlocks);
	RegAdminCmd("sm_bsave", Command_SaveBlocks, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_unitmover", Command_UnitMove, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_blocksnap", Command_BlockSnap, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_snapgrid", Command_SnapGrid, ADMFLAG_CUSTOM1);
	RegAdminCmd("+grab", Command_GrabBlock, ADMFLAG_CUSTOM1);
	RegAdminCmd("-grab", Command_ReleaseBlock, ADMFLAG_CUSTOM1);
	RegAdminCmd("tgrab", Command_ToggleGrab, ADMFLAG_CUSTOM1);
//	RegAdminCmd("velocity_duck", Command_velocity_duck, ADMFLAG_CUSTOM1);
	
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	
	AutoExecConfig();
	
	g_iAmmo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	g_iPrimaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	
	new String:file[256];
	BuildPath(Path_SM, file, sizeof(file), "configs/blockbuilder.blocks.txt");
	
	//ReadBlocksFile();
	
	g_hBlocksKV = CreateKeyValues("Blocks");
}

void ReadBlocksFile()
{
	new Handle:kv = CreateKeyValues("Blocks");
	FileToKeyValues(kv, file);
	
	if (!KvGotoFirstSubKey(kv))
	{
		PrintToServer("No first subkey");
		return;
	}
	
	new i = 0;
	
	do
	{		
		KvGetSectionName(kv, g_eBlocks[i][BlockName], sizeof BlockName);
		//KvGetString(kv, "path", g_eBlocks[i][ModelPath], sizeof ModelPath);
		KvGetString(kv, "model", g_eBlocks[i][ModelName], sizeof ModelName);
		KvGetString(kv, "model_large", g_eBlocks[i][ModelNameLarge], sizeof(ModelNameLarge));
		KvGetString(kv, "model_small", g_eBlocks[i][ModelNameSmall], sizeof(ModelNameSmall))
		KvGetString(kv, "model_pole", g_eBlocks[i][ModelNamePole], sizeof(ModelNamePole))
		KvGetString(kv, "sound", g_eBlocks[i][SoundPath], sizeof SoundPath);
		g_eBlocks[i][EffectTime] = KvGetFloat(kv, "effect");
		g_eBlocks[i][CooldownTime] = KvGetFloat(kv, "cooldown");
		++i;
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);
}

public Action:Command_GrabBlock(client, args)
{
	if(g_iDragEnt[client] == 0)
	{
		new ent = GetClientAimTarget(client, false);
		if(IsValidBlock(ent))
		{
			g_iDragEnt[client] = ent;
			if(g_bGroups[client][g_iDragEnt[client]])
			{
				for(new i=0;i<MAX_EDICTS;++i)
				{
					if(IsValidBlock(i) && g_bGroups[client][i])
					{
						SetEntityMoveType(i, MOVETYPE_VPHYSICS);
						AcceptEntityInput(i, "enablemotion");
					}
				}
			}
			else
			{
				SetEntityMoveType(g_iDragEnt[client], MOVETYPE_VPHYSICS);
				AcceptEntityInput(g_iDragEnt[client], "enablemotion");
			}
			//PrintToChat(client, MESS, "Block has been grabbed.");
		}
		else
		{
	//		CreateBlock(client);
		}
	}
	// Fixar "Unknown Command"
	return Plugin_Handled;
}

public Action:Command_ReleaseBlock(client, args)
{
	if(g_iDragEnt[client] != 0)
	{
		new Float:fVelocity[3] = {0.0, 0.0, 0.0};
		TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], fVelocity);
		if(g_bGroups[client][g_iDragEnt[client]])
		{
			for(new i=0;i<MAX_EDICTS;++i)
			{
				if(IsValidBlock(i) && g_bGroups[client][i])
				{
					SetEntityMoveType(i, MOVETYPE_NONE);
					AcceptEntityInput(i, "disablemotion");
				}
			}
		}
		else
		{
			SetEntityMoveType(g_iDragEnt[client], MOVETYPE_NONE);
			AcceptEntityInput(g_iDragEnt[client], "disablemotion");
		}
		g_iDragEnt[client] = 0;
		//PrintToChat(client, MESS, "Block has been released.");
	}
	// Fixar "Unknown Command"
	return Plugin_Handled;
}

public Action:Command_ToggleGrab(client, args)
{
	if(g_iDragEnt[client] != 0)
	{
		new Float:fVelocity[3] = {0.0, 0.0, 0.0};
		TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], fVelocity);
		if(g_bGroups[client][g_iDragEnt[client]])
		{
			for(new i=0;i<MAX_EDICTS;++i)
			{
				if(IsValidBlock(i) && g_bGroups[client][i])
				{
					SetEntityMoveType(i, MOVETYPE_NONE);
					AcceptEntityInput(i, "disablemotion");
				}
			}
		}
		else
		{
			SetEntityMoveType(g_iDragEnt[client], MOVETYPE_NONE);
			AcceptEntityInput(g_iDragEnt[client], "disablemotion");
		}
		g_iDragEnt[client] = 0;
		//PrintToChat(client, MESS, "Block has been released.");
	}
	else
	{
		new ent = GetClientAimTarget(client, false);
		if(IsValidBlock(ent))
		{
			g_iDragEnt[client] = ent;
			if(g_bGroups[client][g_iDragEnt[client]])
			{
				for(new i=0;i<MAX_EDICTS;++i)
				{
					if(IsValidBlock(i) && g_bGroups[client][i])
					{
						SetEntityMoveType(i, MOVETYPE_VPHYSICS);
						AcceptEntityInput(i, "enablemotion");
					}
				}
			}
			else
			{
				SetEntityMoveType(g_iDragEnt[client], MOVETYPE_VPHYSICS);
				AcceptEntityInput(g_iDragEnt[client], "enablemotion");
			}
			//PrintToChat(client, MESS, "Block has been grabbed.");
		}
		else
		{
		//	CreateBlock(client);
		}
	}
}

public OnRandomChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	randomblock_time = StringToFloat(newVal)
}

public OnPrefixChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Format(CHAT_TAG, sizeof(CHAT_TAG), "%s", newVal)
}

public Action:Command_BlockSnap(client, args)
{
	if(g_bSnapping[client])
	{
		g_bSnapping[client] = false
		PrintToChat(client, "\x03%s\x04 Block Snapping Off.", CHAT_TAG);
	}
	else
	{
		PrintToChat(client, "\x03%s\x04 Block Snapping On.", CHAT_TAG);
		g_bSnapping[client] = true;
	}
}

public Action:Command_SnapGrid(client, args)
{
	decl String:argc[18]
	GetCmdArg(1, argc, sizeof(argc))
	
	g_fSnappingGap[client] = StringToFloat(argc)
}

public Action:Command_UnitMove(client, args)
{
	decl Float:vecAngles[3], Float:vecOrigin[3];
	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);
	
	new entity = GetClientAimTarget(client, false);
	if(IsValidBlock(entity) || g_iTeleporters[entity])
	{
		currentEnt[client] = entity
		DrawUnitMovePanel(client);
		return Plugin_Handled;
	}
	PrintToChat(client, "\x03%s\x04 You have to aim at the object to change it's position.", CHAT_TAG);
	DisplayMenu(CreateMainMenu(client), client, 0);
	
	return Plugin_Handled;
}

DrawUnitMovePanel(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Advanced Block Placement");
	decl String:concatedMoveBy[128];
	Format(concatedMoveBy, sizeof(concatedMoveBy), "%s%f", "Move by: ", float(byUnits[client]) / 10);
	DrawPanelItem(panel, concatedMoveBy);
	DrawPanelItem(panel, "X+");
	DrawPanelItem(panel, "X-");
	DrawPanelItem(panel, "Y+");
	DrawPanelItem(panel, "Y-");
	DrawPanelItem(panel, "Z+");
	DrawPanelItem(panel, "Z-");
	if(!Unit_Rotation[client])
	{
		DrawPanelItem(panel, "Mode: Position");
	}
	else
	{
		DrawPanelItem(panel, "Mode: Rotation");
	}
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, DrawUnitMovePanelHandler, 360);
 
	CloseHandle(panel);
}
/*
 DETOUR_DECL_STATIC5(KillEater, void*, void *, item, CBaseEntity *, attacker, CBaseEntity *, victim, struct kill_eater_event_t, data, int, unk5)
{
if (victim == 0)
return DETOUR_STATIC_CALL(KillEater)(item, attacker, victim, data, unk5);
*/

public DrawUnitMovePanelHandler(Handle:menu, MenuAction:action, client, key)
{
	if (action == MenuAction_Select)
	{
		new Float:currentEntLocation[3];
		if(!Unit_Rotation[client])
		{
			GetEntPropVector(currentEnt[client], Prop_Send, "m_vecOrigin", currentEntLocation);
		}
		else
		{
			GetEntPropVector(currentEnt[client], Prop_Data, "m_angRotation", currentEntLocation);  
		}
		
		new Float:byUnitsFloat = float(byUnits[client]) / 10;
		new Dont = false
		switch(key) 
		{
			case 1: 
			{
				switch(byUnits[client]) 
				{
					case 1: 
					{
						byUnits[client] = 5;
					}
					case 5: 
					{
						byUnits[client] = 10;
					}
					case 10: 
					{
						byUnits[client] = 80;
					}
					case 120: 
					{
						byUnits[client] = 320;
					}
					case 330: 
					{
						byUnits[client] = 640;
					}
					case 660: 
					{
						byUnits[client] = 1;
					}
					default: 
					{
						byUnits[client] = 1;
					}
				}
			}
			case 2: 
			{ 
				currentEntLocation[0] += byUnitsFloat;
			}
			case 3: 
			{ 
				currentEntLocation[0] -= byUnitsFloat;
			}
			case 4: 
			{ 
				currentEntLocation[1] += byUnitsFloat;
			}
			case 5: 
			{ 
				currentEntLocation[1] -= byUnitsFloat;
			}
			case 6: 
			{ 
				currentEntLocation[2] += byUnitsFloat;
			}
			case 7: 
			{ 
				currentEntLocation[2] -= byUnitsFloat;
			}
			case 8:
			{
					if(!Unit_Rotation[client])
					{
						Unit_Rotation[client] = true;
					}
					else
					{
						Unit_Rotation[client] = false;
					}
			}
			case 9: 
			{ 
				CreateMainMenu(client);
				Dont = true
			}
		}
		if(!Dont)
			DrawUnitMovePanel(client);
		if(!(key == 8))
		{
			if(!Unit_Rotation[client])
			{
				TeleportEntity(currentEnt[client], currentEntLocation, NULL_VECTOR, NULL_VECTOR);
			}
			else
			{
				TeleportEntity(currentEnt[client], NULL_VECTOR, currentEntLocation, NULL_VECTOR);
			}
		}
	}
}

public OnHeightConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TrueForce = StringToFloat(newVal)
}

// REMOVE BREAKABLES
public OnEntityCreated(entity, const String:classname[]) {  
    if(StrEqual(classname, "func_breakable") || StrEqual(classname, "func_breakable_surf")) { 
        SDKHook(entity, SDKHook_Spawn, Hook_OnEntitySpawn);  
    }  
}  
public Action:Hook_OnEntitySpawn(entity) {  
    AcceptEntityInput(entity, "Kill");  
    return Plugin_Handled;  
} 
// END OF REMOVE BREAKABLES

public OnConfigsExecuted()
{
	new String:sound[512];
	GetConVarString(g_hTeleSound, sound, sizeof(sound));
	if(!StrEqual(sound, ""))
	{
		PrecacheSound(sound);
	}
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// STEALTH FIX ?? 
	for(int client = 1; client <= MaxClients; client++) 
	{ 
		if(!IsClientInGame(client)) 
			continue;
		SetEntityRenderMode(client , RENDER_NORMAL); 
		SDKUnhook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
	} 

	for(new i=0;i<MAX_EDICTS;++i)
	{
		g_iBlocks[i]=-1;
		g_bTriggered[i]=false;
		g_iTeleporters[i]=-1;
	}
	for(new i=1;i<=MaxClients;++i)
	{
		g_bHEgrenadeCanUse[i]=true;
		g_bFlashbangCanUse[i]=true;
		g_bSmokegrenadeCanUse[i]=true;
		g_iCurrentTele[i]=-1;
		g_bInv[i]=false;
		g_bInvCanUse[i]=true;
		g_bStealthCanUse[i]=true;
		g_bBootsCanUse[i]=true;
		g_bLocked[i]=false;
		g_bNoFallDmg[i]=false;
		g_bCamCanUse[i]=true;
		g_bAwpCanUse[i]=true;
		g_bDeagleCanUse[i]=true;
		g_bRandomCantUse[i]=false;
	}
	RoundIndex++
	LoadBlocks();
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	g_bInv[client]=false;
	g_bInvCanUse[client]=true;
	g_bStealthCanUse[client]=true;
	g_bBootsCanUse[client]=true;
	g_bLocked[client]=false;
	g_bNoFallDmg[client]=false;
	g_bCamCanUse[client]=true;
	g_bAwpCanUse[client]=true;
	g_bDeagleCanUse[client]=true;
	g_bHEgrenadeCanUse[client]=true;
	g_bFlashbangCanUse[client]=true;
//	g_iClientBlocks[client]=-1;
	g_iCurrentTele[client]=-1;
	g_bSnapping[client] = false;
	g_bRandomCantUse[client] = false;
	g_fSnappingGap[client] = 0.0
	//size
	blocksize[client] = 1;
	
	for(new i=0;i<MAX_EDICTS;++i)
		g_bGroups[client][i]=false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnMapStart()
{
	ReadBlocksFile();
	
	RoundIndex = 0;
	SetConVarBool(FindConVar("sv_turbophysics"), true);

	for(new i=0;i<sizeof(g_eBlocks);++i)
	{
		if(strcmp(g_eBlocks[i][SoundPath], "")!=0)
			PrecacheSound(g_eBlocks[i][SoundPath], true);
	}
	
	PrecacheModel("models/platforms/b-tele.mdl", true);
	PrecacheModel("models/platforms/r-tele.mdl", true);
	PrecacheModel("models/player/ctm_gign.mdl");
	PrecacheModel("models/player/tm_phoenix.mdl");
	
	FakePrecacheSound(INVI_SOUND_PATH);
	FakePrecacheSound(STEALTH_SOUND_PATH);
	FakePrecacheSound(NUKE_SOUND_PATH);
	FakePrecacheSound(BOS_SOUND_PATH);
	FakePrecacheSound(CAM_SOUND_PATH);
	FakePrecacheSound(TELE_SOUND_PATH);

	DownloadsTable()
	
	g_iBeamSprite = PrecacheModel("materials/sprites/orangelight1.vmt");
	
	for(new i=0;i<MAX_EDICTS;++i)
	{
		for(new a=1;a<=MaxClients;++a)
		{
			g_bGroups[a][i]=false;
		}
		g_iBlocks[i]=-1;
		g_iTeleporters[i]=-1;
		g_bTriggered[i]=false;
	}
	
	if(g_hBlocksKV != INVALID_HANDLE)
	{
		CloseHandle(g_hBlocksKV);
		g_hBlocksKV = INVALID_HANDLE;
	}
		
	new String:file[256];
	new String:map[64];
	//new String:id[64];
	//GetCurrentWorkshopMap(map, 65, id, 65)
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, sizeof(file), "data/block.%s.txt", map);
	if(FileExists(file))
	{
		g_hBlocksKV = CreateKeyValues("Blocks");
		FileToKeyValues(g_hBlocksKV, file);
	}
}

DownloadsTable()
{
	File f = OpenFile("blockbuilder.downloadlist.txt", "r");
	
	if(f == null)
	{
		return;
	}
	
	char szLine[PLATFORM_MAX_PATH];
	while (ReadFileLine(f, szLine, sizeof szLine))
	{
		if (!szLine[0] || szLine[0] == ';' || szLine[0] == '#')
		{
			continue;
		}
		
		FDownloader_AddSinglePath(szLine);
	}
	
	for(i; i < MAX_BLOCKS; i++)
	{
		if (g_eBlocks[i][ModelName][0] != 0)
		{
			FormatEx(szLine, sizeof szLine, "%s", g_eBlocks[i][ModelName]);
			PrecacheModel(szLine);
		}
		
		if (g_eBlocks[i][ModelNameLarge][0] != 0)
		{
			FormatEx(szLine, sizeof szLine, "%s", g_eBlocks[i][ModelNameLarge]);
			PrecacheModel(szLine);
		}
		
		if (g_eBlocks[i][ModelNameSmall][0] != 0)
		{
			FormatEx(szLine, sizeof szLine, "%s", g_eBlocks[i][ModelNameSmall]);
			PrecacheModel(szLine);
		}
		
		if (g_eBlocks[i][ModelNamePole][0] != 0)
		{
			FormatEx(szLine, sizeof szLine, "%s", g_eBlocks[i][ModelNamePole]);
			PrecacheModel(szLine);
		}
	}
}

public Action:Command_SaveBlocks(client, args)
{
	if(client)
	{
//		if(!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 || GetUserFlagBits(client) & ADMFLAG_ROOT))
//		{
//			PrintToChat(client, "\x03%s\x04 You don't have permission to access this.", CHAT_TAG);
//			return Plugin_Handled;
//		}
	}
	else {
		new iPlayers = 0;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				iPlayers++;
			}
		}
		if(!iPlayers)
		{
			PrintToServer("You can only save when at least one client is in-game");
			return Plugin_Handled;
		}
	}
	
	
	if(g_hBlocksKV != INVALID_HANDLE)
		CloseHandle(g_hBlocksKV);
	g_hBlocksKV = CreateKeyValues("Blocks");
	KvGotoFirstSubKey(g_hBlocksKV);
	new index = 1, blocks=0,teleporters=0;
	new String:tmp[11];
	new Float:fPos[3], Float:fAng[3];
	for(new i=0;i<MAX_EDICTS;++i)
	{
		if(!IsValidBlock(i) || g_iTeleporters[i]==1)
			continue;
		
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", fPos);
		
	
		IntToString(index, tmp, sizeof(tmp));
		KvJumpToKey(g_hBlocksKV, tmp, true);
		if(g_iTeleporters[i]>1 && IsValidBlock(g_iTeleporters[i]))
		{
			GetEntPropVector(g_iTeleporters[i], Prop_Data, "m_vecOrigin", fAng);
			KvSetNum(g_hBlocksKV, "teleporter", 1);
			KvSetVector(g_hBlocksKV, "entrance", fPos);
			KvSetVector(g_hBlocksKV, "exit", fAng);
			teleporters++;
		}
		else
		{
			GetEntPropVector(i, Prop_Data, "m_angRotation", fAng);
			KvSetNum(g_hBlocksKV, "blocktype", g_iBlocks[i]);
			KvSetNum(g_hBlocksKV, "size", g_iBlocksize[i]);
			KvSetVector(g_hBlocksKV, "position", fPos);
			KvSetVector(g_hBlocksKV, "angles", fAng);
			if(g_iBlocks[i] == 5)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", TrampolineForce[i])
			}
			else if(g_iBlocks[i] == 6)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", SpeedBoostForce_1[i])
				KvSetFloat(g_hBlocksKV, "attrib2", SpeedBoostForce_2[i])
			}
			else if(g_iBlocks[i] == 28)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", SpeedBoostForce_1[i])
			}
			if(Block_Transparency[i] > 0)
				KvSetNum(g_hBlocksKV, "transparency", Block_Transparency[i])
			blocks++;
		}
		KvGoBack(g_hBlocksKV);
		index++;
	}
	KvRewind(g_hBlocksKV);
	new String:file[256];
	new String:map[64];
	//new String:id[64];

	//GetCurrentWorkshopMap(map, 65, id, 65)
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, sizeof(file), "data/block.%s.txt", map);
	KeyValuesToFile(g_hBlocksKV, file);
	
	PrintToChatAll("\x03%s\x04 %d blocks and %d pair of teleporters were saved.", CHAT_TAG, blocks, teleporters);
	PrintToServer("%d blocks and %d teleports saved", blocks, teleporters);

	return Plugin_Handled;
}

SaveBlocks(bool:msg=false)
{
	if(g_hBlocksKV != INVALID_HANDLE)
		CloseHandle(g_hBlocksKV);
	g_hBlocksKV = CreateKeyValues("Blocks");
	KvGotoFirstSubKey(g_hBlocksKV);
	new index = 1, blocks=0,teleporters=0;
	new String:tmp[11];
	new Float:fPos[3], Float:fAng[3];
	for(new i=MaxClients+1;i<=MAX_EDICTS;++i)
	{
		if(!IsValidBlock(i) || g_iTeleporters[i]==1)
			continue;
		
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", fPos);
		
	
		IntToString(index, tmp, sizeof(tmp));
		KvJumpToKey(g_hBlocksKV, tmp, true);
		if(g_iTeleporters[i]>1 && IsValidBlock(g_iTeleporters[i]))
		{
			GetEntPropVector(g_iTeleporters[i], Prop_Data, "m_vecOrigin", fAng);
			KvSetNum(g_hBlocksKV, "teleporter", 1);
			KvSetVector(g_hBlocksKV, "entrance", fPos);
			KvSetVector(g_hBlocksKV, "exit", fAng);
			teleporters++;
		}
		else
		{
			GetEntPropVector(i, Prop_Data, "m_angRotation", fAng);
			KvSetNum(g_hBlocksKV, "blocktype", g_iBlocks[i]);
			KvSetNum(g_hBlocksKV, "size", g_iBlocksize[i]);
			KvSetVector(g_hBlocksKV, "position", fPos);
			KvSetVector(g_hBlocksKV, "angles", fAng);
			if(g_iBlocks[i] == 5)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", TrampolineForce[i])
			}
			else if(g_iBlocks[i] == 6)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", SpeedBoostForce_1[i])
				KvSetFloat(g_hBlocksKV, "attrib2", SpeedBoostForce_2[i])
			}
			else if(g_iBlocks[i] == 28)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", SpeedBoostForce_1[i])
			}
			if(Block_Transparency[i] > 0)
				KvSetNum(g_hBlocksKV, "transparency", Block_Transparency[i])
			blocks++;
		}
		KvGoBack(g_hBlocksKV);
		index++;
	}
	KvRewind(g_hBlocksKV);
	new String:file[256];
	new String:map[64];
	//new String:id[64];

	//GetCurrentWorkshopMap(map, 65, id, 65)
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, sizeof(file), "data/block.%s.txt", map);
	KeyValuesToFile(g_hBlocksKV, file);
	
	if(msg)
	{
		PrintToChatAll("\x03%s\x04 %d blocks and %d pair of teleporters were saved.", CHAT_TAG, blocks, teleporters);
		PrintToServer("%d blocks and %d teleports saved", blocks, teleporters);
	}
}

LoadBlocks(bool:msg=false)
{
	if(g_hBlocksKV == INVALID_HANDLE)
		return;
		
	new teleporters=0, blocks=0;
	new Float:fPos[3], Float:fAng[3];
	KvRewind(g_hBlocksKV);
	KvGotoFirstSubKey(g_hBlocksKV);
	do
	{
		if(KvGetNum(g_hBlocksKV, "teleporter") == 1)
		{
			KvGetVector(g_hBlocksKV, "entrance", fPos);
			KvGetVector(g_hBlocksKV, "exit", fAng);
			g_iTeleporters[CreateTeleportEntrance(0, fPos)] = CreateTeleportExit(0, fAng);
			teleporters++;
		}
		else
		{
			KvGetVector(g_hBlocksKV, "position", fPos);
			KvGetVector(g_hBlocksKV, "angles", fAng);
			new transparency = KvGetNum(g_hBlocksKV, "transparency", 0)
			new blocktype = KvGetNum(g_hBlocksKV, "blocktype")
			new sizetype = KvGetNum(g_hBlocksKV, "size")
			if(blocktype == 5)
			{
				CreateBlock(0, blocktype, sizetype, fPos, fAng, KvGetFloat(g_hBlocksKV, "attrib1"), 0.0, transparency)
			}
			else if(blocktype == 6)
			{
				CreateBlock(0, blocktype, sizetype, fPos, fAng, KvGetFloat(g_hBlocksKV, "attrib1"), KvGetFloat(g_hBlocksKV, "attrib2"), transparency)
			}
			else if(blocktype == 28)
			{
				CreateBlock(0, blocktype, sizetype, fPos, fAng, KvGetFloat(g_hBlocksKV, "attrib1"), 0.0, transparency) 
			}
			else
			{
				CreateBlock(0, blocktype, sizetype, fPos, fAng, 0.0, 0.0, transparency);
			}
			blocks++;
		}
	} while (KvGotoNextKey(g_hBlocksKV));
	
	if(msg)
		PrintToChatAll("\x03%s\x04 %d blocks and %d pair of teleporters were loaded.", CHAT_TAG, blocks, teleporters);
}

//public Action:ResetPerform(Handle:timer, any:client)
//{
//	if(!DuckHop[client])
//		DuckHop_Perform[client] = false
//}
 
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	/*
	if(IsPlayerAlive(client))
	{
		if (buttons & IN_DUCK)
		{
			if (!(GetEntityFlags(client) & FL_ONGROUND))
			{
				if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
				{
				//	if(GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
				//	{
						DuckHop[client] = true;
				//	}
				}
			}
			else
			{
				decl Float:velocity[3]
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
				if(DuckHop[client])
				{
					DuckHop[client] = false
					
					DuckHop_Perform[client] = true
					DuckHop_Velocity[client][0] = velocity[0] * 5.5
					DuckHop_Velocity[client][1] = velocity[1] * 5.5 // velocity_duck
				}
				if(DuckHop_Perform[client])
				{
					if(buttons & IN_JUMP)
					{
						DuckHop_Velocity[client][2] = velocity[2]
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, DuckHop_Velocity[client])
					
					}
					else
					{
						CreateTimer(0.80, ResetPerform, client)
					}
				}
			}
		}
	}*/
	
	new Float:fPos[3];
	new Float:fPos2[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2]+=50.0;
	
	//new block_ent = GetClientAimTarget(client, false);
	
	for(new a=MaxClients+1;a<MAX_EDICTS;++a)
	{
		if(GetClientTeam(client)<2)
			continue;

		if(g_iBlocks[a]==10) // Could be a XP Block 
		{
			GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
			if(fPos[0] - 20.0 < fPos2[0] < fPos[0] + 20.0 && fPos[1] - 20.0 < fPos2[1] < fPos[1] + 20.0 && fPos[2] - 60.0 < fPos2[2] < fPos[2] + 60.0)
			{
				new iTeam=GetClientTeam(client);
				if(iTeam==2)
					PrintToChatAll("\x03%s\x04 %N has nuked the Counter-Terrorist team.", CHAT_TAG, client);
				else if(iTeam==3)
					PrintToChatAll("\x03%s\x04 %N has nuked the Terrorist team.", CHAT_TAG, client);
					
				g_iBlocks[a]=0;
				
				EmitSoundToAll(NUKE_SOUND_PATH)
				
				for(new i=1;i<=MaxClients;++i)
				{
					if(IsClientInGame(i))
					{
						if(IsPlayerAlive(i))
						{
							if((iTeam == 2 && GetClientTeam(i)==3) || (iTeam == 3 && GetClientTeam(i)==2))
							{
								if(!g_bInv[i])
									ForcePlayerSuicide(i);
							}
						}
					}
				}
				break;
			}
		} 
		else if(g_iBlocks[a]==14 || g_iBlocks[a]==43 || g_iBlocks[a]==72 || g_iBlocks[a]==101) // CT Barrier
		{
			if(GetClientTeam(client)==3)
			{
				if(!g_bLocked[client])
				{
					GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
					if(fPos[0] - 60.0 < fPos2[0] < fPos[0] + 60.0 && fPos[1] - 60.0 < fPos2[1] < fPos[1] + 60.0 && fPos[2] - 120.0 < fPos2[2] < fPos[2] + 120.0)
					{
						new Float:fVelocity[3];
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity); 
						ScaleVector(fVelocity, -2.0);
						fVelocity[2] = 0.0;
						g_bLocked[client]=true;
						CreateTimer(0.1, ResetLock, client);

						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
					}
				}
			}
		}
		else if(g_iBlocks[a]==15 || g_iBlocks[a]==44 || g_iBlocks[a]==73 || g_iBlocks[a]==102) // T Barrier
		{
		
			if(GetClientTeam(client)==2)
			{
				if(!g_bLocked[client])
				{
					GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
					if(fPos[0] - 60.0 < fPos2[0] < fPos[0] + 60.0 && fPos[1] - 60.0 < fPos2[1] < fPos[1] + 60.0 && fPos[2] - 120.0 < fPos2[2] < fPos[2] + 120.0)
					{
						new Float:fVelocity[3];
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity); 
						ScaleVector(fVelocity, -2.0);
						fVelocity[2] = 0.0;
						g_bLocked[client]=true;
						CreateTimer(0.1, ResetLock, client);

						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
					}
				}
			}
		} 
		else if(g_iBlocks[a]==19 || g_iBlocks[a]==5 || g_iBlocks[a]==6 || g_iBlocks[a]==35 || g_iBlocks[a]==64 || g_iBlocks[a]==93 || g_iBlocks[a]==36 || g_iBlocks[a]==65 || g_iBlocks[a]==94 || g_iBlocks[a]==48 || g_iBlocks[a]==77 || g_iBlocks[a]==105) // NOFALLDAMAGE for the NOFALLDMG Block TRAMPOLINE AND SPEEDBOOST
		{
			GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
			if(GetVectorDistance(fPos, fPos2)<=100.0)
			{
				if(!g_bNoFallDmg[client])
					CreateTimer(0.2, ResetNoFall, client);
				g_bNoFallDmg[client]=true;
			}
		} else if(g_iTeleporters[a]>1 && 2<=GetClientTeam(client)<=3)
		{
			GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
			if(IsValidBlock(g_iTeleporters[a]))
			{
				if(fPos[0] - 32.0 < fPos2[0] < fPos[0] + 32.0 && fPos[1] - 32.0 < fPos2[1] < fPos[1] + 32.0 && fPos[2] - 64.0 < fPos2[2] < fPos[2] + 64.0)
				{
					new String:sound[512];
					GetConVarString(g_hTeleSound, sound, sizeof(sound));
					GetEntPropVector(g_iTeleporters[a], Prop_Data, "m_vecOrigin", fPos2);
					TeleportEntity(client, fPos2, NULL_VECTOR, NULL_VECTOR);
					EmitSoundToClient(client, TELE_SOUND_PATH);
				}
			}
		}
	}
	if(g_iDragEnt[client] != 0)
	{
		if(IsValidEdict(g_iDragEnt[client]))
		{
			//	new ent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			//	if(ent != -1)
			//	{
			//		SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", 10000.0);
			//		SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", 10000.0);
			//	}
			
			new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];
			new Float:viewang[3];
			
			GetClientEyeAngles(client, viewang);
			GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
			GetClientEyePosition(client, vecPos);
			
			vecPos[0]+=vecDir[0]*200;
			vecPos[1]+=vecDir[1]*200;
			vecPos[2]+=vecDir[2]*200;
			
			GetEntPropVector(g_iDragEnt[client], Prop_Send, "m_vecOrigin", vecDir);
			
			new Float:fPos3[3];
			
			new bool:bSnap = false;
			new bool:bGroup = g_bGroups[client][g_iDragEnt[client]];
			
			if(g_bSnapping[client] && (FloatAbs(g_fClientAngles[client][1]) - FloatAbs(angles[1])) < 2.0 && !bGroup)
			{
				for(new i=MaxClients+1;i<MAX_EDICTS;++i)
				{
					if(IsValidBlock(i) && i != g_iDragEnt[client])
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPos3);
						if(GetVectorDistance(vecDir, fPos3) <= 60.0+g_fSnappingGap[client])
						{
							bSnap = true;
							new Float:d1, Float:d2, Float:d3, Float:d4, Float:d5, Float:d6;
							if(g_fAngles[i][1] == 0.0 && g_fAngles[i][2]==0.0)
							{
								fPos3[0]+=64.0;
								d1=GetVectorDistance(vecDir, fPos3);
								fPos3[0]-=128.0;
								d2=GetVectorDistance(vecDir, fPos3);
								fPos3[0]+=64.0;
								fPos3[1]+=64.0;
								d3=GetVectorDistance(vecDir, fPos3);
								fPos3[1]-=128.0;
								d4=GetVectorDistance(vecDir, fPos3);
								fPos3[1]+=64.0;
								fPos3[2]+=8.0;
								d5=GetVectorDistance(vecDir, fPos3);
								fPos3[2]-=16.0;
								d6=GetVectorDistance(vecDir, fPos3);
								fPos3[2]+=8.0;
								
								vecDir = fPos3;
								if(d1 < d2 && d1 < d3 && d1 < d4 && d1 < d5 && d1 < d6)
									vecDir[0]+=64.0+g_fSnappingGap[client];
								else if(d2 < d1 && d2 < d3 && d2 < d4 && d2 < d5 && d2 < d6)
									vecDir[0]-=64.0+g_fSnappingGap[client];
								else if(d3 < d1 && d3 < d2 && d3 < d4 && d3 < d5 && d3 < d6)
									vecDir[1]+=64.0+g_fSnappingGap[client];
								else if(d4 < d1 && d4 < d2 && d4 < d3 && d4 < d5 && d4 < d6)
									vecDir[1]-=64.0+g_fSnappingGap[client];
								else if(d5 < d1 && d5 < d2 && d5 < d3 && d5 < d4 && d5 < d6)
									vecDir[2]+=8.0+g_fSnappingGap[client];
								else if(d6 < d1 && d6 < d2 && d6 < d3 && d6 < d4 && d6 < d5)
									vecDir[2]-=8.0+g_fSnappingGap[client];
							} else if(g_fAngles[i][1]==0.0 && g_fAngles[i][2] == 90.0)
							{
								fPos3[0]+=64.0;
								d1=GetVectorDistance(vecDir, fPos3);
								fPos3[0]-=128.0;
								d2=GetVectorDistance(vecDir, fPos3);
								fPos3[0]+=64.0;
								fPos3[1]+=8.0;
								d3=GetVectorDistance(vecDir, fPos3);
								fPos3[1]-=16.0;
								d4=GetVectorDistance(vecDir, fPos3);
								fPos3[1]+=8.0;
								fPos3[2]+=64.0;
								d5=GetVectorDistance(vecDir, fPos3);
								fPos3[2]-=128.0;
								d6=GetVectorDistance(vecDir, fPos3);
								fPos3[2]+=64.0;
								
								vecDir = fPos3;
								if(d1 < d2 && d1 < d3 && d1 < d4 && d1 < d5 && d1 < d6)
									vecDir[0]+=64.0+g_fSnappingGap[client];
								else if(d2 < d1 && d2 < d3 && d2 < d4 && d2 < d5 && d2 < d6)
									vecDir[0]-=64.0+g_fSnappingGap[client];
								else if(d3 < d1 && d3 < d2 && d3 < d4 && d3 < d5 && d3 < d6)
									vecDir[1]+=8.0+g_fSnappingGap[client];
								else if(d4 < d1 && d4 < d2 && d4 < d3 && d4 < d5 && d4 < d6)
									vecDir[1]-=8.0+g_fSnappingGap[client];
								else if(d5 < d1 && d5 < d2 && d5 < d3 && d5 < d4 && d5 < d6)
									vecDir[2]+=64.0+g_fSnappingGap[client];
								else if(d6 < d1 && d6 < d2 && d6 < d3 && d6 < d4 && d6 < d5)
									vecDir[2]-=64.0+g_fSnappingGap[client];
							}
							else
							{
								fPos3[0]+=8.0;
								d1=GetVectorDistance(vecDir, fPos3);
								fPos3[0]-=16.0;
								d2=GetVectorDistance(vecDir, fPos3);
								fPos3[0]+=8.0;
								fPos3[1]+=64.0;
								d3=GetVectorDistance(vecDir, fPos3);
								fPos3[1]-=128.0;
								d4=GetVectorDistance(vecDir, fPos3);
								fPos3[1]+=64.0;
								fPos3[2]+=64.0;
								d5=GetVectorDistance(vecDir, fPos3);
								fPos3[2]-=128.0;
								d6=GetVectorDistance(vecDir, fPos3);
								fPos3[2]+=64.0;
								
								vecDir = fPos3;
								if(d1 < d2 && d1 < d3 && d1 < d4 && d1 < d5 && d1 < d6)
									vecDir[0]+=8.0+g_fSnappingGap[client];
								else if(d2 < d1 && d2 < d3 && d2 < d4 && d2 < d5 && d2 < d6)
									vecDir[0]-=8.0+g_fSnappingGap[client];
								else if(d3 < d1 && d3 < d2 && d3 < d4 && d3 < d5 && d3 < d6)
									vecDir[1]+=64.0+g_fSnappingGap[client];
								else if(d4 < d1 && d4 < d2 && d4 < d3 && d4 < d5 && d4 < d6)
									vecDir[1]-=64.0+g_fSnappingGap[client];
								else if(d5 < d1 && d5 < d2 && d5 < d3 && d5 < d4 && d5 < d6)
									vecDir[2]+=64.0+g_fSnappingGap[client];
								else if(d6 < d1 && d6 < d2 && d6 < d3 && d6 < d4 && d6 < d5)
									vecDir[2]-=64.0+g_fSnappingGap[client];
							}
							
							g_fAngles[g_iDragEnt[client]] = g_fAngles[i];
							break;
						}
					}
				}
			}
			
			if(!bSnap)
			{
				SubtractVectors(vecPos, vecDir, vecVel);
				ScaleVector(vecVel, 10.0);
				TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], vecVel);
				if(bGroup)
				{
					new Float:playerPos[3];
					GetClientEyePosition(client, playerPos);
					new Float:vecOrig[3];
					vecOrig = vecPos;
					
					for(new i=MaxClients+1;i<MAX_EDICTS;++i)
					{
						if(IsValidBlock(i) && i != g_iDragEnt[client] && g_bGroups[client][i])
						{
							vecPos = vecOrig;
							SubtractVectors(vecPos, vecDir, vecVel);
							ScaleVector(vecVel, 10.0);
							
							TeleportEntity(i, NULL_VECTOR, g_fAngles[i], vecVel);
						}
					}
				}
			}
			else
			{
				SetEntityMoveType(g_iDragEnt[client], MOVETYPE_NONE);
				AcceptEntityInput(g_iDragEnt[client], "disablemotion");
				new Float:nvel[3] = {0.0, 0.0, 0.0};
				TeleportEntity(g_iDragEnt[client], vecDir, g_fAngles[g_iDragEnt[client]], nvel);
				
				g_iDragEnt[client] = 0
				
				DisplayMenu(CreateMainMenu(client), client, 0);
			}
		}
		else
		{
			g_iDragEnt[client] = 0;
		}
	}
	
	g_fClientAngles[client]=angles;
	
	return Plugin_Continue;
}

public Action:ResetLock(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bLocked[client]=false;
	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity); 
	ScaleVector(fVelocity, -0.5);
	return Plugin_Stop;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data)
		return false;
	return true;
}

public Action:Command_BlockBuilder(client, args)
{
//	if(!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 || GetUserFlagBits(client) & ADMFLAG_ROOT))
//	{
//		PrintToChat(client, "\x03%s\x04 You don't have permission to access this.", CHAT_TAG);
//		return Plugin_Handled;
//	}
	
	new Handle:menu = CreateMainMenu(client);
	
	DisplayMenu(menu, client, 30); 
	return Plugin_Handled;
}

public Handler_BlockBuilder(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new bool:bDisplayMenu = true;
		if(param2==0)
		{
			bDisplayMenu = false;
			DisplayMenu(CreateBlocksMenu(), client, 0); 
		} else if(param2==1)
		{
			if(g_iDragEnt[client] == 0)
			{
				new ent = GetClientAimTarget(client, false);
				if(IsValidBlock(ent))
				{
					g_iDragEnt[client] = ent;
					if(g_bGroups[client][g_iDragEnt[client]])
					{
						for(new i=0;i<MAX_EDICTS;++i)
						{
							if(IsValidBlock(i) && g_bGroups[client][i])
							{
								SetEntityMoveType(i, MOVETYPE_VPHYSICS);
								AcceptEntityInput(i, "enablemotion");
							}
						}
					}
					else
					{
						SetEntityMoveType(g_iDragEnt[client], MOVETYPE_VPHYSICS);
						AcceptEntityInput(g_iDragEnt[client], "enablemotion");
					}
					//PrintToChat(client, MESS, "Block has been grabbed.");
				}
				else
				{
					// Skapar blocket
					CreateBlock(client);
				}
			}
			else
			{
				new Float:fVelocity[3] = {0.0, 0.0, 0.0};
				TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], fVelocity);
				if(g_bGroups[client][g_iDragEnt[client]])
				{
					for(new i=0;i<MAX_EDICTS;++i)
					{
						if(IsValidBlock(i) && g_bGroups[client][i])
						{
							SetEntityMoveType(i, MOVETYPE_NONE);
							AcceptEntityInput(i, "disablemotion");
						}
					}
				}
				else
				{
					SetEntityMoveType(g_iDragEnt[client], MOVETYPE_NONE);
					AcceptEntityInput(g_iDragEnt[client], "disablemotion");
				}
				g_iDragEnt[client] = 0;
				//PrintToChat(client, MESS, "Block has been released.");
			}
		}
		else if(param2==2) //Menusize
		{
			if(blocksize[client] == 1)
			{
				blocksize[client] = 2;
			}
			else if(blocksize[client] == 2)
			{
				blocksize[client] = 3;
			}
			else if(blocksize[client] == 3)
			{
				blocksize[client] = 4;
			}
			else
			{
				blocksize[client] = 1;
			}
		}
		else if(param2==3)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent))
			{
				decl Float:vAng[3];
				GetEntPropVector(ent, Prop_Data, "m_angRotation", vAng);

				if (vAng[1])
				{
					vAng[1] = 0.0;
					vAng[2] = 0.0;
				}
				else if (vAng[2])
					vAng[1] = 90.0;
				else
					vAng[2] = 90.0;
					
				g_fAngles[ent] = vAng;
					
				TeleportEntity(ent, NULL_VECTOR, vAng, NULL_VECTOR);
			}
			else
			{
				PrintToChat(client, "\x03%s\x04 You must aim at a block.", CHAT_TAG);
			}
		} else if(param2==4)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent) && g_iTeleporters[ent]==-1)
			{
				if(g_iBlockSelection[client]==g_iBlocks[ent])
				{
					PrintToChat(client, "%s The block type is the same, there's no need to change.", CHAT_TAG);
				}
				else
				{
					new String:mdl[256];
					g_iBlocks[ent]=g_iBlockSelection[client];
					if(blocksize[client] != 1)
						Format(mdl, sizeof(mdl), "%s%s%s", g_eBlocks[g_iBlockSelection[client]][ModelPath], blocktag[client], g_eBlocks[g_iBlockSelection[client]][ModelName]);
					else
						Format(mdl, sizeof(mdl), "%s%s", g_eBlocks[g_iBlockSelection[client]][ModelPath], g_eBlocks[g_iBlockSelection[client]][ModelName]);
					g_iBlocksize[ent] = blocksize[client];
					SetEntityModel(ent, mdl);
					//PrintToChat(client, "%sSuccessfully converted the block to \x03%s\x04.", CHAT_TAG, g_eBlocks[g_iBlockSelection[client]][BlockName]);
				}
			}
			else
			{
				PrintToChat(client, "\x03%s\x04 You must aim at a block.", CHAT_TAG);
			}
		} else if(param2==5)
		{
				new ent = GetClientAimTarget(client, false);
				if(IsValidBlock(ent))
				{
					AcceptEntityInput(ent, "Kill");
					g_iBlocks[ent]=-1;
					if(g_iTeleporters[ent]>=1)
					{
						if(g_iTeleporters[ent]>1 && IsValidBlock(g_iTeleporters[ent]))
						{
							AcceptEntityInput(g_iTeleporters[ent], "Kill");
							g_iTeleporters[g_iTeleporters[ent]] = -1;
						} else if(g_iTeleporters[ent]==1)
						{
							for(new i=MaxClients+1;i<MAX_EDICTS;++i)
							{
								if(g_iTeleporters[i]==ent)
								{
									if(IsValidBlock(i))
										AcceptEntityInput(i, "Kill");
									g_iTeleporters[i] = -1;
									break;
								}
							}
						}
						
						g_iTeleporters[ent]=-1;
					}
					//PrintToChat(client, MESS, "Block has been deleted.");
				}
				else
				{
					PrintToChat(client, "\x03%s\x04 You must aim at a block.", CHAT_TAG);
				}
		} else if(param2==6)
		{
			if(GetEntityMoveType(client) != MOVETYPE_NOCLIP)
			{
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
			}
			else
			{
				SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
			}
		} else if(param2==7)
		{
			if(GetEntProp(client, Prop_Data, "m_takedamage", 1) == 2)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			}
			else
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			}
			DisplayMenu(CreateMainMenu(client), client, 0); 
		} else if(param2==8)
		{
			bDisplayMenu=false;
			DisplayMenu(CreateTeleportMenu(client), client, 0);
		} else if(param2==11)
		{
			bDisplayMenu=false;
			DisplayMenu(CreateOptionsMenu(client), client, 0);
		}
		else if(param2==10)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent))
			{
				if(g_iBlocks[ent] == 5 || g_iBlocks[ent] == 93 || g_iBlocks[ent] == 64 || g_iBlocks[ent] == 35) // TRAMPOLINE
				{
					bDisplayMenu=false;
					CurrentModifier[client] = ent
					AdjustTrampolineForce(client)

				}
				else if(g_iBlocks[ent] == 6 || g_iBlocks[ent] == 94 || g_iBlocks[ent] == 65 || g_iBlocks[ent] == 36)
				{
					bDisplayMenu=false;
					CurrentModifier[client] = ent
					ShowMenu3E(client)
				}
				else if(g_iBlocks[ent] == 18 || g_iBlocks[ent] == 105 || g_iBlocks[ent] == 76 || g_iBlocks[ent] == 47)
				{
					bDisplayMenu=false;
					CurrentModifier[client] = ent
					ShowMenuDelayed_NoSlowdown(client)
				}
				else if(g_iBlocks[ent] == 28 || g_iBlocks[ent] == 115 || g_iBlocks[ent] == 86 || g_iBlocks[ent] == 57)
				{
					bDisplayMenu=false;
					CurrentModifier[client] = ent
					ShowMenuDelayed(client)
				}
				else
				{
					bDisplayMenu=false;
					DisplayMenu(CreateMainMenu(client), client, 0); 
					PrintToChat(client, "\x03%s\x04 There are no properties available for this block.", CHAT_TAG);
				}
			}
			else
			{
					bDisplayMenu=false;
					DisplayMenu(CreateMainMenu(client), client, 0); 
					PrintToChat(client, "\x03%s\x04 You have to aim at the block to change it's properties.", CHAT_TAG);
			}
		}
		else if(param2==9)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent))
			{
				bDisplayMenu=false;
				CurrentModifier[client] = ent
				Command_BlockAlpha(client)
			}
		}

		// Ställer in block size
//		else if(param2==2)
//		{
//			
//			if(blocksize==1)
//			{
//				blocksize=2;
//			}
//			else if(blocksize==2)
//			{
//				blocksize=0;
//			}
//			else
//			{
//				blocksize=1;
//			}
//			
//		}

		if(bDisplayMenu)
			DisplayMenu(CreateMainMenu(client), client, 0); 
	}
}

public Command_BlockAlpha(client)
{
	new Handle:menu = CreateMenu(BB_ALPHA, MenuAction_Select | MenuAction_End);
	SetMenuTitle(menu, "Block Transparency");
	AddMenuItem(menu, "20", "20");
	AddMenuItem(menu, "40", "40");
	AddMenuItem(menu, "60", "60");
	AddMenuItem(menu, "80", "80");
	AddMenuItem(menu, "100", "100");
	AddMenuItem(menu, "120", "120");
	AddMenuItem(menu, "140", "140");
	AddMenuItem(menu, "160", "160");
	AddMenuItem(menu, "180", "180");
	AddMenuItem(menu, "200", "200");
	AddMenuItem(menu, "220", "240");
	AddMenuItem(menu, "250", "250");
	AddMenuItem(menu, "255", "255 (DEFAULT)");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

 
public BB_ALPHA(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SetEntityRenderMode(CurrentModifier[client], RENDER_TRANSCOLOR)
			SetEntityRenderColor(CurrentModifier[client], 255, 255, 255, StringToInt(item))
			DisplayMenu(CreateMainMenu(client), client, 0);
			PrintToChat(client, "\x03%s\x04 Block's Transparency has been adjusted.", CHAT_TAG);
			Block_Transparency[CurrentModifier[client]] = StringToInt(item);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public AdjustTrampolineForce(client)
{
		new Handle:menu = CreateMenu(TFCH2, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Adjust Trampoline Force:");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "900", "900");
		AddMenuItem(menu, "800", "800");
		AddMenuItem(menu, "700", "700");
		AddMenuItem(menu, "600", "600");
		AddMenuItem(menu, "500", "500 (DEFAULT)");
		AddMenuItem(menu, "400", "400");
		AddMenuItem(menu, "300", "300");

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
 
public TFCH2(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			TrampolineForce[CurrentModifier[client]] = StringToFloat(item)
			DisplayMenu(CreateMainMenu(client), client, 0);
			PrintToChat(client, "\x03%s\x04 Trampoline has been adjusted.", CHAT_TAG);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Handle:CreateTeleportMenu(client)
{
	new Handle:menu = CreateMenu(Handler_Teleport);
	SetMenuTitle(menu, "Teleport Menu");
	if(g_iCurrentTele[client]==-1)
		AddMenuItem(menu, "0", "Teleport Start");
	else
		AddMenuItem(menu, "0", "Cancel teleport");
	AddMenuItem(menu, "1", "Teleport End");
	AddMenuItem(menu, "2", "Swap Teleport Start/End");
	AddMenuItem(menu, "3", "Delete Teleport");
	AddMenuItem(menu, "4", "Show Teleport Path");
	SetMenuExitBackButton(menu, true);
	return menu;
}

public Handle:CreateBlocksMenu()
{
	new Handle:menu = CreateMenu(Handler_Blocks);
	decl String:szItem[4];
	SetMenuTitle(menu, "Block Menu");
	for (new i; i < sizeof(g_eBlocks); i++)
	{
		IntToString(i, szItem, sizeof(szItem));
		AddMenuItem(menu, szItem, g_eBlocks[i][BlockName]);
	}
	SetMenuExitBackButton(menu, true);
	return menu;
}

public Handle:CreateMainMenu(client)
{
	new Handle:menu = CreateMenu(Handler_BlockBuilder);

	SetMenuTitle(menu, "BlockBuilder"); //mainmenu
	
	new String:sInfo[256];
	Format(sInfo, sizeof(sInfo), "Block: %s", g_eBlocks[g_iBlockSelection[client]][BlockName]);
	AddMenuItem(menu, "0", sInfo);
	if(g_iDragEnt[client]==0)
		AddMenuItem(menu, "1", "Place Block");
	else
		AddMenuItem(menu, "1", "Release Block");
	
	if(blocksize[client] == 1)
		AddMenuItem(menu, "2", "Size: Normal");
	else if(blocksize[client] == 2)
		AddMenuItem(menu, "2", "Size: Large");
	else if(blocksize[client] == 3)
		AddMenuItem(menu, "2", "Size: Small");
	else
		AddMenuItem(menu, "2", "Size: Pole");


	AddMenuItem(menu, "3", "Rotate Block");
	AddMenuItem(menu, "4", "Replace Block");
	AddMenuItem(menu, "5", "Delete Block");
 
	if(GetEntityMoveType(client) != MOVETYPE_NOCLIP)
		AddMenuItem(menu, "6", "No Clip: Off");
	else
		AddMenuItem(menu, "6", "No Clip: On");

	if(GetEntProp(client, Prop_Data, "m_takedamage", 1) == 2)
		AddMenuItem(menu, "7", "Godmode: Off");
	else
		AddMenuItem(menu, "7", "Godmode: On");

	AddMenuItem(menu, "8", "Teleport Builder");
	AddMenuItem(menu, "9", "Block Transparency");
	AddMenuItem(menu, "10", "Block Properties");
	AddMenuItem(menu, "11", "More Options");
	SetMenuExitButton(menu, true);
	g_hClientMenu[client] = menu;
	return menu;
}

public Handle:CreateOptionsMenu(client)
{
	new Handle:menu = CreateMenu(Handler_Options);
	SetMenuTitle(menu, "Options Menu");
	
	if(g_bSnapping[client])
		AddMenuItem(menu, "0", "Snapping: On");
	else
		AddMenuItem(menu, "0", "Snapping: Off");
	
		
	new String:sText[256];
	Format(sText, sizeof(sText), "Snapping gap: %.1f\n \n", g_fSnappingGap[client]);
	AddMenuItem(menu, "1", sText);
	
	AddMenuItem(menu, "2", "Add to group");
	AddMenuItem(menu, "3", "Clear group\n \n");

	new bRoot = (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ReadFlagString("p") ?true:false);
	
//	AddMenuItem(menu, "4", "Load from file");
	AddMenuItem(menu, "4", "Load from file", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
//	AddMenuItem(menu, "5", "Save to file\n \n");
	AddMenuItem(menu, "5", "Save to file\n \n", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
	
//	AddMenuItem(menu, "6", "Delete all blocks");
	AddMenuItem(menu, "6", "Delete all blocks", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
//	AddMenuItem(menu, "7", "Delete all teleporters");
	AddMenuItem(menu, "7", "Delete all teleporters", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));

	SetMenuExitBackButton(menu, true);
	return menu;
}

CreateTeleportEntrance(client, Float:fPos[3]={0.0, 0.0, 0.0})
{
	new Float:vecDir[3], Float:vecPos[3], Float:viewang[3];
	if(client > 0)
	{
		GetClientEyeAngles(client, viewang);
		GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);
		vecPos[0]+=vecDir[0]*100;
		vecPos[1]+=vecDir[1]*100;
		vecPos[2]+=vecDir[2]*100;
	}
	else
	{
		vecPos = fPos;
	}

	new ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "model", "models/platforms/b-tele.mdl");
	TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);
	
	SetEntityMoveType(ent, MOVETYPE_NONE);
	AcceptEntityInput(ent, "disablemotion");
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	
	g_iTeleporters[ent]=1;
	g_iCurrentTele[client]=ent;
	
	SDKHook(ent, SDKHook_StartTouch, OnStartTouch);
	
	return ent;
}

CreateTeleportExit(client, Float:fPos[3]={0.0, 0.0, 0.0})
{
	new Float:vecDir[3], Float:vecPos[3], Float:viewang[3];
	if(client > 0)
	{
		GetClientEyeAngles(client, viewang);
		GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);
		vecPos[0]+=vecDir[0]*100;
		vecPos[1]+=vecDir[1]*100;
		vecPos[2]+=vecDir[2]*100;
	}
	else
	{
		vecPos = fPos;
	}

	new ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "model", "models/platforms/r-tele.mdl");
	TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);
	
	SetEntityMoveType(ent, MOVETYPE_NONE);
	AcceptEntityInput(ent, "disablemotion");
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	
	g_iTeleporters[ent]=1;
	
	return ent;
}

#define FSOLID_CUSTOMRAYTEST 0x0001 // Ignore solid type + always call into the entity for ray tests
#define FSOLID_CUSTOMBOXTEST 0x0002 // Ignore solid type + always call into the entity for swept box tests
#define FSOLID_NOT_SOLID 0x0004 // Are we currently not solid?
#define FSOLID_TRIGGER 0x0008 // This is something may be collideable but fires touch functions even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
#define FSOLID_NOT_STANDABLE 0x0010 // You can't stand on this
#define FSOLID_VOLUME_CONTENTS 0x0020 // Contains volumetric contents (like water)
#define FSOLID_FORCE_WORLD_ALIGNED 0x0040 // Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
#define FSOLID_USE_TRIGGER_BOUNDS 0x0080 // Uses a special trigger bounds separate from the normal OBB
#define FSOLID_ROOT_PARENT_ALIGNED 0x0100 // Collisions are defined in root parent's local coordinate space
#define FSOLID_TRIGGER_TOUCH_DEBRIS 0x0200 // This trigger will touch debris objects 

CreateBlock(client, blocktype=0, sizetype=0, Float:fPos[3]={0.0, 0.0, 0.0}, Float:fAng[3]={0.0, 0.0, 0.0}, Float:attrib1=0.0, Float:attrib2=0.0, transparency=0)
{ 
	PrintToChatAll("Entity Create");
	PrintToChatAll("client: %d -- Blocktype %d -- Size %d -- fPos: %0.1f %0.1f %0.1f -- fAngle: %0.1f %0.1f %0.1f", client, blocktype, sizetype, fPos[0], fPos[1], fPos[2], fAng[0], fAng[1], fAng[2]);
	PrintToChatAll("Attrib1: %0.2f -- Attrib2: %0.2f -- Transperancy: %d", attrib1, attrib2, transparency);
	new Float:vecDir[3], Float:vecPos[3], Float:viewang[3];
	if(client > 0)
	{
		GetClientEyeAngles(client, viewang);
		GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);
		vecPos[0]+=vecDir[0]*100;
		vecPos[1]+=vecDir[1]*100;
		vecPos[2]+=vecDir[2]*100;
	}
	else
	{
		vecPos = fPos;
	}

	
	int block_entity = CreateEntityByName("prop_dynamic");
    
//    // SMALL BLOCKS (the suffix _small should be added)
//    if (blocksize == 1)
//    {
//        
//    }
//    // LARGE BLOCKS (the suffix _large should be added)
//    else if (blocksize == 2)
//   {
//
//		if(g_iBlockSelection[blocktype] == 0)
//        {
//			g_iBlockSelection[blocktype]=30;
//			g_iBlockSelection[ModelPath]="models/blockbuilder/large_platform.mdl";
//        }
//        else if(g_iBlockSelection[blocktype] == 1)
//        {
//	        g_iBlockSelection[blocktype]=31;
//			g_iBlockSelection[ModelPath]="models/blockbuilder/large_bhop.mdl";
//        }
//	    else
//	    {
//			
//	    }
//
//    DispatchKeyValue(block_entity, "model", g_eBlocks[(g_iBlockSelection[blocktype])][ModelPath]);
//       
//    }
//    // NORMAL BLOCKS (no suffix is needed here)
//    else
//    {
//        DispatchKeyValue(block_entity, "model", g_eBlocks[(client > 0 ? g_iBlockSelection[client]:blocktype)][ModelPath]);
//    }

	if(client > 0)
		g_iBlocksize[block_entity] = blocksize[client];
	else
		g_iBlocksize[block_entity] = sizetype;
		
	new String:mdl[256];
	
	/*if(g_iBlocksize[block_entity] == 2)
		g_iBlocktag[block_entity] = "large_";
	else if(g_iBlocksize[block_entity] == 3)
		g_iBlocktag[block_entity] = "small_";
	else if(g_iBlocksize[block_entity] == 4)
		g_iBlocktag[block_entity] = "pole_";
			
	if(g_iBlocksize[block_entity] != 1)
		Format(mdl, sizeof(mdl), "%s%s%s", g_eBlocks[(client > 0 ? g_iBlockSelection[client]:blocktype)][ModelPath], g_iBlocktag[block_entity], g_eBlocks[(client > 0 ? g_iBlockSelection[client]:blocktype)][ModelName]);
	else
		Format(mdl, sizeof(mdl), "%s%s", g_eBlocks[(client > 0 ? g_iBlockSelection[client]:blocktype)][ModelPath], g_eBlocks[(client > 0 ? g_iBlockSelection[client]:blocktype)][ModelName]);*/
	
	switch(g_iBlocksize[block_entity])
	{
		// 1 Normal
		// 2 Large
		// 3 Small
		case 1:
		{
			if(client > 0)
			{
				FormatEx(mdl, sizeof mdl, "%s/%s", g_eBlock[g_iBlockSelection[client]][ModelPath], g_eBlock[g_iBlockSelection[client]][ModelName]);
			}
			
			else
			{
				FormatEx(mdl, sizeof mdl, "%s/%s", g_eBlock[blocktype][ModelPath], g_eBlock[blocktype][ModelName]);
			}
		}
		
		case 2:
		{
			if(client > 0)
			{
				FormatEx(mdl, sizeof mdl, "%s/%s", g_eBlock[g_iBlockSelection[client]][ModelPath], g_eBlock[g_iBlockSelection[client]][ModelNameLarge]);
			}
			
			else
			{
				FormatEx(mdl, sizeof mdl, "%s/%s", g_eBlock[blocktype][ModelPath], g_eBlock[blocktype][ModelNameLarge]);
			}
		}
		
		case 3:
		{
			if(client > 0)
			{
				FormatEx(mdl, sizeof mdl, "%s/%s", g_eBlock[g_iBlockSelection[client]][ModelPath], g_eBlock[g_iBlockSelection[client]][ModelNamePole]);
			}
			
			else
			{
				FormatEx(mdl, sizeof mdl, "%s/%s", g_eBlock[blocktype][ModelPath], g_eBlock[blocktype][ModelNamePole]);
			}
		}
	}
	
	if(strcmp(mdl, "") == 0)
	{
		// Copy Normal Size model name instead
		if(client > 0)
		{
			FormatEx(mdl, sizeof mdl, "%s/%s", g_eBlock[g_iBlockSelection[client]][ModelPath], g_eBlock[g_iBlockSelection[client]][ModelName]);
		}
			
		else
		{
			FormatEx(mdl, sizeof mdl, "%s/%s", g_eBlock[blocktype][ModelPath], g_eBlock[blocktype][ModelName]);
		}
	}
		
	DispatchKeyValue(block_entity, "model", mdl);
	PrintToChatAll("Model: %s", mdl);
	DispatchKeyValue(block_entity, "solid", "6");
	
	DispatchSpawn(block_entity);
	
	SetEntProp(block_entity, Prop_Send, "m_usSolidFlags", 152);
	SetEntProp(block_entity, Prop_Send, "m_CollisionGroup", 8);

	TeleportEntity(block_entity, vecPos, fAng, NULL_VECTOR);

	//SetEntityMoveType(block_entity, MOVETYPE_NONE); 
	/*
	if(transparency > 0)
	{ 
		SetEntityRenderMode(block_entity, RENDER_TRANSCOLOR)
		SetEntityRenderColor(block_entity, 255, 255, 255, transparency)
		Block_Transparency[block_entity] = transparency;
	}
	else
	{
		Block_Transparency[block_entity] = -1;
	}
	
	//AcceptEntityInput(block_entity, "disablemotion");
	if(14 <= (client>0?g_iBlockSelection[client]:blocktype) <= 15)
	{
		SetEntProp(block_entity, Prop_Data, "m_CollisionGroup", 2);
	}*/
	
	//SetEntProp(block_entity, Prop_Data, "m_usSolidFlags", FSOLID_TRIGGER, 2);
	//SetEntProp(block_entity, Prop_Data, "m_nSolidType", 6);
	//SetEntProp(block_entity, Prop_Send, "m_usSolidFlags", 152);
	//SetEntProp(block_entity, Prop_Send, "m_CollisionGroup", 8);
	
	
	
	g_iBlocks[block_entity]= ( client > 0 ? g_iBlockSelection[client] : blocktype );
	PrintToChatAll("V1.5");
	/*
	if(g_iBlocks[block_entity] == 5)
	{
		if(attrib1 == 0)
		{
			TrampolineForce[block_entity] = 500.0
		}
		else
		{
			TrampolineForce[block_entity] = attrib1
		}
		CurrentModifier[client] = block_entity

		if(client > 0)
		{
			CreateTimer(0.10, ShowMenu, client)
		}
		else
		{
			SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
			SDKHook(block_entity, SDKHook_Touch, OnTouch);
			SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);
		}
	}
	else if(g_iBlocks[block_entity] == 6)
	{
		if(attrib1 == 0)
		{
			SpeedBoostForce_1[block_entity] = 800.0
		}
		else
		{
			SpeedBoostForce_1[block_entity] = attrib1
		}
		if(attrib2 == 0)
		{
			SpeedBoostForce_2[block_entity] = 260.0
		}
		else
		{
			SpeedBoostForce_2[block_entity] = attrib2
		}
		CurrentModifier[client] = block_entity
		if(client > 0)
		{
			CreateTimer(0.10, ShowMenu3, client)
		}
		else
		{
			SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
			SDKHook(block_entity, SDKHook_Touch, OnTouch);
			SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);
		}
	}
//	else if(g_iBlocks[block_entity] == 8)
//	{
//		SetEntityRenderColor(block_entity, 255, 255, 255 ,75);
//		SetEntityRenderMode(block_entity, RENDER_GLOW)
//	}
//	else if(g_iBlocks[block_entity] == 14) // CT Barrier
//	{
//		SDKHook(block_entity, SDKHook_ShouldCollide, ShouldCollide_CT)
//		PrintToChatAll("CT Barreir touched now")
//	}
//	else if(g_iBlocks[block_entity] == 15) // T Barrier
//	{
//		SDKHook(block_entity, SDKHook_ShouldCollide, ShouldCollide_T)
//		PrintToChatAll("TT Barier touched now")
//	}
	else if(g_iBlocks[block_entity] == 28)
	{
		CurrentModifier[client] = block_entity
		if(attrib1 == 0)
		{
			SpeedBoostForce_1[block_entity] = 1.5
		}
		else
		{
			SpeedBoostForce_1[block_entity] = attrib1
		}
		if(client > 0)
		{
			CreateTimer(0.10, ShowMenuDelayed2, client)
		}
		else
		{
			SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
			SDKHook(block_entity, SDKHook_Touch, OnTouch);
			SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);
		}
		
	}
	else if(g_iBlocks[block_entity] == 18)
	{
		CurrentModifier[client] = block_entity
		if(attrib1 == 0)
		{
			SpeedBoostForce_1[block_entity] = 1.5
		}
		else
		{
			SpeedBoostForce_1[block_entity] = attrib1
		}
		if(client > 0)
		{
			CreateTimer(0.10, ShowMenuDelayed_NoSlowdown2, client);
		}
		else
		{
			SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
			SDKHook(block_entity, SDKHook_Touch, OnTouch);
			SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);
		}
		
	}
	else
	{
		SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
		SDKHook(block_entity, SDKHook_Touch, OnTouch);
		SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);
	}

	g_fAngles[block_entity]=fAng;
	
	//PrintToChat(client, "%sSuccessfully spawned block \x03%s\x04.", CHAT_TAG, g_eBlocks[g_iBlockSelection[client]][BlockName]);
	return block_entity;
	*/
}
 /*
public bool:ShouldCollide_T(entity, collisiongroup, contentsmask, bool:originalResult)
{
	if ((contentsmask & CONTENTS_TEAM2 == CONTENTS_TEAM2))
	{
		return false;
	}
	return true;
}

public bool:ShouldCollide_CT(entity, collisiongroup, contentsmask, bool:originalResult)
{
	if ((contentsmask & CONTENTS_TEAM1 == CONTENTS_TEAM1))
	{
		return false;
	}
	return true;
}*/

public Action:ShowMenu(Handle:timer, any:client)
{
		new Handle:menu = CreateMenu(TFCH, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Trampoline Force:");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "900", "900");
		AddMenuItem(menu, "800", "800");
		AddMenuItem(menu, "700", "700");
		AddMenuItem(menu, "600", "600");
		AddMenuItem(menu, "500", "500 (DEFAULT)");
		AddMenuItem(menu, "400", "400");
		AddMenuItem(menu, "300", "300");

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
 
public TFCH(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			TrampolineForce[CurrentModifier[client]] = StringToFloat(item)
			
			SDKHook(CurrentModifier[client], SDKHook_StartTouch, OnStartTouch);
			SDKHook(CurrentModifier[client], SDKHook_Touch, OnTouch);
			SDKHook(CurrentModifier[client], SDKHook_EndTouch, OnEndTouch);
			DisplayMenu(CreateMainMenu(client), client, 0);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(g_bInv[victim] || (g_bNoFallDmg[victim] && damagetype & DMG_FALL))
		return Plugin_Handled;
	return Plugin_Continue;
}

public OnStartTouch(ent1, ent2)
{
	new client = -1;
	new block = -1;
	if(1 <= ent1 <= MaxClients){
		client = ent1;
	}
	else if(1 <= ent2 <= MaxClients){
		client = ent2;
	}
	
	if(IsValidBlock(ent1)){
		block = ent1;
	}
	else if(IsValidBlock(ent2)){
		block = ent2;
	}
	
	if(client == -1 || block == -1){
		return;
	}
	
	if(g_iTeleporters[block]!=-1){
		return;
	}
	if(GetClientTeam(client)<2){
		return;
	}
	
	
	if(g_iBlocks[block]==5 || g_iBlocks[block]==35 || g_iBlocks[block]==64 || g_iBlocks[block]==93) // TRAMP ?
	{
		new Handle:packet = CreateDataPack()
		WritePackCell(packet, client)
		WritePackCell(packet, block)
		CreateTimer(0.0, JumpPlayer, packet)
		g_bNoFallDmg[client]=true;
	} 
	else if(g_iBlocks[block]==6 || g_iBlocks[block]==36 || g_iBlocks[block]==65 || g_iBlocks[block]==94)
	{
		new Handle:packet = CreateDataPack()
		WritePackCell(packet, client)
		WritePackCell(packet, block)
		CreateTimer(0.0, BoostPlayer, packet);
	}
	
	decl Float:block_loc[3]
	GetEntPropVector(block, Prop_Send, "m_vecOrigin", block_loc);
	decl Float:player_loc[3]
	GetClientAbsOrigin(client, player_loc)
	player_loc[2] += TrueForce;


	// NEW DEATHBLOCK
	if(g_iBlocks[block]==9 || g_iBlocks[block]==29 || g_iBlocks[block]==58 || g_iBlocks[block]==87)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(!g_bInv[client]) {
				if(GetEntityFlags(client) && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == block) {
					SDKHooks_TakeDamage(client, 0, 0, 10000.0);
				}
			}
		}  
	}

	// NEW DAMAGE
	else if(g_iBlocks[block]==2 || g_iBlocks[block]==32 || g_iBlocks[block]==61 || g_iBlocks[block]==90)
	{
		if(GetEntityFlags(client) && !g_bInv[client] && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == block)
		{
			KillTimer(Block_Timers[client]);
			Block_Timers[client] = CreateTimer(g_eBlocks[2][CooldownTime], DamagePlayer, client);
		}
	}

	// NEW HEAL
	else if(g_iBlocks[block]==3 || g_iBlocks[block]==33 || g_iBlocks[block]==62 || g_iBlocks[block]==91)
	{
		if(GetEntityFlags(client) && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == block)
		{
			KillTimer(Block_Timers[client]);
		
			Block_Timers[client] = CreateTimer(g_eBlocks[3][EffectTime], HealPlayer, client);
		}
	}


	if(FL_ONGROUND && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == block)
	{
//	new bool:bRandom = false;
	if(g_iBlocks[block]==24 || g_iBlocks[block]==53 || g_iBlocks[block]==82 || g_iBlocks[block]==111)
	{
		if(!g_bRandomCantUse[client])
		{
			g_bRandomCantUse[client] = true;
			new Handle:datapack = CreateDataPack()
			WritePackCell(datapack, client)
			WritePackCell(datapack, RoundIndex)
			if(randomblock_time >= 1.0)
			{
				CreateTimer(randomblock_time, ResetCooldownRandom, datapack)
			}
			else
			{
				CreateTimer(1.0, ResetCooldownRandom, datapack)
			}
			new random = RoundFloat(GetRandomFloat(1.00, 8.00))
			if(random == 1) // Invincibility, Stealth, Camouflage, Boots Of Speed, a slap, or death!
			{
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex) 
				WritePackCell(packet_f, client)
				CreateTimer(g_eBlocks[7][EffectTime], ResetInv, packet_f);
				CreateTimer(g_eBlocks[7][CooldownTime], ResetInvCooldown, packet_f);
				g_bInv[client]=true;
				g_bInvCanUse[client]=false;
				
			//	CreateLight(client)
				
				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[7][EffectTime]))
				WritePackString(packet, "Invincibility")
				
				EmitSoundToClient(client, INVI_SOUND_PATH, block)
				CreateTimer(1.0, TimeLeft, packet)
				PrintToChat(client, "\x03%s\x04 You've rolled an Invincibility from Random Block!", CHAT_TAG);
			}
			else if(random == 2)
			{
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex)
				WritePackCell(packet_f, client)
				
				CreateTimer(g_eBlocks[8][EffectTime], ResetStealth, packet_f);
				CreateTimer(g_eBlocks[8][CooldownTime], ResetStealthCooldown, packet_f);
				SetEntityRenderMode(client, RENDER_NONE);
				SDKHook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
				g_bStealthCanUse[client]=false;
				
				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[8][EffectTime]))
				WritePackString(packet, "Stealth")
				EmitSoundToClient(client, STEALTH_SOUND_PATH, block)
				CreateTimer(1.0, TimeLeft, packet)
				PrintToChat(client, "\x03%s\x04 You've rolled a Stealth from Random Block!", CHAT_TAG);
			}
			else if(random == 3)
			{
				if(GetClientTeam(client)==2)
					SetEntityModel(client, "models/player/ctm_gign.mdl");
				else if(GetClientTeam(client)==3)
					SetEntityModel(client, "models/player/tm_phoenix.mdl");
				g_bCamCanUse[client]=false;
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex)
				WritePackCell(packet_f, client)
				CreateTimer(g_eBlocks[21][EffectTime], ResetCamouflage, packet_f);
				CreateTimer(g_eBlocks[21][CooldownTime], ResetCamCanUse, packet_f);
				
				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[21][EffectTime]))
				WritePackString(packet, "Camouflage")
				EmitSoundToClient(client, CAM_SOUND_PATH, block)
				CreateTimer(1.0, TimeLeft, packet)
				PrintToChat(client, "\x03%s\x04 You've rolled a Camouflage from Random Block!", CHAT_TAG);
			}
			else if(random == 4)
			{
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex)
				WritePackCell(packet_f, client)
				CreateTimer(g_eBlocks[16][EffectTime], ResetBoots, packet_f);
				CreateTimer(g_eBlocks[16][CooldownTime], ResetBootsCooldown, packet_f);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.45);
				g_bBootsCanUse[client]=false;
				
				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[16][EffectTime]))
				WritePackString(packet, "Speed Boost")
				
				EmitSoundToClient(client, BOS_SOUND_PATH, block)
				
				CreateTimer(1.0, TimeLeft, packet)
				PrintToChat(client, "\x03%s\x04 You've rolled a Speed Boost from Random Block!", CHAT_TAG);
			}
			else if(random == 5)
			{
				if(!g_bInv[client])
				{
					SDKHooks_TakeDamage(client, 0, 0, 10000.0);
					PrintToChat(client, "\x03%s\x04 You've rolled a Death from Random Block!", CHAT_TAG);
				}
				else
				{
					PrintToChat(client, "\x03%s\x04 Huh? It looks like you've avoided death from Random Block!", CHAT_TAG);
				}
			}
			else if(random == 6)
			{
				new ent = -1;
				ent = Client_GiveWeaponAndAmmo(client, "weapon_deagle", true, 0, 1, 1, 1);
				SetEntProp(ent, Prop_Data, "m_iClip1", 1);
				SetEntProp(ent, Prop_Data, "m_iClip2", 1);
				SetEntData(client, g_iAmmo+(GetEntData(ent, g_iPrimaryAmmoType)<<2), 0, 4, true);
				PrintToChatAll("\x03%s\x04 %N just got a Deagle", CHAT_TAG, client);
			}
			else if(random == 7)
			{
				new ent = -1;
				ent = Client_GiveWeaponAndAmmo(client, "weapon_awp", true, 0, 1, 1, 1);
				SetEntProp(ent, Prop_Data, "m_iClip1", 1);
				SetEntProp(ent, Prop_Data, "m_iClip2", 1);
				SetEntData(client, g_iAmmo+(GetEntData(ent, g_iPrimaryAmmoType)<<2), 0, 4, true);
				PrintToChatAll("\x03%s\x04 %N just got a AWP", CHAT_TAG, client);
			}
			else if(random == 8)
			{
				new grenade_random = RoundFloat(GetRandomFloat(1.00, 3.00))
				if(grenade_random == 1)
				{
					GivePlayerItem(client, "weapon_hegrenade");
				}
				else if(grenade_random == 2)
				{
						GivePlayerItem(client, "weapon_flashbang");
				}
				else if(grenade_random == 3)
				{
				        // GivePlayerItem(client, "weapon_smokegrenade");
						GivePlayerItem(client, "weapon_decoy");
				}
				PrintToChat(client, "\x03%s\x04 You've rolled a Grenade from Random Block!", CHAT_TAG);
			}
		}
	}
//	else if(g_iBlocks[block]==2 || g_iBlocks[block]==32 || g_iBlocks[block]==61 || g_iBlocks[block]==90)
//	{
//		if(IsValidHandle(Block_Timers[client]))
//			KillTimer(Block_Timers[client])
//		CreateTimer(g_eBlocks[2][CooldownTime], DamagePlayer, client);
//	}
//	else if(g_iBlocks[block]==3 || g_iBlocks[block]==33 || g_iBlocks[block]==62 || g_iBlocks[block]==91)
//	{
//		if(IsValidHandle(Block_Timers[client]))
//			KillTimer(Block_Timers[client])
//		Block_Timers[client] = CreateTimer(g_eBlocks[3][EffectTime], HealPlayer, client);
//	}
	else if(g_iBlocks[block]==4)
	{ 
	}
	else if(g_iBlocks[block]==7)
	{
		if(g_bInvCanUse[client])
		{
			new Handle:packet_f = CreateDataPack()
			WritePackCell(packet_f, RoundIndex)
			WritePackCell(packet_f, client)
			CreateTimer(g_eBlocks[7][EffectTime], ResetInv, packet_f);
			CreateTimer(g_eBlocks[7][CooldownTime], ResetInvCooldown, packet_f);
			g_bInv[client]=true;
			g_bInvCanUse[client]=false;
			
		//	CreateLight(client)
			
			new Handle:packet = CreateDataPack()
			WritePackCell(packet, RoundIndex)
			WritePackCell(packet, client)
			WritePackCell(packet, RoundFloat(g_eBlocks[7][EffectTime]))
			WritePackString(packet, "Invincibility")
			
			EmitSoundToClient(client, INVI_SOUND_PATH, block)
			CreateTimer(1.0, TimeLeft, packet)
		}
	}
	else if(g_iBlocks[block]==8)
	{
		if(g_bStealthCanUse[client])
		{
			new Handle:packet_f = CreateDataPack()
			WritePackCell(packet_f, RoundIndex)
			WritePackCell(packet_f, client)
			
			CreateTimer(g_eBlocks[8][EffectTime], ResetStealth, packet_f);
			CreateTimer(g_eBlocks[8][CooldownTime], ResetStealthCooldown, packet_f);
			SetEntityRenderMode(client, RENDER_NONE);
			SDKHook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
			g_bStealthCanUse[client]=false;
			
			new Handle:packet = CreateDataPack()
			WritePackCell(packet, RoundIndex)
			WritePackCell(packet, client)
			WritePackCell(packet, RoundFloat(g_eBlocks[8][EffectTime]))
			WritePackString(packet, "Stealth")
			EmitSoundToClient(client, STEALTH_SOUND_PATH, block)
			CreateTimer(1.0, TimeLeft, packet)
		}
	}
	else if(g_iBlocks[block]==11)
	{
		SetEntityGravity(client, 0.4);
		CreateTimer(3.0, ResetGrav, client)
		g_iGravity[client]=1;
	}
	else if(g_iBlocks[block]==12)
	{
		KillTimer(Block_Timers[client])
		CreateTimer(g_eBlocks[2][CooldownTime], DamagePlayer_Fire, client);
		IgniteEntity(client, 10000.0);
	}
	else if(g_iBlocks[block]==13)
	{
		CreateTimer(0.0, SlapPlayerBlock, client);
	}
//	else if(g_iBlocks[block]==14 || g_iBlocks[block]==43 || g_iBlocks[block]==72 || g_iBlocks[block]==101)
//	{
//		if(GetClientTeam(client) == 2)
//		{
//			SetEntProp(block_entity, Prop_Data, "m_CollisionGroup", 2);
//		}
//	}
//	else if(g_iBlocks[block]==15 || g_iBlocks[block]==44 || g_iBlocks[block]==73 || g_iBlocks[block]==102)
//	{
//		if(GetClientTeam(client) == 3)
//		{
//			SetEntProp(block_entity, Prop_Data, "m_CollisionGroup", 2);
//		}
//	} 
	else if(g_iBlocks[block]==16)
	{
		if(g_bBootsCanUse[client])
		{
			new Handle:packet_f = CreateDataPack()
			WritePackCell(packet_f, RoundIndex)
			WritePackCell(packet_f, client)
			CreateTimer(g_eBlocks[16][EffectTime], ResetBoots, packet_f);
			CreateTimer(g_eBlocks[16][CooldownTime], ResetBootsCooldown, packet_f);
			//		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 2.33);

			// Ny boots of speed hastighet
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.45);
			g_bBootsCanUse[client]=false;

			new Handle:packet = CreateDataPack()
			WritePackCell(packet, RoundIndex)
			WritePackCell(packet, client)
			WritePackCell(packet, RoundFloat(g_eBlocks[16][EffectTime]))
			WritePackString(packet, "Speed Boost")

			EmitSoundToClient(client, BOS_SOUND_PATH, block)

			CreateTimer(1.0, TimeLeft, packet)
		}
	}
	else if(g_iBlocks[block]==19)
	{
		g_bNoFallDmg[client]=true;
	}
	else if(g_iBlocks[block]==20)
	{

	}
	else if(g_iBlocks[block]==21)
	{
		if(g_bCamCanUse[client])
		{
			if(GetClientTeam(client)==2)
				SetEntityModel(client, "models/player/ctm_gign.mdl");
			else if(GetClientTeam(client)==3)
				SetEntityModel(client, "models/player/tm_phoenix.mdl");
			g_bCamCanUse[client]=false;
			new Handle:packet_f = CreateDataPack()
			WritePackCell(packet_f, RoundIndex)
			WritePackCell(packet_f, client)
			CreateTimer(g_eBlocks[21][EffectTime], ResetCamouflage, packet_f);
			CreateTimer(g_eBlocks[21][CooldownTime], ResetCamCanUse, packet_f);
			
			new Handle:packet = CreateDataPack()
			WritePackCell(packet, RoundIndex)
			WritePackCell(packet, client)
			WritePackCell(packet, RoundFloat(g_eBlocks[21][EffectTime]))
			WritePackString(packet, "Camouflage")
			EmitSoundToClient(client, CAM_SOUND_PATH, block)
			CreateTimer(1.0, TimeLeft, packet)
		}
	}
	else if(g_iBlocks[block]==22)
	{
		if(g_bDeagleCanUse[client])
		{
			if(GetClientTeam(client)==2)
			{
				new ent = -1;
				ent = Client_GiveWeaponAndAmmo(client, "weapon_deagle", true, 0, 1, 1, 1);
				SetEntProp(ent, Prop_Data, "m_iClip1", 1);
				SetEntProp(ent, Prop_Data, "m_iClip2", 1);
				SetEntData(client, g_iAmmo+(GetEntData(ent, g_iPrimaryAmmoType)<<2), 0, 4, true);
				PrintToChatAll("\x03%s\x04 %N has got a DEAGLE", CHAT_TAG, client);
				g_bDeagleCanUse[client] = false;
			}
		}
	}
	else if(g_iBlocks[block]==23)
	{
		if(g_bAwpCanUse[client])
		{
			if(GetClientTeam(client)==2)
			{
				new ent = -1;
				ent = Client_GiveWeaponAndAmmo(client, "weapon_awp", true, 0, 1, 1, 1);
				SetEntProp(ent, Prop_Data, "m_iClip1", 1);
				SetEntProp(ent, Prop_Data, "m_iClip2", 1);
				SetEntData(client, g_iAmmo+(GetEntData(ent, g_iPrimaryAmmoType)<<2), 0, 4, true);
				PrintToChatAll("\x03%s\x04 %N has got an AWP", CHAT_TAG, client);
				g_bAwpCanUse[client] = false;
			}
		}
	}


	
//	if(bRandom)
//		g_iBlocks[block]=24;
	}
	if(g_iBlocks[block]==1)
	{
		g_bTriggered[block]=true;
		CreateTimer(g_eBlocks[1][EffectTime], StartNoBlock, block);
	}

	else if(g_iBlocks[block]==18)
	{
		g_bTriggered[block]=true;
		CreateTimer(g_eBlocks[18][EffectTime], StartNoBlock, block);
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
	}
	else if(g_iBlocks[block]==28) // Delayed
	{
		g_bTriggered[block]=true;
		CreateTimer(SpeedBoostForce_1[block], StartNoBlock, block);
	}
}

public Action:ResetCooldownRandom(Handle:timer, any:packet)
{
	ResetPack(packet)
	new client = ReadPackCell(packet)
	new round = ReadPackCell(packet)
	if(round == RoundIndex)
	{
		g_bRandomCantUse[client] = false;
		PrintToChat(client, "\x03%s\x04 Random block cooldown has worn off.", CHAT_TAG);
	}
}

public Action:Stealth_SetTransmit(entity, clients)
{
	if(entity == clients)
		return Plugin_Continue;
	return Plugin_Handled;
}

public Action:TimeLeft(Handle:timer, any:pack)
{
	ResetPack(pack)
	new round_index = ReadPackCell(pack)
	if(round_index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(pack)
	if(!IsFakeClient(client))
	{
		if(IsClientInGame(client))
		{
			new time = ReadPackCell(pack)
			time -= 1
			
			if(time > 0)
			{
				decl String:effectname[32];
				ReadPackString(pack, effectname, sizeof(effectname))
				PrintHintText(client, "%s will worn off in: %i", effectname, time)
				
				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, time)
				WritePackString(packet, effectname)
				
				
				CreateTimer(1.0, TimeLeft, packet)
			}
		}
	}
	return Plugin_Continue;
}

public Action:ResetGrav(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{
		SetEntityGravity(client, 1.0)
	}
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}  

public OnTouch(ent1, ent2)
{
	new client = -1;
	new block = -1;
	if(1 <= ent1 <= MaxClients)
		client = ent1;
	else if(1 <= ent2 <= MaxClients)
		client = ent2;
		
	if(IsValidBlock(ent1))
		block = ent1;
	else if(IsValidBlock(ent2))
		block = ent2;
		
	if(client == -1 || block == -1)
		return;
		
	if(GetClientTeam(client)<2)
		return;
		
	
	decl Float:block_loc[3]
	GetEntPropVector(block, Prop_Send, "m_vecOrigin", block_loc);
	decl Float:player_loc[3]
	GetClientAbsOrigin(client, player_loc)
	player_loc[2] += TrueForce;

	Block_Touching[client] = g_iBlocks[block]

	if(!(player_loc[2] <= block_loc[2]))
	{
		
		
	if(g_iBlocks[block]==1)
	{
		if(!g_bTriggered[block])
			CreateTimer(g_eBlocks[1][EffectTime], StartNoBlock, block);
	} else if(g_iBlocks[block]==2)
	{
	} else if(g_iBlocks[block]==3)
	{
	} else if(g_iBlocks[block]==4)
	{
	} else if(g_iBlocks[block]==5)
	{
	} else if(g_iBlocks[block]==6)
	{
	} else if(g_iBlocks[block]==7)
	{
	} else if(g_iBlocks[block]==8)
	{
	}
	else if(g_iBlocks[block]==9 || g_iBlocks[block]==29 || g_iBlocks[block]==58 || g_iBlocks[block]==87) // DEATHBLOCK
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(!g_bInv[client]) {
				if(GetEntityFlags(client) & FL_ONGROUND ) {
					SDKHooks_TakeDamage(client, 0, 0, 10000.0);
				}
			}
		} 
	}
	else if(g_iBlocks[block]==10 || g_iBlocks[block]==39 || g_iBlocks[block]==68 || g_iBlocks[block]==97)
	{
	} else if(g_iBlocks[block]==11 || g_iBlocks[block]==40 || g_iBlocks[block]==69 || g_iBlocks[block]==98)
	{
	} else if(g_iBlocks[block]==12 || g_iBlocks[block]==41 || g_iBlocks[block]==70 || g_iBlocks[block]==99)
	{
	} else if(g_iBlocks[block]==13 || g_iBlocks[block]==42 || g_iBlocks[block]==71 || g_iBlocks[block]==100)
	{
	} else if(g_iBlocks[block]==14 || g_iBlocks[block]==43 || g_iBlocks[block]==72 || g_iBlocks[block]==101)
	{
	} else if(g_iBlocks[block]==15 || g_iBlocks[block]==44 || g_iBlocks[block]==73 || g_iBlocks[block]==102)
	{
	} else if(g_iBlocks[block]==16 || g_iBlocks[block]==45 || g_iBlocks[block]==74 || g_iBlocks[block]==103)
	{
	} else if(g_iBlocks[block]==18 || g_iBlocks[block]==47 || g_iBlocks[block]==76 || g_iBlocks[block]==105)
	{
		if(!g_bTriggered[block])
			CreateTimer(g_eBlocks[18][EffectTime], StartNoBlock, block);
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
	} 
	else if(g_iBlocks[block]==19 || g_iBlocks[block]==48 || g_iBlocks[block]==77 || g_iBlocks[block]==106)
	{
		g_bNoFallDmg[client]=true;
	}
	else if(g_iBlocks[block] == 20 || g_iBlocks[block]==49 || g_iBlocks[block]==78 || g_iBlocks[block]==107)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.4);
	}
	else if(g_iBlocks[block]==25 || g_iBlocks[block]==54 || g_iBlocks[block]==83 || g_iBlocks[block]==112)
	{
		if(g_bHEgrenadeCanUse[client])
		{
			if(GetClientTeam(client) == 2)
			{
				if(GetClientHEGrenades(client) < 1)
				{
					GivePlayerItem(client, "weapon_hegrenade");
					g_bHEgrenadeCanUse[client] = false;
				}
			}
		}
	}
	else if(g_iBlocks[block]==26 || g_iBlocks[block]==55 || g_iBlocks[block]==84 || g_iBlocks[block]==113)
	{
		if(g_bFlashbangCanUse[client])
		{
			if(GetClientTeam(client)==2)
			{
				if(GetClientFlashbangs(client) < 1)
				{
					GivePlayerItem(client, "weapon_flashbang");
					g_bFlashbangCanUse[client] = false;
				}
			}
		}
	} 
	else if(g_iBlocks[block]==27 || g_iBlocks[block]==56 || g_iBlocks[block]==85 || g_iBlocks[block]==114)
	{
		if(g_bSmokegrenadeCanUse[client])
		{
			if(GetClientTeam(client) == 2)
			{
				if(GetClientSmokeGrenades(client) < 1)
				{
					// GivePlayerItem(client, "weapon_smokegrenade");
					GivePlayerItem(client, "weapon_decoy");
					g_bSmokegrenadeCanUse[client] = false;
				}
			}
		}
	}
	
//	if(bRandom)
//		g_iBlocks[block]=24;
	}
}

// Thanks for those three stocks to TnTSCS (https://forums.alliedmods.net/showpost.php?p=2242491&postcount=12)

stock GetClientHEGrenades(client) 
{
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, HEGrenadeOffset);
}

stock GetClientSmokeGrenades(client)
{
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, SmokegrenadeOffset);
}

stock GetClientFlashbangs(client)
{
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, FlashbangOffset);
}

public OnEndTouch(ent1, ent2)
{
	new client = -1;
	new block = -1;
	if(1 <= ent1 <= MaxClients)
		client = ent1;
	else if(1 <= ent2 <= MaxClients)
		client = ent2;
		
	if(IsValidBlock(ent1))
		block = ent1;
	else if(IsValidBlock(ent2))
		block = ent2;
		
	if(client == -1 || block == -1)
		return;
		
	if(GetClientTeam(client)<2)
		return;
		
	decl Float:block_loc[3]
	GetEntPropVector(block, Prop_Send, "m_vecOrigin", block_loc);
	
	decl Float:player_loc[3]
	GetClientAbsOrigin(client, player_loc)
	
	player_loc[2] += TrueForce;
	if(!(player_loc[2] <= block_loc[2]))
	{
			
		if(g_iBlocks[block]==1 || g_iBlocks[block]==31 || g_iBlocks[block]==89 || g_iBlocks[block]==60)
		{
		} else if(g_iBlocks[block]==2 || g_iBlocks[block]==32 || g_iBlocks[block]==61 || g_iBlocks[block]==90)
		{
		} else if(g_iBlocks[block]==3 || g_iBlocks[block]==33 || g_iBlocks[block]==62 || g_iBlocks[block]==91)
		{
		} else if(g_iBlocks[block]==4 || g_iBlocks[block]==34 || g_iBlocks[block]==63 || g_iBlocks[block]==92)
		{
		} else if(g_iBlocks[block]==5 || g_iBlocks[block]==35 || g_iBlocks[block]==64 || g_iBlocks[block]==93)
		{
			g_bNoFallDmg[client]=false;
		} else if(g_iBlocks[block]==6 || g_iBlocks[block]==36 || g_iBlocks[block]==65 || g_iBlocks[block]==94)
		{
		} else if(g_iBlocks[block]==7 || g_iBlocks[block]==37 || g_iBlocks[block]==66 || g_iBlocks[block]==95)
		{
		} else if(g_iBlocks[block]==8 || g_iBlocks[block]==38 || g_iBlocks[block]==67 || g_iBlocks[block]==96)
		{
		} else if(g_iBlocks[block]==9 || g_iBlocks[block]==29 || g_iBlocks[block]==58 || g_iBlocks[block]==87)
		{
		} else if(g_iBlocks[block]==10 || g_iBlocks[block]==39 || g_iBlocks[block]==68 || g_iBlocks[block]==97)
		{
		} else if(g_iBlocks[block]==11 || g_iBlocks[block]==40 || g_iBlocks[block]==69 || g_iBlocks[block]==98)
		{
			g_iGravity[client]=2;
		} else if(g_iBlocks[block]==12 || g_iBlocks[block]==41 || g_iBlocks[block]==70 || g_iBlocks[block]==99)
		{
			CreateTimer(0.2, ResetFire, client)

		} else if(g_iBlocks[block]==13 || g_iBlocks[block]==42 || g_iBlocks[block]==71 || g_iBlocks[block]==100)
		{
		} else if(g_iBlocks[block]==14 || g_iBlocks[block]==43 || g_iBlocks[block]==72 || g_iBlocks[block]==101)
		{
		} else if(g_iBlocks[block]==15 || g_iBlocks[block]==44 || g_iBlocks[block]==73 || g_iBlocks[block]==102)
		{
		} else if(g_iBlocks[block]==16 || g_iBlocks[block]==45 || g_iBlocks[block]==74 || g_iBlocks[block]==103)
		{
		} else if(g_iBlocks[block]==18 || g_iBlocks[block]==47 || g_iBlocks[block]==76 || g_iBlocks[block]==105)
		{
		} else if(g_iBlocks[block]==19 || g_iBlocks[block]==48 || g_iBlocks[block]==77 || g_iBlocks[block]==106)
		{
			g_bNoFallDmg[client]=false;
		}
		else if(g_iBlocks[block]==20 || g_iBlocks[block]==49 || g_iBlocks[block]==78 || g_iBlocks[block]==107)
		{
			CreateTimer(0.2, ResetHoney, client)
		}
		
//		if(bRandom)
//		{
//			g_iBlocks[block]=24;
//		}
	}
	CreateTimer(0.01, BlockTouch_End, client)
}

public Action:ResetFire(Handle:timer, any:client)
{
	if(Block_Touching[client] != 12 && Block_Touching[client] != 41 && Block_Touching[client] != 70 && Block_Touching[client] != 99)
	{
		new ent = GetEntPropEnt(client, Prop_Data, "m_hEffectEntity");
		if (IsValidEdict(ent))
			SetEntPropFloat(ent, Prop_Data, "m_flLifetime", 0.0);
	}
}

public Action:BlockTouch_End(Handle:timer, any:client)
{
	Block_Touching[client] = 0;
}

public Action:ResetHoney(Handle:timer, any:client)
{
	if(Block_Touching[client] != 20 && Block_Touching[client] != 49 && Block_Touching[client] != 78 && Block_Touching[client] != 107)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}

// DAMAGE FUNCTION
public Action:DamagePlayer(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(Block_Touching[client] == 2 || Block_Touching[client] == 32 || Block_Touching[client] == 61 || Block_Touching[client] == 90)
			{
				if(!g_bInv[client]) {
					if(GetClientHealth(client)-5>0) {
						SetEntityHealth(client, GetClientHealth(client)-5);
					}
					else {
						SDKHooks_TakeDamage(client, 0, 0, 10000.0);
					}
				}
				Block_Timers[client] = CreateTimer(g_eBlocks[3][EffectTime], DamagePlayer, client);
			}
			else {
				KillTimer(Block_Timers[client]);
			}
		}
	} 
	return Plugin_Stop; 
}

public Action:DamagePlayer_Fire(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(Block_Touching[client] == 12 || Block_Touching[client] == 41 || Block_Touching[client] == 70 || Block_Touching[client] == 99)
			{
				SDKHooks_TakeDamage(client, 0, 0, float(RoundFloat(GetRandomFloat(1.00, 8.00))), DMG_BURN)
				Block_Timers[client] = CreateTimer(g_eBlocks[2][EffectTime], DamagePlayer_Fire, client);
			}
		}
	} 
	return Plugin_Stop;
}

public Action:ResetCamouflage(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	if(GetClientTeam(client)==3)
		SetEntityModel(client, "models/player/ctm_gign.mdl");
	else if(GetClientTeam(client)==2)
		SetEntityModel(client, "models/player/tm_phoenix.mdl");
		
	PrintToChat(client, "\x03%s\x04 Camouflage has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetCamCanUse(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bCamCanUse[client]=true;
	PrintToChat(client, "\x03%s\x04 Camouflage block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:StartNoBlock(Handle:timer, any:block)
{
	SetEntProp(block, Prop_Data, "m_CollisionGroup", 2);
	SetEntityRenderMode(block, RENDER_TRANSADD);
	if(Block_Transparency[block] > 0)
	{
		SetEntityRenderColor(block, 177, 177, 177, RoundFloat(float(Block_Transparency[block])*0.4588));
	}
	else
	{
		SetEntityRenderColor(block, 177, 177, 177, 177);
	}
	CreateTimer(g_eBlocks[g_iBlocks[block]][CooldownTime], CancelNoBlock, block);
	return Plugin_Stop;
}

public Action:CancelNoBlock(Handle:timer, any:block)
{
	SetEntProp(block, Prop_Data, "m_CollisionGroup", 0);
	SetEntityRenderMode(block, RENDER_TRANSCOLOR); 
	if(Block_Transparency[block] > 0)
	{
		SetEntityRenderColor(block, 255, 255, 255, Block_Transparency[block]);
	}
	else
	{
		SetEntityRenderColor(block, 255, 255, 255, 255);
	}
	g_bTriggered[block]=false;
	return Plugin_Stop;
}

public Action:HealPlayer(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(Block_Touching[client] == 3 || Block_Touching[client] == 33 || Block_Touching[client] == 62 || Block_Touching[client] == 91)
			{
				if(GetClientHealth(client)+5<=100) {
					SetEntityHealth(client, GetClientHealth(client)+5);
				}
				else {
					SetEntityHealth(client, 100); 
				}
				Block_Timers[client] = CreateTimer(g_eBlocks[3][EffectTime], HealPlayer, client);
			}
			else {
			KillTimer(Block_Timers[client]); 
			}
		}
	}
	return Plugin_Stop;
}

public Action:ResetNoFall(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bNoFallDmg[client] = false;
	return Plugin_Stop;
}

public Action:ResetInv(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bInv[client] = false;
	PrintToChat(client, "\x03%s\x04 Invincibility has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetInvCooldown(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bInvCanUse[client] = true;
	PrintToChat(client, "\x03%s\x04 Invincibility block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetStealth(Handle:timer, any:packet)
{
	ResetPack(packet)

	new index = ReadPackCell(packet)

	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}

	new client = ReadPackCell(packet) 
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	SetEntityRenderMode(client , RENDER_NORMAL); 
	SDKUnhook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
	PrintToChat(client, "\x03%s\x04 Stealth has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetStealthCooldown(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bStealthCanUse[client] = true;
	PrintToChat(client, "\x03%s\x04 Stealth block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

//public Action:ResetRandom(Handle:timer, any:packet)
//{
//	ResetPack(packet)
//	new index = ReadPackCell(packet)
//	if(index != RoundIndex)
//	{
//		KillTimer(timer, true)
//		return Plugin_Handled;
//	}
//	new client = ReadPackCell(packet)
//
//	if(!IsClientInGame(client))
//		return Plugin_Stop;
//	g_iClientBlocks[client]=-1;
//	return Plugin_Stop;
//}

public Action:ResetBoots(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
//	PrintToChat(client, "\x03%s\x04 Boots of Speed has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetBootsCooldown(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	g_bBootsCanUse[client] = true;
	PrintToChat(client, "\x03%s\x04 Boots of Speed block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public ShowMenuDelayed_NoSlowdown(client)
{
	new Handle:menu = CreateMenu(MenuDelayed_Return, MenuAction_Select | MenuAction_End);
	SetMenuTitle(menu, "Choose Delay for disappearance of the block:");
	AddMenuItem(menu, "0.01", "0.01s")
	AddMenuItem(menu, "0.02", "0.02s")
	AddMenuItem(menu, "0.03", "0.03s")
	AddMenuItem(menu, "0.04", "0.04s")
	AddMenuItem(menu, "0.05", "0.05s")
	AddMenuItem(menu, "0.10", "0.10s")
	AddMenuItem(menu, "0.15", "0.15s")
	AddMenuItem(menu, "0.20", "0.20s")
	AddMenuItem(menu, "0.25", "0.25s")
	AddMenuItem(menu, "0.30", "0.30s")
	AddMenuItem(menu, "0.35", "0.35s")
	AddMenuItem(menu, "0.40", "0.40s")
	AddMenuItem(menu, "0.45", "0.45s")
	AddMenuItem(menu, "0.50", "0.50s")
	AddMenuItem(menu, "0.60", "0.60s")
	AddMenuItem(menu, "0.70", "0.70s")
	AddMenuItem(menu, "0.80", "0.80s")
	AddMenuItem(menu, "0.90", "0.90s")
	AddMenuItem(menu, "1", "1s")

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public Action:ShowMenuDelayed_NoSlowdown2(Handle:timer, any:client)
{
	new Handle:menu = CreateMenu(MenuDelayed_Return2, MenuAction_Select | MenuAction_End);
	SetMenuTitle(menu, "Choose Delay for disappearance of the block:");
	AddMenuItem(menu, "0.01", "0.01s")
	AddMenuItem(menu, "0.02", "0.02s")
	AddMenuItem(menu, "0.03", "0.03s")
	AddMenuItem(menu, "0.04", "0.04s")
	AddMenuItem(menu, "0.05", "0.05s")
	AddMenuItem(menu, "0.10", "0.10s")
	AddMenuItem(menu, "0.15", "0.15s")
	AddMenuItem(menu, "0.20", "0.20s")
	AddMenuItem(menu, "0.25", "0.25s")
	AddMenuItem(menu, "0.30", "0.30s")
	AddMenuItem(menu, "0.35", "0.35s")
	AddMenuItem(menu, "0.40", "0.40s")
	AddMenuItem(menu, "0.45", "0.45s")
	AddMenuItem(menu, "0.50", "0.50s")
	AddMenuItem(menu, "0.60", "0.60s")
	AddMenuItem(menu, "0.70", "0.70s")
	AddMenuItem(menu, "0.80", "0.80s")
	AddMenuItem(menu, "0.90", "0.90s")
	AddMenuItem(menu, "1", "1s")

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

 public ShowMenuDelayed(client)
{
		new Handle:menu = CreateMenu(MenuDelayed_Return, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Delay for disappearance of the block:");
		AddMenuItem(menu, "0.25", "0.25s")
		AddMenuItem(menu, "0.5", "0.5s")
		AddMenuItem(menu, "0.75", "0.75s")
		AddMenuItem(menu, "1", "1s")
		AddMenuItem(menu, "1.5", "1.5s")
		AddMenuItem(menu, "2", "2s")
		AddMenuItem(menu, "2.5", "2.5s")
		AddMenuItem(menu, "3.0", "3s")
		AddMenuItem(menu, "3.5", "3.5s")
		AddMenuItem(menu, "4.0", "4s")
		AddMenuItem(menu, "4.5", "4.5s")
		AddMenuItem(menu, "5.0", "5s")
		AddMenuItem(menu, "6", "6s")
		AddMenuItem(menu, "7", "7s")
		AddMenuItem(menu, "8", "8s")
		AddMenuItem(menu, "9", "9s")
		AddMenuItem(menu, "10", "10s")

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

 public Action:ShowMenuDelayed2(Handle:timer, any:client)
{
		new Handle:menu = CreateMenu(MenuDelayed_Return2, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Delay for disappearance of the block:");
		AddMenuItem(menu, "0.25", "0.25s")
		AddMenuItem(menu, "0.5", "0.5s")
		AddMenuItem(menu, "0.75", "0.75s")
		AddMenuItem(menu, "1", "1s")
		AddMenuItem(menu, "1.5", "1.5s")
		AddMenuItem(menu, "2", "2s")
		AddMenuItem(menu, "2.5", "2.5s")
		AddMenuItem(menu, "3.0", "3s")
		AddMenuItem(menu, "3.5", "3.5s")
		AddMenuItem(menu, "4.0", "4s")
		AddMenuItem(menu, "4.5", "4.5s")
		AddMenuItem(menu, "5.0", "5s")
		AddMenuItem(menu, "6", "6s")
		AddMenuItem(menu, "7", "7s")
		AddMenuItem(menu, "8", "8s")
		AddMenuItem(menu, "9", "9s")
		AddMenuItem(menu, "10", "10s")

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuDelayed_Return2(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SpeedBoostForce_1[CurrentModifier[client]] = StringToFloat(item)
			
			SDKHook(CurrentModifier[client], SDKHook_StartTouch, OnStartTouch);
			SDKHook(CurrentModifier[client], SDKHook_Touch, OnTouch);
			SDKHook(CurrentModifier[client], SDKHook_EndTouch, OnEndTouch);
			DisplayMenu(CreateMainMenu(client), client, 0);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}
public MenuDelayed_Return(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SpeedBoostForce_1[CurrentModifier[client]] = StringToFloat(item)

			DisplayMenu(CreateMainMenu(client), client, 0);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

 public ShowMenu3E(client)
{
		new Handle:menu = CreateMenu(TFCH_BoostF, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Speed Boost Forward Force:");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "900", "900");
		AddMenuItem(menu, "800", "800 (DEFAULT)");
		AddMenuItem(menu, "700", "700");
		AddMenuItem(menu, "600", "600");
		AddMenuItem(menu, "500", "500");
		AddMenuItem(menu, "400", "400");
		AddMenuItem(menu, "300", "300");
		AddMenuItem(menu, "200", "200");

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
 public Action:ShowMenu3(Handle:timer, any:client)
{
		new Handle:menu = CreateMenu(TFCH_BoostF, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Speed Boost Forward Force:");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "900", "900");
		AddMenuItem(menu, "800", "800 (DEFAULT)");
		AddMenuItem(menu, "700", "700");
		AddMenuItem(menu, "600", "600");
		AddMenuItem(menu, "500", "500");
		AddMenuItem(menu, "400", "400");
		AddMenuItem(menu, "300", "300");
		AddMenuItem(menu, "200", "200");

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public TFCH_BoostF(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SpeedBoostForce_1[CurrentModifier[client]] = StringToFloat(item)
			
			SDKHook(CurrentModifier[client], SDKHook_StartTouch, OnStartTouch);
			SDKHook(CurrentModifier[client], SDKHook_Touch, OnTouch);
			SDKHook(CurrentModifier[client], SDKHook_EndTouch, OnEndTouch);
			ShowMenu4(client)
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public TFCH_BoostF2(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SpeedBoostForce_2[CurrentModifier[client]] = StringToFloat(item)
			DisplayMenu(CreateMainMenu(client), client, 0);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

 public ShowMenu4(client)
{
		new Handle:menu = CreateMenu(TFCH_BoostF2, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Speed Boost Jump Force:");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "900", "900");
		AddMenuItem(menu, "800", "800");
		AddMenuItem(menu, "700", "700");
		AddMenuItem(menu, "600", "600");
		AddMenuItem(menu, "500", "500");
		AddMenuItem(menu, "400", "400");
		AddMenuItem(menu, "300", "300");
		AddMenuItem(menu, "260", "260 (DEFAULT)");
		AddMenuItem(menu, "200", "200");

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Action:BoostPlayer(Handle:timer, any:pack)
{
	ResetPack(pack)
	new client = ReadPackCell(pack)
	new block = ReadPackCell(pack)
	
	new Float:fAngles[3];
	GetClientEyeAngles(client, fAngles);
	
	new Float:fVelocity[3];
	GetAngleVectors(fAngles, fVelocity, NULL_VECTOR, NULL_VECTOR);
	
	NormalizeVector(fVelocity, fVelocity);
	
	ScaleVector(fVelocity, SpeedBoostForce_1[block]);
	fVelocity[2] = SpeedBoostForce_2[block];
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	return Plugin_Stop;
}

public Action:JumpPlayer(Handle:timer, any:pack)
{
	ResetPack(pack)
	new client = ReadPackCell(pack)
	new block = ReadPackCell(pack)
	if(IsClientInGame(client) && IsValidBlock(block))
	{
		decl Float:block_loc[3]
		GetEntPropVector(block, Prop_Send, "m_vecOrigin", block_loc);
		decl Float:player_loc[3]
		GetClientAbsOrigin(client, player_loc)
		player_loc[2] += TrueForce;
		if(!(player_loc[2] <= block_loc[2]))
		{
			new Float:fVelocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
			fVelocity[0]*=1.5;
			fVelocity[1]*=1.5;
			fVelocity[2] = TrampolineForce[block]
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		}
		else
		{
			new Float:fVelocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
			fVelocity[0]*=1.25;
			fVelocity[1]*=1.25;
			fVelocity[2] = 300.0
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		}
	}
	return Plugin_Stop;
}

public Action:SlapPlayerBlock(Handle:timer, any:client)
{
	SlapPlayer(client, 5);
	new Float:fVelocity[3];
	fVelocity[0] = float(GetRandomInt(-100, 100));
	fVelocity[1] = float(GetRandomInt(-100, 100));
	fVelocity[2] = float(GetRandomInt(260, 360));
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	return Plugin_Stop;
}

public Handler_Teleport(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		if(param2==0)
		{
			if(g_iCurrentTele[client]==-1)
				CreateTeleportEntrance(client);
			else
			{
				if(IsValidEdict(g_iCurrentTele[client]))
					AcceptEntityInput(g_iCurrentTele[client], "Kill");
				g_iCurrentTele[client]=-1;
			}
		} else if(param2==1)
		{
			if(g_iCurrentTele[client]==-1)
				PrintToChat(client, "\x03%s\x04 You must create an entrance first", CHAT_TAG);
			else
			{
				g_iTeleporters[g_iCurrentTele[client]]=CreateTeleportExit(client);
				g_iCurrentTele[client]=-1;
			}
		} else if(param2==2)
		{
			new ent = GetClientAimTarget(client, false);
			new entrance = -1;
			new hexit = -1;
			if(g_iTeleporters[ent]>=1)
			{
				if(g_iTeleporters[ent]>1)
				{
					entrance = ent;
					hexit = g_iTeleporters[ent];
				}
				else
				{
				    for(new i=MaxClients+1;i<MAX_EDICTS;++i)
					{
						if(g_iTeleporters[i]==ent)
						{
							hexit = ent;
							entrance = i;
							break;
						}
					}
				}
				
				if(entrance > 0 && hexit > 0)
				{
					if(IsValidBlock(entrance) && IsValidBlock(hexit))
					{
						SetEntityModel(entrance, "models/platforms/r-tele.mdl");
						SetEntityModel(hexit, "models/platforms/b-tele.mdl");
						g_iTeleporters[entrance]=1;
						g_iTeleporters[hexit]=entrance;
					}
				}
			}
		} else if(param2==3)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent))
			{
				AcceptEntityInput(ent, "Kill");
				g_iBlocks[ent]=-1;
				if(g_iTeleporters[ent]>=1)
				{
					if(g_iTeleporters[ent]>1 && IsValidBlock(g_iTeleporters[ent]))
					{
						AcceptEntityInput(g_iTeleporters[ent], "Kill");
						g_iTeleporters[g_iTeleporters[ent]] = -1;
					} else if(g_iTeleporters[ent]==1)
					{
						for(new i=MaxClients+1;i<MAX_EDICTS;++i)
						{
							if(g_iTeleporters[i]==ent)
							{
								if(IsValidBlock(i))
									AcceptEntityInput(i, "Kill");
								g_iTeleporters[i] = -1;
								break;
							}
						}
					}
					
					g_iTeleporters[ent]=-1;
				}
			}
		} else if(param2==4)
		{
			new ent = GetClientAimTarget(client, false);
			if(ent!=-1)
			{
				new entrance = -1;
				new hexit = -1;
				if(g_iTeleporters[ent]>=1)
				{
					if(g_iTeleporters[ent]>1)
					{
						entrance = ent;
						hexit = g_iTeleporters[ent];
					}
					else
					{
						for(new i=MaxClients+1;i<MAX_EDICTS;++i)
						{
							if(g_iTeleporters[i]==ent)
							{
								hexit = ent;
								entrance = i;
								break;
							}
						}
					}
					if(entrance > 0 && hexit > 0)
					{
						if(IsValidBlock(entrance) && IsValidBlock(hexit))
						{
							new color[4]={255, 0, 0, 255};
							new Float:pos1[3], Float:pos2[3];
							GetEntPropVector(entrance, Prop_Data, "m_vecOrigin", pos1);
							GetEntPropVector(hexit, Prop_Data, "m_vecOrigin", pos2);
							TE_SetupBeamPoints(pos2, pos1, g_iBeamSprite, 0, 0, 40, 15.0, 20.0, 20.0, 25, 0.0, color, 10);
							TE_SendToClient(client);
						}
					}
				}
			}
			else
			{
				PrintToChat(client, "\x03%s\x04 You must aim at a teleporter first", CHAT_TAG);
			}
		}
		DisplayMenu(CreateTeleportMenu(client), client, 0);
	}
	else if ((action == MenuAction_Cancel) && (param2 == MenuCancel_ExitBack))
		DisplayMenu(CreateMainMenu(client), client, 0);
}

public Handler_Blocks(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		g_iBlockSelection[client]=param2;
		//PrintToChat(client, "%sYou have selected block \x03%s\x04.", CHAT_TAG, g_eBlocks[param2][BlockName]);
		DisplayMenu(CreateMainMenu(client), client, 0);
	}
	else if ((action == MenuAction_Cancel) && (param2 == MenuCancel_ExitBack))
		DisplayMenu(CreateMainMenu(client), client, 0);
}

public Handler_Options(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new bool:bDontDisplay = false;
		if(param2 == 0)
		{
			if(g_bSnapping[client])
				g_bSnapping[client]=false;
			else
				g_bSnapping[client]=true;
		}
		else if(param2 == 1)
		{
			if(g_fSnappingGap[client]<100.0)
				g_fSnappingGap[client]+=5.0;
			else
				g_fSnappingGap[client]=0.0;
		}
		else if(param2 == 2)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent))
				g_bGroups[client][ent]=true;
		} else if(param2 == 3)
		{
			for(new i=0;i<MAX_EDICTS;++i)
				g_bGroups[client][i] = false;
		} else if(param2 == 4)
		{
			LoadBlocks_Menu(client);
			bDontDisplay = true;
		} else if(param2 == 5)
		{
			SaveBlocks_Menu(client);
			bDontDisplay = true;
		} else if(param2 == 6)
		{
			for(new i=MaxClients+1;i<MAX_EDICTS;++i)
			{
				if(g_iBlocks[i]!=-1)
				{
					if(IsValidBlock(i))
					{
						AcceptEntityInput(i, "Kill");
					}
					g_iBlocks[i]=-1;
				}
			}
		} else if(param2 == 7)
		{
			for(new i=MaxClients+1;i<MAX_EDICTS;++i)
			{
				if(g_iTeleporters[i]!=-1)
				{
					if(IsValidBlock(i))
					{
						AcceptEntityInput(i, "Kill");
					}
					g_iTeleporters[i]=-1;
				}
			}
		}
		if(!bDontDisplay)
		{
			DisplayMenu(CreateOptionsMenu(client), client, 0);
		}
	}
	else if ((action == MenuAction_Cancel) && (param2 == MenuCancel_ExitBack))
		DisplayMenu(CreateMainMenu(client), client, 0);
}

stock SaveBlocks_Menu(client)
{
	new Handle:menu = CreateMenu(SaveBlocks_Handler, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(menu, "Blockbuilder - Save Blocks?");
	AddMenuItem(menu, "X", "Are you sure you want to save blocks?", ITEMDRAW_DISABLED)
	AddMenuItem(menu, "1", "Yes!")
	AddMenuItem(menu, "2", "No!")
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public SaveBlocks_Handler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			new option = StringToInt(item)
			if(option == 1)
			{
				SaveBlocks(true)
			}
			else
			{
				DisplayMenu(CreateOptionsMenu(client), client, 0);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}


stock LoadBlocks_Menu(client)
{
	new Handle:menu = CreateMenu(LoadBlocks_Handler, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(menu, "BlockBuilder - Load Blocks?");
	AddMenuItem(menu, "X", "Are you sure you want to load blocks?", ITEMDRAW_DISABLED)
	AddMenuItem(menu, "1", "Yes!")
	AddMenuItem(menu, "2", "No!")
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
} 

public LoadBlocks_Handler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			new option = StringToInt(item)
			if(option == 1)
			{
				LoadBlocks(true)
			}
			else
			{
				DisplayMenu(CreateOptionsMenu(client), client, 0);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

bool:IsValidBlock(ent)
{
	if(MaxClients < ent < MAX_EDICTS)
		if((g_iBlocks[ent] != -1 || g_iTeleporters[ent]!=-1) && IsValidEdict(ent))
			return true;
	return false;
}

stock FakePrecacheSound( const String:szPath[] )
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}

stock GetCurrentWorkshopMap(String:szMap[], iMapBuf, String:szWorkShopID[], iWorkShopBuf)
{
    decl String:szCurMap[128];
    decl String:szCurMapSplit[2][64];
    
    GetCurrentMap(szCurMap, sizeof(szCurMap));
    
    ReplaceString(szCurMap, sizeof(szCurMap), "workshop/", "", false);
    
    ExplodeString(szCurMap, "/", szCurMapSplit, 2, 64);
    
    strcopy(szMap, iMapBuf, szCurMapSplit[1]);
    strcopy(szWorkShopID, iWorkShopBuf, szCurMapSplit[0]);
}

