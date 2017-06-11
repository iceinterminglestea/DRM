# DRM

## Installation:
1. Compile **drm.sma** locally. *From what i've heard, web compiler is buggy*.
  * **Requirements:** AMXX 1.8.2: amxmodx amxmisc cstrike hamsandwich fakemeta dhudmessage, sqlx
2. Move **drm.amxx** to **/amxmodx/plugins/** and **drm_ml.txt** to **/amxmodx/data/lang**.
3. Add **drm.amxx** to **/amxmodx/configs/plugins.ini**.
4. On a live server, change map, otherwise just start the server.
5. Done.

## Configuring

### Cvars
*Used to configure the gameplay*

| pCvar Name      | Recommended Value     | Maximum Value | Description                                          |
|-----------------|-----------------------|---------------|------------------------------------------------------|
| drm_helprules   | "url to help page"    | 64            | File Location or URL                                 |
| drm_respawns    | 1                     | *             | Maximum respawns for default player per round.       |
| drm_viprespawns | 2                     | *             | Maxiumum respawns for vip player per round.          |
| drm_minplayers  | 2                     | 32            | When to start the game, 2 means 1v1                  |
| drm_spec_max    | 5                     | *             | Maximum amount of free spectate slots.               |
| drm_spec_vip    | 1                     | 1             | Personal VIP Spectating slot.                        |
| drm_queue_auto  | 1                     | 2             | 1 - Auto-join the Queue; 2- VIP auto-joins the Queue |
| drm_queue_type  | 1                     | 1             | 0 - Random; 1 - From Queue                           |
| drm_servername  | "Your Community Name" | 64            | Used in hostname " | Season X | "                    |
| drm_gamename    | "Your Community Name" | 64            | Used as GameName in Server Browser.                  |
| drm_vip_flags   | "bjn"                 | 8             | Used to give access to specified functions.          |
| drm_admin_flags | "abcdny"              | 8             | Used to give access to specified functions.          |

### SQL Cvars
*Used to store respawns, settings etc..*

| pCvar Name   | Data    | Max. Value | Description                                  |
|--------------|---------|------------|----------------------------------------------|
| drm_sql_use  | boolean | 1          | Determines whether to use the SQL functions. |
| drm_sql_host | string  | 255        | Hostname                                     |
| drm_sql_usr  | string  | 32         | Username to connect to the DB                |
| drm_sql_pw   | string  | 64         | Password to connect to the DB                |
| drm_sql_db   | string  | 32         | DB Name                                      |
