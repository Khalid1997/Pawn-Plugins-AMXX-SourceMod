/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "New Plug-In"
#define VERSION "1.0"
#define AUTHOR "author"


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("meta list", "test")
}
public test(id)
{
	//server_print("called")
	client_cmd(id, "clear")
	return PLUGIN_HANDLED
}