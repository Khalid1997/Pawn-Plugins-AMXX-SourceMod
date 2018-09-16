/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <xs>

#define PLUGIN "New Plug-In"
#define VERSION "1.0"
#define AUTHOR "author"

new const pev_allow_take = pev_bInDuck

new g_szPropsModels[][] = {
	{ "models/w_usp.mdl" },
	{ "models/w_ak47.mdl" },
	{ "models/w_m4a1.mdl" },
	{ "models/w_awp.mdl" }
}

new const g_szPropClassName[] = "prophunt_prop"

new Array:gArraySpawnPoint
new g_iMenu[33]

new g_iMainMenu;
new g_iGrabEnt[33];

public plugin_precache()
{
	for(new i; i < sizeof g_szPropsModels; i++)
	{
		precache_model(g_szPropsModels[i]);
	}
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say /spmenu", "CmdSpawnMenu", ADMIN_RCON)
	
	register_clcmd(g_szGrabCmd, "CmdGrabOn");
	new szCmd[20];
	copy(szCmd, charsmax(szCmd), g_szGrabCmd);
	replace(szCmd, charsmax(szCmd), "+", "-");
	register_clcmd(szCmd, "CmdGrabOff");
	
	BuildMenus()
}

public client_PreThink(id)
{
	// Before delay to keep real-time movement.
	if(g_iGrabEnt[id])
	{
		static Float:vOrigin[3], Float:vAngles[3], Float:vViewOfs[3];
		entity_get_vector(id, EV_VEC_origin, vOrigin);
		entity_get_vector(id, EV_VEC_view_ofs, vViewOfs);
		
		xs_vec_add(vOrigin, vViewOfs, vOrigin);
		
		velocity_by_aim(id, floatround(g_flGrabDistance[id]), vAngles);
		xs_vec_add(vAngles, vOrigin, vAngles);
		
		entity_set_origin(g_iGrabEnt[id], vAngles);
	}
}

public CmdGrabOn(id)
{
	if(	!(get_user_flags(id) & ADMIN_SPAWN_ACCESS ) )
	{
		ColorPrint(id, "^1You don't have the access");
		return PLUGIN_HANDLED;
	}
	
	g_iGrabEnt[id] = 0;
	
	new iHitEnt;
	if(GetHitAimStuff(id, iHitEnt))
	{
		if(is_valid_ent(iHitEnt))
		{
			g_iGrabEnt[id] = iHitEnt;
			g_flGrabDistance[id] = entity_range(id, iHitEnt);
		}
	}
	
	return PLUGIN_HANDLED;
}

public CmdGrabOff(id)
{
	if(!is_valid_ent(g_iGrabEnt[id]))
	{
		g_iGrabEnt[id] = 0;
		return PLUGIN_HANDLED;
	}
	
	if(IsEntStuck(g_iGrabEnt[id]))
	{
		ColorPrint( id, "^1Removed spawn points because it got ^3Stuck^1." );
		RemoveTestSpawnEnt(g_iGrabEnt[id], 1);
	}
	
	g_iGrabEnt[id] = 0;
	return PLUGIN_HANDLED;
}

public client_disconnect(id)
{
	g_iGuidingLaser[id] = 0;
	g_iGrabEnt[id] = 0;
}

BuildMenus()
{
	g_iMainMenu = menu_create("Prpps Spawn Menu");
	menu_additem (g_iMainMenu, "Edit Menu");
	
	menu_addblank(g_iMainMenu, 0);
	menu_additem (g_iMainMenu, "Save All");
	menu_additem (g_iMainMenu, "Remove All");
}

public CmdSpawnMenu(id, level)
{
	if( !( get_user_flags(id) & ADMIN_RCON ) )
	{
		client_print(id, print_chat, "* You don't have the required access to access this command.")
		return PLUGIN_HANDLED;
	}
	
	//menu_additem(g_iMenu[id], "Add Spawn Point (AIM)");
	//menu_additem(g_iMenu[id], "Remove Spawn Point \r(AIM)");
	//menu_additem(g_iMenu[id], "Remove Spawn Point \r(Nearest One)");
	menu_display(id, g_iMenu[id]);
}

public PropsSpawnMenuHandler(id, menu, item)
{
	if(item < 0)
	{
		DestroyMenu(id);
		return;
	}
	
	new iShow = 1
	switch(item)
	{
		case 0:
		{
			CreateMenu(id, "Props Spawn Menu", "PropsEditMenuHandler");
			menu_additem(g_iMenu[id], "Add Spawn Point");
			menu_additem(g_iMenu[id], "Remove Spawn Point");
			
			menu_display(id, g_iMenu[id]);
			
			iShow = 0
		}
		
		case 1:
		{
			SaveAll()
			client_print(id, print_chat, "* Saved All.");
		}
		
		case 2:
		{
			new iEnt
			while( ( iEnt = find_ent_by_class(iEnt, g_szPropClassName) ) )
			{
				remove_entity(iEnt);
			}
			
			ArrayClear(gArraySpawnPoint);
			
			client_print(id, print_chat, "* Removed all Props and spawn points");
		}
		
		case 3:
		{
			new iEnt
			while( ( iEnt = find_ent_by_class(iEnt, g_szPropClassName) ) )
			{
				remove_entity(iEnt);
			}
			
			ArrayClear(gArraySpawnPoint);
			
			LoadFromFile(true)
			client_print(id, print_chat, "* Loaded Everything from original file.");
		}
	}
	
	if(iShow)
	{
		menu_display(id, menu);
	}
}

public PropsEditMenuHandler(id, menu, item)
{
	if(item < 0)
	{
		menu_display(id, g_iMainMenu);
		DestroyMenu(id);
		return;
	}
	
	switch(item)
	{
		case 0:
		{
			new iDump, Float:vEndPoint[3]
			GetHitAimStuff(id, iDump, vEndPoint, 1);
			
			new iEndPoint[3]
			FVecIVec(vEndPoint, iEntPoint);
			
			CreateProp(iEndPoint, true)
			
			ArrayPushArray(gArraySpawnPoint, iEndPoint);
		}
		
		case 1:
		{
			
		}
}

SaveAll()
{
	new szDir[60]
	get_datadir(szDir, charsmax(szDir));
	
	format(szDir, charsmax(szDir), "%s/prophunt", szDir);
	
	if(!dir_exists(szDir))
	{
		mkdir(szDir);
	}
	
	static szMapName[40];
	if(!szMapName[0])
	{
		get_mapname(szMapName, charsmax(szMapName));
	}
	
	new szFile[60]
	formatex(szFile, charsmax(szFile), "%s/%s.ini", szDir, szMapName);
	new f = fopen(szFile, "w+");
	
	new iArraySize = ArraySize(gArraySpawnPoint)

	for(new i, iSpawnPoint[3], szLine[60]; i < iArraySize; i++)
	{
		ArrayGetArray(gArraySpawnPoint, i, iSpawnPoint);
		formatex(szLine, charsmax(szLine), "%i %i %i", iSpawnPoint[0], iSpawnPoint[1], iSpawnPoint[2]);
		fputs(f, szLine);
	}
	
	fclose(f);
	fclose(f);
}

LoadFromFile(bool:bWithModels = false)
{
	new szDir[60]
	get_datadir(szDir, charsmax(szDir));
	
	format(szDir, charsmax(szDir), "%s/prophunt", szDir);
	
	if(!dir_exists(szDir))
	{
		mkdir(szDir);
		return;
	}
	
	static szMapName[40];
	if(!szMapName[0])
	{
		get_mapname(szMapName, charsmax(szMapName));
	}
	
	new szFile[60]
	formatex(szFile, charsmax(szFile), "%s/%s.ini", szDir, szMapName);
	new f = fopen(szFile, "r");
	
	if(!f)
	{
		fclose(f);
		return;
	}
	
	new szLine[60], iArray[3], szArray[3][20], i;
	
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine));
		trim(szLine);
		
		parse(szLine, szArray[0], 19, szArray[1], 19, szArray[2], 19);
		
		for(i = 0; i < 3; i++)
		{
			iArray[i] = str_to_num(szArray[i]);
		}
		
		ArrayPushArray(gArraySpawnPoint, iArray);
		CreateProp(iArray, bWithModels)
	}
	
	fclose(f);
	fclose(f);
}

CreateProp(iOrigin[3], bool:bWithModels)
{
	static iEnt
	iEnt = create_entity("info_target")
	
	if(!iEnt)
	{
		return;
	}
	
	set_pev(iEnt, pev_classname, g_szPropClassName);
	//set_pev(iEnt, pev_mins, Float:{ 0.0, 0.0, 0.0 } )
	//set_pev(iEnt, pev_maxs, Float:{ 2.0, 2.0, 2.0 } )
	
	entity_set_size(iEnt, Float:{ 0.0, 0.0, 0.0 }, Float:{ 2.0, 2.0, 2.0 });
	
	set_pev(iEnt, pev_allow_take, true)
	
	if(bWithModels)
	{
		entity_set_model(iEnt, g_szPropsModels[random(sizeof g_szPropsModels)]
	}
	
	static Float:vOrigin[3]
	IVecFVec(iOrigin, vOrigin);
	
	vOrigin[2] += 5.0
	entity_set_origin(iEnt, vOrigin);
}

stock GetHitAimStuff(id, &iHitEnt, Float:vEndPoint[3] = { 0.0, 0.0, 0.0 }, iAddPlane = 1)
{
	new iTr = create_tr2();
	
	new Float:vOrigin[3], Float:vAngles[3], Float:vViewOfs[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_v_angle, vAngles);
	pev(id, pev_view_ofs, vViewOfs);
	
	xs_vec_add(vOrigin, vViewOfs, vOrigin);
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vAngles);

	vEndPoint = Float:{ 0.0, 0.0, 0.0 };
	xs_vec_mul_scalar(vAngles, 9999.0, vAngles);
	xs_vec_add(vAngles, vOrigin, vAngles);

	//(const float *v1, const float *v2, int fNoMonsters, edict_t *pentToSkip, TraceResult *ptr);
	engfunc(EngFunc_TraceLine, vOrigin, vAngles, DONT_IGNORE_MONSTERS, id, iTr);
	
	new flFraction;
	get_tr2(iTr, TR_flFraction, flFraction);
	
	if(flFraction == 1.0)
	{
		console_print(0, "No solid place in sight.");
		return 0;
	}
	
	get_tr2(iTr, TR_vecEndPos, vEndPoint);
	
	if(iAddPlane)
	{
		new Float:vPlane[3];
		get_tr2(iTr, TR_vecPlaneNormal, vPlane);
		xs_vec_add(vEndPoint, vPlane, vEndPoint);
	}
	
	Draw(vOrigin, vEndPoint, 50, 0, 255, 0, 255, 2, 0);
	
	iHitEnt = get_tr2(iTr, TR_pHit);
	
	free_tr2(iTr);
	return 1;
}

stock Draw(Float:origin[3] = { 0.0, 0.0, 0.0 }, Float:endpoint[], duration = 1, red = 0, green = 255, blue = 0, brightness = 127, scroll = 2, id = 0)
{                    
	if(id)
	{
		message_begin(MSG_ONE, SVC_TEMPENTITY, .player = id);
	}
	
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	}
	
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2]);
	engfunc(EngFunc_WriteCoord, endpoint[0]);
	engfunc(EngFunc_WriteCoord, endpoint[1]);
	engfunc(EngFunc_WriteCoord, endpoint[2]);
	
	write_short(beampoint);
	write_byte(0);
	write_byte(0);
	write_byte(duration); // In tenths of a second.
	write_byte(10);
	write_byte(0);
	write_byte(red); // Red
	write_byte(green); // Green
	write_byte(blue); // Blue
	write_byte(brightness);
	write_byte(scroll);
	message_end();
}  

stock CreateMenu(id, szMenu[] = "", szHandler[] = "")
{
	if(g_iMenu[id])
	{
		DestroyMenu(id);
	}
	
	return ( g_iMenu[id] = menu_create(szMenu, szHandler) );
}

stock DestroyMenu(id)
{
	if(g_iMenu[id])
	{
		menu_destroy(g_iMenu[id]);
		g_iMenu[id] = 0;
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
