/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <time>
#include <sqlx>

#define PLUGIN "Karma"
#define VERSION "1.0"
#define AUTHOR "author"

#define BAN_PERM_KEY			0
#define TIME_BETWEEN_GIVE_KARMA		10080 // 1 week
#define SAY_PLUS_GIVE_KARMA_KARMA	1.0
#define SAY_PLUS_GIVE_KARMA_KARMA_ADMIN	2.0
#define COMPLETE_MATCH_BONUS_KARMA	0.5

#define HOST 		"127.0.0.1"
#define USER 		"root"
#define PASS		""
#define DATABASE 	"test"

new Handle:g_hSql;
new g_szQuery[150];

forward PUG_match_start();
forward PUG_match_end();

#define STEPS 12
new gBanStuff[STEPS] = {
	15,
	30,
	60,
	360,
	1440, 
	2880,
	10080,
	40320,
	80640,
	241920,
	483840,
	BAN_PERM_KEY
};

new Float:gKarmaStuff[] = 
{
	0.5,
	3.0,
	6.0,
	12.0,
	18.0,
	24.0,
	30.0,
	36.0,
	42.0,
	48.0,
	54.0,
	60.0
};

enum _:PlayerSteps
{
	Karma, Ban
};

new Float:g_flPlayerKarma[33]
new g_iPlayerSteps[33][PlayerSteps];
new g_iNextGiveKarmaTime[33];

new g_iXVar_Stage

#define AddToMatchPlayers(%1)	g_iMatchPlayers |= (1<<%1)
#define IsMatchPlayers(%1)	( g_iMatchPlayers & (1<<%1) )
#define RemoveFromMatchPlayers(%1)	g_iMatchPlayers &= ~(1<<%1)
new g_iMatchPlayers

new g_iBanned[33] = -1

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_hSql = SQL_MakeDbTuple(HOST, USER, PASS, DATABASE);
	
	if(g_hSql == Empty_Handle)
	{
		set_fail_state("Could not connect to SQL Database.");
	}
	
	else
	{
		SQL_ThreadQuery(
		g_hSql,
		"QueryHandler",
		"CREATE TABLE IF NOT EXISTS `Pug_Karma` (\
		steamid VARCHAR(32), \
		karma FLOAT(10,2), \
		karma_next_time INT, \
		ban_step INT, \
		karma_step INT, \
		banned INT )" 
		);
	}
	
	register_clcmd("say", "CmdKarma");
	
	g_iXVar_Stage = get_xvar_id("PUG_iStage");
}

public CmdKarma(id)
{
	new szArgs[50];
	new iSysTime;
	read_argv(1, szArgs, charsmax(szArgs));
	
	new szCmd[8], iIdOther, szOtherName[32];//, szKarma[15], Float:flKarma
	
	parse(szArgs, szCmd, charsmax(szCmd), szOtherName, charsmax(szOtherName));//, szKarma, charsmax(szKarma))
	
	if(!equali(szCmd[1], "karma"))
	{
		return;
	}
	
	if(szCmd[0] == '+' || szCmd[0] == '-')
	{
		if(g_iNextGiveKarmaTime[id] <= ( iSysTime = get_systime() ) && g_iNextGiveKarmaTime[id])
		{
			new szTimeFmt[150];
			
			server_print("get_sys_time %d", get_systime());
			get_time_length(id, iSysTime - g_iNextGiveKarmaTime[id], timeunit_seconds, szTimeFmt, charsmax(szTimeFmt));
			client_print(id, print_chat, "You will be able to use this command in %s", szTimeFmt);
		
			return;
		}
	}
	
	else
	{
		return;
	}
	
	iIdOther = cmd_target(id, szOtherName, 0);
	if(!iIdOther)
	{
		return;
	}
	
	//flKarma = str_to_float(szKarma);
	
	//if(flKarma < 0)
	//{
	//	flKarma *= -1.0
	//}
	
	//if(szCmd[0] == '+')
	//{
	
	new szName[32]
	get_user_name(id, szName, 31);
	get_user_name(iIdOther, szOtherName, 31);
	
	new Float:flGiveKarma = is_user_admin(id) ? SAY_PLUS_GIVE_KARMA_KARMA_ADMIN : SAY_PLUS_GIVE_KARMA_KARMA
	
	switch(szCmd[0])
	{
		case '+':
		{
			g_flPlayerKarma[iIdOther] += flGiveKarma
			
			client_print(id, print_chat, "Player %s did +karma on %s", szName, szOtherName);
		}
		
		case '-':
		{
			g_flPlayerKarma[iIdOther] -= flGiveKarma
			client_print(id, print_chat, "Player %s did -karma on %s", szName, szOtherName);
		}
	}
	
	g_iNextGiveKarmaTime[id] = iSysTime + TIME_BETWEEN_GIVE_KARMA
}

public PUG_match_start()
{
	new iPlayers[32], iNum;
	
	get_players(iPlayers, iNum, "e", "CT");
	for(new i; i < iNum; i++)
	{
		AddToMatchPlayers(iPlayers[i])
	}
	
	get_players(iPlayers, iNum, "e", "TERRORIST");
	for(new i; i < iNum; i++)
	{
		AddToMatchPlayers(iPlayers[i])
	}
}

public PUG_match_end()
{
	new iPlayers[32], iNum;
	
	get_players(iPlayers, iNum, "e", "CT");
	for(new i; i < iNum; i++)
	{
		g_flPlayerKarma[iPlayers[i]] += COMPLETE_MATCH_BONUS_KARMA
	}
	
	get_players(iPlayers, iNum, "e", "TERRORIST");
	for(new i; i < iNum; i++)
	{
		g_flPlayerKarma[iPlayers[i]] += COMPLETE_MATCH_BONUS_KARMA
	}
}

public client_connect(id)
{
	g_iBanned[id] = -1
}

public client_putinserver(id)
{
	GetPlayerKarma(id);
}

public client_disconnect(id)
{
	if(g_iBanned[id] >= 0)
	{
		return;
	}
	
	/*
	enum _:PUG_STAGES_CONST
	{
		PUG_STAGE_READY = 0,
		PUG_STAGE_START,
		PUG_STAGE_FIRSTHALF,
		PUG_STAGE_INTERMISSION,
		PUG_STAGE_SECONDHALF,
		PUG_STAGE_OVERTIME,
		PUG_STAGE_END
	};*/
	
	#define PUG_STAGE_FIRSTHALF 2
	#define PUG_STAGE_OVERTIME 5
	if( PUG_STAGE_FIRSTHALF <= get_xvar_num(g_iXVar_Stage) <= PUG_STAGE_OVERTIME )
	{
		if(IsMatchPlayers(id))
		{
			g_iBanned[id] = gBanStuff[ ( g_iPlayerSteps[id][Ban]++ ) - 1 ] + get_systime()
			g_flPlayerKarma[id] -= gKarmaStuff[ ( g_iPlayerSteps[id][Karma]++ ) - 1 ]
		}
	}
	
	new szAuthId[35];
	get_user_authid(id, szAuthId, 34);
	
	server_print("Query1");
	Query(_,_,_,_,"UPDATE `Pug_Karma` SET karma = '%0.1f', ban_step = '%d', karma_next_time = '%d', karma_step = '%d', banned = '%d' WHERE steamid = '%s'", g_flPlayerKarma[id], g_iPlayerSteps[Ban], g_iNextGiveKarmaTime[id], g_iPlayerSteps[Karma], g_iBanned[id], szAuthId);
}

GetPlayerKarma(id)
{
	new iArray[1];
	iArray[0] = id;
	
	new szAuthId[35]; get_user_authid(id, szAuthId, charsmax(szAuthId));
	
	server_print("Query2");
	Query(_, "GetKarmaHandler", iArray, 1, "SELECT karma, karma_next_time, ban_step, karma_step, banned FROM `Pug_Karma` WHERE steamid = '%s'", szAuthId);
}

public GetKarmaHandler(iFailState, Handle:hQuery, szError[], iErrNum, iData[], iDataSize)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("SQL ERROR #%d: %s", iErrNum, szError);
			set_fail_state("Failed to connect to SQL server while executing query");
			
			return;
		}
		
		case TQUERY_QUERY_FAILED:
		{
			log_amx("Query Failed");
			log_amx("SQL ERROR #%d: %s", iErrNum, szError);
			return;
		}
	}
	
	if(iErrNum)
	{
		log_amx("SQL ERROR(2) Error #%d: %s", iErrNum, szError);
		return;
	}
	
	new id = iData[0]
	
	if(!SQL_NumResults(hQuery))
	{
		new szAuthId[35]; get_user_authid(id, szAuthId, 34);
		
		server_print("Query3");
		Query(_,_,_,_, "INSERT INTO `Pug_Karma` VALUES ( '%s', 0.0, 0, 0, 0, -1 )", szAuthId);
		
		g_flPlayerKarma[id] = 0.0
		g_iPlayerSteps[id][Ban] = 0
		g_iPlayerSteps[id][Karma] = 0
		g_iNextGiveKarmaTime[id] = 0
		
		g_iBanned[id] = -1
		return;
	}
	
	server_print("Results");
	new iBanned = SQL_ReadResult(hQuery, 4)
	
	if(iBanned)
	{
		if(iBanned <= get_systime() && iBanned != -1)
		{
			new szTimeFmt[65];
			get_time_length(id, iBanned, timeunit_seconds, szTimeFmt, charsmax(szTimeFmt));
			
			g_iBanned[id] = iBanned
			server_cmd("kick #%d ^"You will be unbanned on %s", szTimeFmt);
			server_exec();
			
			return;
		}
		
		else
		{
			g_iBanned[id] = -1;
			g_iPlayerSteps[id][Karma] = 0;
		}
	}
	
	else
	{
		server_cmd("kick #%d ^"You are banned permanently");
		server_exec();
		
		return;
	}
	
	/*steamid VARCHAR(32), \
	karma FLOAT(10,2), \
	next_karma_time INT, \
	ban_step INT, \
	karma_step INT, \
	banned INT" */
	
	SQL_ReadResult(hQuery, 1, g_flPlayerKarma[iData[0]]);
	g_iPlayerSteps[iData[0]][Ban] = SQL_ReadResult(hQuery, 3);
	g_iPlayerSteps[iData[0]][Karma] = SQL_ReadResult(hQuery, 4);
	g_iNextGiveKarmaTime[iData[0]] = SQL_ReadResult(hQuery, 2);
}

public QueryHandler(iFailState, Handle:hQuery, szError[], iErrNum, iData[], iDataSize)	
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("SQL ERROR #%d: %s", iErrNum, szError);
			set_fail_state("Failed to connect to SQL server while executing query");
			
			return;
		}
		
		case TQUERY_QUERY_FAILED:
		{
			log_amx("Query Failed");
			log_amx("SQL ERROR #%d: %s", iErrNum, szError);
			return;
		}
	}
	
	if(iErrNum)
	{
		log_amx("SQL ERROR(2) Error #%d: %s", iErrNum, szError);
		return;
	}
}

stock Query(Handle:iHandle = Handle:0, szHandler[] = "QueryHandler", Data[] = "", iSizeData = 0, szQuery[], any:...)
{
	vformat(g_szQuery, charsmax(g_szQuery), szQuery, 6);
	
	SQL_ThreadQuery(!iHandle ? g_hSql : iHandle, szHandler, g_szQuery, Data, iSizeData);
}
	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
