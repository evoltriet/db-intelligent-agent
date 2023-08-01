#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include	"eclipse.h"

/*this function takes in a blocker string and return the number of users blocked*/
static int check_users_blocked (lua_State *L) {
    //check and fetch the arguments
    const char *blocker = luaL_checkstring (L, 1);
    
    dident users_blocked_2, fail;
    ec_ref X, Start;
    long users_blocked;
    /* variable instantiation */
	X = ec_ref_create_newvar();
	Start = ec_ref_create(ec_nil());
	/* make atoms and functors */
	fail = ec_did("fail",0);
	users_blocked_2 = ec_did("users_blocked", 2);

	ec_post_goal(ec_term(users_blocked_2, ec_ref_get(X), ec_string(blocker) ));
	/* Execute goal loop */
	while(PSUCCEED == ec_resume1(Start)) {
		if (PSUCCEED == ec_get_long(ec_ref_get(X),&users_blocked)) {
			//if succeed, users_blocked has been set
		}
		ec_post_goal(ec_atom(fail));
	}

	ec_ref_destroy(X);
	ec_ref_destroy(Start);
	
    //push result and return number of result
	lua_pushnumber(L, users_blocked);
    return 1;
}

/*this function takes in a blocker string and return the time blocked*/
static int check_time_blocked (lua_State *L) {
    //check and fetch the arguments
    const char *blocker = luaL_checkstring (L, 1);
    
    dident time_blocked_2, fail;
    ec_ref X, Start;
    long time_blocked;
    /* variable instantiation */
	X = ec_ref_create_newvar();
	Start = ec_ref_create(ec_nil());
	/* make atoms and functors */
	fail = ec_did("fail",0);
	time_blocked_2 = ec_did("time_blocked", 2);

	ec_post_goal(ec_term(time_blocked_2, ec_ref_get(X), ec_string(blocker) ));
	/* Execute goal loop */
	while(PSUCCEED == ec_resume1(Start)) {
		if (PSUCCEED == ec_get_long(ec_ref_get(X),&time_blocked)) {
			//if succeed, time_blocked has been set
		}
		ec_post_goal(ec_atom(fail));
	}

	ec_ref_destroy(X);
	ec_ref_destroy(Start);
	
    //push result and return number of result
	lua_pushnumber(L, time_blocked);
    return 1;
}

/*this function takes in a blocker string and return bool for need alert*/
static int check_need_alert (lua_State *L) {
	//check and fetch the arguments
	const char *blocker = luaL_checkstring (L, 1);
	
	dident need_alert_1;
	ec_ref X, Start;
	int need_alert;
	/* variable instantiation */
	X = ec_ref_create_newvar();
	Start = ec_ref_create(ec_nil());
	/* make atoms and functors */
	need_alert_1 = ec_did("need_alert", 1);

	ec_post_goal(ec_term(need_alert_1, ec_string(blocker) ));
	/* Execute goal loop */
	switch (ec_resume1(Start)) {
	case PSUCCEED: {
		need_alert=1	;
		break;
	}
	case PFAIL: {
		need_alert=0;
		break;
	}
	}

	ec_ref_destroy(X);
	ec_ref_destroy(Start);
	
	//push result and return number of result
	lua_pushboolean(L,need_alert);
	return 1;
}

/*this function takes in the blocker and info about blocked sessions and insert blocking beliefs to Eclipse*/
static int perceive_blockings (lua_State *L) {
	//check and fetch the arguments
	const char *blocker = luaL_checkstring (L, 1);
	const char *blocked_sid = luaL_checkstring (L, 2);
	const char *blocked_username = luaL_checkstring (L, 3);
	const char *blocked_machine = luaL_checkstring (L, 4);
	
	//printf("%d\n", ec_running());
    //Build Eclipse syntax strings
    char blocked_ecl_str[256];
    snprintf(blocked_ecl_str, sizeof blocked_ecl_str, "%s%s%s%s%s", "assert(blocked(", blocked_sid, ",\"", blocker, "\")).");
    printf("%s\n", blocked_ecl_str);
    
    char username_ecl_str[256];
    	snprintf(username_ecl_str, sizeof username_ecl_str, "%s%s%s%s%s", "assert(username(\"", blocked_username, "\",", blocked_sid, ")).");
    	printf("%s\n", username_ecl_str);
    	
    char machine_ecl_str[256];
	snprintf(machine_ecl_str, sizeof machine_ecl_str, "%s%s%s%s%s", "assert(machine(\"", blocked_machine, "\",", blocked_sid, ")).");
	printf("%s\n", machine_ecl_str);
	
	//insert blocking beliefs
	ec_exec_string(blocked_ecl_str, 0);
	ec_exec_string(username_ecl_str, 0);
	ec_exec_string(machine_ecl_str, 0);
	int goalResult = ec_resume();
	
    //push result and return number of result
	lua_pushnumber(L, goalResult);
    return 1;
}

/*this function remove old beliefs and set new current time*/
static int clean_beliefs (lua_State *L) {
    //Get systime in seconds
    time_t now = time(0);
    
    //remove old beliefs
	ec_exec_string("findall(X,currtime(X),L), (foreach(Z, L) do retract(currtime(Z)) ).", 0);
	ec_exec_string("findall(X,blocked(X,Y),L), (foreach(Z, L) do retract(blocked(Z, Y)) ).", 0);
	ec_exec_string("findall(X,machine(X,Y),L), (foreach(Z, L) do retract(machine(Z, Y)) ).", 0);
	ec_exec_string("findall(X,username(X,Y),L), (foreach(Z, L) do retract(username(Z, Y)) ).", 0);
	
    //Build Eclipse syntax string
    char ecl_str[256];
    snprintf(ecl_str, sizeof ecl_str, "%s%ld%s", "assert(currtime(", now, ")).");
    printf("%s\n", ecl_str);
			
	//set new currtime belief
	ec_exec_string(ecl_str, 0);
	int goalResult = ec_resume();
	
    //push result and return number of result
	lua_pushnumber(L, goalResult);
    return 1;
}

/*this function takes in a blocker string and set the start time for the blocker*/
static int set_start_time (lua_State *L) {
    //check and fetch the arguments
    const char *blocker = luaL_checkstring (L, 1);
    
    //Get systime in seconds
    time_t now = time(0);
    
    //Build Eclipse syntax string
    char ecl_str[256];
    snprintf(ecl_str, sizeof ecl_str, "%s%ld%s%s%s", "assert(start(", now, ", \"", blocker, "\")).");
    printf("%s\n", ecl_str);
			
	//set start time of blocker in Eclipse
	ec_exec_string(ecl_str, 0);
	int goalResult = ec_resume();
	
    //push result and return number of result
	lua_pushnumber(L, goalResult);
    return 1;
}

int main ( int argc, char *argv[] )
{
	char *lua_filename = "";
	if (argc == 2) {
		lua_filename = argv[1];
	}
	else {
		printf("Error: Invalid number of parameters. Must give a valid lua filename.\n");
		exit(0);
	}
	
	//initialize Eclipse CLP engine
	//ec_set_option_int(EC_OPTION_IO, MEMORY_IO);
	ec_init();
	ec_exec_string("compile('BlockingAlertLogic.ecl').", 0);
	
	// Create new Lua state and load the lua libraries
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);

	/* register our functions */
	lua_pushcfunction(L, set_start_time);
	lua_setglobal(L, "set_start_time");
	lua_pushcfunction(L, clean_beliefs);
	lua_setglobal(L, "clean_beliefs");
	lua_pushcfunction(L, perceive_blockings);
	lua_setglobal(L, "perceive_blockings");
	lua_pushcfunction(L, check_need_alert);
	lua_setglobal(L, "check_need_alert");
	lua_pushcfunction(L, check_time_blocked);
	lua_setglobal(L, "check_time_blocked");
	lua_pushcfunction(L, check_users_blocked);
	lua_setglobal(L, "check_users_blocked");

	/* run the script */
	luaL_dofile(L, lua_filename);
	
	//shutdown Eclipse engine
	ec_cleanup();
	exit(0);
}

