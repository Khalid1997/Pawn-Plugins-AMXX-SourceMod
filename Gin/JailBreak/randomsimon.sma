/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Random Simon"
#define VERSION "1.0"
#define AUTHOR "Anonymous"

new g_iWasSimon

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_logevent("eRoundStart", 2, "1=Round_Start");
}

public client_putinserver(id)
{
	if(g_iWasSimon & (1<<id))
	{
		g_iWasSimon &= ~(1<<id)
	}
}

public client_disconnect(id)
{
	if(g_iWasSimon & (1<<id))
	{
		g_iWasSimon &= ~(1<<id)
	}
}


public eRoundStart()
{
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "ae", "CT");
	
	if(iNum)
	{
		new iPlayer;
		new iTrys;
		new iCheckPlayers;
		
		while( ( iPlayer = iPlayers[random(iNum)] ) )
		{
			if( !( iCheckPlayers & (1<<iPlayer) ) )
			{
				iCheckPlayers |= (1<<iPlayer);
			}
			
			else	continue;
			
			if( !( g_iWasSimon & ( 1 << iPlayer ) ) )	break;
			
			if(++iTrys == iNum)
			{
				g_iWasSimon = 0;
				continue;
			}
		}
		
		g_iWasSimon |= (1<<iPlayer);
		client_cmd(iPlayer, "say /simon");
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
