/*Played Time with "Current(Total) played Time" on server.*/
/*Many thanks to hackziner & Deviance for show how to use "nvault".*/
/*Thanks to Avalanche for Prune function*/


#include <amxmodx>
#include <amxmisc>
#include <colorchat>
#include <sqlx>

#define PLUGIN "Played Time"
#define VERSION "0.1"
#define AUTHOR "[LF] | Dr.Freeman"

#define host "localhost"
#define user "root"
#define pass ""
#define db "amxx"

new Handle:sql, g_query[512]

new PlayedTime[33]

new showpt;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR );
	
	register_clcmd("say", "handle_say");
	register_concmd("amx_playedtime", "admin_showptime", ADMIN_KICK," <#Player Name> - Details about playedtime.");
	
	showpt = register_cvar("amx_pt_mod","1");
	
}

public plugin_cfg(){
	sql = SQL_MakeDbTuple(host,user,pass,db)
	formatex(g_query,511,"CREATE TABLE IF NOT EXISTS `played_time` (name VARCHAR(32), playedtime INT, date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)")
	SQL_ThreadQuery(sql,"query",g_query)
}

public handle_say(id) 
{
	static said[12]
	read_argv(1, said, 11)
	
	if(equali(said, "/my_time") || equali(said, "/mytime") || equali(said, "my_time") || equali(said, "mytime") || equali(said, "/mt"))
	{
		static ctime[64], timep;
		
		timep = get_user_time(id, 1) / 60;
		get_time("%H:%M:%S", ctime, 63);
		
		PlayedTime[id] = get_playedtime(id)
		
		switch(get_pcvar_num(showpt))
		{
			case 0: return PLUGIN_HANDLED;
				
			case 1 :
			{
				client_print_color(id, Red, "^4[Played Time] ^1You have been playing on the server for: ^3%d ^1minute%s.", timep, timep == 1 ? "" : "s"); 
				client_print_color(id, Red, "^4[Played Time] ^1Your total played time on the server: ^3%d minute%s.", (timep / 2)+PlayedTime[id], timep+PlayedTime[id] == 1 ? "" : "s");
				//client_print(id, print_chat, "[Played Time] Current time: %s", ctime);
			}
			case 2 :
			{
				set_hudmessage(255, 50, 50, 0.34, 0.50, 0, 6.0, 4.0, 0.1, 0.2, -1);
				show_hudmessage(id, "[PT] You have been playing on the server for: %d minute%s.^n[PT]Current time: %s", timep, timep == 1 ? "" : "s", ctime);
			}
		}
		return PLUGIN_HANDLED;
	}
	else if(equal(said,"/top15_time")){
		new data[1];data[0]=id
		
		formatex(g_query,511,"SELECT * FROM played_time ORDER BY playedtime DESC LIMIT 15")
		SQL_ThreadQuery(sql,"show_top15",g_query,data,1)
		
	}
	return PLUGIN_CONTINUE;
}

public admin_showptime(id,level,cid) 
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	static arg[32];
	read_argv(1, arg, 31);
	
	new player = cmd_target(id, arg, 2);
	
	if(!player)
		return PLUGIN_HANDLED;
	
	static name[32];
	get_user_name(player, name, 31);
	
	static timep, ctime[64];
	
	timep = get_user_time(player, 1) / 60;
	get_time("%H:%M:%S", ctime, 63);
	
	console_print(id, "-----------------------(#PlayedTime#)-----------------------");
	console_print(id, "[PT] %s have been playing on the server for %d minute%s.",name, timep, timep == 1 ? "" : "s");
	console_print(id, "[PT] %s's total played time on the server %d minute%s.",name, timep+PlayedTime[player], timep == 1 ? "" : "s"); // new
	console_print(id, "[PT] Current time: %s", ctime);
	console_print(id, "-----------------------------------------------------------------");
	
	return PLUGIN_HANDLED;
}

public client_disconnect(id){
	new name[32]
	
	get_user_name(id,name,31)	
	replace_all(name,32,"'","")
	replace_all(name,32,"^"","")
	
	PlayedTime[id] = get_playedtime(id)
	
	formatex(g_query,511,"UPDATE played_time SET playedtime='%d' WHERE name='%s'",PlayedTime[id],name)
	SQL_ThreadQuery(sql,"query",g_query)
	
	PlayedTime[id] = 0
}

public client_putinserver(id){
	PlayedTime[id] = get_playedtime(id)
}

public plugin_end(){
	SQL_FreeHandle(sql)
}


get_playedtime(id){
	new err,error[128]
	
	new Handle:connect = SQL_Connect(sql,err,error,127)
	
	if(err){
		log_amx("--> MySQL Connection Failed - [%d][%s]",err,error)
		set_fail_state("mysql connection failed")
	}
	
	new name[32],Handle:query,pt
	get_user_name(id,name,31)
	replace_all(name,32,"'","")
	replace_all(name,32,"^"","")
	
	query = SQL_PrepareQuery(connect,"SELECT playedtime FROM played_time WHERE name='%s'",name)
	SQL_Execute(query)
	
	if(!SQL_MoreResults(query)){
		formatex(g_query,511,"INSERT INTO played_time (name,playedtime) VALUES('%s','%d')",name,get_user_time(id,1)/60)
		SQL_ThreadQuery(sql,"query",g_query)
		
		pt = (get_user_time(id,1)/60)
	}else{
		pt = SQL_ReadResult(query,0)+(get_user_time(id,1)/60)
	}
	
	SQL_FreeHandle(connect)
	SQL_FreeHandle(query)
	
	return pt
}

public show_top15(FailState, Handle:Query, Error[], Errcode,Data[], DataSize){
	static name[32]
	
	new id=Data[0]
	new good,motd[1024],len,place
	
	if(!SQL_MoreResults(Query)){
		client_print(id,print_chat,"[PT] No Data")
		return PLUGIN_HANDLED
	}
	
	len = format(motd, 1023,"<body bgcolor=#000000><font color=#FFB000><pre>")
	len += format(motd[len], 1023-len,"%s %-22.22s %3s^n", "#", "Name", "Time")
	
	while(SQL_MoreResults(Query)){
		place++
		
		SQL_ReadResult(Query,0,name, 32)
		good = SQL_ReadResult(Query,1)
		
		replace_all(name, 32,"<","")
		replace_all(name, 32,">","")
		
		len += format(motd[len], 1023-len,"%d %-22.22s %d minute%s^n",place,name,good,good == 1 ? "" : "s")
		
		SQL_NextRow(Query)
	}
	
	len += format(motd[len], 1023-len,"</body></font></pre>")
	show_motd(id, motd,"Played-Time Top 15")
	
	return PLUGIN_CONTINUE
}

public query(FailState, Handle:Query, Error[], Errcode){

}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
