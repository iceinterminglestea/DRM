#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <dhudmessage>
#include <sqlx>

#define TASK_TRAPPER_NEXT 2500
#define TASK_RUNNER_CONNECT 2533

enum _:PlayerData {
  XP,
  Pin,
  Status,
  MapTime,
  Respawns,
  Settings,
  RespawnCount,
  VipUsed,
  XPBoost,
  Queue,
  Team
}

enum _:MapData {
  Best,
  Start,
  Finish
}

enum _:SettingsData {
  Lang[3]
}

enum _:ZoneData {
  Editing,
  ZonePosA,
  ZonePosB,
  ZoneType,
  ZoneName
}

enum _:PluginData {
  TrapperID,
  SQL_MapTime,
  MapTime
}

new Plugin[PluginData];
new Player[33][PlayerData];
new User[33][SettingsData];
new Zone[33][ZoneData];
new Map[33][MapData];

new Handle:SqlTuple;
new p_sql_use,
    p_sql_hostname,
    p_sql_username,
    p_sql_password,
    p_sql_database;

new p_admflags,
    p_vipflags;

new p_servername,
    p_gamename,
    p_minplayers,
    p_viprespawns,
    p_respawns,
    p_queueauto,
    p_queuetype,
    p_maxspec,
    p_vipspec,
    p_helprules;

static ConfigsDir[64];
new Array:TrapperQueue;

public plugin_precache() {

}

public plugin_init() {

  // Plugin Specific
  register_plugin("Deathrun Manager", "0.9.1a", "ROYAL");
  register_dictionary("drm_ml.txt");
  get_configsdir(ConfigsDir, charsmax(ConfigsDir));
  drm_set_hostname();

  TrapperQueue = ArrayCreate(1, 32);

  p_sql_use = register_cvar("drm_sql", "0");
  p_sql_hostname = register_cvar("drm_sql_host", "127.0.0.1");
  p_sql_username = register_cvar("drm_sql_usr", "drmanager");
  p_sql_password = register_cvar("drm_sql_pw", "unsafepw123");
  p_sql_database = register_cvar("drm_sql_db", "deathrun");

  p_servername = register_cvar("drm_servername", "Royal Deathrun");
  p_gamename = register_cvar("drm_gamename", "Royal-Community.eu");

  p_vipflags = register_cvar("drm_vip_flags", "bjn");
  p_admflags = register_cvar("drm_admin_flags", "adbycn");
  p_minplayers = register_cvar("drm_minplayers", "2");
  p_viprespawns = register_cvar("drm_vip_respawns", "2");
  p_respawns = register_cvar("drm_respawns", "1");
  p_queueauto = register_cvar("drm_queue_auto", "1");
  p_queuetype = register_cvar("drm_queue_type", "1");
  p_maxspec = register_cvar("drm_spec_max", "5");
  p_vipspec = register_cvar("drm_spec_vip", "1");
  p_helprules = register_cvar("drm_helprules", "http://royal-community.eu/");


  register_clcmd("jointeam", "drm_team_switch");
  register_clcmd("joinclass", "drm_team_switch");
  register_clcmd("chooseteam", "drm_menu_select");
  register_clcmd("DRM_CMD_PLAYER", "drm_mm_cmd", ADMIN_BAN);

  register_message(get_user_msgid("ShowMenu"), "drm_team_handle");
  register_message(get_user_msgid("VGUIMenu"), "drm_team_handle");

  register_event("SendAudio","event_round_end","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw");

  new _IPv4Host[255], _User[32], _Pass[32], _Db[32];

  get_pcvar_string(p_sql_hostname, _IPv4Host, charsmax(_IPv4Host));
  get_pcvar_string(p_sql_username, _User, charsmax(_User));
  get_pcvar_string(p_sql_password, _Pass, charsmax(_Pass));
  get_pcvar_string(p_sql_database, _Db, charsmax(_Db));

  if(get_pcvar_num(p_sql_use)) {
    SqlTuple = SQL_MakeDbTuple(_IPv4Host, _User, _Pass, _Db);
    // Init
  }
}

public plugin_end() {
  ArrayDestroy(TrapperQueue);
  if(get_pcvar_num(p_sql_use)) {
    SQL_FreeHandle(SqlTuple);
  }
}

public drm_set_hostname() {
  server_cmd("hostname ^"Deathrun | Season %s | Covfefe^"", drm_get_romandate());
  return 0;
}

public event_round_end() {
  new _Winner[9];
  read_data(2, _Winner, charsmax(_Winner));

  switch(_Winner[7]) {
    case 't': drm_reward_team("T");
    case 'c': drm_reward_team("CT");
  }

  set_task(4.85, "drm_game_next", TASK_TRAPPER_NEXT);
  return PLUGIN_CONTINUE;
}

public drm_reward_team(const Team[]) {
  new _Winner[3]
  read_data(1, _Winner, charsmax(_Winner));
  log_amx("%s", _Winner);
}

public drm_game_next() {

  if(task_exists(TASK_TRAPPER_NEXT)) {
    remove_task(TASK_TRAPPER_NEXT);
  }

  if(get_playersnum() < get_pcvar_num(p_minplayers)) {
    // Host FreeRunInstaRespawnMode
    if(is_user_connected(Plugin[TrapperID])) cs_set_user_team(Plugin[TrapperID], CS_TEAM_CT);
    client_print(0, print_chat, "Not enough players to start another game.");
    return 1;
  }

  new _NextID, _Players[32], _Num;

  if(get_pcvar_num(p_queuetype) && ArraySize(TrapperQueue) > 0) {
    _NextID = ArrayGetCell(TrapperQueue, 0);
  } else {
    get_players(_Players, _Num, "ceh", "CT");
    _NextID = _Players[random(_Num)];
  }

  if(is_user_connected(Plugin[TrapperID]) && is_user_connected(_NextID)) {
    cs_set_user_team(Plugin[TrapperID], CS_TEAM_CT);
    cs_set_user_team(_NextID, CS_TEAM_T);
    Plugin[TrapperID] = _NextID;
  }

  return 0;
}

public drm_team_switch(id) {
  return Player[id][Team] == 0 ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public drm_team_handle(MsgID, Dest, id) {

  if(task_exists(TASK_RUNNER_CONNECT + id)) {
    return PLUGIN_HANDLED;
  }

  if(is_user_connected(id) && cs_get_user_team(id) == CS_TEAM_UNASSIGNED) {
    show_menu(id, 0, "\n", 0, _); // Permanent Menu Bugfix
    set_task(0.2, "drm_runner_connect", TASK_RUNNER_CONNECT + id);
    return PLUGIN_HANDLED;
  }

  if(is_user_connected(id) && cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
    return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
}

public drm_runner_connect(id) {
  if(task_exists(TASK_RUNNER_CONNECT + id)) {
    remove_task(TASK_RUNNER_CONNECT + id);
  }
  id = id - TASK_RUNNER_CONNECT;

  if(!is_user_connected(id)) {
    return PLUGIN_HANDLED;
  }

  Player[id][Team] = 0;
  Player[id][Queue] = 0;

  if(cs_get_user_team(id) == CS_TEAM_UNASSIGNED) {
    engclient_cmd(id, "jointeam", "2");
    engclient_cmd(id, "joinclass", "5");
  }

  if(cs_get_user_team(id) == CS_TEAM_CT) {
    Player[id][Team] = 1;
  }

  new _VIP[10];
  get_pcvar_string(p_vipflags, _VIP, charsmax(_VIP));

  if(get_pcvar_num(p_queuetype)) {
    if(get_pcvar_num(p_queueauto) == 2 && has_all_flags(id, _VIP)) {
      drm_queue_add(id);
    } else if(get_pcvar_num(p_queueauto) == 1) {
      drm_queue_add(id);
    }
  }

  if(get_playersnum() == get_pcvar_num(p_minplayers)) {
    drm_game_init();
  }

  return PLUGIN_HANDLED;
}

public drm_game_init() {

  if(get_playersnum() < get_pcvar_num(p_minplayers)) {
    log_amx("[DRM] drm_game_init(): Not enough players")
    return 1;
  }

  new _TrapperID, _Players[32], _Num;
  get_players(_Players, _Num, "ch");

  if(get_pcvar_num(p_queuetype) && ArraySize(TrapperQueue) > 0) {
    _TrapperID = ArrayGetCell(TrapperQueue, 0);
    drm_queue_remove(_TrapperID);
  } else {
    _TrapperID = _Players[random(_Num)];
  }

  if(is_user_connected(_TrapperID)) {
    set_pdata_int(_TrapperID, 125, get_pdata_int(_TrapperID, 125, 5) &  ~(1<<8), 5); // ConnorMcLeod
    Player[_TrapperID][Team] = 0;
    engclient_cmd(_TrapperID, "jointeam", "1");
    engclient_cmd(_TrapperID, "joinclass", "5");
    Player[_TrapperID][Team] = 1;
  } else {
    log_amx("[DRM] drm_game_init(): User not connected!")
  }

  if(cs_get_user_team(_TrapperID) == CS_TEAM_T) {
    Plugin[TrapperID] = _TrapperID;
  }

  return 0;
}

public drm_menu_select(id) {
  drm_main_menu(id);
  return PLUGIN_HANDLED;
}

public drm_main_menu(id) {

  new _Callback = menu_makecallback("DRMainCallback");

  new _Title[128], _Name[32];
  get_pcvar_string(p_servername, _Name, charsmax(_Name));

  formatex(_Title, charsmax(_Title), "\r%s \d/\w %L \r%s \d/\w Covfefe", _Name, id, "ML_SEASON_SELF", drm_get_romandate());
  new drmain = menu_create(_Title, "drmain_handler");

  menu_additem(drmain, "Market", "a", _, _Callback);
  menu_additem(drmain, "Respawn", "b", _, _Callback);
  menu_additem(drmain, "Services", "c", _, _Callback);
  menu_addblank(drmain, 0);
  menu_additem(drmain, "Spectate", "d", _, _Callback);
  menu_additem(drmain, "Settings", "e", _, _Callback);
  menu_additem(drmain, "Help & Rules", "f", _, _Callback);
  menu_addblank(drmain, 0);
  menu_additem(drmain, "Join Queue", "g", _, _Callback);
  menu_additem(drmain, "View Your Stats", "h", _, _Callback);
  menu_addblank(drmain, 1);
  menu_additem(drmain, "Exit", "i", _, _Callback);

  menu_setprop(drmain, MPROP_PERPAGE, 0);

  menu_display(id, drmain, 0);
  return 1;
}

public drmain_handler(id, drmain, num) {

  new _Privileges[2][10];
  get_pcvar_string(p_vipflags, _Privileges[0],  charsmax(_Privileges));
  get_pcvar_string(p_admflags, _Privileges[1], charsmax(_Privileges));

  switch(num) {
    case 2: {
      if(has_all_flags(id, _Privileges[1])) {
        drm_admin_menu(id);
      } else if(has_all_flags(id, _Privileges[0])) {
        // Vipmenu
      } else {
        // Motd
      }
    }
    case 3: {
      new CsTeams:_Team = cs_get_user_team(id);
      if(_Team == CS_TEAM_SPECTATOR) {
        set_pdata_int(id, 125, get_pdata_int(id, 125, 5) &  ~(1<<8), 5); // ConnorMcLeod
        Player[id][Team] = 0;
        engclient_cmd(id, "jointeam", "2");
        engclient_cmd(id, "joinclass", "5");
        Player[id][Team] = 1;
        menu_destroy(drmain);
        return PLUGIN_HANDLED;
      } else if(_Team == CS_TEAM_CT) {
        if(drm_get_specnum() >= get_pcvar_num(p_maxspec)) {
          if((has_all_flags(id, _Privileges[1])) || (get_pcvar_num(p_vipspec) && has_all_flags(id, _Privileges[0]))) {
            if(is_user_alive(id)) user_silentkill(id);
            if(Player[id][Queue]) drm_queue_remove(id);
            cs_set_user_team(id, CS_TEAM_SPECTATOR);
          } else {
            client_print(id, print_chat, "Purchase Royality to gain access to a personal Spectator slot!");
          }
        } else {
          if(is_user_alive(id)) user_silentkill(id);
          if(Player[id][Queue]) drm_queue_remove(id);
          cs_set_user_team(id, CS_TEAM_SPECTATOR);
        }
      }
    }
    case 5: {
      new _File[64];
      get_pcvar_string(p_helprules, _File, charsmax(_File));
      if(_File[0] != EOS) show_motd(id, _File, "Help & Rules");
    }
    case 6: {
      if(Player[id][Queue]) {
        drm_queue_remove(id);
      } else {
        drm_queue_add(id);
      }
    }
    default: {
      client_print(id, print_chat, "Not Implemented.");
    }
  }

  menu_destroy(drmain);
  return PLUGIN_HANDLED;
}

public drm_admin_menu(id) {

  new _Players[32], _Num, _Name[32];
  new dradm = menu_create("\dMain Menu > \rAdministration", "dradm_handler");

  new _AdminCallback = menu_makecallback("CallbackAdmin");

  menu_additem(dradm, "Start Map Vote", _, _, _);
  menu_additem(dradm, "Configuration", _, _, _);
  menu_addblank(dradm, 0);
  menu_additem(dradm, "\ySearch", _, _, _);
  menu_addblank(dradm, 0);

  get_players(_Players, _Num);
  for(new i; i < _Num; i++) {
    get_user_name(_Players[i], _Name, charsmax(_Name));
    menu_additem(dradm, _Name, _Players[i], _, _AdminCallback);
  }

  menu_display(id, dradm, 0);
  return 0;
}

public CallbackAdmin(id, dradm, item) {
  // HERE
  new _Data[2], _Access, _Name[32], _CbID, _VIP[10];
  get_pcvar_string(p_vipflags, _VIP, charsmax(_VIP));
  menu_item_getinfo(dradm, item, _Access, _Data, charsmax(_Data), _Name, charsmax(_Name), _CbID);

  format(_Name, charsmax(_Name), "%s%s", _Name, (has_all_flags(id, _VIP) ? " \y*" : " "));
  menu_item_setname(dradm, item, _Name);
  return (get_user_flags(_Data[0]) & ADMIN_IMMUNITY ? ITEM_DISABLED : ITEM_IGNORE);
}

public dradm_handler(id, dradm, num) {

  new _Data[2], _Access, _Name[32], _CbID;
  menu_item_getinfo(dradm, num, _Access, _Data, charsmax(_Data), _Name, charsmax(_Name), _CbID);

  switch(num) {
    case -3: {}
    case 0: {}
    case 1: {}
    case 2: {
      client_cmd(id, "messagemode ^"DRM_CMD_PLAYER FIND^"");
    }
    default: {
      drm_cmd_menu(id, _Data[0]);
    }
  }

  menu_destroy(dradm);
  return PLUGIN_HANDLED;
}

public drm_cmd_menu(id, const TargetID[]) {

  new _Name[32], _Title[64];
  get_user_name(TargetID[0], _Name, charsmax(_Name));

  formatex(_Title, charsmax(_Title), "\dAdministration > \y^"%s^"",_Name);
  new drcmd = menu_create(_Title, "drcmd_handler");

  menu_additem(drcmd, "Ban", TargetID, _, _); // Call messagemode, send syntax into chat
  menu_additem(drcmd, "Warn", TargetID, _, _); // Call reason messagemode, if empty just warn
  menu_additem(drcmd, "Kick", TargetID, _, _); // Call reason messagemode, if empty just kick
  menu_additem(drcmd, "Profile", _, _, _); // Call MOTD with PHP GET request

  menu_setprop(drcmd, MPROP_EXITNAME, "Back");
  menu_display(id, drcmd, 0)
  return 0;

}

public drcmd_handler(id, drcmd, num) {

  new _Data[2], _Access, _Name[32], _CbID;
  menu_item_getinfo(drcmd, num, _Access, _Data, charsmax(_Data), _Name, charsmax(_Name), _CbID);

  switch (num) {
    case -3: {
      menu_destroy(drcmd);
      drm_admin_menu(id);
      return PLUGIN_HANDLED;
    }
    case 0: client_cmd(id, "messagemode ^"DRM_CMD_PLAYER BAN %i^"", _Data[0]);
    case 1: client_cmd(id, "messagemode ^"DRM_CMD_PLAYER WARN %i^"", _Data[0]);
    case 2: client_cmd(id, "messagemode ^"DRM_CMD_PLAYER KICK %i^"", _Data[0]);
    case 3: {
      // Show MOTD with GET PARAM
    }
    default: client_print(id, print_chat, "Command on %i", get_user_userid(_Data[0]))
  }

  menu_destroy(drcmd);
  return PLUGIN_HANDLED;
}

public drm_mm_cmd(id) {

  new _Args[192], _ID[2], _Command[12], _Duration[3], _Reason[64];
  read_args(_Args, charsmax(_Args));
  remove_quotes(_Args);

  // Read Command
  parse(_Args, _Command, charsmax(_Command));

  if(equali("ban", _Command)) {
    parse(_Args, _Command, charsmax(_Command), _ID, charsmax(_ID), _Duration, charsmax(_Duration), _Reason, charsmax(_Reason));
    client_print(id, print_chat, "%s on %i for %s because %s", _Command, _ID, _Duration, _Reason);
  } else {
    parse(_Args, _Command, charsmax(_Command), _ID, charsmax(_ID), _Reason, charsmax(_Reason));
    client_print(id, print_chat, "%s on %i because %s", _Command, _ID,  _Reason);
  }


  return 0;
}

public drm_queue_add(id) {
  if(!Player[id][Queue]) {
    ArrayPushCell(TrapperQueue, id);
    Player[id][Queue] = 1;
    client_print(id, print_chat, "You have joined the queue. Position: %i/%i", drm_queue_pos(id), ArraySize(TrapperQueue));
  }
}
public drm_queue_remove(id) {
  if(Player[id][Queue] && ArraySize(TrapperQueue) > 0) {
    for(new i; i < ArraySize(TrapperQueue); i++) {
      if(ArrayGetCell(TrapperQueue, i) == id) {
        ArrayDeleteItem(TrapperQueue, i);
      }
    }
    Player[id][Queue] = 0;
    client_print(id, print_chat, "You have left the queue.");
  }
}

public drm_queue_pos(id) {
  new i;
  for(; i < ArraySize(TrapperQueue); i++) {
    if(ArrayGetCell(TrapperQueue, i) == id) {
      break;
    }
  }
  return i;
}

public drm_get_specnum() {
  new _Players[32], _Num, _Count;
  get_players(_Players, _Num, "ceh", "SPECTATOR");
  for(new i; i < _Num; i++) {
    if(Player[_Players[i]][Team]) _Count++
  }
  return _Count;
}

public DRMainCallback(id, drmain, item) {

  new _Data[2], _Access, _Name[64], _CbID;
  menu_item_getinfo(drmain, item, _Access, _Data, charsmax(_Data), _Name, charsmax(_Name), _CbID);

  new _Privileges[2][10], _Return = 0;
  get_pcvar_string(p_vipflags, _Privileges[0], charsmax(_Privileges));
  get_pcvar_string(p_admflags, _Privileges[1], charsmax(_Privileges));

  new CsTeams:_Team = cs_get_user_team(id);

  switch(_Data[0]) {
    case 'a': {
      formatex(_Name, charsmax(_Name), "%L %L", id, "ML_MARKET_SELF", id, "ML_COMINGSOON_SELF");
      _Return = 1;
    }
    case 'b': {
      formatex(_Name, charsmax(_Name), "%L", id, "ML_RESPAWN_SELF");
      if(!is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT && Player[id][Respawns] > 0) {
        if(has_all_flags(id, _Privileges[0])) {
          _Return = (get_pcvar_num(p_viprespawns) < Player[id][RespawnCount] ? 0:1)
        } else {
          _Return = (get_pcvar_num(p_respawns) < Player[id][RespawnCount] ? 0:1)
        }
      } else {
        _Return = 1;
      }

    }
    case 'c': {
      if(has_all_flags(id, _Privileges[1])) {
        formatex(_Name, charsmax(_Name), "%L", id, "ML_SERVICES_ADMIN");
      } else if(has_all_flags(id, _Privileges[0])) {
        formatex(_Name, charsmax(_Name), "%L", id, "ML_SERVICES_VIP");
        if(Player[id][VipUsed] == 1 ) _Return = 1;
      } else {
        formatex(_Name, charsmax(_Name), "%L", id, "ML_SERVICES_SELF");
        _Return = 1;
      }
    }
    case 'd': {
      if(_Team == CS_TEAM_SPECTATOR) {
        formatex(_Name, charsmax(_Name), "%L", id, "ML_SPECTATE_PLAY");
      } else {
        formatex(_Name, charsmax(_Name), "%L (%i/%i)", id, "ML_SPECTATE_SELF", drm_get_specnum(), get_pcvar_num(p_maxspec));
      }
      if(_Team == 2 || _Team == 3) {
        if(drm_get_specnum() >= get_pcvar_num(p_maxspec)) {
          if(!has_all_flags(id, _Privileges[0])) _Return = 1;
        }
      }
    }
    case 'e': {
      formatex(_Name, charsmax(_Name), "%L %L", id, "ML_SETTINGS_SELF", id, "ML_COMINGSOON_SELF");
      _Return = 1;
    }
    case 'f': {
    }
    case 'g': {
      if(Player[id][Queue]) {
        if(drm_queue_pos(id) == 0) {
          formatex(_Name, charsmax(_Name), "%L %L", id, "ML_QUEUE_LEAVE", id, "ML_QUEUE_NEXT");
        } else {
          formatex(_Name, charsmax(_Name), "%L", id, "ML_QUEUE_LEAVE");
        }
      } else {
        if(!get_pcvar_num(p_queuetype)) {
          formatex(_Name, charsmax(_Name), "%L %L", id, "ML_QUEUE_LEAVE", id, "ML_QUEUE_RANDOM");
          _Return = 1;
        } else {
          formatex(_Name, charsmax(_Name), "%L", id, "ML_QUEUE_JOIN");
        }
      }
      if(_Team == CS_TEAM_T) {
        formatex(_Name, charsmax(_Name), "%L", id, "ML_QUEUE_JOIN");
        _Return = 1;
      }
    }
    case 'h': {
      formatex(_Name, charsmax(_Name), "%L %L", id, "ML_STATS_SELF", id, "ML_COMINGSOON_SELF");
      _Return = 1;
    }
    case 'i': {
      formatex(_Name, charsmax(_Name), "%L", id, "ML_EXIT_SELF");
    }

  }
  menu_item_setname(drmain, item, _Name);
  return _Return == 1 ? ITEM_DISABLED : ITEM_IGNORE;
}

public drm_get_romandate() {
  new _Date;
  new _Num[4];
  date(_, _Date, _);
  switch(_Date) {
    case 1: {
      copy(_Num, charsmax(_Num), "I");
    }
    case 2: {
      copy(_Num, charsmax(_Num), "II");
    }
    case 3: {
      copy(_Num, charsmax(_Num), "III");
    }
    case 4: {
      copy(_Num, charsmax(_Num), "IV");
    }
    case 5: {
      copy(_Num, charsmax(_Num), "V");
    }
    case 6: {
      copy(_Num, charsmax(_Num), "VI");
    }
    case 7: {
      copy(_Num, charsmax(_Num), "VII");
    }
    case 8: {
      copy(_Num, charsmax(_Num), "VIII");
    }
    case 9: {
      copy(_Num, charsmax(_Num), "IX");
    }
    case 10: {
      copy(_Num, charsmax(_Num), "X");
    }
    case 11: {
      copy(_Num, charsmax(_Num), "XI");
    }
    case 12: {
      copy(_Num, charsmax(_Num), "XII");
    }
  }
  return _Num;
}
