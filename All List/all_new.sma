/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Player List (Admins, Golden, Silver)"
#define VERSION "1.0"
#define AUTHOR "Khalid"

#pragma ctrlchar '\'

new g_szPrefix[] = "[uG]";

enum _:Ranks
{
	Rank_None,
	Rank_HeadAdmin,
	Rank_Admin,
	Rank_Golden,
	Rank_Silver
};

new const g_iFlags[Ranks] = {
	0,
	ADMIN_IMMUNITY, // Head admins, flag "a"
	ADMIN_RESERVATION, // Regular admins, flag "b"
	ADMIN_LEVEL_H,	// goldens, flag "t"
	ADMIN_LEVEL_G	// silvers, flag "s"
};

enum _:ColorChatColor
{
	ColorChatColor_String[2], ColorChatColor_Index
}

new const g_szRankColor[][ColorChatColor] = {
	{ "", 0 },
	{ "\x04", print_team_default },
	{ "\x03", print_team_red },
	{ "\x01", print_team_default },
	{ "\x03", print_team_grey }
};

new const g_szRankName[][]  = {
	"",
	"Head-Admins",
	"Admins",
	"Goldens",
	"Silvers"
};

new const g_iHeadAdminCommands[][] = {
	"/heads",
	"/headadmins"
};

new const g_iAdminCommands[][] = {
	"/admins",
	"/administrators"
};

new const g_iGoldenCommands[][] = {
	"/golden",
	"/goldens",
	"/goldenplayers"
};

new const g_iSilverCommands[][] = {
	"/silver",
	"/silvers",
	"/silverplayers"
};

new g_iPlayerRank[33];
	
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new szCommand[32];
	for(new i; i < sizeof(g_iHeadAdminCommands); i++)
	{
		formatex(szCommand, charsmax(szCommand), "say %s", g_iHeadAdminCommands[i]);
		register_clcmd(szCommand, "Print_HeadAdminList");
	}
	
	for(new i; i < sizeof(g_iAdminCommands); i++)
	{
		formatex(szCommand, charsmax(szCommand), "say %s", g_iAdminCommands[i]);
		register_clcmd(szCommand, "Print_AdminList");
	}
	
	for(new i; i < sizeof(g_iGoldenCommands); i++)
	{
		formatex(szCommand, charsmax(szCommand), "say %s", g_iGoldenCommands[i]);
		register_clcmd(szCommand, "Print_GoldenList");
	}
	
	for(new i; i < sizeof(g_iSilverCommands); i++)
	{
		formatex(szCommand, charsmax(szCommand), "say %s", g_iSilverCommands[i]);
		register_clcmd(szCommand, "Print_SilverList");
	}
	
	register_clcmd("say /all", "Print_AllList");
}

public client_putinserver(id)
{
	g_iPlayerRank[id] = 0;
	for(new i = 1; i < Ranks; i++)
	{
		if(get_user_flags(id) & g_iFlags[i])
		{
			g_iPlayerRank[id] = i;
			break;
		}
	}
}

public Print_AllList(id)
{
	Print_HeadAdminList(id);
	Print_AdminList(id);
	Print_GoldenList(id);
	Print_SilverList(id);
}

public Print_HeadAdminList(id)
{
	Print_Player_List(id, Rank_HeadAdmin);
}

public Print_AdminList(id)
{
	Print_Player_List(id, Rank_Admin);
}

public Print_GoldenList(id)
{
	Print_Player_List(id, Rank_Golden);
}

public Print_SilverList(id)
{
	Print_Player_List(id, Rank_Silver);
}

stock GetPlayerList(iRank, iPlayers[32], &iCount)
{
	iCount = 0;
	for(new i; i < 33; i++)
	{
		if(is_user_connected(i) && g_iPlayerRank[i] == iRank)
		{
			iPlayers[iCount++] = i;
		}
	}
}

stock Print_Player_List(id, Rank)
{
	new iPlayers[32], iCount;
	GetPlayerList(Rank, iPlayers, iCount);
	
	new szMessage[192], iLen;
	iLen = formatex(szMessage, charsmax(szMessage), "*****%s%s{%s}*****:- ",
	g_szRankColor[Rank][ColorChatColor_String], g_szPrefix, g_szRankName[Rank]);
	
	if(iCount)
	{
		new szName[MAX_NAME_LENGTH];
		for(new i; i < iCount; i++)
		{
			get_user_name(iPlayers[i], szName, charsmax(szName));
			iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "%s%s", szName, i + 1 == iCount ? "." : ", ");
		}
	}
	
	else
	{
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "No %s online", g_szRankName[Rank]);
	}
	
	client_print_color(id, g_szRankColor[Rank][ColorChatColor_Index], szMessage);
}
