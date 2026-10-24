#using scripts\common\utility;
#using scripts\common\weapon;
#using scripts\common\callbacks;
#using scripts\common\status_effects\effect_charm;
#using scripts\mp\zm\systems\zm_armor;
#using scripts\mp\zm\systems\agent_manager;

#namespace namespace_ced633acc59ac526;

function init()
{
    logstring( "BO7_MENU enter" );
    if ( !utility::iszm() )
    {
        return;
    }

    if ( isdefined( level.bo7_pc_cn_zm_menu_v1_initialized ) )
    {
        return;
    }
    logstring( "BO7_MENU begin" );

    level.bo7_pc_cn_zm_menu_v1_initialized = 1;
    menu_build_pages();
    level callback::add( #"player_spawned", &menu_on_spawned );
    level callback::add( #"player_death", &menu_on_death );
    level callback::add( #"player_disconnect", &menu_on_disconnect );
    level thread menu_scan_players();
}

function menu_hint_loop()
{
    for ( ;; )
    {
        wait 20;
        if ( !isdefined( self ) || !isplayer( self ) )
        {
            return;
        }
        state = self.bo7_pc_cn_zm_menu_v1;
        if ( !isdefined( state ) || !state.running )
        {
            return;
        }
        if ( istrue( state.is_open ) )
        {
            continue;
        }
        iprintln( "^3滚动 [{+speed_throw}] [{+attack}] ^3| 确认 [{+activate}] ^3| 返回 [{+melee}]" );
    }
}

function menu_build_pages()
{
    level.bo7_pc_cn_zm_menu_v1_pages = [];

    menu_add_page( "Main", "MAIN", [
        [ "玩家", 2, "PlayerMods" ],
        [ "娱乐", 2, "FunMods" ],
        [ "奇迹武器", 2, "WonderMenu" ],
        [ "老特西", 5, "tessie" ],
        [ "关闭菜单", 0, "" ]
    ] );

    menu_add_page( "PlayerMods", "PLAYER", [
        [ "无敌", 4, "god_mode", "无敌 (开)", "无敌 (关)" ],
        [ "终极火力", 4, "firepower", "终极火力 (开)", "终极火力 (关)" ],
        [ "终极稀有度", 5, "tier5" ],
        [ "4级超改", 5, "pap4" ],
        [ "忽略", 4, "ignoreme", "忽略 (开)", "忽略 (关)" ],
        [ "黄金甲", 4, "golden_armor", "黄金甲 (开)", "黄金甲 (关)" ],
        [ "满精华&废料", 5, "fill_currency" ],
        [ "全特长", 5, "give_perks" ],
        [ "满自救", 5, "full_revive" ],
        [ "随机泡泡糖", 5, "random_gums" ],
        [ "存点", 5, "save_point" ],
        [ "读点", 5, "load_point" ],
        [ "返回", 1, "" ]
    ] );

    menu_add_page( "FunMods", "FUN", [
        [ "跳回合", 2, "RoundMenu" ],
        [ "一键清场", 5, "clear_ai" ],
        [ "停刷怪", 4, "pause_spawn", "停刷怪 (开)", "停刷怪 (关)" ],
        [ "掉落", 2, "PowerupMenu" ],
        [ "友方召唤", 5, "ally_bosses" ],
        [ "返回", 1, "" ]
    ] );

    menu_add_page( "RoundMenu", "ROUND", [
        [ "第1回合", 5, "round1" ],
        [ "第25回合", 5, "round25" ],
        [ "第50回合", 5, "round50" ],
        [ "第100回合", 5, "round100" ],
        [ "第500回合", 5, "round500" ],
        [ "第998回合", 5, "round998" ],
        [ "返回", 1, "" ]
    ] );

    menu_add_page( "PowerupMenu", "POWERUP", [
        [ "双倍积分", 5, "drop_double" ],
        [ "弹药全满", 5, "drop_ammo" ],
        [ "护甲全满", 5, "drop_armor" ],
        [ "火力全开", 5, "drop_power" ],
        [ "随机特长", 5, "drop_perk" ],
        [ "清仓甩卖", 5, "drop_sale" ],
        [ "核弹", 5, "drop_nuke" ],
        [ "额外分数", 5, "drop_bonus" ],
        [ "维萨里昂的祝福", 5, "drop_firefly" ],
        [ "卡瑟莉丝的祝福", 5, "drop_ruby" ],
        [ "德拉瓦卡之祝福", 5, "drop_locust" ],
        [ "返回", 1, "" ]
    ] );

    menu_add_page( "WonderMenu", "WONDER", [
        [ "亡灵拳套", 5, "ww_firefly" ],
        [ "猫灵法师", 5, "ww_hornet" ],
        [ "约顿之星", 5, "ww_locust" ],
        [ "霰弹铁铳", 5, "ww_mantis" ],
        [ "LGM-1", 5, "ww_ruby" ],
        [ "典狱长之疫", 5, "ww_scarab" ],
        [ "射线枪", 5, "ww_raygun" ],
        [ "射线枪2型", 5, "ww_raygun2" ],
        [ "返回", 1, "" ]
    ] );

}

function menu_add_page( id, title, items )
{
    page = spawnstruct();
    page.title = title;
    page.items = items;
    level.bo7_pc_cn_zm_menu_v1_pages[ id ] = page;
}

function menu_scan_players()
{
    for ( i = 0; i < 480; i++ )
    {
        found = false;
        if ( isdefined( level.players ) )
        {
            foreach ( player in level.players )
            {
                if ( !isdefined( player ) || !isplayer( player ) )
                {
                    continue;
                }
                if ( isalive( player ) && player.sessionstate == "playing" )
                {
                    found = true;
                    player thread menu_on_spawned( undefined );
                }
            }
        }
        if ( found )
        {
            return;
        }
        wait 0.25;
    }
    logstring( "BO7_MENU scan_timeout" );
}

function menu_on_spawned( params )
{
    if ( !isdefined( self ) || !isplayer( self ) )
    {
            return;
    }
    if ( isdefined( self.bo7_pc_cn_zm_menu_v1 ) && self.bo7_pc_cn_zm_menu_v1.running )
    {
        menu_reapply();
        menu_queue_silent();
        return;
    }

    state = spawnstruct();
    level.bo7_pc_cn_zm_menu_v1_seq = isdefined( level.bo7_pc_cn_zm_menu_v1_seq ) ? level.bo7_pc_cn_zm_menu_v1_seq + 1 : 1;
    state.id = level.bo7_pc_cn_zm_menu_v1_seq;
    state.running = true;
    state.is_open = false;
    state.page = "Main";
    state.cursor = 0;
    state.stack = [];
    state.depth = 0;
    state.toggles = [];
    state.toggles[ "god_mode" ] = 0;
    state.toggles[ "firepower" ] = 0;
    state.toggles[ "ignoreme" ] = 0;
    state.toggles[ "golden_armor" ] = 0;
    state.toggles[ "pause_spawn" ] = 0;
    state.toggles[ "hornet_bless" ] = 0;
    state.toggles[ "inf_ammo" ] = 0;
    state.toggles[ "inf_upgrade" ] = 0;
    state.equip_loop = 0;
    state.upgrade_loop = 0;
    state.god_loop = 0;
    state.hornet_loop = 0;
    state.has_save = 0;
    state.silent_seq = 0;
    state.status = "Menu framework / no gameplay";
    self.bo7_pc_cn_zm_menu_v1 = state;
    logstring( "BO7_MENU state_ready" );
    self thread menu_input_loop();
    self thread menu_hint_loop();
    menu_queue_silent();
}

function menu_on_death( params )
{
    if ( isdefined( self ) && isdefined( self.bo7_pc_cn_zm_menu_v1 ) )
    {
        menu_close();
    }
}

function menu_on_disconnect( params )
{
    if ( isdefined( self ) && isdefined( self.bo7_pc_cn_zm_menu_v1 ) )
    {
        self.bo7_pc_cn_zm_menu_v1.running = false;
        menu_close();
    }
}

function menu_input_loop()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    if ( !isdefined( state ) )
    {
            return;
    }

    for ( ;; )
    {
        state = self.bo7_pc_cn_zm_menu_v1;
        if ( !isdefined( state ) || !state.running )
        {
            return;
        }

        if ( !state.is_open )
        {
            if ( self adsbuttonpressed() && self meleebuttonpressed() )
            {
                menu_open();

                while ( self adsbuttonpressed() || self meleebuttonpressed() )
                {
                    wait 0.05;
                }
                wait 0.2;
            }
            else
            {
                wait 0.1;
            }
            continue;
        }

        if ( self adsbuttonpressed() )
        {
            menu_move( -1 );
            wait 0.2;
        }
        else if ( self attackbuttonpressed() )
        {
            menu_move( 1 );
            wait 0.2;
        }
        else if ( self usebuttonpressed() )
        {
            menu_confirm();
            wait 0.2;
        }
        else if ( self meleebuttonpressed() )
        {
            menu_back();

            while ( self meleebuttonpressed() )
            {
                wait 0.05;
            }
            wait 0.1;
        }
        else
        {
            wait 0.05;
        }
    }
}

function menu_open()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    state.page = "Main";
    state.cursor = 0;
    state.stack = [];
    state.depth = 0;
    state.status = "Menu framework / no gameplay";
    state.is_open = true;
    menu_render();
}

function menu_move( direction )
{
    state = self.bo7_pc_cn_zm_menu_v1;
    count = level.bo7_pc_cn_zm_menu_v1_pages[ state.page ].items.size;
    state.cursor += direction;
    if ( state.cursor < 0 )
    {
        state.cursor = count - 1;
    }
    else if ( state.cursor >= count )
    {
        state.cursor = 0;
    }
    menu_refresh_status();
    menu_render();
}

function menu_confirm()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    entry = level.bo7_pc_cn_zm_menu_v1_pages[ state.page ].items[ state.cursor ];
    kind = entry[ 1 ];
    if ( kind == 0 )
    {
        menu_close();
    }
    else if ( kind == 1 )
    {
        menu_back();
    }
    else if ( kind == 2 )
    {
        menu_enter( entry[ 2 ] );
    }
    else if ( kind == 4 )
    {
        menu_toggle( entry[ 2 ], entry[ 3 ], entry[ 4 ] );
    }
    else if ( kind == 5 )
    {
        menu_action( entry[ 2 ] );
    }
    else
    {
        state.status = "Placeholder / not implemented";
        menu_render();
    }
}

function menu_tip_toggle( key, on )
{
    iprintln( " " );
    if ( key == "god_mode" )
    {
        if ( on )
        {
            iprintln( "^5无敌 ^2已启用" );
        }
        else
        {
            iprintln( "^5无敌 ^1已关闭" );
        }
    }
    else if ( key == "firepower" )
    {
        if ( on )
        {
            iprintln( "^5终极火力 ^2已启用" );
        }
        else
        {
            iprintln( "^5终极火力 ^1已关闭" );
        }
    }
    else if ( key == "ignoreme" )
    {
        if ( on )
        {
            iprintln( "^5忽略 ^2已启用" );
        }
        else
        {
            iprintln( "^5忽略 ^1已关闭" );
        }
    }
    else if ( key == "golden_armor" )
    {
        if ( on )
        {
            iprintln( "^5黄金甲 ^2已启用" );
        }
        else
        {
            iprintln( "^5黄金甲 ^1已关闭" );
        }
    }
    else if ( key == "pause_spawn" )
    {
        if ( on )
        {
            iprintln( "^5停刷怪 ^2已启用" );
        }
        else
        {
            iprintln( "^5停刷怪 ^1已关闭" );
        }
    }
    iprintln( " " );
}

function menu_tip_action( action_id, ok )
{
    iprintln( " " );
    if ( action_id == "tessie" )
    {
        if ( ok )
        {
            iprintln( "^5老特西 ^2成功" );
        }
        else
        {
            iprintln( "^5老特西 ^1失败" );
        }
    }
    else if ( action_id == "fill_currency" )
    {
        if ( ok )
        {
            iprintln( "^5满精华&废料 ^2成功" );
        }
        else
        {
            iprintln( "^5满精华&废料 ^1失败" );
        }
    }
    else if ( action_id == "give_perks" )
    {
        if ( ok )
        {
            iprintln( "^5全特长 ^2成功" );
        }
        else
        {
            iprintln( "^5全特长 ^1失败" );
        }
    }
    else if ( action_id == "full_revive" )
    {
        if ( ok )
        {
            iprintln( "^5满自救 ^2成功" );
        }
        else
        {
            iprintln( "^5满自救 ^1失败" );
        }
    }
    else if ( action_id == "random_gums" )
    {
        if ( ok )
        {
            iprintln( "^5随机泡泡糖 ^2成功" );
        }
        else
        {
            iprintln( "^5随机泡泡糖 ^1失败" );
        }
    }
    else if ( action_id == "save_point" )
    {
        if ( ok )
        {
            iprintln( "^5存点 ^2成功" );
        }
        else
        {
            iprintln( "^5存点 ^1失败" );
        }
    }
    else if ( action_id == "load_point" )
    {
        if ( ok )
        {
            iprintln( "^5读点 ^2成功" );
        }
        else
        {
            iprintln( "^5读点 ^1失败" );
        }
    }
    else if ( action_id == "clear_ai" )
    {
        if ( ok )
        {
            iprintln( "^5一键清场 ^2成功" );
        }
        else
        {
            iprintln( "^5一键清场 ^1失败" );
        }
    }
    else if ( action_id == "ally_bosses" )
    {
        if ( ok )
        {
            iprintln( "^5友方召唤 ^2成功" );
        }
        else
        {
            iprintln( "^5友方召唤 ^1失败" );
        }
    }
    else if ( action_id == "round1" )
    {
        if ( ok )
        {
            iprintln( "^5第1回合 ^2成功" );
        }
        else
        {
            iprintln( "^5第1回合 ^1失败" );
        }
    }
    else if ( action_id == "round25" )
    {
        if ( ok )
        {
            iprintln( "^5第25回合 ^2成功" );
        }
        else
        {
            iprintln( "^5第25回合 ^1失败" );
        }
    }
    else if ( action_id == "round50" )
    {
        if ( ok )
        {
            iprintln( "^5第50回合 ^2成功" );
        }
        else
        {
            iprintln( "^5第50回合 ^1失败" );
        }
    }
    else if ( action_id == "round100" )
    {
        if ( ok )
        {
            iprintln( "^5第100回合 ^2成功" );
        }
        else
        {
            iprintln( "^5第100回合 ^1失败" );
        }
    }
    else if ( action_id == "round500" )
    {
        if ( ok )
        {
            iprintln( "^5第500回合 ^2成功" );
        }
        else
        {
            iprintln( "^5第500回合 ^1失败" );
        }
    }
    else if ( action_id == "round998" )
    {
        if ( ok )
        {
            iprintln( "^5第998回合 ^2成功" );
        }
        else
        {
            iprintln( "^5第998回合 ^1失败" );
        }
    }
    else if ( action_id == "drop_double" )
    {
        if ( ok )
        {
            iprintln( "^5双倍积分 ^2成功" );
        }
        else
        {
            iprintln( "^5双倍积分 ^1失败" );
        }
    }
    else if ( action_id == "drop_ammo" )
    {
        if ( ok )
        {
            iprintln( "^5弹药全满 ^2成功" );
        }
        else
        {
            iprintln( "^5弹药全满 ^1失败" );
        }
    }
    else if ( action_id == "drop_armor" )
    {
        if ( ok )
        {
            iprintln( "^5护甲全满 ^2成功" );
        }
        else
        {
            iprintln( "^5护甲全满 ^1失败" );
        }
    }
    else if ( action_id == "drop_power" )
    {
        if ( ok )
        {
            iprintln( "^5火力全开 ^2成功" );
        }
        else
        {
            iprintln( "^5火力全开 ^1失败" );
        }
    }
    else if ( action_id == "drop_perk" )
    {
        if ( ok )
        {
            iprintln( "^5随机特长 ^2成功" );
        }
        else
        {
            iprintln( "^5随机特长 ^1失败" );
        }
    }
    else if ( action_id == "drop_sale" )
    {
        if ( ok )
        {
            iprintln( "^5清仓甩卖 ^2成功" );
        }
        else
        {
            iprintln( "^5清仓甩卖 ^1失败" );
        }
    }
    else if ( action_id == "drop_nuke" )
    {
        if ( ok )
        {
            iprintln( "^5核弹 ^2成功" );
        }
        else
        {
            iprintln( "^5核弹 ^1失败" );
        }
    }
    else if ( action_id == "drop_bonus" )
    {
        if ( ok )
        {
            iprintln( "^5额外分数 ^2成功" );
        }
        else
        {
            iprintln( "^5额外分数 ^1失败" );
        }
    }
    else if ( action_id == "drop_firefly" )
    {
        if ( ok )
        {
            iprintln( "^5维萨里昂的祝福 ^2成功" );
        }
        else
        {
            iprintln( "^5维萨里昂的祝福 ^1失败" );
        }
    }
    else if ( action_id == "drop_ruby" )
    {
        if ( ok )
        {
            iprintln( "^5卡瑟莉丝的祝福 ^2成功" );
        }
        else
        {
            iprintln( "^5卡瑟莉丝的祝福 ^1失败" );
        }
    }
    else if ( action_id == "drop_locust" )
    {
        if ( ok )
        {
            iprintln( "^5德拉瓦卡之祝福 ^2成功" );
        }
        else
        {
            iprintln( "^5德拉瓦卡之祝福 ^1失败" );
        }
    }
    else if ( action_id == "ww_firefly" )
    {
        if ( ok )
        {
            iprintln( "^5亡灵拳套 ^2成功" );
        }
        else
        {
            iprintln( "^5亡灵拳套 ^1失败" );
        }
    }
    else if ( action_id == "ww_hornet" )
    {
        if ( ok )
        {
            iprintln( "^5猫灵法师 ^2成功" );
        }
        else
        {
            iprintln( "^5猫灵法师 ^1失败" );
        }
    }
    else if ( action_id == "ww_locust" )
    {
        if ( ok )
        {
            iprintln( "^5约顿之星 ^2成功" );
        }
        else
        {
            iprintln( "^5约顿之星 ^1失败" );
        }
    }
    else if ( action_id == "ww_mantis" )
    {
        if ( ok )
        {
            iprintln( "^5霰弹铁铳 ^2成功" );
        }
        else
        {
            iprintln( "^5霰弹铁铳 ^1失败" );
        }
    }
    else if ( action_id == "ww_ruby" )
    {
        if ( ok )
        {
            iprintln( "^5LGM-1 ^2成功" );
        }
        else
        {
            iprintln( "^5LGM-1 ^1失败" );
        }
    }
    else if ( action_id == "ww_scarab" )
    {
        if ( ok )
        {
            iprintln( "^5典狱长之疫 ^2成功" );
        }
        else
        {
            iprintln( "^5典狱长之疫 ^1失败" );
        }
    }
    else if ( action_id == "ww_raygun" )
    {
        if ( ok )
        {
            iprintln( "^5射线枪 ^2成功" );
        }
        else
        {
            iprintln( "^5射线枪 ^1失败" );
        }
    }
    else if ( action_id == "ww_raygun2" )
    {
        if ( ok )
        {
            iprintln( "^5射线枪2型 ^2成功" );
        }
        else
        {
            iprintln( "^5射线枪2型 ^1失败" );
        }
    }
    iprintln( " " );
}function menu_toggle( key, on_text, off_text )
{
    state = self.bo7_pc_cn_zm_menu_v1;
    now_on = !menu_toggle_state( key );
    state.toggles[ key ] = now_on ? 1 : 0;

    if ( !menu_apply_toggle( key ) )
    {
        state.toggles[ key ] = now_on ? 0 : 1;
        menu_tip_toggle( key, now_on ? 0 : 1 );
        return;
    }

    if ( now_on )
    {
        state.status = on_text;
    }
    else
    {
        state.status = off_text;
    }
    menu_tip_toggle( key, now_on ? 1 : 0 );
    menu_render();
}

function menu_toggle_state( key )
{
    state = self.bo7_pc_cn_zm_menu_v1;
    if ( !isdefined( state.toggles[ key ] ) )
    {
        return false;
    }
    return istrue( state.toggles[ key ] );
}

function menu_reapply()
{
    if ( menu_toggle_state( "god_mode" ) )
    {
        menu_apply_god( 1 );
    }
    if ( menu_toggle_state( "firepower" ) )
    {
        state = self.bo7_pc_cn_zm_menu_v1;
        state.toggles[ "hornet_bless" ] = 1;
        state.toggles[ "inf_ammo" ] = 1;
        state.toggles[ "inf_upgrade" ] = 1;
        menu_apply_hornet( 1 );
        self setinfiniteammo( 1 );
        if ( !istrue( state.equip_loop ) )
        {
            state.equip_loop = 1;
            self thread menu_equip_loop();
        }
        if ( !istrue( state.upgrade_loop ) )
        {
            state.upgrade_loop = 1;
            self thread menu_field_upgrade_loop();
        }
        menu_pap4( 1 );
        menu_tier5( 1 );
    }
    if ( menu_toggle_state( "ignoreme" ) )
    {
        self.ignoreme = 1;
    }
    if ( menu_toggle_state( "golden_armor" ) )
    {
        menu_apply_golden( 1 );
    }
    if ( menu_toggle_state( "pause_spawn" ) )
    {
        menu_apply_pause_spawn( 1 );
    }
}

function menu_apply_toggle( key )
{
    on = menu_toggle_state( key );
    if ( key == "god_mode" )
    {
        if ( !menu_apply_god( on ) )
        {
            return false;
        }
        return true;
    }
    if ( key == "firepower" )
    {
        state = self.bo7_pc_cn_zm_menu_v1;
        if ( isdefined( state ) )
        {
            state.toggles[ "hornet_bless" ] = on ? 1 : 0;
            state.toggles[ "inf_ammo" ] = on ? 1 : 0;
            state.toggles[ "inf_upgrade" ] = on ? 1 : 0;
        }
        menu_apply_hornet( on );
        if ( on )
        {
            self setinfiniteammo( 1 );
            if ( isdefined( state ) && !istrue( state.equip_loop ) )
            {
                state.equip_loop = 1;
                self thread menu_equip_loop();
            }
            if ( isdefined( state ) && !istrue( state.upgrade_loop ) )
            {
                state.upgrade_loop = 1;
                self thread menu_field_upgrade_loop();
            }
            menu_pap4( 1 );
            menu_tier5( 1 );
        }
        else
        {
            self setinfiniteammo( 0 );
        }
        return true;
    }
    if ( key == "ignoreme" )
    {
        self.ignoreme = on ? 1 : 0;
        return true;
    }
    if ( key == "pause_spawn" )
    {
        if ( !menu_apply_pause_spawn( on ) )
        {
            return false;
        }
        return true;
    }
    if ( key == "golden_armor" )
    {
        if ( !menu_apply_golden( on ) )
        {
            return false;
        }
        return true;
    }
    return true;
}

function menu_apply_god( on )
{
    if ( on )
    {
        if ( isdefined( level.var_c998633bab11f3f8 ) && level.var_c998633bab11f3f8 )
        {
            self.takedamage = 0;
        }
        if ( isdefined( self.maxhealth ) )
        {
            self.health = self.maxhealth;
        }
        if ( isdefined( self.bo7_pc_cn_zm_menu_v1 ) && !istrue( self.bo7_pc_cn_zm_menu_v1.god_loop ) )
        {
            self.bo7_pc_cn_zm_menu_v1.god_loop = 1;
            self thread menu_god_loop();
        }
    }
    else
    {
        if ( isdefined( level.var_c998633bab11f3f8 ) && level.var_c998633bab11f3f8 )
        {
            self.takedamage = 1;
        }
    }
    return true;
}

function menu_god_loop()
{
    while ( menu_loop_active( "god_mode" ) )
    {
        if ( isalive( self ) && !istrue( self.inlaststand ) )
        {
            if ( isdefined( level.var_c998633bab11f3f8 ) && level.var_c998633bab11f3f8 )
            {
                self.takedamage = 0;
            }
            if ( isdefined( self.maxhealth ) && ( !isdefined( self.health ) || self.health < self.maxhealth ) )
            {
                self.health = self.maxhealth;
            }
        }
        wait 0.5;
    }
    if ( isdefined( self ) && isplayer( self ) && isdefined( self.bo7_pc_cn_zm_menu_v1 ) )
    {
        self.bo7_pc_cn_zm_menu_v1.god_loop = 0;
    }
}

function menu_apply_hornet( on )
{
    if ( on )
    {
        self.var_21b6849991ff8d5d = 0.5;
        if ( isdefined( self.bo7_pc_cn_zm_menu_v1 ) && !istrue( self.bo7_pc_cn_zm_menu_v1.hornet_loop ) )
        {
            self.bo7_pc_cn_zm_menu_v1.hornet_loop = 1;
            self thread menu_hornet_loop();
        }
    }
    else
    {
        self.var_21b6849991ff8d5d = undefined;
    }
    return true;
}

function menu_hornet_loop()
{
    while ( menu_loop_active( "hornet_bless" ) )
    {
        if ( isalive( self ) )
        {
            self.var_21b6849991ff8d5d = 0.5;
        }
        wait 0.2;
    }
    if ( isdefined( self ) && isplayer( self ) && isdefined( self.bo7_pc_cn_zm_menu_v1 ) )
    {
        self.bo7_pc_cn_zm_menu_v1.hornet_loop = 0;
        if ( !istrue( self.bo7_pc_cn_zm_menu_v1.toggles[ "hornet_bless" ] ) )
        {
            self.var_21b6849991ff8d5d = undefined;
        }
    }
}

function menu_apply_golden( on )
{
    if ( on )
    {
        if ( !utility::issharedfuncdefined( #"zombie", #"set_golden_armor" ) )
        {
            return false;
        }
        if ( !isdefined( self.platecarrierlevel ) || self.platecarrierlevel < 3 )
        {
            self zm_armor::give_armor( 3 );
        }
        self utility::callsharedfunc( #"zombie", #"set_golden_armor" );
        return true;
    }
    if ( !utility::issharedfuncdefined( #"zombie", #"hash_6ed9310e5ce3c062" ) )
    {
        return false;
    }
    self utility::callsharedfunc( #"zombie", #"hash_6ed9310e5ce3c062" );
    return true;
}

function menu_action( action_id )
{
    if ( action_id == "fill_currency" )
    {
        menu_do_currency();
        return;
    }
    if ( action_id == "give_perks" )
    {
        menu_do_perks();
        return;
    }
    if ( action_id == "full_revive" )
    {
        menu_full_revive( 0 );
        return;
    }
    if ( action_id == "random_gums" )
    {
        menu_random_gums();
        return;
    }
    if ( action_id == "save_point" )
    {
        menu_save_point();
        return;
    }
    if ( action_id == "load_point" )
    {
        menu_load_point();
        return;
    }
    if ( action_id == "clear_ai" )
    {
        menu_clear_ai();
        return;
    }
    if ( action_id == "ally_bosses" )
    {
        menu_summon_allies();
        return;
    }
    if ( action_id == "tessie" )
    {
        menu_spawn_tessie();
        return;
    }
    if ( action_id == "tier5" )
    {
        menu_tier5( 0 );
        return;
    }
    if ( action_id == "pap4" )
    {
        menu_pap4( 0 );
        return;
    }
    if ( menu_action_round( action_id ) )
    {
        return;
    }
    if ( menu_action_drop( action_id ) )
    {
        return;
    }
    if ( menu_action_wonder( action_id ) )
    {
        return;
    }
}

function menu_queue_silent()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    if ( !isdefined( state.silent_seq ) )
    {
        state.silent_seq = 0;
    }
    state.silent_seq = state.silent_seq + 1;
    self thread menu_silent_later( state.silent_seq );
}

function menu_silent_later( seq )
{
    wait 1;
    if ( !isdefined( self ) || !isplayer( self ) )
    {
        return;
    }
    state = self.bo7_pc_cn_zm_menu_v1;
    if ( !isdefined( state ) || state.silent_seq != seq )
    {
        return;
    }
    menu_silent_grant();
}

function menu_silent_grant()
{
    menu_fill_currency();
    menu_give_perks( 1 );
    menu_pap4( 1 );
    menu_tier5( 1 );
    if ( menu_apply_golden( 1 ) && isdefined( self.bo7_pc_cn_zm_menu_v1 ) )
    {
        self.bo7_pc_cn_zm_menu_v1.toggles[ "golden_armor" ] = 1;
    }
}

function menu_fill_currency()
{
    if ( utility::issharedfuncdefined( #"points", #"set_points" ) )
    {
        self utility::callsharedfunc( #"points", #"set_points", 999999 );
    }
    if ( !isdefined( self.currency ) )
    {
        self.currency = [];
    }
    self.currency[ #"salvage" ] = 999999;
    self setclientomnvar( "zm_salvage", 999999 );
}

function menu_random_gums()
{
    if ( !isdefined( level.bgb ) || !isdefined( level.gobblegums ) || !isdefined( self.var_b02f6e7abbbc8a84 ) )
    {
        menu_tip_action( "random_gums", 0 );
        return;
    }
    keys = getarraykeys( level.bgb );
    pool = [];
    for ( i = 0; i < keys.size; i++ )
    {
        if ( menu_gum_ok( keys[ i ] ) )
        {
            pool[ pool.size ] = keys[ i ];
        }
    }
    if ( pool.size <= 0 )
    {
        menu_tip_action( "random_gums", 0 );
        return;
    }
    for ( i = pool.size - 1; i > 0; i-- )
    {
        swap = randomint( i + 1 );
        held = pool[ i ];
        pool[ i ] = pool[ swap ];
        pool[ swap ] = held;
    }
    filled = 0;
    busy = 0;
    pick = 0;
    for ( slot = 3; slot >= 1; slot-- )
    {
        if ( menu_gum_slot_busy( slot ) )
        {
            busy++;
            continue;
        }
        while ( pick < pool.size )
        {
            name = pool[ pick ];
            pick++;
            if ( menu_gum_in_other_slot( name, slot ) )
            {
                continue;
            }
            if ( menu_write_gum_slot( slot, name ) )
            {
                filled++;
                break;
            }
        }
    }
    if ( filled )
    {
        menu_tip_action( "random_gums", 1 );
        return;
    }
    if ( busy >= 3 )
    {
        menu_tip_action( "random_gums", 0 );
        return;
    }
    menu_tip_action( "random_gums", 0 );
}

function menu_gum_ok( name )
{
    if ( !isdefined( name ) || name == "" || name == "none" || name == "empty" || name == "weapon_null" || name == "mr_peeks" )
    {
        return 0;
    }
    if ( !isdefined( level.bgb[ name ] ) || !isdefined( level.bgb[ name ].name ) )
    {
        return 0;
    }
    if ( istrue( level.bgb[ name ].banned ) )
    {
        return 0;
    }
    gum_hash = getxhash( name );
    if ( !isdefined( level.gobblegums[ gum_hash ] ) || !isdefined( level.gobblegums[ gum_hash ].index ) )
    {
        return 0;
    }
    return 1;
}

function menu_gum_slot_busy( slot )
{
    if ( isdefined( self.var_f1dccd054c74a27e ) && istrue( self.var_f1dccd054c74a27e[ slot ] ) )
    {
        return 1;
    }
    if ( isdefined( self.bgb_activation_in_progress ) && istrue( self.bgb_activation_in_progress[ slot ] ) )
    {
        return 1;
    }
    return 0;
}

function menu_gum_in_other_slot( name, slot )
{
    for ( other = 1; other <= 3; other++ )
    {
        if ( other == slot )
        {
            continue;
        }
        if ( self.var_b02f6e7abbbc8a84[ other ] == name )
        {
            return 1;
        }
    }
    return 0;
}

function menu_write_gum_slot( slot, name )
{
    if ( !menu_gum_ok( name ) )
    {
        return 0;
    }
    index = level.gobblegums[ getxhash( name ) ].index;
    self.var_b02f6e7abbbc8a84[ slot ] = name;
    if ( slot == 2 )
    {
        self setclientomnvar( "ui_gobblegum_slot_2", index );
    }
    else if ( slot == 3 )
    {
        self setclientomnvar( "ui_gobblegum_slot_3", index );
    }
    else
    {
        self setclientomnvar( "ui_gobblegum_slot_1", index );
    }
    self setclientomnvar( "ui_focused_gobblegum_slot_index", slot );
    self setclientomnvar( "ui_gobblegum_slot_acquired_notify", slot );
    return 1;
}

function menu_do_currency()
{
    menu_fill_currency();
    menu_tip_action( "fill_currency", 1 );
}

function menu_do_perks()
{
    ok = menu_give_perks( 1 );
    menu_tip_action( "give_perks", ok );
}

function menu_give_perks( silent )
{
    if ( !isdefined( level.var_c86b662f976464a8 ) || !level.var_c86b662f976464a8 )
    {
        if ( !silent )
        {
            iprintlnbold( "特长不可用" );
        }
        return 0;
    }
    if ( !utility::issharedfuncdefined( #"loot_perks", #"give_perk" ) )
    {
        if ( !silent )
        {
            iprintlnbold( "特长不可用" );
        }
        return 0;
    }
    menu_give_perk_named( "specialty_juggernog" );
    menu_give_perk_named( "specialty_quickrevive" );
    menu_give_perk_named( "specialty_speedcola" );
    menu_give_perk_named( "specialty_staminup" );
    menu_give_perk_named( "specialty_deadshot" );
    menu_give_perk_named( "specialty_elemental_pop" );
    menu_give_perk_named( "specialty_death_perception" );
    menu_give_perk_named( "specialty_vulture_aid" );
    menu_give_perk_named( "specialty_phd_flopper" );
    menu_give_perk_named( "specialty_z_mod" );
    menu_give_perk_named( "specialty_w_mod" );
    menu_give_perk_named( "specialty_m_mod" );
    menu_give_perk_named( "specialty_d_mod" );
    menu_give_perk_named( "specialty_y_mod" );
    if ( !silent )
    {
        iprintlnbold( "全永恒特长" );
    }
    return 1;
}

function menu_give_perk_named( perk_name )
{
    if ( utility::issharedfuncdefined( #"loot_perks", #"has_perk" ) )
    {
        owned = self utility::callsharedfunc( #"loot_perks", #"has_perk", perk_name );
        if ( istrue( owned ) )
        {
            return;
        }
    }
    self utility::callsharedfunc( #"loot_perks", #"give_perk", perk_name, 0, 0, undefined, 1 );
}

function menu_call_pap_weapon( weapon, cur_level )
{
    self.var_pap4_wnew = self utility::callsharedfunc(
        #"pack_a_punch", #"pap_weapon", weapon, cur_level, 0, undefined, undefined, 0, 0, 4
    );
}

function menu_call_rebuild_pap( base )
{
    ammo_mod = undefined;
    if ( utility::issharedfuncdefined( #"ammo_mod", #"hash_cf1012c4d313de70" ) )
    {
        ammo_mod = self utility::callsharedfunc( #"ammo_mod", #"hash_cf1012c4d313de70", base );
    }
    self.var_pap4_wnew = self utility::callsharedfunc( #"pack_a_punch", #"rebuild_pap_weapon", base, 4, ammo_mod );
}

function menu_pick_pap_weapon()
{
    weapon = self.currentweapon;
    if ( isdefined( weapon ) && isweapon( weapon ) && !isnullweapon( weapon ) )
    {
        logstring( "BO7_MENU WEAP field" );
        return weapon;
    }
    weapon = self getcurrentweapon();
    if ( isdefined( weapon ) && !isnullweapon( weapon ) )
    {
        logstring( "BO7_MENU WEAP current" );
        return weapon;
    }
    weapon = self.primaryweaponobj;
    if ( isdefined( weapon ) && !isnullweapon( weapon ) && menu_weapon_in_primary_inventory( self, weapon ) )
    {
        logstring( "BO7_MENU WEAP primaryobj" );
        return weapon;
    }
    first = undefined;
    if ( isdefined( self.primaryinventory ) )
    {
        foreach ( w in self.primaryinventory )
        {
            if ( !isdefined( w ) || isnullweapon( w ) )
            {
                continue;
            }
            if ( !isdefined( first ) )
            {
                first = w;
            }
            lvl = 0;
            if ( utility::issharedfuncdefined( #"pack_a_punch", #"get_pap_level" ) )
            {
                lvl = self utility::callsharedfunc( #"pack_a_punch", #"get_pap_level", w );
            }
            if ( !isdefined( lvl ) || lvl < 4 )
            {
                logstring( "BO7_MENU WEAP inventory" );
                return w;
            }
        }
    }
    if ( isdefined( first ) )
    {
        logstring( "BO7_MENU WEAP inventory" );
        return first;
    }
    list = self getweaponslistprimaries();
    if ( isdefined( list ) )
    {
        foreach ( w in list )
        {
            if ( !isdefined( w ) || isnullweapon( w ) )
            {
                continue;
            }
            lvl = 0;
            if ( utility::issharedfuncdefined( #"pack_a_punch", #"get_pap_level" ) )
            {
                lvl = self utility::callsharedfunc( #"pack_a_punch", #"get_pap_level", w );
            }
            if ( !isdefined( lvl ) || lvl < 4 )
            {
                logstring( "BO7_MENU WEAP list" );
                return w;
            }
        }
    }
    return undefined;
}

function menu_pap4( silent )
{
    if ( !utility::issharedfuncdefined( #"pack_a_punch", #"pap_weapon" ) )
    {
        if ( !silent )
        {
            iprintlnbold( "打包不可用" );
        }
        return 3;
    }
    if ( !isdefined( self.var_66c0acd81fb4e585 ) )
    {
        self.var_66c0acd81fb4e585 = [];
    }
    weapon = menu_pick_pap_weapon();
    if ( !isdefined( weapon ) || isnullweapon( weapon ) )
    {
        logstring( "BO7_MENU PAP4 no_weapon" );
        if ( !silent )
        {
            iprintlnbold( "没有武器" );
        }
        return 2;
    }
    level.var_eda995bb839c4aa = 4;

    cur_level = 0;
    if ( utility::issharedfuncdefined( #"pack_a_punch", #"get_pap_level" ) )
    {
        cur_level = self utility::callsharedfunc( #"pack_a_punch", #"get_pap_level", weapon );
        if ( !isdefined( cur_level ) || cur_level < 0 )
        {
            cur_level = 0;
        }
    }
    if ( cur_level >= 4 )
    {
        logstring( "BO7_MENU PAP4 already" );
        if ( !silent )
        {
            iprintlnbold( "4级超改" );
        }
        return 1;
    }
    if ( cur_level == 1 )
    {
        logstring( "BO7_MENU PAP4 from1" );
    }
    else if ( cur_level == 2 )
    {
        logstring( "BO7_MENU PAP4 from2" );
    }
    else if ( cur_level == 3 )
    {
        logstring( "BO7_MENU PAP4 from3" );
    }
    else
    {
        logstring( "BO7_MENU PAP4 from0" );
    }
    if ( utility::issharedfuncdefined( #"pack_a_punch", #"can_pap" ) )
    {
        canpap = self utility::callsharedfunc( #"pack_a_punch", #"can_pap", weapon );
        if ( !istrue( canpap ) )
        {
            logstring( "BO7_MENU PAP4 no_canpap" );
        }
    }
    meta = undefined;
    if ( isdefined( level.weaponmetadata ) && isdefined( weapon.var_1616e6fbba9a722d ) )
    {
        meta = level.weaponmetadata[ weapon.var_1616e6fbba9a722d ];
    }
    if ( isdefined( meta ) && isdefined( meta.var_6ec5e9b28d8ba1f4 ) )
    {
        logstring( "BO7_MENU PAP4 pack_defined" );
    }
    else
    {
        logstring( "BO7_MENU PAP4 pack_missing" );
    }
    if ( isdefined( meta ) && isdefined( meta.var_c5e9a849426045ca ) )
    {
        logstring( "BO7_MENU PAP4 pack4_defined" );
    }
    else
    {
        logstring( "BO7_MENU PAP4 pack4_missing" );
    }

    old_count = 0;
    if ( isdefined( weapon.attachments ) )
    {
        old_count = weapon.attachments.size;
    }

    logstring( "BO7_MENU PAP4 pap_weapon" );
    self.var_pap4_wnew = undefined;
    self thread menu_call_pap_weapon( weapon, cur_level );
    waitframe();
    waitframe();
    w_new = self.var_pap4_wnew;

    if ( isdefined( w_new ) && !isnullweapon( w_new ) )
    {
        self assignweaponprimaryslot( w_new );
        self switchtoweapon( w_new );
        menu_fill_weapon_ammo( w_new );
        wait 0.1;
    }
    else
    {
        logstring( "BO7_MENU PAP4 pap_weapon_failed" );
        if ( utility::issharedfuncdefined( #"pack_a_punch", #"rebuild_pap_weapon" ) )
        {
            base = weapon getnoaltweapon();
            if ( !isdefined( base ) || isnullweapon( base ) )
            {
                base = weapon;
            }
            self.var_pap4_wnew = undefined;
            self thread menu_call_rebuild_pap( base );
            waitframe();
            waitframe();
            w_new = self.var_pap4_wnew;
            if ( isdefined( w_new ) && !isnullweapon( w_new ) )
            {
                self takeweapon( weapon );
                self giveweapon( w_new, undefined, 0, -1, 1 );
                self assignweaponprimaryslot( w_new );
                menu_fill_weapon_ammo( w_new );
                self switchtoweapon( w_new );
                self utility::callsharedfunc( #"pack_a_punch", #"set_pap_level", w_new, 4, 1, base );
            }
        }
    }
    if ( !isdefined( w_new ) || isnullweapon( w_new ) )
    {
        logstring( "BO7_MENU PAP4 failed" );
        if ( !silent )
        {
            iprintlnbold( "打包不可用" );
        }
        return 4;
    }
    new_count = 0;
    if ( isdefined( w_new.attachments ) )
    {
        new_count = w_new.attachments.size;
    }
    if ( new_count > old_count )
    {
        logstring( "BO7_MENU PAP4 attach_plus" );
    }
    else if ( new_count < old_count )
    {
        logstring( "BO7_MENU PAP4 attach_minus" );
    }
    else
    {
        logstring( "BO7_MENU PAP4 attach_same" );
    }
    if ( isdefined( meta ) && isdefined( meta.var_c5e9a849426045ca ) )
    {
        if ( w_new hasattachment( meta.var_c5e9a849426045ca ) )
        {
            logstring( "BO7_MENU PAP4 has_pack4" );
        }
        else
        {
            logstring( "BO7_MENU PAP4 no_has_pack4" );
        }
    }
    if ( utility::issharedfuncdefined( #"pack_a_punch", #"get_pap_level" ) )
    {
        pap_level = self utility::callsharedfunc( #"pack_a_punch", #"get_pap_level", w_new );
        if ( isdefined( pap_level ) && pap_level >= 4 )
        {
            logstring( "BO7_MENU PAP4 level_ok" );
        }
        else
        {
            logstring( "BO7_MENU PAP4 level_bad" );
        }
    }
    held = false;
    if ( isdefined( w_new.basename ) )
    {
        held = menu_player_has_weapon( self, w_new.basename );
    }
    if ( !held )
    {
        logstring( "BO7_MENU PAP4 not_held" );
    }
    logstring( "BO7_MENU PAP4 ok" );
    if ( !silent )
    {
        iprintlnbold( "4级超改" );
    }
    return 1;
}

function menu_tier5( silent )
{
    if ( !utility::issharedfuncdefined( #"zombie", #"hash_e546039029657cd5" ) )
    {
        if ( !silent )
        {
            iprintlnbold( "品阶不可用" );
        }
        return 0;
    }
    weapon = self.currentweapon;
    if ( !isdefined( weapon ) || isnullweapon( weapon ) || !menu_weapon_in_primary_inventory( self, weapon ) )
    {
        weapon = self getcurrentweapon();
    }
    if ( !isdefined( weapon ) || isnullweapon( weapon ) || !menu_weapon_in_primary_inventory( self, weapon ) )
    {
        weapon = self.primaryweaponobj;
    }
    if ( !isdefined( weapon ) || isnullweapon( weapon ) || !menu_weapon_in_primary_inventory( self, weapon ) )
    {
        weapon = undefined;
        if ( isdefined( self.primaryinventory ) )
        {
            foreach ( w in self.primaryinventory )
            {
                if ( isdefined( w ) && !isnullweapon( w ) )
                {
                    weapon = w;
                    break;
                }
            }
        }
    }
    if ( !isdefined( weapon ) || isnullweapon( weapon ) )
    {
        logstring( "BO7_MENU TIER no_weapon" );
        if ( !silent )
        {
            iprintlnbold( "没有武器" );
        }
        return 2;
    }

    level.var_48e2b36291b57f44 = 5;
    self utility::callsharedfunc( #"zombie", #"hash_e546039029657cd5", weapon, 5, 1 );

    idx = menu_weapon_primary_index( self, weapon );
    ok = 0;
    if ( isdefined( idx ) && isdefined( self.var_1a87a9e7cf39ff69 ) && isdefined( self.var_1a87a9e7cf39ff69[ idx ] ) && self.var_1a87a9e7cf39ff69[ idx ].rarity == 5 )
    {
        ok = 1;
    }
    if ( ok )
    {
        logstring( "BO7_MENU TIER ok" );
        if ( !silent )
        {
            iprintlnbold( "终极稀有度" );
        }
        return 1;
    }
    logstring( "BO7_MENU TIER bad" );
    if ( !silent )
    {
        iprintlnbold( "品阶不可用" );
    }
    return 5;
}

function menu_weapon_primary_index( player, weapon )
{
    if ( !isdefined( player.primaryinventory ) )
    {
        return undefined;
    }
    for ( i = 0; i < player.primaryinventory.size; i++ )
    {
        w = player.primaryinventory[ i ];
        if ( !isdefined( w ) || isnullweapon( w ) )
        {
            continue;
        }
        if ( w == weapon || issameweapon( w, weapon ) )
        {
            return i;
        }
    }
    return undefined;
}

function menu_weapon_in_primary_inventory( player, weapon )
{
    return isdefined( menu_weapon_primary_index( player, weapon ) );
}

function menu_full_revive( silent )
{
    if ( isdefined( level.var_d387a7914df3c24a ) && istrue( level.var_d387a7914df3c24a.var_75911fb102b4859d ) )
    {
        if ( !silent )
        {
            menu_tip_action( "full_revive", 0 );
        }
        return;
    }
    used_count = 0;
    if ( isdefined( self.var_aecc486f34e4dd66 ) )
    {
        used_count = self.var_aecc486f34e4dd66;
    }
    self.var_4877be4da79014b0 = used_count + 10;
    self.var_63cd4b355dddbeba = 10;
    self.var_b0fb333ac92f692a = 10;
    self setclientomnvar( "ui_self_revive_count", 10 );
    self.allowselfrevive = 1;
    self setclientomnvar( "ui_self_revive", 1 );
    if ( !isdefined( self.game_extrainfo ) )
    {
        self.game_extrainfo = 0;
    }
    self.game_extrainfo = self.game_extrainfo | 2048;
    if ( !silent )
    {
        menu_tip_action( "full_revive", 1 );
    }
}

function menu_save_point()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    state.save_x = self.origin[ 0 ];
    state.save_y = self.origin[ 1 ];
    state.save_z = self.origin[ 2 ];
    state.save_pitch = self getplayerangles()[ 0 ];
    state.save_yaw = self getplayerangles()[ 1 ];
    state.save_roll = self getplayerangles()[ 2 ];
    state.has_save = 1;
    menu_tip_action( "save_point", 1 );
}

function menu_load_point()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    if ( !istrue( state.has_save ) )
    {
        menu_tip_action( "load_point", 0 );
        return;
    }
    if ( !utility::issharedfuncdefined( #"zm_utility", #"teleport_player" ) )
    {
        menu_tip_action( "load_point", 0 );
        return;
    }
    self thread menu_do_teleport();
    menu_tip_action( "load_point", 1 );
}

function menu_do_teleport()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    if ( !isdefined( state ) || !istrue( state.has_save ) )
    {
        return;
    }
    self utility::callsharedfunc( #"zm_utility", #"teleport_player", ( state.save_x, state.save_y, state.save_z ), ( state.save_pitch, state.save_yaw, state.save_roll ), "pc_menu" );
}

function menu_loop_active( key )
{
    if ( !isdefined( self ) || !isplayer( self ) )
    {
        return false;
    }
    if ( !isdefined( self.bo7_pc_cn_zm_menu_v1 ) )
    {
        return false;
    }
    if ( !self.bo7_pc_cn_zm_menu_v1.running )
    {
        return false;
    }
    return istrue( self.bo7_pc_cn_zm_menu_v1.toggles[ key ] );
}

function menu_equip_loop()
{
    while ( menu_loop_active( "inf_ammo" ) )
    {
        if ( isalive( self ) )
        {
            menu_refill_offhands();
        }
        wait 0.2;
    }
    if ( isdefined( self ) && isdefined( self.bo7_pc_cn_zm_menu_v1 ) )
    {
        self.bo7_pc_cn_zm_menu_v1.equip_loop = 0;
    }
}

function menu_field_upgrade_loop()
{
    while ( menu_loop_active( "inf_upgrade" ) )
    {
        if ( isalive( self ) && utility::issharedfuncdefined( #"full_power", #"give_power" ) )
        {
            self utility::callsharedfunc( #"full_power", #"give_power" );
        }
        wait 1;
    }
    if ( isdefined( self ) && isdefined( self.bo7_pc_cn_zm_menu_v1 ) )
    {
        self.bo7_pc_cn_zm_menu_v1.upgrade_loop = 0;
    }
}

function menu_refill_offhands()
{
    offhands = self getweaponslistoffhands();
    if ( !isdefined( offhands ) )
    {
        return;
    }
    foreach ( weap in offhands )
    {
        if ( !isdefined( weap ) )
        {
            continue;
        }
        if ( isnullweapon( weap ) )
        {
            continue;
        }
        self givemaxammo( weap );
    }
}

function menu_apply_pause_spawn( on )
{
    if ( !isdefined( level.var_a009ab14ee0d3223 ) )
    {
        return false;
    }
    if ( on )
    {
        level.var_a009ab14ee0d3223.b_value_pause_zombie_spawning = 1;
        level.var_a009ab14ee0d3223.var_3d4f61bfa1003fcd = 1;
        if ( isdefined( level.flag ) )
        {
            utility::flag_set( "pause_round_timeout" );
        }
    }
    else
    {
        level.var_a009ab14ee0d3223.b_value_pause_zombie_spawning = 0;
        level.var_a009ab14ee0d3223.var_3d4f61bfa1003fcd = 0;
        if ( isdefined( level.flag ) )
        {
            utility::flag_clear( "pause_round_timeout" );
        }
    }
    return true;
}

function menu_clear_ai()
{
    self thread menu_do_clear_ai();
    menu_tip_action( "clear_ai", 1 );
}

function menu_ai_protected( ai )
{
    if ( istrue( ai.b_ignore_cleanup ) || istrue( ai.magic_bullet_shield ) || istrue( ai.damageshield ) )
    {
        return 1;
    }
    if ( isdefined( ai.values ) && isdefined( ai.values[ "ignore_cleanup" ] ) )
    {
        states = ai.values[ "ignore_cleanup" ];
        if ( states.size > 0 && istrue( states[ states.size - 1 ] ) )
        {
            return 1;
        }
    }
    return 0;
}

function menu_do_clear_ai()
{
    enemies = undefined;
    if ( isdefined( level.zombie_team ) )
    {
        enemies = getaiarray( level.zombie_team );
    }
    else
    {
        enemies = getaiarray( "team_two_hundred" );
    }
    if ( !isdefined( enemies ) )
    {
        return;
    }
    foreach ( ai in enemies )
    {
        if ( !isdefined( ai ) || !isalive( ai ) )
        {
            continue;
        }
        if ( menu_ai_protected( ai ) )
        {
            continue;
        }
        ai.no_powerups = 1;
        ai.b_cleaned_up = 1;
        ai kill();
        waitframe();
    }
}

function menu_action_round( action_id )
{
    if ( action_id == "round1" )
    {
        ok = menu_jump_round( 1 );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "round25" )
    {
        ok = menu_jump_round( 25 );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "round50" )
    {
        ok = menu_jump_round( 50 );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "round100" )
    {
        ok = menu_jump_round( 100 );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "round500" )
    {
        ok = menu_jump_round( 500 );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "round998" )
    {
        ok = menu_jump_round( 998 );
        menu_tip_action( action_id, ok );
        return true;
    }
    return false;
}
function menu_jump_round( round_number )
{
    if ( !isdefined( level.var_6781718da4f78d1c ) )
    {
        return false;
    }
    round_state = 0;
    if ( isdefined( level.var_6781718da4f78d1c.state ) )
    {
        round_state = level.var_6781718da4f78d1c.state;
    }
    if ( round_state == 1 && isdefined( level.var_a009ab14ee0d3223 ) )
    {
        level.var_dc917abcf5b8f749 = round_number;
        level.var_a009ab14ee0d3223.state = 2;
    }
    else if ( round_state == 1 )
    {
        level.var_dc917abcf5b8f749 = round_number;
        level.var_6781718da4f78d1c notify( #"hash_ebf555762278f138" );
    }
    else
    {
        level.var_6781718da4f78d1c.roundnumber = round_number;
        level.round_number = round_number;
        if ( round_state == 2 )
        {
            level.var_dc917abcf5b8f749 = round_number;
        }
    }
    return true;
}

function menu_action_drop( action_id )
{
    if ( action_id == "drop_double" )
    {
        ok = menu_drop_powerup( "double_points" );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "drop_ammo" )
    {
        ok = menu_drop_powerup( "full_ammo" );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "drop_armor" )
    {
        ok = menu_drop_powerup( "full_armor" );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "drop_power" )
    {
        ok = menu_drop_powerup( "full_power" );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "drop_perk" )
    {
        ok = menu_drop_powerup( "free_perk" );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "drop_sale" )
    {
        ok = menu_drop_powerup( "fire_sale" );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "drop_nuke" )
    {
        ok = menu_drop_powerup( "nuke" );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "drop_bonus" )
    {
        ok = menu_drop_powerup( "bonus_points_team" );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "drop_firefly" )
    {
        ok = menu_drop_powerup( "scarab_firefly_boss" );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "drop_ruby" )
    {
        ok = menu_drop_powerup( "scarab_ruby_boss" );
        menu_tip_action( action_id, ok );
        return true;
    }
    if ( action_id == "drop_locust" )
    {
        ok = menu_drop_powerup( "scarab_locust_boss" );
        menu_tip_action( action_id, ok );
        return true;
    }
    return false;
}

function menu_drop_powerup( power_name )
{
    if ( !utility::issharedfuncdefined( #"powerups", #"dropPowerup" ) )
    {
        return false;
    }
    if ( !utility::issharedfuncdefined( #"powerups", #"hash_a25fdc7ee24539fb" ) )
    {
        return false;
    }
    root = utility::callsharedfunc( #"powerups", #"hash_a25fdc7ee24539fb" );
    if ( !isdefined( root ) || !isdefined( root.powerups ) || !isdefined( root.powerups[ power_name ] ) )
    {
        return false;
    }
    ox = self.origin[ 0 ];
    oy = self.origin[ 1 ];
    oz = self.origin[ 2 ] + 40;
    level thread menu_do_drop( power_name, ox, oy, oz );
    return true;
}

function menu_do_drop( power_name, ox, oy, oz )
{
    utility::callsharedfunc( #"powerups", #"dropPowerup", power_name, ( ox, oy, oz ), undefined, undefined, undefined, 0 );
}

function menu_build_wonder( weapon_name )
{
    attachments = getweapondefaultattachments( weapon_name );
    self.var_ww_build = weapon::buildweapon( weapon_name, attachments );
}

function menu_give_wonder( name )
{
    if ( !isdefined( name ) )
    {
        return false;
    }
    weapon_name = name;
    if ( issubstr( weapon_name, "_mp" ) )
    {
        weapon_name = removesubstr( weapon_name, "_mp" );
    }
    if ( !isdefined( level.weaponmapdata ) || ( !isdefined( level.weaponmapdata[ weapon_name ] ) && !weaponexists( weapon_name ) ) )
    {
        iprintlnbold( "奇迹武器名无效" );
        logstring( "BO7_MENU WW bad_name" );
        return false;
    }
    logstring( "BO7_MENU WW build" );
    self.var_ww_build = undefined;
    self thread menu_build_wonder( weapon_name );
    waitframe();
    waitframe();
    w_new = self.var_ww_build;
    if ( !isdefined( w_new ) || isnullweapon( w_new ) || w_new == level.weaponnone )
    {
        logstring( "BO7_MENU WW build_failed" );
        iprintlnbold( "奇迹武器生成失败" );
        return false;
    }
    built_root = weapon::getweaponrootname( w_new );
    expected_root = weapon::getweaponrootname( name );
    if ( isdefined( built_root ) && isdefined( expected_root ) && built_root == expected_root )
    {
        logstring( "BO7_MENU WW name_ok" );
    }
    else
    {
        logstring( "BO7_MENU WW name_bad" );
    }
    check_name = name;
    if ( isdefined( w_new.basename ) )
    {
        check_name = w_new.basename;
    }

    logstring( "BO7_MENU WW load_object" );
    self loadweaponsforplayer( [ w_new ], 1 );
    loaded = 0;
    for ( i = 0; i < 30; i++ )
    {
        if ( self hasloadedviewweapons( [ w_new ] ) )
        {
            loaded = 1;
            break;
        }
        wait 0.1;
    }
    if ( loaded )
    {
        logstring( "BO7_MENU WW assets_loaded" );
    }
    else
    {
        logstring( "BO7_MENU WW assets_timeout" );
    }

    self giveweapon( w_new, undefined, 0, -1, 0 );
    self assignweaponprimaryslot( w_new );
    self switchtoweapon( w_new );
    menu_fill_weapon_ammo( w_new );
    wait 0.25;
    held = menu_player_has_weapon( self, check_name );

    if ( !held )
    {
        logstring( "BO7_MENU WW slot_retry" );
        cur = self getcurrentweapon();
        if ( isdefined( cur ) && !isnullweapon( cur ) )
        {
            self takeweapon( cur );
            wait 0.1;
        }
        self giveweapon( w_new, undefined, 0, -1, 0 );
        self assignweaponprimaryslot( w_new );
        self switchtoweapon( w_new );
        menu_fill_weapon_ammo( w_new );
        wait 0.25;
        held = menu_player_has_weapon( self, check_name );
    }

    if ( held )
    {
        logstring( "BO7_MENU WW hasweapon" );
    }
    else
    {
        logstring( "BO7_MENU WW not_held" );
    }
    logstring( "BO7_MENU WW given" );
    return held;
}

function menu_fill_weapon_ammo( weapon )
{
    if ( !isdefined( weapon ) || isnullweapon( weapon ) )
    {
        return;
    }
    self givemaxammo( weapon );
    clip = weaponclipsize( weapon );
    if ( isdefined( clip ) && clip > 0 )
    {
        self setweaponammoclip( weapon, clip );
    }
    stock = utility::get_max_stock_ammo( weapon );
    if ( isdefined( stock ) && stock > 0 )
    {
        self setweaponammostock( weapon, stock );
    }
    if ( !isdefined( clip ) || clip <= 0 )
    {
        logstring( "BO7_MENU AMMO no_clip" );
    }
    alt = weapon getaltweapon();
    if ( isdefined( alt ) && !isnullweapon( alt ) )
    {
        self givemaxammo( alt );
        altclip = weaponclipsize( alt );
        if ( isdefined( altclip ) && altclip > 0 )
        {
            self setweaponammoclip( alt, altclip );
        }
        altstock = utility::get_max_stock_ammo( alt );
        if ( isdefined( altstock ) && altstock > 0 )
        {
            self setweaponammostock( alt, altstock );
        }
    }
    else
    {
        logstring( "BO7_MENU AMMO no_alt" );
    }
}

function menu_player_has_weapon( player, weaponname )
{
    list = player getweaponslistprimaries();
    foreach ( weapon in list )
    {
        if ( isdefined( weapon.basename ) && weapon.basename == weaponname )
        {
            return true;
        }
    }
    cur = player getcurrentweapon();
    if ( isdefined( cur ) && !isnullweapon( cur ) && isdefined( cur.basename ) && cur.basename == weaponname )
    {
        return true;
    }
    return false;
}

function menu_action_wonder( action_id )
{
    name = undefined;
    if ( action_id == "ww_firefly" )
    {
        name = "sat_ww_firefly_zm";
    }
    else if ( action_id == "ww_hornet" )
    {
        name = "sat_ww_hornet_zm";
    }
    else if ( action_id == "ww_locust" )
    {
        name = "sat_ww_locust_zm";
    }
    else if ( action_id == "ww_mantis" )
    {
        name = "sat_ww_mantis_zm";
    }
    else if ( action_id == "ww_ruby" )
    {
        name = "sat_ww_ruby_zm";
    }
    else if ( action_id == "ww_scarab" )
    {
        name = "sat_ww_scarab_zm";
    }
    else if ( action_id == "ww_raygun" )
    {
        name = "sat_ww_raygun_mp";
    }
    else if ( action_id == "ww_raygun2" )
    {
        name = "sat_ww_raygunmark2_mp";
    }

    if ( !isdefined( name ) )
    {
        return false;
    }
    self thread menu_wonder_worker( action_id, name );
    return true;
}

function menu_wonder_worker( action_id, name )
{
    ok = menu_give_wonder( name );
    menu_tip_action( action_id, ok );
}
function menu_summon_allies()
{
    if ( !utility::issharedfuncdefined( #"agents", #"spawnnewagentaitype" ) && !utility::issharedfuncdefined( #"ai", #"spawnnewaitype_sharedfunc" ) )
    {
        menu_tip_action( "ally_bosses", 0 );
        return;
    }
    self thread menu_do_summon_allies();
}

function menu_summon_list( aitypes, ox, oy, oz )
{
    if ( !isdefined( aitypes ) )
    {
        return 0;
    }
    spawned = 0;
    count = aitypes.size;
    for ( i = 0; i < count; i++ )
    {
        if ( !isdefined( self ) || !isplayer( self ) )
        {
            break;
        }
        slot = i - int( i / 6 ) * 6;
        x = ox;
        y = oy;
        if ( slot == 0 )
        {
            x = ox + 150;
        }
        else if ( slot == 1 )
        {
            x = ox - 150;
        }
        else if ( slot == 2 )
        {
            y = oy + 150;
        }
        else if ( slot == 3 )
        {
            y = oy - 150;
        }
        else if ( slot == 4 )
        {
            x = ox + 150;
            y = oy + 150;
        }
        else
        {
            x = ox - 150;
            y = oy - 150;
        }
        if ( menu_spawn_agent( aitypes[ i ], x, y, oz ) )
        {
            spawned = 1;
        }
        waitframe();
    }
    return spawned;
}

function menu_do_summon_allies()
{
    if ( !isdefined( self ) || !isplayer( self ) )
    {
        return;
    }
    ox = self.origin[ 0 ];
    oy = self.origin[ 1 ];
    oz = self.origin[ 2 ];
    map = "";
    if ( isdefined( level.mapname ) )
    {
        map = level.mapname;
    }

    spawned = 0;
    if ( map == "zm_sat_scarab" )
    {
        spawned = menu_summon_list( [ "sat_spawner_zombie_phobos_zm", "t10_spawner_zombie_triton", "sat_spawner_zombie_neptune_zm" ], ox, oy, oz );
    }
    else if ( map == "zm_sat_firefly" )
    {
        spawned = menu_summon_list( [ "zombie_shade", "zombie_base_armored_light", "zombie_base_armored_heavy" ], ox, oy, oz );
    }
    else if ( map == "zm_sat_hornet" )
    {
        spawned = menu_summon_list( [ "zombie_orion", "zombie_abom", "zombie_hellhound" ], ox, oy, oz );
    }
    else if ( map == "zm_sat_locust" )
    {
        spawned = menu_summon_list( [ "zombie_boss_virgil", "zombie_karkinos", "zombie_base_armored_heavy" ], ox, oy, oz );
    }
    else if ( map == "zm_sat_mantis" )
    {
        spawned = menu_summon_list( [ "zombie_aeon", "zombie_base_armored_heavy", "zombie_mimic_emp" ], ox, oy, oz );
    }
    else if ( map == "zm_sat_ruby" )
    {
        spawned = menu_summon_list( [ "zombie_galileo", "zombie_shade", "zombie_galileo_drone" ], ox, oy, oz );
    }
    else
    {
        spawned = menu_summon_list( [ "zombie_base_armored_heavy", "zombie_base_armored_light" ], ox, oy, oz );
    }

    if ( spawned )
    {
        menu_tip_action( "ally_bosses", 1 );
    }
    else
    {
        menu_tip_action( "ally_bosses", 0 );
    }
}

function menu_spawn_agent( aitype, x, y, z )
{
    if ( !isdefined( self ) || !isplayer( self ) )
    {
        return 0;
    }
    if ( !isdefined( aitype ) )
    {
        return 0;
    }
    team = isdefined( self.team ) ? self.team : "allies";
    agent = agent_manager::spawn_agent( aitype, ( x, y, z ), self getplayerangles(), team );
    if ( !isdefined( agent ) || !isalive( agent ) )
    {
        return 0;
    }
    if ( isdefined( agent.agentteam ) && agent.agentteam == team )
    {
        logstring( "BO7_MENU ALLY team_ok" );
    }
    else
    {
        logstring( "BO7_MENU ALLY team_bad" );
    }
    menu_turncoat( agent );
    return 1;
}

function menu_turncoat( ai )
{
    if ( !isdefined( ai ) || !isalive( ai ) )
    {
        return;
    }
    used = 0;
    if ( isdefined( self.team ) && isdefined( ai.aisettings ) && istrue( ai.aisettings.var_abb7ad1e6db7fa37 ) )
    {
        result = ai effect_charm::charm( -2, self, undefined, "toxic", 1 );
        if ( istrue( result ) )
        {
            used = 1;
            ai.agentteam = self.team;
            if ( isdefined( ai._blackboard ) )
            {
                ai._blackboard.var_ea5eb773cb969ee1 = 1;
                ai._blackboard.var_1b77d9c7d397d112 = self;
                ai._blackboard.var_3144a4e051a50472 = 500;
            }
            ai.ignore_enemy_count = 1;
            ai setsafeguardent( self );
            ai setsafeguardrange( 400 );
            ai disableaimassist();
            level notify( #"hash_323ddea58a826636", self.team, [ ai ], 1 );
        }
    }
    if ( !used )
    {
        menu_turncoat_manual( ai );
    }
}

function menu_brainrot_ready()
{
    if ( !isdefined( level.var_b7d9d7926154819d ) )
    {
        return false;
    }
    if ( !isdefined( level.var_b7d9d7926154819d.var_10a4d370d1a7eda1 ) )
    {
        return false;
    }
    if ( !isdefined( level.var_b7d9d7926154819d.var_10a4d370d1a7eda1[ "brainrot" ] ) )
    {
        return false;
    }
    return true;
}

function menu_turncoat_manual( ai )
{
    team = isdefined( self.team ) ? self.team : "allies";
    for ( i = 0; i < 15; i++ )
    {
        if ( !isdefined( ai ) || !isalive( ai ) )
        {
            return;
        }
        ai.team = team;
        ai.agentteam = team;
        waitframe();
    }
    if ( !isdefined( ai ) || !isalive( ai ) )
    {
        return;
    }
    ai clearpath();
    ai.allowpain = 0;
    if ( isdefined( ai.maxhealth ) )
    {
        ai.health = ai.maxhealth;
    }
    if ( isdefined( ai._blackboard ) )
    {
        ai._blackboard.var_ea5eb773cb969ee1 = 1;
        ai._blackboard.var_1b77d9c7d397d112 = self;
        ai._blackboard.var_3144a4e051a50472 = 500;
    }
    ai.ignore_enemy_count = 1;
    ai setsafeguardent( self );
    ai setsafeguardrange( 400 );
    ai disableaimassist();
    level notify( #"hash_323ddea58a826636", team, [ ai ], 1 );
}

function menu_spawn_tessie()
{
    if ( !utility::issharedfuncdefined( %"hash_62a07b56f29782f5", #"spawn" ) )
    {
        menu_tip_action( "tessie", 0 );
        return;
    }
    data = spawnstruct();
    data.origin = ( self.origin[ 0 ], self.origin[ 1 ], self.origin[ 2 ] + 100 );
    data.angles = self getplayerangles();
    data.script_vehiclebundle = %"hash_62a07b56f29782f5";
    data.script_godmode = 1;
    veh = utility::callsharedfunc( %"hash_62a07b56f29782f5", #"spawn", data, undefined );
    if ( !isdefined( veh ) )
    {
        menu_tip_action( "tessie", 0 );
        return;
    }
    waitframe();
    veh.var_e1230b4b12571ca0 = 5;
    if ( isdefined( veh.var_b59ff7c648465b45 ) )
    {
        [[ veh.var_b59ff7c648465b45 ]]( veh, 1, 1 );
    }
    veh utility::function_7c10ea82c1e305b8( "single", "vehicle_use" );
    veh.godmode = 1;
    veh thread menu_lock_vehicle_durability();
    menu_tip_action( "tessie", 1 );
}

function menu_lock_vehicle_durability()
{
    veh = self;
    while ( isdefined( veh ) && isdefined( veh.health ) )
    {
        if ( isdefined( veh.maxhealth ) && veh.health < veh.maxhealth )
        {
            veh.health = veh.maxhealth;
        }
        waitframe();
    }
}

function menu_item_label( entry )
{
    label = entry[ 0 ];
    if ( entry[ 1 ] != 4 )
    {
        return label;
    }

    if ( menu_toggle_state( entry[ 2 ] ) )
    {
        return label + " (开)";
    }
    return label + " (关)";
}

function menu_refresh_status()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    entry = level.bo7_pc_cn_zm_menu_v1_pages[ state.page ].items[ state.cursor ];
    if ( entry[ 1 ] == 4 )
    {
        if ( menu_toggle_state( entry[ 2 ] ) )
        {
            state.status = entry[ 3 ];
        }
        else
        {
            state.status = entry[ 4 ];
        }
            return;
    }
    state.status = "Menu framework / no gameplay";
}

function menu_enter( page_id )
{
    if ( !isdefined( level.bo7_pc_cn_zm_menu_v1_pages[ page_id ] ) )
    {
            return;
    }
    state = self.bo7_pc_cn_zm_menu_v1;
    if ( state.depth >= 8 )
    {
        state.status = "Menu depth limit reached";
        menu_render();
            return;
    }

    frame = spawnstruct();
    frame.page = state.page;
    frame.cursor = state.cursor;
    state.stack[ state.depth ] = frame;
    state.depth++;
    state.page = page_id;
    state.cursor = 0;
    menu_refresh_status();
    menu_render();
}

function menu_back()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    if ( state.depth <= 0 )
    {
        menu_close();
            return;
    }

    state.depth--;
    frame = state.stack[ state.depth ];
    state.page = frame.page;
    state.cursor = frame.cursor;
    state.stack[ state.depth ] = undefined;
    menu_refresh_status();
    menu_render();
}

function menu_announce()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    if ( state.page == "Main" )
    {
        if ( state.cursor == 0 )
        {
            iprintlnbold( "^6主页 ^7(1/5) ^6* 玩家" );
        }
        else if ( state.cursor == 1 )
        {
            iprintlnbold( "^6主页 ^7(2/5) ^6* 娱乐" );
        }
        else if ( state.cursor == 2 )
        {
            iprintlnbold( "^6主页 ^7(3/5) ^6* 奇迹武器" );
        }
        else if ( state.cursor == 3 )
        {
            iprintlnbold( "^6主页 ^7(4/5) ^6* 老特西" );
        }
        else
        {
            iprintlnbold( "^6主页 ^7(5/5) ^6* 关闭菜单" );
        }
        return;
    }
    if ( state.page == "PlayerMods" )
    {
        if ( state.cursor == 0 )
        {
            if ( istrue( state.toggles[ "god_mode" ] ) )
            {
                iprintlnbold( "^6玩家 ^7(1/13) ^6* 无敌 (开)" );
            }
            else
            {
                iprintlnbold( "^6玩家 ^7(1/13) ^6* 无敌 (关)" );
            }
        }
        else if ( state.cursor == 1 )
        {
            if ( istrue( state.toggles[ "firepower" ] ) )
            {
                iprintlnbold( "^6玩家 ^7(2/13) ^6* 终极火力 (开)" );
            }
            else
            {
                iprintlnbold( "^6玩家 ^7(2/13) ^6* 终极火力 (关)" );
            }
        }
        else if ( state.cursor == 2 )
        {
            iprintlnbold( "^6玩家 ^7(3/13) ^6* 终极稀有度" );
        }
        else if ( state.cursor == 3 )
        {
            iprintlnbold( "^6玩家 ^7(4/13) ^6* 4级超改" );
        }
        else if ( state.cursor == 4 )
        {
            if ( istrue( state.toggles[ "ignoreme" ] ) )
            {
                iprintlnbold( "^6玩家 ^7(5/13) ^6* 忽略 (开)" );
            }
            else
            {
                iprintlnbold( "^6玩家 ^7(5/13) ^6* 忽略 (关)" );
            }
        }
        else if ( state.cursor == 5 )
        {
            if ( istrue( state.toggles[ "golden_armor" ] ) )
            {
                iprintlnbold( "^6玩家 ^7(6/13) ^6* 黄金甲 (开)" );
            }
            else
            {
                iprintlnbold( "^6玩家 ^7(6/13) ^6* 黄金甲 (关)" );
            }
        }
        else if ( state.cursor == 6 )
        {
            iprintlnbold( "^6玩家 ^7(7/13) ^6* 满精华&废料" );
        }
        else if ( state.cursor == 7 )
        {
            iprintlnbold( "^6玩家 ^7(8/13) ^6* 全特长" );
        }
        else if ( state.cursor == 8 )
        {
            iprintlnbold( "^6玩家 ^7(9/13) ^6* 满自救" );
        }
        else if ( state.cursor == 9 )
        {
            iprintlnbold( "^6玩家 ^7(10/13) ^6* 随机泡泡糖" );
        }
        else if ( state.cursor == 10 )
        {
            iprintlnbold( "^6玩家 ^7(11/13) ^6* 存点" );
        }
        else if ( state.cursor == 11 )
        {
            iprintlnbold( "^6玩家 ^7(12/13) ^6* 读点" );
        }
        else
        {
            iprintlnbold( "^6玩家 ^7(13/13) ^6* 返回" );
        }
        return;
    }
    if ( state.page == "FunMods" )
    {
        if ( state.cursor == 0 )
        {
            iprintlnbold( "^6娱乐 ^7(1/6) ^6* 跳回合" );
        }
        else if ( state.cursor == 1 )
        {
            iprintlnbold( "^6娱乐 ^7(2/6) ^6* 一键清场" );
        }
        else if ( state.cursor == 2 )
        {
            if ( istrue( state.toggles[ "pause_spawn" ] ) )
            {
                iprintlnbold( "^6娱乐 ^7(3/6) ^6* 停刷怪 (开)" );
            }
            else
            {
                iprintlnbold( "^6娱乐 ^7(3/6) ^6* 停刷怪 (关)" );
            }
        }
        else if ( state.cursor == 3 )
        {
            iprintlnbold( "^6娱乐 ^7(4/6) ^6* 掉落" );
        }
        else if ( state.cursor == 4 )
        {
            iprintlnbold( "^6娱乐 ^7(5/6) ^6* 友方召唤" );
        }
        else
        {
            iprintlnbold( "^6娱乐 ^7(6/6) ^6* 返回" );
        }
        return;
    }
    if ( state.page == "RoundMenu" )
    {
        if ( state.cursor == 0 )
        {
            iprintlnbold( "^6回合 ^7(1/7) ^6* 第1回合" );
        }
        else if ( state.cursor == 1 )
        {
            iprintlnbold( "^6回合 ^7(2/7) ^6* 第25回合" );
        }
        else if ( state.cursor == 2 )
        {
            iprintlnbold( "^6回合 ^7(3/7) ^6* 第50回合" );
        }
        else if ( state.cursor == 3 )
        {
            iprintlnbold( "^6回合 ^7(4/7) ^6* 第100回合" );
        }
        else if ( state.cursor == 4 )
        {
            iprintlnbold( "^6回合 ^7(5/7) ^6* 第500回合" );
        }
        else if ( state.cursor == 5 )
        {
            iprintlnbold( "^6回合 ^7(6/7) ^6* 第998回合" );
        }
        else
        {
            iprintlnbold( "^6回合 ^7(7/7) ^6* 返回" );
        }
        return;
    }
    if ( state.page == "PowerupMenu" )
    {
        if ( state.cursor == 0 )
        {
            iprintlnbold( "^6掉落 ^7(1/12) ^6* 双倍积分" );
        }
        else if ( state.cursor == 1 )
        {
            iprintlnbold( "^6掉落 ^7(2/12) ^6* 弹药全满" );
        }
        else if ( state.cursor == 2 )
        {
            iprintlnbold( "^6掉落 ^7(3/12) ^6* 护甲全满" );
        }
        else if ( state.cursor == 3 )
        {
            iprintlnbold( "^6掉落 ^7(4/12) ^6* 火力全开" );
        }
        else if ( state.cursor == 4 )
        {
            iprintlnbold( "^6掉落 ^7(5/12) ^6* 随机特长" );
        }
        else if ( state.cursor == 5 )
        {
            iprintlnbold( "^6掉落 ^7(6/12) ^6* 清仓甩卖" );
        }
        else if ( state.cursor == 6 )
        {
            iprintlnbold( "^6掉落 ^7(7/12) ^6* 核弹" );
        }
        else if ( state.cursor == 7 )
        {
            iprintlnbold( "^6掉落 ^7(8/12) ^6* 额外分数" );
        }
        else if ( state.cursor == 8 )
        {
            iprintlnbold( "^6掉落 ^7(9/12) ^6* 维萨里昂的祝福" );
        }
        else if ( state.cursor == 9 )
        {
            iprintlnbold( "^6掉落 ^7(10/12) ^6* 卡瑟莉丝的祝福" );
        }
        else if ( state.cursor == 10 )
        {
            iprintlnbold( "^6掉落 ^7(11/12) ^6* 德拉瓦卡之祝福" );
        }
        else
        {
            iprintlnbold( "^6掉落 ^7(12/12) ^6* 返回" );
        }
        return;
    }
    if ( state.page == "WonderMenu" )
    {
        if ( state.cursor == 0 )
        {
            iprintlnbold( "^6奇迹 ^7(1/9) ^6* 亡灵拳套" );
        }
        else if ( state.cursor == 1 )
        {
            iprintlnbold( "^6奇迹 ^7(2/9) ^6* 猫灵法师" );
        }
        else if ( state.cursor == 2 )
        {
            iprintlnbold( "^6奇迹 ^7(3/9) ^6* 约顿之星" );
        }
        else if ( state.cursor == 3 )
        {
            iprintlnbold( "^6奇迹 ^7(4/9) ^6* 霰弹铁铳" );
        }
        else if ( state.cursor == 4 )
        {
            iprintlnbold( "^6奇迹 ^7(5/9) ^6* LGM-1" );
        }
        else if ( state.cursor == 5 )
        {
            iprintlnbold( "^6奇迹 ^7(6/9) ^6* 典狱长之疫" );
        }
        else if ( state.cursor == 6 )
        {
            iprintlnbold( "^6奇迹 ^7(7/9) ^6* 射线枪" );
        }
        else if ( state.cursor == 7 )
        {
            iprintlnbold( "^6奇迹 ^7(8/9) ^6* 射线枪2型" );
        }
        else
        {
            iprintlnbold( "^6奇迹 ^7(9/9) ^6* 返回" );
        }
        return;
    }
}function menu_render()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    if ( !state.is_open )
    {
        return;
    }
    menu_announce();
}

function menu_close()
{
    state = self.bo7_pc_cn_zm_menu_v1;
    was_open = state.is_open;
    state.is_open = false;
    if ( was_open )
    {
        iprintlnbold( "菜单已关闭" );
    }
    state.stack = [];
    state.depth = 0;
}
