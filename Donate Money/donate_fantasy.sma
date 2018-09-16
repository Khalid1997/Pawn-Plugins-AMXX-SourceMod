/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define PLUGIN "Donate Money"
#define VERSION "1.0"
#define AUTHOR "Khalid"

new const PREFIX[] = "^x04[UaE-Gaming]"

new g_szCommands[][] = {
	"/donatemoney",
	"/donate",
	"donatemoney",
	"donate"
};

new g_iMoneyAmountInMenu[] = {
	2000,
	4000,
	6000,
	8000,
	10000,
	12000
};

new g_iDonateTo[MAX_PLAYERS + 1];
new g_iDonateAmount[MAX_PLAYERS + 1];
new g_hAmountMenu;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new szCommand[26];
	for(new i; i < sizeof g_szCommands; i++)
	{
		formatex(szCommand, charsmax(szCommand), "say %s", g_szCommands[i]);
		register_clcmd(szCommand, "Command_DonateMoneyMenu");
	}
	
	register_concmd("Type_The_Amount_To_Donate", "Command_CustomAmount");

	DoAmountMenu()
}

public Command_DonateMoneyMenu(id)
{
	new iPlayers[32], iCount;
	get_players(iPlayers, iCount, "c");
	
	if(iCount - 1 < 0)
	{
		client_print_color(id, print_team_default, "%s ^x01There are no other clients connected.", PREFIX);
		return;
	}
	
	new menu = menu_create("\r[UaE-Gaming] \wChoose a Player to Donate to:", "MenuHandler_ChoosePlayer");
	
	new szName[32], szInfo[3], iPlayer;
	new szMenuName[40];
	for(new i; i < iCount; i++)
	{
		iPlayer = iPlayers[i];
		
		if(iPlayer == id)
		{
			continue;
		}
		
		get_user_name(iPlayer, szName, charsmax(szName));
		formatex(szMenuName, charsmax(szMenuName), "%s \r(%d\y$\r)", szName, cs_get_user_money(iPlayer));
		
		num_to_str(iPlayer, szInfo, charsmax(szInfo));
		menu_additem(menu, szMenuName, szInfo);
	}
	
	menu_display(id, menu);
}

public Command_CustomAmount(id)
{
	g_iDonateAmount[id] = read_argv(1);
	HandleDonation(id);
	
	return PLUGIN_HANDLED;
}

public MenuHandler_ChoosePlayer(id, menu, item)
{
	if(item < 0)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new iDump, szInfo[3];
	menu_item_getinfo(menu, item, iDump, szInfo, charsmax(szInfo), .callback = iDump);
	
	g_iDonateTo[id] = str_to_num(szInfo);
	
	if(!is_user_connected(g_iDonateTo[id]))
	{
		client_print_color(id, print_team_default, "%s ^x01Player no longer connected", PREFIX);
		return PLUGIN_HANDLED
	}
	
	menu_destroy(menu);
	menu_display(id, g_hAmountMenu);
	
	return PLUGIN_HANDLED;
}

public MenuHandler_ChooseAmount(id, menu, item)
{
	if(item < 0)
	{
		return PLUGIN_HANDLED;
	}
	
	new iItemNumber, szInfo[3];
	menu_item_getinfo(menu, item, iItemNumber, szInfo, charsmax(szInfo), .callback = iItemNumber);
	
	iItemNumber = str_to_num(szInfo);
	
	if(iItemNumber == -1)
	{
		client_cmd(id, "messagemode ^"Type_The_Amount_To_Donate^"");
		return PLUGIN_HANDLED;
	}
	
	else g_iDonateAmount[id] = g_iMoneyAmountInMenu[iItemNumber];
	
	HandleDonation(id);
	return PLUGIN_HANDLED;
}

HandleDonation(id)
{
	if(!is_user_connected(g_iDonateTo[id]))
	{
		client_print_color(id, print_team_default, "%s ^x01Player no longer connected");
		return;
	}
	
	new iMoney = cs_get_user_money(id);
	if(g_iDonateAmount[id] > iMoney)
	{
		client_print_color(id, print_team_default, "%s ^x01Not enough money (missing ^x03%d$^x01).", PREFIX, g_iDonateAmount[id] - iMoney);
		return;
	}
	
	cs_set_user_money(id, iMoney - g_iDonateAmount[id]);
	cs_set_user_money(g_iDonateTo[id], cs_get_user_money(g_iDonateTo[id]) + g_iDonateAmount[id]);
	
	new szName[32], szOtherName[32];
	get_user_name(id, szName, charsmax(szName));
	get_user_name(g_iDonateTo[id], szOtherName, charsmax(szOtherName));
	client_print_color(0, print_team_default, "%s ^x01Player ^x03'%s'^x01 donated ^x03%d$ ^x01to ^x03'%s'", PREFIX, szName, g_iDonateAmount[id], szOtherName);
}

DoAmountMenu()
{
	g_hAmountMenu = menu_create("Choose an amount:", "MenuHandler_ChooseAmount");
	
	new szItem[50], szInfo[3];
	for(new i; i < sizeof g_iMoneyAmountInMenu; i++)
	{
		formatex(szItem, sizeof szItem, "%d\y$", g_iMoneyAmountInMenu[i]);
		num_to_str(i, szInfo, charsmax(szInfo));
		menu_additem(g_hAmountMenu, szItem, szInfo);
	}
	
	menu_additem(g_hAmountMenu, "Custom Amount", "-1");
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
