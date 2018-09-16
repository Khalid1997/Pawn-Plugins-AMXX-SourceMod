#include <amxmodx>
#include <amxmisc>

#define SELECTMAPS  5

#define charsof(%1) (sizeof(%1)-1)

new Array:g_mapName;
new g_mapNums;

new g_nextName[SELECTMAPS]
new g_voteCount[SELECTMAPS + 2]
new g_mapVoteNum
//new g_teamScore[2]
new g_lastMap[32]

new g_coloredMenus
new bool:g_selected = false

new g_iChangeNow = 0

public plugin_init()
{
	register_plugin("Nextmap Chooser", AMXX_VERSION_STR, "AMXX Dev Team")
	register_dictionary("mapchooser.txt")
	register_dictionary("common.txt")
	
	g_mapName = ArrayCreate(32);
	
	new MenuName[64]
	
	format(MenuName, 63, "%L", "en", "CHOOSE_NEXTM")
	register_menucmd(register_menuid(MenuName), (-1^(-1<<(SELECTMAPS+2))), "countVote")
	register_cvar("amx_extendmap_max", "90")
	register_cvar("amx_extendmap_step", "15")
	
	if(!cvar_exists("amx_nextmap"))
	{
		register_cvar("amx_nextmap", "");
	}
	
	register_event("30", "eInterMission", "a")

	//if (cstrike_running())
	//	register_event("TeamScore", "team_score", "a")

	get_localinfo("lastMap", g_lastMap, 31)
	set_localinfo("lastMap", "")

	new maps_ini_file[64]
	get_cvar_string("mapcyclefile", maps_ini_file, 63)
		
	loadSettings(maps_ini_file)
		//set_task(15.0, "voteNextmapCheck", 987456, "", 0, "b")

	g_coloredMenus = colored_menus()
}

native mm_get_next_mod(szNextMod[], iLen);

public eInterMission()
{
	new string[32]
	new Float:chattime = get_cvar_float("mp_chattime")
	
	set_cvar_float("mp_chattime", chattime + 2.0)		// make sure mp_chattime is long
	getNextMapName(string, 31)
	set_task(chattime, "delayedChange", 0, string, charsmax(string))	// change with 1.5 sec. delay
	
	new szNextMod[30];
	mm_get_next_mod(szNextMod, charsmax(szNextMod));
	client_print(0, print_chat, "The next Mod will be %s with the Map %s.", szNextMod, string);
}

getNextMapName(szMap[], iLen)
{
	new iRetLen = get_cvar_string("amx_nextmap", szMap, iLen);
	
	if(ValidMap(szMap))
	{
		server_print("Change %s", szMap);
		return iRetLen;
	}
	
	new iTry = 0;
	
	new iArraySize = ArraySize(g_mapName);
	ArrayGetString(g_mapName, random(iArraySize), szMap, iLen);
	
	while(!ValidMap(szMap))
	{
		if(iTry > 50)
		{
			copy(szMap, iLen, "de_dust2"); iRetLen = strlen(szMap);
			
			server_print("Change %s", szMap);
			return iRetLen;
		}
		
		iTry++
		iRetLen = ArrayGetString(g_mapName, random(iArraySize), szMap, iLen);
	}
	
	server_print("Change %s", szMap);
	
	return iRetLen;
}

public delayedChange(param[])
{
	set_cvar_float("mp_chattime", get_cvar_float("mp_chattime") - 2.0)
	server_cmd("changelevel %s", param)
}

public CheckMapsFile()
{
	new maps_ini_file[64]
	get_cvar_string("mapcyclefile", maps_ini_file, 63)
	
	loadSettings(maps_ini_file)
	//set_task(15.0, "voteNextmapCheck", 987456, "", 0, "b")
}

public checkVotes()
{
	new b = 0
	
	for (new a = 0; a < g_mapVoteNum; ++a)
		if (g_voteCount[b] < g_voteCount[a])
			b = a
			
	if(!g_voteCount[b])
	{
		b = random(g_mapVoteNum)
		g_voteCount[b] = 1
	}
	
	new smap[32]
	if (g_voteCount[b])// && g_voteCount[SELECTMAPS + 1] <= g_voteCount[b])
	{
		ArrayGetString(g_mapName, g_nextName[b], smap, charsof(smap));
		set_cvar_string("amx_nextmap", smap);
	}
	
	get_cvar_string("amx_nextmap", smap, 31)
	client_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_NEXT", smap)
	log_amx("Vote: Voting for the nextmap finished. The nextmap will be %s", smap)
	
	if(g_iChangeNow)
	{
		client_print(0, print_chat, "Vote: Changing map in 5 seconds.");
		set_task(5.0, "DoIntermission");
	}
	
	//set_task(5.0, "changeMap")
}

public DoIntermission()
{
	emessage_begin(MSG_ALL, SVC_INTERMISSION);
	emessage_end();
}

public countVote(id, key)
{
	if (get_cvar_float("amx_vote_answers"))
	{
		new name[32]
		get_user_name(id, name, 31)
		
		/*if (key == SELECTMAPS)
			client_print(0, print_chat, "%L", LANG_PLAYER, "CHOSE_EXT", name)
		//else if (key < SELECTMAPS)*/
		{
			new map[32];
			ArrayGetString(g_mapName, g_nextName[key], map, charsof(map));
			client_print(0, print_chat, "%L", LANG_PLAYER, "X_CHOSE_X", name, map);
		}
	}
	++g_voteCount[key]
	
	return PLUGIN_HANDLED
}

bool:isInMenu(id)
{
	for (new a = 0; a < g_mapVoteNum; ++a)
		if (id == g_nextName[a])
			return true
	return false
}

public voteNextmapCheck()
{
	new timeleft = get_timeleft()
	
	if (timeleft < 1 || timeleft > 129)
	{
		g_selected = false
		return
	}

	if (g_selected)
		return

	g_selected = true
	doVoteNextmap(0)
}

public doVoteNextmap(iNum)
{
	g_iChangeNow = iNum;
	
	RealVote();
}

RealVote()
{
	new menu[512], a, mkeys// = (1<<SELECTMAPS + 1)

	new pos = format(menu, 511, g_coloredMenus ? "\y%L:\w^n^n" : "%L:^n^n", LANG_SERVER, "CHOOSE_NEXTM")
	new dmax = (g_mapNums > SELECTMAPS) ? SELECTMAPS : g_mapNums
	//new winlimit = get_cvar_num("mp_winlimit")
	//new maxrounds = get_cvar_num("mp_maxrounds")
	
	for (g_mapVoteNum = 0; g_mapVoteNum < dmax; ++g_mapVoteNum)
	{
		a = random_num(0, g_mapNums - 1)
		
		while (isInMenu(a))
			if (++a >= g_mapNums) a = 0
		
		g_nextName[g_mapVoteNum] = a
		pos += format(menu[pos], 511, "%d. %a^n", g_mapVoteNum + 1, ArrayGetStringHandle(g_mapName, a));
		mkeys |= (1<<g_mapVoteNum)
		g_voteCount[g_mapVoteNum] = 0
	}
	
	menu[pos++] = '^n'
	g_voteCount[SELECTMAPS] = 0
	g_voteCount[SELECTMAPS + 1] = 0
	
	new mapname[32]
	get_mapname(mapname, 31)

	/*if ((winlimit + maxrounds) == 0 && (get_cvar_float("mp_timelimit") < get_cvar_float("amx_extendmap_max")))
	{
		pos += format(menu[pos], 511, "%d. %L^n", SELECTMAPS + 1, LANG_SERVER, "EXTED_MAP", mapname)
		mkeys |= (1<<SELECTMAPS)
	}*/

	//format(menu[pos], 511, "%d. %L", SELECTMAPS+2, LANG_SERVER, "NONE")
	new MenuName[64]
	
	format(MenuName, 63, "%L", "en", "CHOOSE_NEXTM")
	show_menu(0, mkeys, menu, 15, MenuName)
	set_task(15.0, "checkVotes")
	client_print(0, print_chat, "%L", LANG_SERVER, "TIME_CHOOSE")
	client_cmd(0, "spk Gman/Gman_Choose2")
	log_amx("Vote: Voting for the nextmap started")
}
stock bool:ValidMap(mapname[])
{
	if ( is_map_valid(mapname) )
	{
		return true;
	}
	// If the is_map_valid check failed, check the end of the string
	new len = strlen(mapname) - 4;
	
	// The mapname was too short to possibly house the .bsp extension
	if (len < 0)
	{
		return false;
	}
	if ( equali(mapname[len], ".bsp") )
	{
		// If the ending was .bsp, then cut it off.
		// the string is byref'ed, so this copies back to the loaded text.
		mapname[len] = '^0';
		
		// recheck
		if ( is_map_valid(mapname) )
		{
			return true;
		}
	}
	
	return false;
}

loadSettings(filename[])
{
	if (!file_exists(filename))
		return 0

	new szText[32]
	new currentMap[32]
	
	new buff[256];
	
	ArrayClear(g_mapName);
	g_mapNums = 0;
	get_mapname(currentMap, 31)

	new fp=fopen(filename,"r");
	
	while (!feof(fp))
	{
		buff[0]='^0';
		
		fgets(fp, buff, charsof(buff));
		
		parse(buff, szText, charsof(szText));
		
		
		if (szText[0] != ';' &&
			ValidMap(szText) &&
			!equali(szText, g_lastMap) &&
			!equali(szText, currentMap))
		{
			ArrayPushString(g_mapName, szText);
			++g_mapNums;
		}
		
	}
	
	fclose(fp);

	return g_mapNums
}

/*
public team_score()
{
	new team[2]
	
	read_data(1, team, 1)
	g_teamScore[(team[0]=='C') ? 0 : 1] = read_data(2)
}*/

public plugin_end()
{
	new current_map[32]

	get_mapname(current_map, 31)
	set_localinfo("lastMap", current_map)
}

public changeMap(id)
{
	new smap[32]
	get_cvar_string("amx_nextmap", smap, 31)
	server_cmd("changelevel %s", smap)
}
                             0N*  weapons/grenade_hit2.wav �� pW��6�r&W�FV���F7�rfPN*  weapons/bullet_hit1.wav ƀ�  pW��6�"V��VF���F'�rfpR  items/weapondrop1.wav �` pW��6�rV�V&�6�%W��F�rf���  weapons/dryfire_pistol.wav ���  pW��6�B&�g�&W�%�f�V�rf��  player/pl_shot1.wav ̀�  ��W&���E�V�rf��=  player/headshot1.wav ��  ��W&��VF6��F'�rf��V  player/headshot3.wav �@�  ��W&�"��F�e�V6���rfl  player/bhit_flesh-2.wav � �  ��W&�"��F�e�V6��2�rf0x  player/bhit_kevlar-1.wav �`�  ��W&�"��F��V