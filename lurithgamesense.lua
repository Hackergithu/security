print("Welcome back to lurith for gamesense.")


                  peg_loader = {}
                  peg_loader.fetch = function()
                    local build = 'recode'
                    local user = 'gamesense'
                    return build, user
                  end
                local ffi = require("ffi")
local c_entity = require("gamesense/entity")
local pui = require("gamesense/pui")
local base64 = require("gamesense/base64")
local clipboard = require("gamesense/clipboard")
local vector = require("vector")
local json = require("json")
local trace = require "gamesense/trace"

local lua_db = {configs = ':infinix:"cfg_test:'}

if not peg_loader then return end
local build, username = peg_loader.fetch()

local ref = {
    enabled = ui.reference('AA', 'Anti-aimbot angles', 'Enabled'),
    yawbase = ui.reference('AA', 'Anti-aimbot angles', 'Yaw base'),
    fsbodyyaw = ui.reference('AA', 'anti-aimbot angles', 'Freestanding body yaw'),
    edgeyaw = ui.reference('AA', 'Anti-aimbot angles', 'Edge yaw'),
    fakeduck = ui.reference('RAGE', 'Other', 'Duck peek assist'),
    forcebaim = ui.reference('RAGE', 'Aimbot', 'Force body aim'),
    safepoint = ui.reference('RAGE', 'Aimbot', 'Force safe point'),
    roll = { ui.reference('AA', 'Anti-aimbot angles', 'Roll') },
    clantag = ui.reference('Misc', 'Miscellaneous', 'Clan tag spammer'),
    legs = ui.reference('AA', 'Other', 'Leg Movement'),

    pitch = { ui.reference('AA', 'Anti-aimbot angles', 'pitch'), },
    rage = { ui.reference('RAGE', 'Aimbot', 'Enabled') },
    yaw = { ui.reference('AA', 'Anti-aimbot angles', 'Yaw') }, 
    yawjitter = { ui.reference('AA', 'Anti-aimbot angles', 'Yaw jitter') },
    bodyyaw = { ui.reference('AA', 'Anti-aimbot angles', 'Body yaw') },
    freestand = { ui.reference('AA', 'Anti-aimbot angles', 'Freestanding') },
    slow = { ui.reference('AA', 'Other', 'Slow motion') },
    os = { ui.reference('AA', 'Other', 'On shot anti-aim') },
    slow = { ui.reference('AA', 'Other', 'Slow motion') },
    dt = { ui.reference('RAGE', 'Aimbot', 'Double tap') },
    minimum_damage_override = { ui.reference("RAGE", "Aimbot", "Minimum damage override") },
    quick_peek = { ui.reference('RAGE', 'Other', 'Quick peek assist') },

    aimbot = ui.reference('RAGE', 'Aimbot', 'Enabled'),
    doubletap = {
        main = { ui.reference('RAGE', 'Aimbot', 'Double tap') },
        fakelag_limit = ui.reference('RAGE', 'Aimbot', 'Double tap fake lag limit'),
    },
    peek = { ui.reference('RAGE', 'Other', 'Quick peek assist') }
}

math.clamp = function (x, a, b)
    if a > x then return a
    elseif b < x then return b
    else return x end
end

math.lerp = function(name, value, speed)
    return name + (value - name) * globals.absoluteframetime() * speed
end

renderer.rec = function(x, y, w, h, radius, color)
    radius = math.min(x/2, y/2, radius)
    local r, g, b, a = unpack(color)
    renderer.rectangle(x, y + radius, w, h - radius*2, r, g, b, a)
    renderer.rectangle(x + radius, y, w - radius*2, radius, r, g, b, a)
    renderer.rectangle(x + radius, y + h - radius, w - radius*2, radius, r, g, b, a)
    renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
    renderer.circle(x - radius + w, y + radius, r, g, b, a, radius, 90, 0.25)
    renderer.circle(x - radius + w, y - radius + h, r, g, b, a, radius, 0, 0.25)
    renderer.circle(x + radius, y - radius + h, r, g, b, a, radius, -90, 0.25)
end

renderer.rec_outline = function(x, y, w, h, radius, thickness, color)
    radius = math.min(w/2, h/2, radius)
    local r, g, b, a = unpack(color)
    if radius == 1 then
            renderer.rectangle(x, y, w, thickness, r, g, b, a)
            renderer.rectangle(x, y + h - thickness, w , thickness, r, g, b, a)
    else
        renderer.rectangle(x + radius, y, w - radius*2, thickness, r, g, b, a)
        renderer.rectangle(x + radius, y + h - thickness, w - radius*2, thickness, r, g, b, a)
        renderer.rectangle(x, y + radius, thickness, h - radius*2, r, g, b, a)
        renderer.rectangle(x + w - thickness, y + radius, thickness, h - radius*2, r, g, b, a)
        renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, thickness)
        renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, thickness)
        renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, -90, 0.25, thickness)
        renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, thickness)
    end
end

renderer.glow_module = function(x, y, w, h, width, rounding, accent, accent_inner)
    local thickness = 1
    local offset = 1
    local r, g, b, a = unpack(accent)
    if accent_inner then
        renderer.rec(x , y, w, h + 1, rounding, accent_inner)
    end
    for k = 0, width do
        if a * (k/width)^(1) > 5 then
            local accent = {r, g, b, a * (k/width)^(2)}
            renderer.rec_outline(x + (k - width - offset)*thickness, y + (k - width - offset) * thickness, w - (k - width - offset)*thickness*2, h + 1 - (k - width - offset)*thickness*2, rounding + thickness * (width - k + offset), thickness, accent)
        end
    end
end

local lua_group = pui.group("aa", "anti-aimbot angles")
local fakelag_group = pui.group("aa", "Fake lag")
local other_group = pui.group("aa", "Other")

local antiaim_cond = { 'global', 'stand', 'walking', 'running' , 'air', 'air crouching', 'crouch', 'crouch moving', 'manual', 'legit AA', 'freestanding', 'safe head'}
local short_cond = { 'G', 'S', 'W', 'R' ,'A', 'A+C', 'C', 'C+M', 'M', 'L', 'F', 'S+'}


local lua_menu = {
    main = {
        tab = lua_group:combobox('lurith ~ \aA4B2F1FF'..username, {"aa", "visuals", "misc", "config"}),
    },
    antiaim = {
        label7s1 = lua_group:label("                         "),
        tab = lua_group:combobox("features/builder", {"main", "builder"}),
        aa_override = lua_group:multiselect('aa', {'on warmup', 'no enemies alive'}),
        safe_head = lua_group:multiselect('safe head', {'air+c knife', 'air+c zeus', 'air+c smg', 'height difference'}),
        height_difference = lua_group:slider('height difference', 0, 300, 200, true, '%'),
        yaw_direction = lua_group:checkbox('additional antiaim'),
        fr_options = lua_group:multiselect('options', {'freestanding on peek', 'freestanding disablers', 'disable yaw modifier', 'fake peek'}),
        fr_disablers = lua_group:multiselect('disablers', {'walking', 'crouch', 'air'}),
        edge_yaw = lua_group:hotkey('edge yaw'),
        freestanding = lua_group:hotkey('freestanding'),

        manual_direction = lua_group:checkbox('manuals <  >'),
        yaw_options = lua_group:multiselect('direction options', {'disable yaw modifier', 'fake peek'}),
        key_left = lua_group:hotkey('left manual'),
        key_right = lua_group:hotkey('right manual'),
        key_forward = lua_group:hotkey('forward manual'),
        yaw_base = lua_group:combobox("yaw", {"local view", "at targets"}),
        condition = lua_group:combobox('state', antiaim_cond),
    },
    visuals = {
        defensive_window = lua_group:checkbox("def. indicator", {255, 255, 255}),
        defensive_window_type = lua_group:combobox("type", {'normal', 'remade'}),
        velocity_window = lua_group:checkbox("vel. indicator", {255, 255, 255}),
        velocity_window_type = lua_group:combobox("type", {'normal', 'remade'}),
        ragebot_logs = lua_group:multiselect("ragebot logs", {'console', 'screen'}),
        ragebot_logs_hit = lua_group:color_picker('hit Color', 116, 189, 96, 255),
        ragebot_logs_miss = lua_group:color_picker('miss Color', 189, 99, 96, 255),
    },
    misc = {
        antibackstab = lua_group:checkbox('avoid backstab'),
        fast_ladder = lua_group:checkbox("fast ladder"),
        console = lua_group:checkbox("console filter"),
        kinguru = lua_group:checkbox("perfect animfix"),
        clantag = lua_group:checkbox("clantag"),
    },
    config = {
        list = lua_group:listbox("\vconfigs", ""),
        name = lua_group:textbox("\vconfig Name"),
        create = lua_group:button("\vcreate", function() end),
        load = lua_group:button("\vload", function() end),
        save = lua_group:button("\vsave", function() end),
        delete = lua_group:button("\vdelete", function() end),
        import = lua_group:button("\vimport", function() end),
        export = lua_group:button("\vexport", function() end),
    }
}

local antiaim_system = {}

local space = {"\n", "\n\n", "\n\n\n", "\n\n\n\n", "\n\n\n\n\n", "\n\n\n\n\n\n", "\n\n\n\n\n\n\n", "\n\n\n\n\n\n\n\n", '\n\n\n\n\n\n\n\n\n', '\n\n\n\n\n\n\n\n\n\n', '\n\n\n\n\n\n\n\n\n\n\n', '\n\n\n\n\n\n\n\n\n\n\n\n'}

for i=1, #antiaim_cond do
    antiaim_system[i] = {
        enable = lua_group:checkbox('enable '..antiaim_cond[i]..' state'),
        pitch = lua_group:combobox('pitch '..space[i], {"off", "down", 'random'}),
        yaw_offset = lua_group:slider('yaw offset'..space[i], -180, 180, 0, true, '°', 1),
        yaw_override = lua_group:checkbox('l/r yaw'..space[i]),
        yaw_left = lua_group:slider('yaw left'..space[i], -180, 180, 0, true, '°', 1),
        yaw_right = lua_group:slider('yaw right'..space[i], -180, 180, 0, true, '°', 1),
        yaw_random = lua_group:slider('randomization'..space[i], 0, 100, 0, true, '%', 1),
        mod_type = lua_group:combobox('jitter type'..space[i], {'off', 'offset', 'center', 'random', 'skitter'}),
        mod_dm = lua_group:slider('jitter amount'..space[i], -180, 180, 0, true, '°', 1),
        mod_random = lua_group:slider(' jitter random'..space[i], 0, 100, 0, true, '%', 1),
        body_yaw_type = lua_group:combobox('body yaw'..space[i], {'off', 'opposite', 'jitter', 'static'}),
        body_slider = lua_group:slider('body yaw amount'..space[i], -180, 180, 0, true, '°', 1),
        yaw_delay = lua_group:slider('delay'..space[i], 1, 10, 1, true, 't', 1),
        delay_random = lua_group:slider('delay randomize'..space[i], 1, 6, 1, true, 't', 1),
        force_def = lua_group:checkbox('force defensive'..space[i]),
        peek_def = lua_group:checkbox('quasimodo on peek'..space[i]),
        defensive = lua_group:checkbox('defensive anti~aim'..space[i]),
        defensive_yaw = lua_group:combobox('defensive yaw'..space[i], {'off', 'offset', 'spin', 'catnap~ways', 'randomise'}),
        yaw_value = lua_group:slider(' yaw value'..space[i], -180, 180, 0, true, '°', 1),
        spin_offset = lua_group:slider(' spin offset'..space[i], 0, 360, 360, true, '°', 1),
        spin_speed = lua_group:slider(' spin speed'..space[i], -50, 50, 10, true, '%', 0.1),
        defensive_pitch = lua_group:combobox(' defensive pitch'..space[i], {'off', 'customise', 'catnap~ways', 'randomise', 'spin'}),
        pitch_value = lua_group:slider(' pitch value'..space[i], -89, 89, 0, true, '°', 1),
        pitch_speed = lua_group:slider(' pitch speed'..space[i], -44, 44, 0, true, '%', 0.1),
        defensive_select = lua_group:multiselect(' additions'..space[i], {'jitter', 'body Yaw'}),
        def_mod_type = lua_group:combobox(' jitter type'..space[i], {'off', 'offset', 'center', 'random', 'skitter'}),
        def_mod_dm = lua_group:slider(' jitter amount'..space[i], -180, 180, 0, true, '°', 1),
        def_mod_random = lua_group:slider(' jitter random'..space[i], 0, 100, 0, true, '%', 1),
        def_body_yaw_type = lua_group:combobox('body yaw '..space[i], {'off', 'opposite', 'jitter', 'static'}),
        def_body_slider = lua_group:slider(' body yaw amount'..space[i], -180, 180, 0, true, '°', 1),
    }
end

local aa_tab = {lua_menu.main.tab, "aa"}
local misc_tab = {lua_menu.main.tab, "misc"}
local visual_tab = {lua_menu.main.tab, "visuals"}
local config_tab = {lua_menu.main.tab, "config"}
local aa_builder = {lua_menu.antiaim.tab, "builder"}
local aa_main = {lua_menu.antiaim.tab, "main"}

lua_menu.antiaim.label7s1:depend(aa_tab)
lua_menu.antiaim.tab:depend(aa_tab)
lua_menu.antiaim.aa_override:depend(aa_tab, aa_main)
lua_menu.antiaim.safe_head:depend(aa_tab, aa_main)
lua_menu.antiaim.height_difference:depend(aa_tab, aa_main, {lua_menu.antiaim.safe_head, 'height difference'})

lua_menu.antiaim.yaw_direction:depend(aa_tab, aa_main)
lua_menu.antiaim.edge_yaw:depend(aa_tab, aa_main, {lua_menu.antiaim.yaw_direction, true})
lua_menu.antiaim.freestanding:depend(aa_tab, aa_main, {lua_menu.antiaim.yaw_direction, true})
lua_menu.antiaim.fr_options:depend(aa_tab, aa_main, {lua_menu.antiaim.yaw_direction, true})
lua_menu.antiaim.fr_disablers:depend(aa_tab, aa_main, {lua_menu.antiaim.yaw_direction, true}, {lua_menu.antiaim.fr_options, 'freestanding disablers'})
lua_menu.antiaim.manual_direction:depend(aa_tab, aa_main)
lua_menu.antiaim.yaw_options:depend(aa_tab, aa_main, {lua_menu.antiaim.manual_direction, true})
lua_menu.antiaim.key_left:depend(aa_tab, aa_main, {lua_menu.antiaim.manual_direction, true})
lua_menu.antiaim.key_right:depend(aa_tab, aa_main, {lua_menu.antiaim.manual_direction, true})
lua_menu.antiaim.key_forward:depend(aa_tab, aa_main, {lua_menu.antiaim.manual_direction, true})

lua_menu.antiaim.yaw_base:depend(aa_tab, aa_main)


lua_menu.antiaim.condition:depend(aa_tab, aa_builder)

--Visuals
lua_menu.visuals.defensive_window:depend(visual_tab)
lua_menu.visuals.defensive_window_type:depend(visual_tab, {lua_menu.visuals.defensive_window, true})
lua_menu.visuals.velocity_window:depend(visual_tab)
lua_menu.visuals.velocity_window_type:depend(visual_tab, {lua_menu.visuals.velocity_window, true})
lua_menu.visuals.ragebot_logs:depend(visual_tab)
lua_menu.visuals.ragebot_logs_hit:depend(visual_tab, {lua_menu.visuals.ragebot_logs, function() return lua_menu.visuals.ragebot_logs:get('console') or lua_menu.visuals.ragebot_logs:get('screen') end})
lua_menu.visuals.ragebot_logs_miss:depend(visual_tab, {lua_menu.visuals.ragebot_logs, function() return lua_menu.visuals.ragebot_logs:get('console') or lua_menu.visuals.ragebot_logs:get('screen') end})

--Misc
lua_menu.misc.antibackstab:depend(misc_tab)
lua_menu.misc.fast_ladder:depend(misc_tab)
lua_menu.misc.console:depend(misc_tab)
lua_menu.misc.kinguru:depend(misc_tab)
lua_menu.misc.clantag:depend(misc_tab)


lua_menu.config.list:depend(config_tab)
lua_menu.config.name:depend(config_tab)
lua_menu.config.create:depend(config_tab)
lua_menu.config.load:depend(config_tab)
lua_menu.config.save:depend(config_tab)
lua_menu.config.delete:depend(config_tab)
lua_menu.config.import:depend(config_tab)
lua_menu.config.export:depend(config_tab)

for i=1, #antiaim_cond do
    local cond_check = {lua_menu.antiaim.condition, function() return (i ~= 1) end}
    local tab_cond = {lua_menu.antiaim.condition, antiaim_cond[i]}
    local cnd_en = {antiaim_system[i].enable, function() if (i == 1) then return true else return antiaim_system[i].enable:get() end end}
    local aa_tab = {lua_menu.main.tab, "aa"}
    local jit_ch = {antiaim_system[i].mod_type, function() return antiaim_system[i].mod_type:get() ~= "off" end}
    local def_jit_ch = {antiaim_system[i].def_mod_type, function() return antiaim_system[i].def_mod_type:get() ~= "off" end}
    local def_ch = {antiaim_system[i].defensive, true}
    local body_ch = {antiaim_system[i].body_yaw_type, function() return antiaim_system[i].body_yaw_type:get() == "static"  end}
    local def_body_ch = {antiaim_system[i].def_body_yaw_type, function() return antiaim_system[i].def_body_yaw_type:get() == "static" end}
    local delay_ch = {antiaim_system[i].yaw_type, "slow"}
    local yaw_ch = {antiaim_system[i].defensive_yaw, "spin"}
    local pitch_ch = {antiaim_system[i].defensive_pitch, function() return antiaim_system[i].defensive_pitch:get() == "customise" or antiaim_system[i].defensive_pitch:get() == "spin" end}
    local is_jitter = {antiaim_system[i].defensive_select, 'jitter'}
    local is_bodyyaw = {antiaim_system[i].defensive_select, 'body yaw'}

    antiaim_system[i].enable:depend(cond_check, tab_cond, aa_tab, aa_builder)
    antiaim_system[i].pitch:depend(cnd_en, tab_cond, aa_tab, aa_builder)
    antiaim_system[i].yaw_override:depend(cnd_en, tab_cond, aa_tab, aa_builder)
    antiaim_system[i].yaw_offset:depend(cnd_en, tab_cond, aa_tab, aa_builder, {antiaim_system[i].yaw_override, false})
    antiaim_system[i].yaw_left:depend(cnd_en, tab_cond, aa_tab, aa_builder, {antiaim_system[i].yaw_override, true})
    antiaim_system[i].yaw_right:depend(cnd_en, tab_cond, aa_tab, aa_builder, {antiaim_system[i].yaw_override, true})
    antiaim_system[i].yaw_random:depend(cnd_en, tab_cond, aa_tab, aa_builder, {antiaim_system[i].yaw_override, true})
    antiaim_system[i].mod_type:depend(cnd_en, tab_cond, aa_tab, aa_builder)

    antiaim_system[i].mod_dm:depend(cnd_en, tab_cond, aa_tab, jit_ch, aa_builder)
    antiaim_system[i].mod_random:depend(cnd_en, tab_cond, aa_tab, jit_ch, aa_builder)
    antiaim_system[i].body_yaw_type:depend(cnd_en, tab_cond, aa_tab, aa_builder)
    antiaim_system[i].body_slider:depend(cnd_en, tab_cond, aa_tab, body_ch, aa_builder)
    antiaim_system[i].yaw_delay:depend(cnd_en, tab_cond, aa_tab, aa_builder, {antiaim_system[i].body_yaw_type, function() return antiaim_system[i].body_yaw_type:get() == 'jitter' end})
    antiaim_system[i].delay_random:depend(cnd_en, tab_cond, aa_tab, aa_builder, {antiaim_system[i].body_yaw_type, function() return antiaim_system[i].body_yaw_type:get() == 'jitter' end}, {antiaim_system[i].yaw_delay, function() return antiaim_system[i].yaw_delay:get() > 1 end})

    antiaim_system[i].force_def:depend(cnd_en, tab_cond, aa_tab, aa_builder)
    antiaim_system[i].peek_def:depend(cnd_en, tab_cond, aa_tab, {antiaim_system[i].force_def, false}, aa_builder)
    antiaim_system[i].defensive:depend(cnd_en, tab_cond, aa_tab, aa_builder)
    antiaim_system[i].defensive_yaw:depend(cnd_en, tab_cond, aa_tab, def_ch, aa_builder)
    antiaim_system[i].yaw_value:depend(cnd_en, tab_cond, aa_tab, def_ch, aa_builder, {antiaim_system[i].defensive_yaw, function() return antiaim_system[i].defensive_yaw:get() ~= 'off' and antiaim_system[i].defensive_yaw:get() ~= 'spin' end})
    antiaim_system[i].spin_offset:depend(cnd_en, tab_cond, aa_tab, def_ch, aa_builder, {antiaim_system[i].defensive_yaw, function() return antiaim_system[i].defensive_yaw:get() == 'spin' end})
    antiaim_system[i].spin_speed:depend(cnd_en, tab_cond, aa_tab, def_ch, aa_builder, {antiaim_system[i].defensive_yaw, function() return antiaim_system[i].defensive_yaw:get() == 'spin' end})
    antiaim_system[i].defensive_pitch:depend(cnd_en, tab_cond, aa_tab, def_ch, aa_builder)
    antiaim_system[i].pitch_value:depend(cnd_en, tab_cond, aa_tab, def_ch, pitch_ch, aa_builder)
    antiaim_system[i].pitch_speed:depend(cnd_en, tab_cond, aa_tab, def_ch, aa_builder, {antiaim_system[i].defensive_pitch, 'spin'})
    antiaim_system[i].defensive_select:depend(cnd_en, tab_cond, aa_tab, def_ch, aa_builder)

    antiaim_system[i].def_mod_type:depend(cnd_en, tab_cond, aa_tab, def_ch, aa_builder, is_jitter)
    antiaim_system[i].def_mod_dm:depend(cnd_en, tab_cond, aa_tab, def_ch, def_jit_ch, aa_builder, is_jitter)
    antiaim_system[i].def_mod_random:depend(cnd_en, tab_cond, aa_tab, def_ch, def_jit_ch, aa_builder, is_jitter)
    antiaim_system[i].def_body_yaw_type:depend(cnd_en, tab_cond, aa_tab, def_ch, aa_builder, is_bodyyaw)
    antiaim_system[i].def_body_slider:depend(cnd_en, tab_cond, aa_tab, def_ch, def_body_ch, aa_builder, is_bodyyaw)
end


local function hide_original_menu(state)
    ui.set_visible(ref.enabled, state)
    ui.set_visible(ref.pitch[1], state)
    ui.set_visible(ref.pitch[2], state)
    ui.set_visible(ref.yawbase, state)
    ui.set_visible(ref.yaw[1], state)
    ui.set_visible(ref.yaw[2], state)
    ui.set_visible(ref.yawjitter[1], state)
    ui.set_visible(ref.roll[1], state)
    ui.set_visible(ref.yawjitter[2], state)
    ui.set_visible(ref.bodyyaw[1], state)
    ui.set_visible(ref.bodyyaw[2], state)
    ui.set_visible(ref.fsbodyyaw, state)
    ui.set_visible(ref.edgeyaw, state)
    ui.set_visible(ref.freestand[1], state)
    ui.set_visible(ref.freestand[2], state)
end

local function randomize_value(original_value, percent)
    local min_range = original_value - (original_value * percent / 100)
    local max_range = original_value + (original_value * percent / 100)
    return math.random(min_range, max_range)
end

local breaker = {
    defensive = 0,
    defensive_check = 0,
    cmd = 0,
    tickbase = 0
}

client.set_event_callback("predict_command", function(cmd)
    me = entity.get_local_player()
    if not me or not entity.is_alive(me) then     
        breaker.defensive = 0
        breaker.defensive_check = 0
        return
    end
    breaker.tickbase = entity.get_prop(entity.get_local_player(), "m_nTickBase")
    breaker.defensive_check = math.max(breaker.tickbase, breaker.defensive_check)
    breaker.cmd = 0
    if math.abs(breaker.tickbase - breaker.defensive_check) > 64 then
        breaker.defensive = 0
        breaker.defensive_check = 0
    end
    if breaker.defensive_check > breaker.tickbase then          
        breaker.defensive = math.abs(breaker.tickbase - breaker.defensive_check)
    end
    breaker.tickbase_check = globals.tickcount() > entity.get_prop(me, "m_nTickbase")
end)

function is_defensive_active(lp)
    is_defensive = breaker.tickbase_check and breaker.defensive > 2 and breaker.defensive < 14
    return is_defensive
end

local id = 1   
local function player_state(cmd)
    local lp = entity.get_local_player()
    if lp == nil then return end

    local vecvelocity = { entity.get_prop(lp, 'm_vecVelocity') }
    local flags = entity.get_prop(lp, 'm_fFlags')
    local velocity = math.sqrt(vecvelocity[1]^2+vecvelocity[2]^2)
    local groundcheck = bit.band(flags, 1) == 1
    local jumpcheck = bit.band(flags, 1) == 0 or cmd.in_jump == 1
    local ducked = entity.get_prop(lp, 'm_flDuckAmount') > 0.7
    local duckcheck = ducked or ui.get(ref.fakeduck)
    local slowwalk_key = ui.get(ref.slow[1]) and ui.get(ref.slow[2])

    if jumpcheck and duckcheck then return "air+c"
    elseif jumpcheck then return "air"
    elseif duckcheck and velocity > 10 then return "duck-moving"
    elseif duckcheck and velocity < 10 then return "duck"
    elseif groundcheck and slowwalk_key and velocity > 10 then return "walking"
    elseif groundcheck and velocity > 5 then return "moving"
    elseif groundcheck and velocity < 5 then return "stand"
    else return "global" end
end

local yaw_direction = 0
local last_press_t_dir = 0
local is_freestand = false
local is_static = false

local function run_direction(cmd)
    local lp = entity.get_local_player()
    if lp == nil then return end
    local vecvelocity = { entity.get_prop(lp, 'm_vecVelocity') }
    local flags = entity.get_prop(lp, 'm_fFlags')
    local jumpcheck = bit.band(flags, 1) == 0 or cmd.in_jump == 1
    local moving = math.sqrt(vecvelocity[1]^2+vecvelocity[2]^2) > 10
    local ducked = entity.get_prop(lp, 'm_flDuckAmount') > 0.7
    local duckcheck = ducked or ui.get(ref.fakeduck)

    local is_walking = moving and ui.get(ref.slow[1]) and ui.get(ref.slow[2])
    local is_crouching = duckcheck and not jumpcheck

    local fr_disabler = lua_menu.antiaim.fr_options:get('freestanding disablers')

    is_freestand = lua_menu.antiaim.yaw_direction:get() and lua_menu.antiaim.freestanding:get()

    local is_quick_peek = ui.get(ref.quick_peek[1]) and ui.get(ref.quick_peek[2])

    if (fr_disabler and lua_menu.antiaim.fr_disablers:get('walking') and is_walking) or (fr_disabler and lua_menu.antiaim.fr_disablers:get('crouch') and is_crouching) or (fr_disabler and lua_menu.antiaim.fr_disablers:get('air') and jumpcheck) then
        ui.set(ref.freestand[1], false)
        ui.set(ref.freestand[2], lua_menu.antiaim.freestanding:get() and 'Always on' or 'On hotkey')
        is_freestand = false
    elseif is_quick_peek and lua_menu.antiaim.fr_options:get('freestanding on peek') then
        ui.set(ref.freestand[1], true)
        ui.set(ref.freestand[2], 'always on')
        is_freestand = true
    else
        ui.set(ref.freestand[1], lua_menu.antiaim.yaw_direction:get())
        ui.set(ref.freestand[2], lua_menu.antiaim.freestanding:get() and 'always on' or 'on hotkey')
    end

    if yaw_direction ~= 0 then
        ui.set(ref.freestand[1], false)
        is_freestand = false
    end

    is_static = (lua_menu.antiaim.fr_options:get('disable yaw modifier') and is_freestand) or (yaw_direction ~= 0 and lua_menu.antiaim.yaw_options:get('disable yaw modifier'))

    if lua_menu.antiaim.manual_direction:get() and lua_menu.antiaim.key_right:get() and last_press_t_dir + 0.2 < globals.curtime() then
        yaw_direction = yaw_direction == 90 and 0 or 90
        last_press_t_dir = globals.curtime()
    elseif lua_menu.antiaim.manual_direction:get() and lua_menu.antiaim.key_left:get() and last_press_t_dir + 0.2 < globals.curtime() then
        yaw_direction = yaw_direction == -90 and 0 or -90
        last_press_t_dir = globals.curtime()
    elseif lua_menu.antiaim.manual_direction:get() and lua_menu.antiaim.key_forward:get() and last_press_t_dir + 0.2 < globals.curtime() then
        yaw_direction = yaw_direction == 180 and 0 or 180
        last_press_t_dir = globals.curtime()
    elseif last_press_t_dir > globals.curtime() then
        last_press_t_dir = globals.curtime()
    end
end

anti_knife_dist = function (x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

local function is_vulnerable()
    for _, v in ipairs(entity.get_players(true)) do
        local flags = (entity.get_esp_data(v)).flags
        if bit.band(flags, bit.lshift(1, 11)) ~= 0 then
            return true
        end
    end
    return false
end

local function legit_aa(cmd)
    local in_use = cmd.in_use == 1
    local in_bombsite = entity.get_prop(entity.get_local_player(), "m_bInBombZone") > 0
    local nTeam = entity.get_prop(entity.get_local_player(), "m_iTeamNum")
    lx,ly,lz = entity.get_origin(entity.get_local_player())
    local from = vector(client.eye_position())
	local to = from + vector():init_from_angles(client.camera_angles()) * 1024
    local tr = trace.line(from, to, { skip = entity.get_local_player(), mask = "MASK_SHOT" })
    local local_pos = vector(entity.get_origin(entity.get_local_player()))

    if tr.fraction >= 1 then
        tr.entindex = 0
    end
   
   if entity.get_classname(tr.entindex) ~= "CWorld" and entity.get_classname(tr.entindex) ~= "CCSPlayer" and entity.get_classname(tr.entindex) ~= "CFuncBrush" and entity.get_classname(tr.entindex) ~= "CBaseButton" and entity.get_classname(tr.entindex) ~= "CDynamicProp" and entity.get_classname(tr.entindex) ~= "CPhysicsPropMultiplayer" and entity.get_classname(tr.entindex) ~= "CBaseEntity" and entity.get_classname(tr.entindex) ~= "CC4" then 
      
        local not_wepwep = vector(entity.get_origin(tr.entindex))

        if entity.get_classname(tr.entindex) == "CPropDoorRotating" or (entity.get_classname(tr.entindex) == "CHostage" and nTeam == 3) then
            
            if local_pos:dist(not_wepwep) < 125 then

                return false
            end

        elseif entity.get_classname(tr.entindex) ~= "CPropDoorRotating" and entity.get_classname(tr.entindex) ~= "CHostage" then

            if local_pos:dist(not_wepwep) < 200 then
                return false
            end
        end
   end
  
    local bomb_table    = entity.get_all("CPlantedC4")
    local bomb_planted  = #bomb_table > 0
    local bomb_distance = 100

    if bomb_planted then
        local bomb_entity = bomb_table[#bomb_table]
        local bomb_pos = vector(entity.get_origin(bomb_entity))
        bomb_distance = local_pos:dist(bomb_pos)
    end

    local defusing = bomb_distance < 50 and nTeam == 3

    if defusing then return false end

    if in_use then
        cmd.in_use = 0
        return true
    end
    return false
end

local current_tickcount = 0
local to_jitter = false
local to_defensive = true
local first_execution = true
local yaw_amount = 0
local last_yaw = 0
local not_def_yaw = 0
local builder_items = nil
local jit_amount = 0
local safe_head = false

local function defensive_peek()
    to_defensive = false
end

local function defensive_disabler()
    to_defensive = true
end

local function normalize_yaw(yaw)
    return (yaw + 180) % 360 - 180
end
 
local function custom_spin(value, offset)
    if offset == 0 then
        return 0
    end

    if value >= 0 then
        tick = globals.tickcount() * value
        result = (tick % offset) - offset/2
        return result
    else
        tick = globals.tickcount() * value
        result = (tick % -offset) + offset/2
        return result
    end
end

local alive_players = {}

aa_setup = function(cmd)
    local lp = entity.get_local_player()
    if lp == nil then return end
    builder_items = antiaim_system[id]
    if antiaim_system[12].enable:get() and safe_head then id = 12
    elseif antiaim_system[11].enable:get() and is_freestand then id = 11
    elseif antiaim_system[10].enable:get() and cmd.in_use == 1 then id = 10
    elseif antiaim_system[9].enable:get() and yaw_direction ~= 0 then id = 9
    elseif player_state(cmd) == "duck-moving" and antiaim_system[8].enable:get() then id = 8
    elseif player_state(cmd) == "duck" and antiaim_system[7].enable:get() then id = 7
    elseif player_state(cmd) == "air+c" and antiaim_system[6].enable:get() then id = 6
    elseif player_state(cmd) == "air" and antiaim_system[5].enable:get() then id = 5
    elseif player_state(cmd) == "moving" and antiaim_system[4].enable:get() then id = 4
    elseif player_state(cmd) == "walking" and antiaim_system[3].enable:get() then id = 3
    elseif player_state(cmd) == "stand" and antiaim_system[2].enable:get() then id = 2
    else id = 1 end

    if id == 10 then
        legit_aa(cmd)
    end

    safe_head = false

    ui.set(ref.roll[1], 0)

    run_direction(cmd)

    if globals.tickcount() > current_tickcount + builder_items.yaw_delay:get() + math.random(0, builder_items.delay_random:get()) then
        if cmd.chokedcommands == 0 then
            to_jitter = not to_jitter
            current_tickcount = globals.tickcount()
        end
    elseif globals.tickcount() <  current_tickcount then
        current_tickcount = globals.tickcount()
    end

    if is_vulnerable() then
        if first_execution then
            first_execution = false
            to_defensive = true
            client.set_event_callback("setup_command", defensive_disabler)
        end
        if globals.tickcount() % 10 == 9 then
            defensive_peek()
            client.unset_event_callback("setup_command", defensive_disabler)
        end
    else
        first_execution = true
        to_defensive = false
    end

    ui.set(ref.fsbodyyaw, false)
    

    cmd.force_defensive = builder_items.force_def:get() or builder_items.peek_def:get() and to_defensive

    local desync_type = entity.get_prop(lp, 'm_flPoseParameter', 11) * 120 - 60
    local desync_side = desync_type > 0

    ui.set(ref.yaw[1], '180')
    ui.set(ref.pitch[1], antiaim_system[id].pitch:get())
    ui.set(ref.yawbase, lua_menu.antiaim.yaw_base:get())
    if builder_items.yaw_delay:get() > 1 and builder_items.body_yaw_type:get() == 'jitter' then
        ui.set(ref.bodyyaw[1], "static")
        ui.set(ref.bodyyaw[2], to_jitter and 1 or -1)
        ui.set(ref.yawjitter[1], 'off')
        ui.set(ref.yawjitter[2], 0)
        local yaw_l = antiaim_system[id].yaw_override:get() and randomize_value(builder_items.yaw_right:get(), builder_items.yaw_random:get()) or antiaim_system[id].yaw_offset:get()
        local yaw_r = antiaim_system[id].yaw_override:get() and randomize_value(builder_items.yaw_left:get(), builder_items.yaw_random:get()) or antiaim_system[id].yaw_offset:get()
        jit_amount = randomize_value(builder_items.mod_dm:get(), builder_items.mod_random:get())

        if builder_items.mod_type:get() == 'center' then
            yaw_amount = to_jitter and (yaw_l + jit_amount/2) or (yaw_r - jit_amount/2)
        elseif builder_items.mod_type:get() == 'offset' then
            yaw_amount = to_jitter and (yaw_l) or (yaw_r - jit_amount/2)
        elseif builder_items.mod_type:get() == 'random' then
            yaw_amount = to_jitter and (yaw_l + jit_amount/2) or (yaw_r - jit_amount/2)
        elseif builder_items.mod_type:get() == 'skitter' then
            if globals.tickcount() % 3 == 0 then 
                yaw_amount = to_jitter and (yaw_l + jit_amount/2) or (yaw_r)
            elseif globals.tickcount() % 3 == 1 then 
                yaw_amount = to_jitter and (yaw_l) or (yaw_r)
            else
                yaw_amount = to_jitter and (yaw_l) or (yaw_r - jit_amount/2)
            end
        else
            yaw_amount = to_jitter and yaw_l or yaw_r
        end
        not_def_yaw = yaw_amount
    else
        ui.set(ref.bodyyaw[1], builder_items.body_yaw_type:get())
        ui.set(ref.bodyyaw[2], builder_items.body_yaw_type:get() == 'jitter' and 1 or builder_items.body_slider:get())
        ui.set(ref.yawjitter[1], builder_items.mod_type:get())
        ui.set(ref.yawjitter[2], math.clamp(randomize_value(builder_items.mod_dm:get(), builder_items.mod_random:get()), -180, 180))
        if antiaim_system[id].yaw_override:get() then
            yaw_amount = desync_side and randomize_value(builder_items.yaw_left:get(), builder_items.yaw_random:get()) or randomize_value(builder_items.yaw_right:get(), builder_items.yaw_random:get())
        else
            yaw_amount = antiaim_system[id].yaw_offset:get()
        end
        not_def_yaw = yaw_amount
    end

    if is_defensive_active(lp) and builder_items.defensive:get() and not is_static then
        ui.set(ref.pitch[1], 'custom')

        if antiaim_system[id].defensive_select:get('jitter') then
            ui.set(ref.yawjitter[1], builder_items.def_mod_type:get())
            ui.set(ref.yawjitter[2], math.clamp(randomize_value(builder_items.def_mod_dm:get(), builder_items.def_mod_random:get()), -180, 180))
        end

        if antiaim_system[id].defensive_select:get('body yaw') then
            ui.set(ref.bodyyaw[1], builder_items.def_body_yaw_type:get()) 
            ui.set(ref.bodyyaw[2], builder_items.def_body_yaw_type:get() == 'jitter' and 1 or builder_items.def_body_slider:get())
        end

        if builder_items.defensive_yaw:get() == "spin" then
            yaw_amount = custom_spin(builder_items.spin_speed:get(), builder_items.spin_offset:get())
        elseif builder_items.defensive_yaw:get() == "catnap~ways" then
            yaw_amount = globals.tickcount() % 4 > 1 and builder_items.yaw_value:get()+not_def_yaw or -(builder_items.yaw_value:get()-not_def_yaw)
        elseif builder_items.defensive_yaw:get() == "randomise" then
            yaw_amount = math.random(-builder_items.yaw_value:get(), builder_items.yaw_value:get())
        elseif builder_items.defensive_yaw:get() == "offset" then
            yaw_amount = yaw_direction == 0 and builder_items.yaw_value:get() or yaw_direction
        end
        
        if builder_items.defensive_pitch:get() == "customise" then
            ui.set(ref.pitch[2], builder_items.pitch_value:get())
        elseif builder_items.defensive_pitch:get() == "catnap~ways" then
            ui.set(ref.pitch[2], globals.tickcount() % 4 > 1 and 49 or -49)
        elseif builder_items.defensive_pitch:get() == "randomise" then
            ui.set(ref.pitch[2], math.random(-89, 89))
        elseif builder_items.defensive_pitch:get() == "spin" then
            ui.set(ref.pitch[2], math.clamp(custom_spin(builder_items.pitch_speed:get(), builder_items.pitch_value:get()), -89, 89))
        else
            ui.set(ref.pitch[2], 89)
        end
    end

    ui.set(ref.yaw[2], yaw_direction == 0 and math.clamp(yaw_amount, -180, 180) or yaw_direction)

    if is_static then
        ui.set(ref.yaw[2], yaw_direction == 0 and 0 or yaw_direction)
        ui.set(ref.yawjitter[1], 'off')
        ui.set(ref.yawjitter[2], 0)
        ui.set(ref.bodyyaw[1], 'static')
        ui.set(ref.bodyyaw[2], 1)
    end

    local players = entity.get_players(true)
    if lua_menu.antiaim.aa_override:get('on warmup') then
        if entity.get_prop(entity.get_game_rules(), "m_bWarmupPeriod") == 1 then
            ui.set(ref.yaw[2], globals.tickcount() % 36 * 10 - 180)
            ui.set(ref.yawjitter[2], 0)
            ui.set(ref.bodyyaw[1], 'static')
            ui.set(ref.bodyyaw[2], 0)
            ui.set(ref.pitch[1], "custom")
            ui.set(ref.pitch[2], 0) 
            cmd.force_defensive = false
        end
    end

    for i=1, 64 do
        if entity.is_alive(i) and entity.is_enemy(i) then
            table.insert(alive_players, i)
        end
    end

    if lua_menu.antiaim.aa_override:get('no enemies alive') then
        if client.current_threat() == nil and #alive_players == 0 then
            ui.set(ref.yaw[2], globals.tickcount() % 36 * 10 - 180)
            ui.set(ref.yawjitter[2], 0)
            ui.set(ref.bodyyaw[1], 'static')
            ui.set(ref.bodyyaw[2], 0)
            ui.set(ref.pitch[1], "custom")
            ui.set(ref.pitch[2], 0) 
            cmd.force_defensive = false
        end
    end

    alive_players = {}

    if id == 10 then
        ui.set(ref.yawbase, 'local view')
        ui.set(ref.pitch[1], "off")
        ui.set(ref.yaw[1], 'off')
    end

    local threat = client.current_threat()
    local lp_weapon = entity.get_player_weapon(lp)
    local lp_orig_x, lp_orig_y, lp_orig_z = entity.get_prop(lp, "m_vecOrigin")
    local flags = entity.get_prop(lp, 'm_fFlags')
    local jumpcheck = bit.band(flags, 1) == 0 or cmd.in_jump == 1
    local ducked = entity.get_prop(lp, 'm_flDuckAmount') > 0.7


    if lp_weapon ~= nil then
        if lua_menu.antiaim.safe_head:get("air+c knife") then
            if jumpcheck and ducked and entity.get_classname(lp_weapon) == "CKnife" then
                safe_head = true
            end
        end
        if lua_menu.antiaim.safe_head:get("air+c zeus") then
            if jumpcheck and ducked and entity.get_classname(lp_weapon) == "CWeaponTaser" then
                safe_head = true
            end
        end
        if lua_menu.antiaim.safe_head:get("height difference") then
            if threat ~= nil and is_vulnerable() then
                threat_x, threat_y, threat_z = entity.get_prop(threat, "m_vecOrigin")
                threat_dist = lp_orig_z - threat_z
                if threat_dist > lua_menu.antiaim.height_difference:get() then
                    safe_head = true
                end
            end
        end
        
        if lua_menu.antiaim.safe_head:get("air+c smg") then
            if jumpcheck and ducked and (entity.get_classname(lp_weapon) == "CWeaponMAC10" or entity.get_classname(lp_weapon) == "CWeaponMP9" or entity.get_classname(lp_weapon) == "CWeaponMP7" or entity.get_classname(lp_weapon) == "CWeaponUMP45" or entity.get_classname(lp_weapon) == "CWeaponBizon" or entity.get_classname(lp_weapon) == "CWeaponP90") then
                safe_head = true
            end
        end
    end

    if lua_menu.antiaim.yaw_options:get('fake peek') and yaw_direction ~= 0 then
        cmd.force_defensive = true
        if is_defensive_active(lp) then
            ui.set(ref.yaw[1], '180')
            ui.set(ref.yaw[2], -yaw_direction)
            ui.set(ref.pitch[2], math.random(-10, 10))
        end
    end

    if is_freestand and lua_menu.antiaim.fr_options:get('fake peek') and yaw_direction == 0 then
        if is_vulnerable() then
            cmd.force_defensive = true
            if not is_defensive_active(lp) then
                last_yaw = entity.get_prop(lp, 'm_flLowerBodyYawTarget')
            else    
                cmd.pitch = (math.random(-10, 10))
                if last_yaw > 0 then
                    cmd.yaw = normalize_yaw(last_yaw - 180)
                else
                    cmd.yaw = normalize_yaw(last_yaw + 180)
                end
            end
        end
    end

    if lua_menu.misc.antibackstab:get() then
        for i=1, #players do
            if players == nil then return end
            enemy_orig_x, enemy_orig_y, enemy_orig_z = entity.get_prop(players[i], "m_vecOrigin")
            distance_to = anti_knife_dist(lp_orig_x, lp_orig_y, lp_orig_z, enemy_orig_x, enemy_orig_y, enemy_orig_z)
            weapon = entity.get_player_weapon(players[i])
            if weapon == nil then return end
            if entity.get_classname(weapon) == "CKnife" and distance_to <= 250 then
                ui.set(ref.yaw[2], 180)
                ui.set(ref.yawbase, "at targets")
            end
        end
    end


    --Force Defensive Triggers

end


local screen = {client.screen_size()}
local center = {screen[1]/2, screen[2]/2} 

math.lerp = function(name, value, speed)
    return name + (value - name) * globals.absoluteframetime() * speed
end

local rgba_to_hex = function(b, c, d, e)
    return string.format('%02x%02x%02x%02x', b, c, d, e)
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function clamp(x, minval, maxval)
    if x < minval then
        return minval
    elseif x > maxval then
        return maxval
    else
        return x
    end
end

local function text_fade_animation(x, y, speed, color1, color2, text, flag)
    local final_text = ''
    local curtime = globals.curtime()

    for i = 0, #text do
        local x_offset = i * 10
        local wave = math.cos(8 * speed * curtime + x_offset / 30)
        local color = rgba_to_hex(
            lerp(color1.r, color2.r, clamp(wave, 0, 1)),
            lerp(color1.g, color2.g, clamp(wave, 0, 1)),
            lerp(color1.b, color2.b, clamp(wave, 0, 1)),
            color1.a
        )
        final_text = final_text .. '\a' .. color .. text:sub(i, i)
    end

    renderer.text(x, y, color1.r, color1.g, color1.b, color1.a, flag, nil, final_text)
end

local function fade_anim(speed, color1, color2, text)
    local final_text = ''
    local curtime = globals.curtime()

    for i = 0, #text do
        local x_offset = i * 10
        local wave = math.cos(8 * speed * curtime + x_offset / 30)
        local color = rgba_to_hex(
            lerp(color1.r, color2.r, clamp(wave, 0, 1)),
            lerp(color1.g, color2.g, clamp(wave, 0, 1)),
            lerp(color1.b, color2.b, clamp(wave, 0, 1)),
            color1.a
        )
        final_text = final_text .. '\a' .. color .. text:sub(i, i)
    end
    return final_text
end

local function doubletap_charged()
    if not ui.get(ref.dt[1]) or not ui.get(ref.dt[2]) or ui.get(ref.fakeduck) then return false end
    if not entity.is_alive(entity.get_local_player()) or entity.get_local_player() == nil then return end
    local weapon = entity.get_prop(entity.get_local_player(), "m_hActiveWeapon")
    if weapon == nil then return false end
    local next_attack = entity.get_prop(entity.get_local_player(), "m_flNextAttack") + 0.01
    local checkcheck = entity.get_prop(weapon, "m_flNextPrimaryAttack")
    if checkcheck == nil then return end
    local next_primary_attack = checkcheck + 0.01
    if next_attack == nil or next_primary_attack == nil then return false end
    return next_attack - globals.curtime() < 0 and next_primary_attack - globals.curtime() < 0
end

local scoped_space = 0

local desync = 0

breathe = function(offset, multiplier)
    local m_speed = globals.realtime() * (multiplier or 1.0);
    local m_factor = m_speed % math.pi;

    local m_sin = math.sin(m_factor + (offset or 0));
    local m_abs = math.abs(m_sin);

    return m_abs
end

local defensive_alpha = 0
local defensive_amount = 0
local velocity_alpha = 0
local velocity_amount = 0

local function velocity_ind()
    local lp = entity.get_local_player()
    if lp == nil then return end
    local r, g, b, a = lua_menu.visuals.velocity_window:get_color()
    local vel_mod = entity.get_prop(lp, 'm_flVelocityModifier')

    if not ui.is_menu_open() then
        velocity_alpha = math.lerp(velocity_alpha, vel_mod < 1 and 255 or 0, 5)
        velocity_amount = math.lerp(velocity_amount, vel_mod, 5)
    else
        velocity_alpha = math.lerp(velocity_alpha, 255, 5)
        velocity_amount = globals.tickcount() % 50/100 * 2
    end

    if velocity_alpha < 5 then return end

    renderer.text(center[1], screen[2] / 3 - 15, 255, 255, 255, velocity_alpha, "c", 0, "- ~ v ~ -")

    if lua_menu.visuals.velocity_window_type:get() == 'normal' then
        renderer.rectangle(center[1]-50, screen[2] / 3, 100, 5, 0,0,0, velocity_alpha)
        renderer.rectangle(center[1]-49, screen[2] / 3+1, (100*velocity_amount)-1, 3, r, g, b, velocity_alpha)
    else
        renderer.glow_module(center[1]-50 - math.floor(50*velocity_amount) + 50, screen[2] / 3, math.floor(100*velocity_amount), 3, 6, 3, {r, g, b, velocity_alpha/2}, {r, g, b, velocity_alpha})
    end
end

local function defensive_ind()
    local lp = entity.get_local_player()
    if lp == nil then return end
    local charged = doubletap_charged()
    local active = is_defensive_active(lp)
    local r, g, b, a = lua_menu.visuals.defensive_window:get_color()
    if not ui.is_menu_open() then
        if ui.get(ref.dt[1]) and ui.get(ref.dt[2]) and not ui.get(ref.fakeduck) then
            if charged and active then
                defensive_alpha = math.lerp(defensive_alpha, 255, 5)
                defensive_amount = math.lerp(defensive_amount, 1, 5)
            elseif charged and not active then
                defensive_alpha = math.lerp(defensive_alpha, 0, 5)
                defensive_amount = math.lerp(defensive_amount, 0.5, 5)
            else
                defensive_alpha = math.lerp(defensive_alpha, 255, 5)
                defensive_amount = math.lerp(defensive_amount, 0, 5)
            end
        else
            defensive_alpha = math.lerp(defensive_alpha, 0, 5)
            defensive_amount = math.lerp(defensive_amount, 0, 5)
        end
    else
        defensive_alpha = math.lerp(defensive_alpha, 255, 10)
        defensive_amount = globals.tickcount() % 50/100 * 2
    end

    if defensive_alpha < 5 then return end

    renderer.text(center[1], screen[2] / 4 - 15, 255, 255, 255, defensive_alpha, "c", 0, "- ~ D ~ -")

    if lua_menu.visuals.defensive_window_type:get() == 'normal' then
        renderer.rectangle(center[1]-50, screen[2] / 4, 100, 5, 0,0,0, defensive_alpha)
        renderer.rectangle(center[1]-49, screen[2] / 4+1, (100*defensive_amount)-1, 3, r, g, b, defensive_alpha)
    else
        renderer.glow_module(center[1]-50 - math.floor(50*defensive_amount) + 50, screen[2] / 4, math.floor(100*defensive_amount), 3, 6, 3, {r, g, b, defensive_alpha/2}, {r, g, b, defensive_alpha})
    end
end

    local function clantag()
        if not lua_menu.misc.clantag:get() then
            client.set_clan_tag("") -- Zamknięcie clantag
            return
        end
        local tag = "   lurith   " -- Skrócone odstępy dla lepszego efektu
        local length = #tag
        once = false
        local curtime = math.floor(globals.curtime() * 3.5) -- Przyspieszenie animacji
        local cycle_time = length * 2 -- Poprawiony cykl otwierania i zamykania
        local index = (curtime % cycle_time) + 1
        
        local new_tag
        if index <= length then
            new_tag = tag:sub(1, index) -- Stopniowe otwieranie
        else
            new_tag = tag:sub(1, math.max(0, (2 * length) - index)) -- Stopniowe zamykanie bez uciania liter
        end
        
             client.set_clan_tag(new_tag)
             old_time = curtime
            end


local function air_qs(cmd)
    local lp = entity.get_local_player()
    if not lp then return end
    if not entity.is_alive(lp) then return end

    local ticks = 0
    local players = entity.get_players(true)
    local lpvec = vector(entity.get_prop(lp, "m_vecOrigin"))
    local weapon = entity.get_player_weapon(lp)
    local class = entity.get_classname(weapon)

    if class ~= "CWeaponSSG08" then return end
    local vecvelocity = { entity.get_prop(lp, 'm_vecVelocity') }

    local check_vel = vecvelocity[3] > 0
    local flags = entity.get_prop(lp, 'm_fFlags')
    local jumpcheck = bit.band(flags, 1) == 0

    local enemy = client.current_threat()
    if not enemy then return end
    if not jumpcheck then return end
    local enemyvec = vector(entity.get_origin(enemy))
    local trace_l = vector(entity.get_origin(lp))
    if not check_vel then return end
    for i=1, #players do
        if players == nil then return end
        local x1, y1, z1 = entity.get_prop(players[i], "m_vecOrigin")

        local dist = anti_knife_dist(lpvec.x, lpvec.y, lpvec.z, x1, y1, z1)
        if dist <= 1500 then
            if cmd.quick_stop then
                if (globals.tickcount() - ticks) > 3 then
                    cmd.in_speed = 1
                end
            else
                ticks = globals.tickcount()
            end
        end
    end
end

local prev_console = cvar.con_filter_text:get_string()

local function console_filter(value)
    cvar.con_filter_enable:set_int(value and 1 or 0)  
    cvar.con_filter_text:set_int(value and 1 or 0)
    cvar.con_filter_text_out:set_int(value and 1 or 0)
    cvar.con_filter_text:set_string(value and "__" or prev_console)
end

console_filter(lua_menu.misc.console:get())

lua_menu.misc.console:set_callback(function(self)
    console_filter(self:get())
end)

local shot_logger = {}

prefer_safe_point = ui.reference('RAGE', 'Aimbot', 'Prefer safe point')
force_safe_point = ui.reference('RAGE', 'Aimbot', 'Force safe point')

shot_logger.add = function(...)
    args = { ... }
    len = #args
    for i = 1, len do
        arg = args[i]
        r, g, b = unpack(arg)

        msg = {}

        if #arg == 3 then
            _G.table.insert(msg, " ")
        else
            for i = 4, #arg do
                _G.table.insert(msg, arg[i])
            end
        end
        msg = _G.table.concat(msg)

        if len > i then
            msg = msg .. "\0"
        end

        client.color_log(r, g, b, msg)


    end
end

shot_logger.bullet_impacts = {}
shot_logger.bullet_impact = function(e)
    local tick, me, user = globals.tickcount(), entity.get_local_player(), client.userid_to_entindex(e.userid)
    if user ~= me then return end
    if #shot_logger.bullet_impacts > 150 then shot_logger.bullet_impacts = {} end
    shot_logger.bullet_impacts[#shot_logger.bullet_impacts+1] = {tick = tick, eye = vector(client.eye_position()), shot = vector(e.x, e.y, e.z)}
end

shot_logger.get_inaccuracy_tick = function(pre_data, tick)
    for _, impact in pairs(shot_logger.bullet_impacts) do
        if impact.tick == tick then
            local spread_angle = vector((pre_data.eye-pre_data.shot_pos):angles()-(pre_data.eye-impact.shot):angles()):length2d()
            return spread_angle
        end
    end
    return -1
end

shot_logger.get_safety = function(aim_data, target)
    if not aim_data.boosted then return -1 end
    local plist_safety, ui_safety = plist.get(target, 'Override safe point'), {ui.get(prefer_safe_point), ui.get(force_safe_point) or plist_safety == 'On'}
    if plist_safety == 'Off' or not (ui_safety[1] or ui_safety[2]) then return 0 end
    return ui_safety[2] and 2 or (ui_safety[1] and 1 or 0)
end

shot_logger.generate_flags = function(pre_data)
    return {pre_data.self_choke > 1 and 1 or 0, pre_data.velocity_modifier < 1.00 and 1 or 0, pre_data.flags.boosted and 1 or 0}
end


shot_logger.hitboxes = {"generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear"}
shot_logger.on_aim_fire = function(e)
	local p_ent = e.target
	local me = entity.get_local_player()

	shot_logger[e.id] = {
		original = e,
		dropped_packets = { },

		handle_time = globals.realtime(),
		self_choke = globals.chokedcommands(),

		flags = {
			boosted = e.boosted
		},

		feet_yaw = entity.get_prop(p_ent, 'm_flPoseParameter', 11)*120-60,
		correction = plist.get(p_ent, 'Correction active'),

		safety = shot_logger.get_safety(e, p_ent),
		shot_pos = vector(e.x, e.y, e.z),
		eye = vector(client.eye_position()),
		view = vector(client.camera_angles()),

		velocity_modifier = entity.get_prop(me, 'm_flVelocityModifier'),
		total_hits = entity.get_prop(me, 'm_totalHitsOnServer'),

		history = globals.tickcount() - e.tick
	}
end
shot_logger.on_aim_hit = function(e)
	if not lua_menu.visuals.ragebot_logs:get('console') then return end

	if shot_logger[e.id] == nil then
		return 
	end

	local info = 
	{
		type = math.max(0, entity.get_prop(e.target, 'm_iHealth')) > 0,
		prefix = { lua_menu.visuals.ragebot_logs_hit:get() },
		hit = { lua_menu.visuals.ragebot_logs_hit:get() },
		name = entity.get_player_name(e.target),
		hitgroup = shot_logger.hitboxes[e.hitgroup + 1] or '?',
		flags = string.format('%s', _G.table.concat(shot_logger.generate_flags(shot_logger[e.id]))),
		aimed_hitgroup = shot_logger.hitboxes[shot_logger[e.id].original.hitgroup + 1] or '?',
		aimed_hitchance = string.format('%d%%', math.floor(shot_logger[e.id].original.hit_chance + 0.5)),
		hp = math.max(0, entity.get_prop(e.target, 'm_iHealth')),
		spread_angle = string.format('%.2f°', shot_logger.get_inaccuracy_tick(shot_logger[e.id], globals.tickcount())),
		correction = string.format('%d:%d°', shot_logger[e.id].correction and 1 or 0, (shot_logger[e.id].feet_yaw < 10 and shot_logger[e.id].feet_yaw > -10) and 0 or shot_logger[e.id].feet_yaw)
	}

	shot_logger.add({ info.prefix[1], info.prefix[2], info.prefix[3], 'lurith'}, 
					{ 134, 134, 134, ' » ' }, 
					{ 200, 200, 200, info.type and 'damaged ' or 'killed ' }, 
					{ info.hit[1], info.hit[2], info.hit[3],  info.name }, 
					{ 200, 200, 200, ' in the ' }, 
					{ info.hit[1], info.hit[2], info.hit[3], info.hitgroup }, 
					{ 200, 200, 200, info.type and info.hitgroup ~= info.aimed_hitgroup and ' (' or ''},
					{ info.hit[1], info.hit[2], info.hit[3], info.type and (info.hitgroup ~= info.aimed_hitgroup and info.aimed_hitgroup) or '' },
					{ 200, 200, 200, info.type and info.hitgroup ~= info.aimed_hitgroup and ']' or ''},
					{ 200, 200, 200, info.type and ' for ' or '' },
					{ info.hit[1], info.hit[2], info.hit[3], info.type and e.damage or '' },
					{ 200, 200, 200, info.type and e.damage ~= shot_logger[e.id].original.damage and ' (' or ''},
					{ info.hit[1], info.hit[2], info.hit[3], info.type and (e.damage ~= shot_logger[e.id].original.damage and shot_logger[e.id].original.damage) or '' },
					{ 200, 200, 200, info.type and e.damage ~= shot_logger[e.id].original.damage and ')' or ''},
					{ 200, 200, 200, info.type and ' damage' or '' },
					{ 200, 200, 200, info.type and ' (' or '' }, { info.hit[1], info.hit[2], info.hit[3], info.type and info.hp or '' }, { 200, 200, 200, info.type and ' hp remaning)' or '' },
					{ 200, 200, 200, ' [hc: ' }, { info.hit[1], info.hit[2], info.hit[3], info.aimed_hitchance }, { 200, 200, 200, ' | safety: ' }, { info.hit[1], info.hit[2], info.hit[3], shot_logger[e.id].safety },
					{ 200, 200, 200, ' | bt: ' }, { info.hit[1], info.hit[2], info.hit[3], shot_logger[e.id].history },
					{ 200, 200, 200, ']' })
end



shot_logger.on_aim_miss = function(e)
    if not lua_menu.visuals.ragebot_logs:get('console') then return end

    local me = entity.get_local_player()
    local info = {
        prefix = {lua_menu.visuals.ragebot_logs_miss:get()},
        hit = {lua_menu.visuals.ragebot_logs_miss:get()},
        name = entity.get_player_name(e.target),
        hitgroup = shot_logger.hitboxes[e.hitgroup + 1] or '?',
        flags = string.format('%s', _G.table.concat(shot_logger.generate_flags(shot_logger[e.id]))),
        aimed_hitgroup = shot_logger.hitboxes[shot_logger[e.id].original.hitgroup + 1] or '?',
        aimed_hitchance = string.format('%d%%', math.floor(shot_logger[e.id].original.hit_chance + 0.5)),
        hp = math.max(0, entity.get_prop(e.target, 'm_iHealth')),
        reason = e.reason == '?' and (shot_logger[e.id].total_hits ~= entity.get_prop(me, 'm_totalHitsOnServer') and 'damage rejection' or 'unknown') or e.reason,
        spread_angle = string.format('%.2f°', shot_logger.get_inaccuracy_tick(shot_logger[e.id], globals.tickcount())),
        correction = string.format('%d:%d°', shot_logger[e.id].correction and 1 or 0, (shot_logger[e.id].feet_yaw < 10 and shot_logger[e.id].feet_yaw > -10) and 0 or shot_logger[e.id].feet_yaw)
    }

    shot_logger.add(
        {info.prefix[1], info.prefix[2], info.prefix[3], 'lurith'}, {134, 134, 134, ' » '}, 
        {200, 200, 200, 'missed shot at '}, {info.hit[1], info.hit[2], info.hit[3], info.name}, 
        {200, 200, 200, ' in the '}, {info.hit[1], info.hit[2], info.hit[3], info.hitgroup}, 
        {200, 200, 200, ' due to '}, {info.hit[1], info.hit[2], info.hit[3], info.reason},
        {200, 200, 200, ' [hc: '}, {info.hit[1], info.hit[2], info.hit[3], info.aimed_hitchance}, 
        {200, 200, 200, ' | safety: '}, {info.hit[1], info.hit[2], info.hit[3], shot_logger[e.id].safety},
        {200, 200, 200, ' | bt: '}, {info.hit[1], info.hit[2], info.hit[3], shot_logger[e.id].history},
        {200, 200, 200, ']'}
    )
end

client.set_event_callback('aim_fire', shot_logger.on_aim_fire)
client.set_event_callback('aim_miss', shot_logger.on_aim_miss)
client.set_event_callback('aim_hit', shot_logger.on_aim_hit)
client.set_event_callback('bullet_impact', shot_logger.bullet_impact)

local logs = {}
local function ragebot_logs()
    local offset, x, y = 0, screen[1] / 2, screen[2] / 1.4
    for idx, data in ipairs(logs) do
        if (((globals.curtime()/2) * 2.0) - data[3]) < 4.0 and not (#logs > 5 and idx < #logs - 5) then
            data[2] = math.lerp(data[2], 255, 10)
        else
            data[2] = math.lerp(data[2], 0, 10)
        end
        offset = offset - 40 * (data[2] / 255)

        local r, g, b = unpack(data[4])
        text_size_x, text_sise_y = renderer.measure_text("", data[1])
        renderer.glow_module(x - 7 - text_size_x / 2, y - offset-4, text_size_x + 13, 20, 4, 8, {r, g, b, data[2]/2}, {20, 20, 20, data[2]/2})
        renderer.text(x - 1 - text_size_x / 2, y - offset+1, 255, 255, 255, data[2], "", 0, data[1])
        if data[2] < 0.1 or not entity.get_local_player() then table.remove(logs, idx) end
    end
end

renderer.log = function(text, color)
    table.insert(logs, { text, 0, ((globals.curtime() / 2) * 2.0), color})
end

local hitgroup_names = {'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear'}

local function aim_hit(e)
    breaker.tickbase_check = false
    breaker.cmd = 0
    breaker.defensive = 0
    breaker.defensive_check = 0
    if not lua_menu.visuals.ragebot_logs:get('screen') then return end
    local group = hitgroup_names[e.hitgroup + 1] or '?'
    renderer.log(string.format('lurith » it %s in the %s for %d damage', entity.get_player_name(e.target) or "amigus", group, e.damage or 0), {lua_menu.visuals.ragebot_logs_hit:get()})
end
client.set_event_callback('aim_hit', aim_hit)

local function aim_miss(e)
    breaker.tickbase_check = false
    breaker.cmd = 0
    breaker.defensive = 0
    breaker.defensive_check = 0
    if not lua_menu.visuals.ragebot_logs:get('screen') then return end
    local group = hitgroup_names[e.hitgroup + 1] or '?'
    renderer.log(string.format('lurith » missed %s in the %s due to %s', entity.get_player_name(e.target) or "amigus", group, e.reason or "?"), {lua_menu.visuals.ragebot_logs_miss:get()})
end
client.set_event_callback('aim_miss', aim_miss)

local function fastladder(e)
    local me = entity.get_local_player()
    if entity.get_prop(me, "m_MoveType") == 9 then 
        local forward = vector(entity.get_prop(me, "m_vecLadderNormal"));
        if forward:lengthsqr() == 0 then return end

        local view = vector(client.camera_angles())
        local angle = vector(forward:angles())

        local delta_yaw = angle.y - view.y + 180
        local delta_pitch = angle.x - view.x

        delta_yaw = normalize_yaw(delta_yaw)
        delta_pitch = math.clamp(delta_pitch, -89, 89)

        local abs_yaw = math.abs(delta_yaw)

        local pitch = 89
        local yaw_offset = -90

        local is_looking_down = delta_pitch < -45
        local is_looking_to_right = delta_yaw > 0

        local is_sidemove = e.sidemove > 0
        local is_forwardmove = e.forwardmove > 0

            -- sideways
        if abs_yaw > 70 and abs_yaw < 135 then
            if e.forwardmove ~= 0 or e.sidemove == 0 then
                return;
            end

            if not is_looking_to_right then
                yaw_offset = -yaw_offset
            end

            if is_looking_to_right then
                is_sidemove = not is_sidemove
            end

            e.in_back = is_sidemove and 1 or 0
            e.in_forward = is_sidemove and 0 or 1

            if is_looking_to_right then
                is_sidemove = not is_sidemove
            end

            e.in_moveleft = is_sidemove and 1 or 0
            e.in_moveright = is_sidemove and 0 or 1

            e.pitch = pitch
            e.yaw = normalize_yaw(angle.y + yaw_offset)

            return
        end

            -- straight
        if e.sidemove ~= 0 or e.forwardmove == 0 then
            return
        end

        if not is_looking_to_right then
            yaw_offset = -yaw_offset
        end

        if not is_looking_down then
            is_forwardmove = not is_forwardmove
        end

        e.in_back = is_forwardmove and 0 or 1
        e.in_forward = is_forwardmove and 1 or 0

        if not is_looking_to_right then
            is_forwardmove = not is_forwardmove
        end

        e.in_moveleft = is_forwardmove and 1 or 0
        e.in_moveright = is_forwardmove and 0 or 1

        e.pitch = pitch
        e.yaw = normalize_yaw(angle.y + yaw_offset)
    end
end

client.set_event_callback("pre_render", function()
    if lua_menu.misc.kinguru:get() then
        entity.set_prop(entity.get_local_player(), "m_flPoseParameter", math.random(0, 10)/10, 3)
        entity.set_prop(entity.get_local_player(), "m_flPoseParameter", math.random(0, 10)/10, 7)
        entity.set_prop(entity.get_local_player(), "m_flPoseParameter", math.random(0, 10)/10, 6)
    end
end) 


-- #checkbox
ui.new_label("AA", "Other", "                   ")
ui.new_combobox("AA", "Other", "lurith ~ \aA4B2F1FFresolver \aB94A4AFF(beta)", "disable", "enable")

-- #resolver
local L647 = function(L631)
    local L632 = L27.get_players(true)
    if #L632 == 0 then
        L71 = { cur = {}, prev = {}, pre_prev = {}, pre_pre_prev = {} }
        return nil
    end;
    for L633, L634 in L9(L632) do
        if L27.is_alive(L634) and not L27.is_dormant(L634) then
            local L635 = 0;
            local L636 = L27.get_esp_data(L634).flags or 0;
            if L21.band(L636, L21.lshift(1, 17)) ~= 0 then
                L635 = L503(L27.get_prop(L634, "m_flSimulationTime")) - 14
            else
                L635 = L503(L27.get_prop(L634, "m_flSimulationTime"))
            end;
            if L71.cur[L634] == nil or L635 - L71.cur[L634].simtime >= 1 then
                L71.pre_pre_prev[L634] = L71.pre_prev[L634]
                L71.pre_prev[L634] = L71.prev[L634]
                L71.prev[L634] = L71.cur[L634]
                local L637 = L2(L27.get_prop(L631, "m_vecOrigin"))
                local L638 = L2(L27.get_prop(L634, "m_angEyeAngles"))
                local L639 = L2(L27.get_prop(L634, "m_vecOrigin"))
                local L640 = L23.floor(L138(L638.y - calculate_angle(L637, L639)))
                local L641 = L27.get_prop(L634, "m_flDuckAmount")
                local L642 = L21.band(L27.get_prop(L634, "m_fFlags"), 1) == 1;
                local L643 = L2(L27.get_prop(L634, 'm_vecVelocity')):length2d()
                local L644 = L642 and (L641 == 1 and "duck" or (L643 > 1.2 and "running" or "standing")) or "air"
                local L645 = L27.get_player_weapon(L634)
                local L646 = L27.get_prop(L645, "m_fLastShotTime")
                L71.cur[L634] = { id = L634, origin = L2(L27.get_origin(L634)), pitch = L638.x, yaw = L640, yaw_backwards = L23.floor(L138(calculate_angle(L637, L639))), simtime = L635, stance = L644, esp_flags = L27.get_esp_data(L634).flags or 0, last_shot_time = L646 }
            end
        end
    end
end;
local L648 = false;
local L672 = function(L649)
    if not L27.is_alive(L649) then
        if L648 then
        end;
        L648 = false;
        return
    end;
    local L650 = L27.get_players(true)
    if #L650 == 0 then
        return nil
    end;
    for L651, L652 in L9(L650) do
        if L27.is_alive(L652) and not L27.is_dormant(L652) then
            if L71.cur[L652] ~= nil and L71.prev[L652] ~= nil and L71.pre_prev[L652] ~= nil and L71.pre_pre_prev[L652] ~= nil then
                local L653 = nil;
                local L654 = nil;
                local L655;
                local L656;
                local L657 = L23.abs(L138(L71.cur[L652].yaw - L71.prev[L652].yaw))
                local L658 = L138(L71.cur[L652].yaw - L71.prev[L652].yaw)
                if L71.cur[L652].last_shot_time ~= nil then
                    L655 = L26.curtime() - L71.cur[L652].last_shot_time;
                    L656 = L655 / L26.tickinterval()
                    L654 = L656 <= L23.floor(0.2 / L26.tickinterval())
                end;
                if L24.get(L90["debug"][1]) == "enable" then
                    L648 = true;
                    local L659 = L71.cur[L652].yaw;
                    local L660 = L71.prev[L652].yaw;
                    local L661 = L71.pre_prev[L652].yaw;
                    local L662 = L71.pre_pre_prev[L652].yaw;
                    local L663 = L138(L659 - L660)
                    local L664 = L138(L659 - L661)
                    local L665 = L138(L660 - L662)
                    local L666 = L138(L660 - L661)
                    local L667 = L138(L661 - L662)
                    local L668 = L138(L662 - L659)
                    local L669 = L138(L657 - L668)
                    if L654 and L23.abs(L23.abs(L71.cur[L652].pitch) - L23.abs(L71.prev[L652].pitch)) > 30 and L71.cur[L652].pitch < L71.prev[L652].pitch then
                        L653 = "ON SHOT"
                    else
                        if L23.abs(L71.cur[L652].pitch) > 60 then
                            if L657 > 30 and L23.abs(L664) < 15 and L23.abs(L665) < 15 then
                                L653 = "[!!]"
                            elseif L23.abs(L663) > 15 or L23.abs(L666) > 15 or L23.abs(L667) > 15 or L23.abs(L668) > 15 then
                                L653 = "[!!!]"
                            end
                        end
                    end;
                    if L24.get(L90["debug"][5]) and L24.get(L90["debug"][6]) then
                        if L653 ~= "ON SHOT" then
                            L18.set(L652, "Add to whitelist", true)
                        else
                            L18.set(L652, "Add to whitelist", false)
                        end
                    else
                        L18.set(L652, "Add to whitelist", false)
                    end;
                    if L147[L652] and L653 ~= nil then
                        if L71.cur[L652].stance == "standing" and #L73[L652].stand < 20 then
                            table.insert(L73[L652].stand_type, L653)
                            if L653 == "[!!!]" and L657 > 5 then
                                table.insert(L73[L652].stand, L657)
                            else
                                if L653 == "[!!]" then
                                    table.insert(L73[L652].stand, L657)
                                end
                            end
                        elseif L71.cur[L652].stance == "running" and #L73[L652].run < 20 then
                            table.insert(L73[L652].run_type, L653)
                            if L653 == "[!!!]" and L657 > 5 then
                                table.insert(L73[L652].run, L657)
                            else
                                if L653 == "[!!]" then
                                    table.insert(L73[L652].run, L657)
                                end
                            end
                        elseif L71.cur[L652].stance == "air" and #L73[L652].air < 20 then
                            table.insert(L73[L652].air_type, L653)
                            if L653 == "[!!!]" and L657 > 5 then
                                table.insert(L73[L652].air, L657)
                            else
                                if L653 == "[!!]" then
                                    table.insert(L73[L652].air, L657)
                                end
                            end
                        elseif L71.cur[L652].stance == "duck" and #L73[L652].duck < 20 then
                            table.insert(L73[L652].duck_type, L653)
                            if L653 == "[!!!]" and L657 > 5 then
                                table.insert(L73[L652].duck, L657)
                            else
                                if L653 == "[!!]" then
                                    table.insert(L73[L652].duck, L657)
                                end
                            end
                        end
                    end;
                    if L71.cur[L652].pitch >= 78 and L71.prev[L652].pitch > 78 then
                        if L653 == "[!!!]" or L653 == "[!!]" then
                            if L653 == "[!!]" then
                                if L138(L659 - L660) > 0 then
                                    L18.set(L652, "Force body yaw", true)
                                    L18.set(L652, "Force body yaw value", 60)
                                elseif L138(L659 - L660) < 0 then
                                    L18.set(L652, "Force body yaw", true)
                                    L18.set(L652, "Force body yaw value", -60)
                                end
                            elseif L653 == "[!!!]" then
                                local L670 = 0;
                                local L671 = 0;
                                if (L660 == L138(L659 - L657) or L660 == L138(L659 + L657)) and (L661 == L138(L659 + L657) or L661 == L659) and (L661 == L138(L659 + L657) or L661 == L659) then
                                    L18.set(L652, "Force body yaw", true)
                                    L18.set(L652, "Force body yaw value", 0)
                                    L670 = L659
                                else
                                    if L659 ~= L670 then
                                        if L659 < 0 then
                                            L18.set(L652, "Force body yaw", true)
                                            L18.set(L652, "Force body yaw value", 60)
                                        else
                                            L18.set(L652, "Force body yaw", true)
                                            L18.set(L652, "Force body yaw value", -60)
                                        end
                                    end
                                end
                            end
                        else
                            L18.set(L652, "Force body yaw", false)
                            L18.set(L652, "Force body yaw value", 0)
                        end
                    end
                elseif L24.get(L90["debug"][1]) == "---" then
                    L653 = nil;
                    L648 = true;
                    break
                elseif L24.get(L90["debug"][1]) == "disable" then
                    if L648 then
                        L653 = nil;
                        L24.set(L127.plist.reset, true)
                        L18.set(L652, "Force body yaw", false)
                        L18.set(L652, "Force body yaw value", 0)
                        L648 = false
                    end
                end;
                L72[L652] = { anti_aim_type = L653, yaw_delta = L658 }
            end
        else
            m_fired = false;
            time_difference = 0;
            ticks_since_last_shot = 0
        end
    end
end

local function check_charge()
    local lp = entity.get_local_player()
    local m_nTickBase = entity.get_prop(lp, 'm_nTickBase')
    local client_latency = client.latency()
    local shift = math.floor(m_nTickBase - globals.tickcount() - 3 - toticks(client_latency) * .5 + .5 * (client_latency * 10))
    local wanted = -14 + (ui.get(ref.doubletap.fakelag_limit) - 1) + 3
    return shift <= wanted
end

local is_hittable = false

local config_cfg = {lua_menu, antiaim_system}

local package, data, encrypted, decrypted = pui.setup(config_cfg), "", "", ""
config = {}

local cfg_system = {}
configs_db = database.read(lua_db.configs) or { }
configs_db.cfg_list = configs_db.cfg_list or {{'default', 'W3sidmlzdWFscyI6eyJkZWZlbnNpdmVfd2luZG93X3R5cGUiOiJNb2Rlcm4iLCJjcm9zc19jb2xvciI6dHJ1ZSwiZGVmZW5zaXZlX3dpbmRvd19jIjoiI0ZGRkZGRkZGIiwicmFnZWJvdF9sb2dzIjpbIkNvbnNvbGUiLCJTY3JlZW4iLCJ+Il0sInJhZ2Vib3RfbG9nc19taXNzIjoiI0JENjM2MEZGIiwiY3Jvc3NfY29sb3JfYyI6IiM2NDY0NjRGRiIsInJhZ2Vib3RfbG9nc19oaXQiOiIjNzRCRDYwRkYiLCJjcm9zc19pbmQiOnRydWUsImNyb3NzX2luZF9jIjoiI0M4QzhDOEZGIiwia2V5X2NvbG9yIjp0cnVlLCJ2ZWxvY2l0eV93aW5kb3dfYyI6IiNGRkZGRkZGRiIsImtleV9jb2xvcl9jIjoiI0ZGRkZGRkZGIiwiY3Jvc3NfaW5kX3R5cGUiOiJBbHRlcm5hdGl2ZSIsImRlZmVuc2l2ZV93aW5kb3ciOnRydWUsInZlbG9jaXR5X3dpbmRvd190eXBlIjoiTW9kZXJuIiwidmVsb2NpdHlfd2luZG93Ijp0cnVlfSwibWlzYyI6eyJwcmVkaWN0IjpmYWxzZSwiZmFzdF9sYWRkZXIiOnRydWUsInVuc2FmZV9yZWNoYXJnZSI6dHJ1ZSwidW5zYWZlX3R5cGUiOiJBbHRlcm5hdGl2ZSIsImFzcGVjdHJhdGlvIjp0cnVlLCJhaXJxc2JpbmQiOlsxLDYsIn4iXSwiY29uc29sZSI6dHJ1ZSwiYXNwZWN0cmF0aW9fdmFsdWUiOjEzMywiZGVmZW5zaXZlX2ZpeCI6dHJ1ZSwiYWlycXMiOnRydWUsInRoaXJkX3BlcnNvbiI6dHJ1ZSwiYW50aWJhY2tzdGFiIjp0cnVlLCJ0aGlyZF9wZXJzb25fdmFsdWUiOjQ1fSwibWFpbiI6eyJ0YWIiOiLimaYgQ29uZmlnIOKZpiJ9LCJhbnRpYWltIjp7InRhYiI6Ik1haW4iLCJkZWZlbnNpdmVfY29uZGl0aW9uIjpbIn4iXSwieWF3X29wdGlvbnMiOlsifiJdLCJrZXlfbGVmdCI6WzEsOTAsIn4iXSwic2FmZV9oZWFkIjpbIkFpcitDIEtuaWZlIiwiQWlyK0MgWmV1cyIsIkhlaWdodCBEaWZmZXJlbmNlIiwifiJdLCJmcl9vcHRpb25zIjpbIkZyZWVzdGFuZGluZyBPbiBRdWljayBQZWVrIiwifiJdLCJmcl9kaXNhYmxlcnMiOlsifiJdLCJhYV9vdmVycmlkZSI6WyJPbiBXYXJtdXAiLCJObyBFbmVtaWVzIEFsaXZlIiwifiJdLCJ5YXdfYmFzZSI6IkF0IHRhcmdldHMiLCJlZGdlX3lhdyI6WzEsMCwifiJdLCJrZXlfZm9yd2FyZCI6WzEsMCwifiJdLCJtYW51YWxfZGlyZWN0aW9uIjpmYWxzZSwiaGVpZ2h0X2RpZmZlcmVuY2UiOjIwMCwiY29uZGl0aW9uIjoiV2Fsa2luZyIsInlhd19kaXJlY3Rpb24iOnRydWUsImRlZmVuc2l2ZV90cmlnZ2VycyI6WyJ+Il0sImZyZWVzdGFuZGluZyI6WzEsMCwifiJdLCJrZXlfcmlnaHQiOlsxLDY3LCJ+Il19LCJjb25maWciOnsibGlzdCI6MSwibmFtZSI6IiJ9fSxbeyJlbmFibGUiOmZhbHNlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJPZmYiLCJ5YXdfb2Zmc2V0IjowLCJwZWVrX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZV9waXRjaCI6Ik9mZiIsImRlbGF5X3JhbmRvbSI6MSwiYm9keV9zbGlkZXIiOjAsImJvZHlfeWF3X3R5cGUiOiJPZmYiLCJ5YXdfcmFuZG9tIjowLCJkZWZfYm9keV9zbGlkZXIiOjAsImRlZmVuc2l2ZSI6ZmFsc2UsIm1vZF9kbSI6MCwiZGVmX21vZF9kbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJ+Il0sInlhd19yaWdodCI6MCwiZm9yY2VfZGVmIjpmYWxzZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6Ik9mZiIsImRlZmVuc2l2ZV95YXciOiJPZmYiLCJkZWZfbW9kX3R5cGUiOiJPZmYiLCJ5YXdfdmFsdWUiOjAsIm1vZF9yYW5kb20iOjAsInNwaW5fb2Zmc2V0IjozNjAsInNwaW5fc3BlZWQiOjEwLCJwaXRjaF9zcGVlZCI6MCwieWF3X292ZXJyaWRlIjpmYWxzZSwieWF3X2xlZnQiOjAsInBpdGNoX3ZhbHVlIjowLCJwaXRjaCI6IkRvd24ifSx7ImVuYWJsZSI6dHJ1ZSwiZGVmX21vZF9yYW5kb20iOjAsIm1vZF90eXBlIjoiU2tpdHRlciIsInlhd19vZmZzZXQiOjMsInBlZWtfZGVmIjpmYWxzZSwiZGVmZW5zaXZlX3BpdGNoIjoiT2ZmIiwiZGVsYXlfcmFuZG9tIjoxLCJib2R5X3NsaWRlciI6MSwiYm9keV95YXdfdHlwZSI6IkppdHRlciIsInlhd19yYW5kb20iOjAsImRlZl9ib2R5X3NsaWRlciI6MSwiZGVmZW5zaXZlIjp0cnVlLCJtb2RfZG0iOi0zMywiZGVmX21vZF9kbSI6LTUwLCJkZWZlbnNpdmVfc2VsZWN0IjpbIkppdHRlciIsIkJvZHkgWWF3IiwifiJdLCJ5YXdfcmlnaHQiOjAsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6IkppdHRlciIsImRlZmVuc2l2ZV95YXciOiJPZmZzZXQiLCJkZWZfbW9kX3R5cGUiOiJTa2l0dGVyIiwieWF3X3ZhbHVlIjozLCJtb2RfcmFuZG9tIjowLCJzcGluX29mZnNldCI6MzYwLCJzcGluX3NwZWVkIjoxMCwicGl0Y2hfc3BlZWQiOjEsInlhd19vdmVycmlkZSI6ZmFsc2UsInlhd19sZWZ0IjowLCJwaXRjaF92YWx1ZSI6ODksInBpdGNoIjoiRG93biJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJTa2l0dGVyIiwieWF3X29mZnNldCI6MywicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmVfcGl0Y2giOiJPZmYiLCJkZWxheV9yYW5kb20iOjEsImJvZHlfc2xpZGVyIjoxLCJib2R5X3lhd190eXBlIjoiSml0dGVyIiwieWF3X3JhbmRvbSI6MCwiZGVmX2JvZHlfc2xpZGVyIjowLCJkZWZlbnNpdmUiOnRydWUsIm1vZF9kbSI6LTQwLCJkZWZfbW9kX2RtIjotNjUsImRlZmVuc2l2ZV9zZWxlY3QiOlsiSml0dGVyIiwifiJdLCJ5YXdfcmlnaHQiOjAsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6IkppdHRlciIsImRlZmVuc2l2ZV95YXciOiJPZmZzZXQiLCJkZWZfbW9kX3R5cGUiOiJTa2l0dGVyIiwieWF3X3ZhbHVlIjozLCJtb2RfcmFuZG9tIjowLCJzcGluX29mZnNldCI6MzYwLCJzcGluX3NwZWVkIjoxMCwicGl0Y2hfc3BlZWQiOjIsInlhd19vdmVycmlkZSI6ZmFsc2UsInlhd19sZWZ0IjowLCJwaXRjaF92YWx1ZSI6ODksInBpdGNoIjoiRG93biJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJTa2l0dGVyIiwieWF3X29mZnNldCI6MTksInBlZWtfZGVmIjpmYWxzZSwiZGVmZW5zaXZlX3BpdGNoIjoiT2ZmIiwiZGVsYXlfcmFuZG9tIjoxLCJib2R5X3NsaWRlciI6MSwiYm9keV95YXdfdHlwZSI6IkppdHRlciIsInlhd19yYW5kb20iOjAsImRlZl9ib2R5X3NsaWRlciI6MCwiZGVmZW5zaXZlIjp0cnVlLCJtb2RfZG0iOi0zNSwiZGVmX21vZF9kbSI6LTUwLCJkZWZlbnNpdmVfc2VsZWN0IjpbIkppdHRlciIsIn4iXSwieWF3X3JpZ2h0IjozLCJmb3JjZV9kZWYiOnRydWUsInlhd19kZWxheSI6MSwiZGVmX2JvZHlfeWF3X3R5cGUiOiJPZmYiLCJkZWZlbnNpdmVfeWF3IjoiT2Zmc2V0IiwiZGVmX21vZF90eXBlIjoiU2tpdHRlciIsInlhd192YWx1ZSI6MywibW9kX3JhbmRvbSI6MCwic3Bpbl9vZmZzZXQiOjM2MCwic3Bpbl9zcGVlZCI6MTAsInBpdGNoX3NwZWVkIjowLCJ5YXdfb3ZlcnJpZGUiOnRydWUsInlhd19sZWZ0IjozLCJwaXRjaF92YWx1ZSI6MCwicGl0Y2giOiJEb3duIn0seyJlbmFibGUiOnRydWUsImRlZl9tb2RfcmFuZG9tIjowLCJtb2RfdHlwZSI6IlNraXR0ZXIiLCJ5YXdfb2Zmc2V0IjoxNywicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmVfcGl0Y2giOiJPZmYiLCJkZWxheV9yYW5kb20iOjEsImJvZHlfc2xpZGVyIjoxLCJib2R5X3lhd190eXBlIjoiSml0dGVyIiwieWF3X3JhbmRvbSI6MCwiZGVmX2JvZHlfc2xpZGVyIjoxLCJkZWZlbnNpdmUiOnRydWUsIm1vZF9kbSI6LTMzLCJkZWZfbW9kX2RtIjotNTEsImRlZmVuc2l2ZV9zZWxlY3QiOlsiSml0dGVyIiwiQm9keSBZYXciLCJ+Il0sInlhd19yaWdodCI6MywiZm9yY2VfZGVmIjp0cnVlLCJ5YXdfZGVsYXkiOjEsImRlZl9ib2R5X3lhd190eXBlIjoiSml0dGVyIiwiZGVmZW5zaXZlX3lhdyI6Ik9mZnNldCIsImRlZl9tb2RfdHlwZSI6IlNraXR0ZXIiLCJ5YXdfdmFsdWUiOjMsIm1vZF9yYW5kb20iOjAsInNwaW5fb2Zmc2V0IjozNjAsInNwaW5fc3BlZWQiOjEwLCJwaXRjaF9zcGVlZCI6LTEsInlhd19vdmVycmlkZSI6dHJ1ZSwieWF3X2xlZnQiOjMsInBpdGNoX3ZhbHVlIjo4OSwicGl0Y2giOiJEb3duIn0seyJlbmFibGUiOnRydWUsImRlZl9tb2RfcmFuZG9tIjowLCJtb2RfdHlwZSI6IlNraXR0ZXIiLCJ5YXdfb2Zmc2V0IjoxNiwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmVfcGl0Y2giOiJPZmYiLCJkZWxheV9yYW5kb20iOjEsImJvZHlfc2xpZGVyIjoxLCJib2R5X3lhd190eXBlIjoiSml0dGVyIiwieWF3X3JhbmRvbSI6MCwiZGVmX2JvZHlfc2xpZGVyIjoxLCJkZWZlbnNpdmUiOnRydWUsIm1vZF9kbSI6LTMzLCJkZWZfbW9kX2RtIjotNTEsImRlZmVuc2l2ZV9zZWxlY3QiOlsiSml0dGVyIiwiQm9keSBZYXciLCJ+Il0sInlhd19yaWdodCI6MTAsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6IkppdHRlciIsImRlZmVuc2l2ZV95YXciOiJPZmZzZXQiLCJkZWZfbW9kX3R5cGUiOiJTa2l0dGVyIiwieWF3X3ZhbHVlIjoxMCwibW9kX3JhbmRvbSI6MCwic3Bpbl9vZmZzZXQiOjM2MCwic3Bpbl9zcGVlZCI6MTAsInBpdGNoX3NwZWVkIjowLCJ5YXdfb3ZlcnJpZGUiOnRydWUsInlhd19sZWZ0IjoxMCwicGl0Y2hfdmFsdWUiOjAsInBpdGNoIjoiRG93biJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MTAsIm1vZF90eXBlIjoiQ2VudGVyIiwieWF3X29mZnNldCI6NiwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmVfcGl0Y2giOiJDdXN0b20iLCJkZWxheV9yYW5kb20iOjEsImJvZHlfc2xpZGVyIjoxLCJib2R5X3lhd190eXBlIjoiSml0dGVyIiwieWF3X3JhbmRvbSI6MTIsImRlZl9ib2R5X3NsaWRlciI6MSwiZGVmZW5zaXZlIjp0cnVlLCJtb2RfZG0iOjU1LCJkZWZfbW9kX2RtIjowLCJkZWZlbnNpdmVfc2VsZWN0IjpbIkppdHRlciIsIkJvZHkgWWF3IiwifiJdLCJ5YXdfcmlnaHQiOjcsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6IlN0YXRpYyIsImRlZmVuc2l2ZV95YXciOiJTcGluIiwiZGVmX21vZF90eXBlIjoiT2ZmIiwieWF3X3ZhbHVlIjoxODAsIm1vZF9yYW5kb20iOjEwLCJzcGluX29mZnNldCI6MzYwLCJzcGluX3NwZWVkIjo5LCJwaXRjaF9zcGVlZCI6MCwieWF3X292ZXJyaWRlIjpmYWxzZSwieWF3X2xlZnQiOjcsInBpdGNoX3ZhbHVlIjotODksInBpdGNoIjoiRG93biJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MTAsIm1vZF90eXBlIjoiQ2VudGVyIiwieWF3X29mZnNldCI6NiwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmVfcGl0Y2giOiJDdXN0b20iLCJkZWxheV9yYW5kb20iOjEsImJvZHlfc2xpZGVyIjoxLCJib2R5X3lhd190eXBlIjoiSml0dGVyIiwieWF3X3JhbmRvbSI6MTMsImRlZl9ib2R5X3NsaWRlciI6LTEsImRlZmVuc2l2ZSI6dHJ1ZSwibW9kX2RtIjo1MCwiZGVmX21vZF9kbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJKaXR0ZXIiLCJCb2R5IFlhdyIsIn4iXSwieWF3X3JpZ2h0IjoyMiwiZm9yY2VfZGVmIjp0cnVlLCJ5YXdfZGVsYXkiOjEsImRlZl9ib2R5X3lhd190eXBlIjoiU3RhdGljIiwiZGVmZW5zaXZlX3lhdyI6IlNwaW4iLCJkZWZfbW9kX3R5cGUiOiJPZmYiLCJ5YXdfdmFsdWUiOjE4MCwibW9kX3JhbmRvbSI6MTAsInNwaW5fb2Zmc2V0IjozNjAsInNwaW5fc3BlZWQiOjUsInBpdGNoX3NwZWVkIjowLCJ5YXdfb3ZlcnJpZGUiOmZhbHNlLCJ5YXdfbGVmdCI6MCwicGl0Y2hfdmFsdWUiOi04OSwicGl0Y2giOiJEb3duIn0seyJlbmFibGUiOmZhbHNlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJPZmYiLCJ5YXdfb2Zmc2V0IjowLCJwZWVrX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZV9waXRjaCI6Ik9mZiIsImRlbGF5X3JhbmRvbSI6MSwiYm9keV9zbGlkZXIiOjAsImJvZHlfeWF3X3R5cGUiOiJPZmYiLCJ5YXdfcmFuZG9tIjowLCJkZWZfYm9keV9zbGlkZXIiOjAsImRlZmVuc2l2ZSI6ZmFsc2UsIm1vZF9kbSI6MCwiZGVmX21vZF9kbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJ+Il0sInlhd19yaWdodCI6MCwiZm9yY2VfZGVmIjpmYWxzZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6Ik9mZiIsImRlZmVuc2l2ZV95YXciOiJPZmYiLCJkZWZfbW9kX3R5cGUiOiJPZmYiLCJ5YXdfdmFsdWUiOjAsIm1vZF9yYW5kb20iOjAsInNwaW5fb2Zmc2V0IjozNjAsInNwaW5fc3BlZWQiOjEwLCJwaXRjaF9zcGVlZCI6MCwieWF3X292ZXJyaWRlIjpmYWxzZSwieWF3X2xlZnQiOjAsInBpdGNoX3ZhbHVlIjowLCJwaXRjaCI6Ik9mZiJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJPZmYiLCJ5YXdfb2Zmc2V0IjoxODAsInBlZWtfZGVmIjpmYWxzZSwiZGVmZW5zaXZlX3BpdGNoIjoiT2ZmIiwiZGVsYXlfcmFuZG9tIjoxLCJib2R5X3NsaWRlciI6MCwiYm9keV95YXdfdHlwZSI6IkppdHRlciIsInlhd19yYW5kb20iOjAsImRlZl9ib2R5X3NsaWRlciI6MCwiZGVmZW5zaXZlIjpmYWxzZSwibW9kX2RtIjoxMDYsImRlZl9tb2RfZG0iOjAsImRlZmVuc2l2ZV9zZWxlY3QiOlsifiJdLCJ5YXdfcmlnaHQiOjAsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6Ik9mZiIsImRlZmVuc2l2ZV95YXciOiJPZmYiLCJkZWZfbW9kX3R5cGUiOiJPZmYiLCJ5YXdfdmFsdWUiOjAsIm1vZF9yYW5kb20iOjAsInNwaW5fb2Zmc2V0IjozNjAsInNwaW5fc3BlZWQiOjEwLCJwaXRjaF9zcGVlZCI6MCwieWF3X292ZXJyaWRlIjpmYWxzZSwieWF3X2xlZnQiOjAsInBpdGNoX3ZhbHVlIjowLCJwaXRjaCI6Ik9mZiJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJPZmYiLCJ5YXdfb2Zmc2V0Ijo1LCJwZWVrX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZV9waXRjaCI6IkN1c3RvbSIsImRlbGF5X3JhbmRvbSI6MSwiYm9keV9zbGlkZXIiOjEsImJvZHlfeWF3X3R5cGUiOiJTdGF0aWMiLCJ5YXdfcmFuZG9tIjowLCJkZWZfYm9keV9zbGlkZXIiOi0xLCJkZWZlbnNpdmUiOnRydWUsIm1vZF9kbSI6MCwiZGVmX21vZF9kbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJCb2R5IFlhdyIsIn4iXSwieWF3X3JpZ2h0IjowLCJmb3JjZV9kZWYiOnRydWUsInlhd19kZWxheSI6MSwiZGVmX2JvZHlfeWF3X3R5cGUiOiJTdGF0aWMiLCJkZWZlbnNpdmVfeWF3IjoiT2ZmIiwiZGVmX21vZF90eXBlIjoiT2ZmIiwieWF3X3ZhbHVlIjowLCJtb2RfcmFuZG9tIjowLCJzcGluX29mZnNldCI6MzYwLCJzcGluX3NwZWVkIjoxMCwicGl0Y2hfc3BlZWQiOjAsInlhd19vdmVycmlkZSI6ZmFsc2UsInlhd19sZWZ0IjowLCJwaXRjaF92YWx1ZSI6LTg5LCJwaXRjaCI6IkRvd24ifSx7ImVuYWJsZSI6dHJ1ZSwiZGVmX21vZF9yYW5kb20iOjAsIm1vZF90eXBlIjoiT2ZmIiwieWF3X29mZnNldCI6MjUsInBlZWtfZGVmIjpmYWxzZSwiZGVmZW5zaXZlX3BpdGNoIjoiQ3VzdG9tIiwiZGVsYXlfcmFuZG9tIjoxLCJib2R5X3NsaWRlciI6MSwiYm9keV95YXdfdHlwZSI6IlN0YXRpYyIsInlhd19yYW5kb20iOjAsImRlZl9ib2R5X3NsaWRlciI6MCwiZGVmZW5zaXZlIjp0cnVlLCJtb2RfZG0iOjAsImRlZl9tb2RfZG0iOjAsImRlZmVuc2l2ZV9zZWxlY3QiOlsifiJdLCJ5YXdfcmlnaHQiOjAsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6Ik9mZiIsImRlZmVuc2l2ZV95YXciOiJPZmZzZXQiLCJkZWZfbW9kX3R5cGUiOiJPZmYiLCJ5YXdfdmFsdWUiOjE4MCwibW9kX3JhbmRvbSI6MCwic3Bpbl9vZmZzZXQiOjM2MCwic3Bpbl9zcGVlZCI6MTAsInBpdGNoX3NwZWVkIjowLCJ5YXdfb3ZlcnJpZGUiOmZhbHNlLCJ5YXdfbGVmdCI6MCwicGl0Y2hfdmFsdWUiOjAsInBpdGNoIjoiRG93biJ9XV0='}}
configs_db.menu_list = configs_db.menu_list or {'default'}
configs_db.cfg_list = configs_db.cfg_list or {{'unmatched preset', 'W3sidmlzdWFscyI6eyJyYWdlYm90X2xvZ3MiOlsiY29uc29sZSIsInNjcmVlbiIsIn4iXSwicmFnZWJvdF9sb2dzX21pc3MiOiIjQkQ2MzYwRkYiLCJkZWZlbnNpdmVfd2luZG93X3R5cGUiOiJub3JtYWwiLCJyYWdlYm90X2xvZ3NfaGl0IjoiIzc0QkQ2MEZGIiwidmVsb2NpdHlfd2luZG93X2MiOiIjRkZGRkZGRkYiLCJ2ZWxvY2l0eV93aW5kb3ciOmZhbHNlLCJkZWZlbnNpdmVfd2luZG93IjpmYWxzZSwidmVsb2NpdHlfd2luZG93X3R5cGUiOiJub3JtYWwiLCJkZWZlbnNpdmVfd2luZG93X2MiOiIjRkZGRkZGRkYifSwibWlzYyI6eyJmYXN0X2xhZGRlciI6dHJ1ZSwiY2xhbnRhZyI6dHJ1ZSwia2luZ3VydSI6ZmFsc2UsImFudGliYWNrc3RhYiI6dHJ1ZSwiY29uc29sZSI6ZmFsc2V9LCJtYWluIjp7InRhYiI6ImNvbmZpZyJ9LCJhbnRpYWltIjp7ImFhX292ZXJyaWRlIjpbIn4iXSwidGFiIjoiYnVpbGRlciIsInlhd19iYXNlIjoiYXQgdGFyZ2V0cyIsImtleV9mb3J3YXJkIjpbMSwwLCJ+Il0sImtleV9yaWdodCI6WzEsNjcsIn4iXSwiZnJlZXN0YW5kaW5nIjpbMSwxOCwifiJdLCJlZGdlX3lhdyI6WzEsMCwifiJdLCJ5YXdfb3B0aW9ucyI6WyJ+Il0sImtleV9sZWZ0IjpbMSw5MCwifiJdLCJtYW51YWxfZGlyZWN0aW9uIjpmYWxzZSwiZnJfb3B0aW9ucyI6WyJmcmVlc3RhbmRpbmcgZGlzYWJsZXJzIiwifiJdLCJoZWlnaHRfZGlmZmVyZW5jZSI6MjAwLCJmcl9kaXNhYmxlcnMiOlsifiJdLCJ5YXdfZGlyZWN0aW9uIjp0cnVlLCJjb25kaXRpb24iOiJydW5uaW5nIiwic2FmZV9oZWFkIjpbImFpcitjIHpuaWZlIiwiYWlyK2MgemV1cyIsIn4iXX0sImNvbmZpZyI6eyJsaXN0IjoyLCJuYW1lIjoic2FmZSBoZWFkIn19LFt7ImVuYWJsZSI6ZmFsc2UsImRlZl9tb2RfcmFuZG9tIjowLCJtb2RfdHlwZSI6Im9mZiIsInlhd19vZmZzZXQiOjAsInBpdGNoX3NwZWVkIjowLCJkZWZlbnNpdmVfcGl0Y2giOiJvZmYiLCJwaXRjaF92YWx1ZSI6MCwiYm9keV9zbGlkZXIiOjAsImRlbGF5X3JhbmRvbSI6MSwiZGVmX21vZF9kbSI6MCwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmUiOmZhbHNlLCJtb2RfZG0iOjAsInlhd19yYW5kb20iOjAsImRlZmVuc2l2ZV9zZWxlY3QiOlsifiJdLCJ5YXdfZGVsYXkiOjEsImZvcmNlX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZV95YXciOiJvZmYiLCJwaXRjaCI6ImRvd24iLCJzcGluX29mZnNldCI6MzYwLCJkZWZfbW9kX3R5cGUiOiJvZmYiLCJ5YXdfdmFsdWUiOjAsIm1vZF9yYW5kb20iOjAsImRlZl9ib2R5X3lhd190eXBlIjoib2ZmIiwic3Bpbl9zcGVlZCI6MTAsImRlZl9ib2R5X3NsaWRlciI6MCwieWF3X292ZXJyaWRlIjpmYWxzZSwieWF3X2xlZnQiOjAsInlhd19yaWdodCI6MCwiYm9keV95YXdfdHlwZSI6Im9mZiJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJvZmYiLCJ5YXdfb2Zmc2V0Ijo1LCJwaXRjaF9zcGVlZCI6MSwiZGVmZW5zaXZlX3BpdGNoIjoib2ZmIiwicGl0Y2hfdmFsdWUiOjg5LCJib2R5X3NsaWRlciI6MSwiZGVsYXlfcmFuZG9tIjoxLCJkZWZfbW9kX2RtIjotNTAsInBlZWtfZGVmIjpmYWxzZSwiZGVmZW5zaXZlIjpmYWxzZSwibW9kX2RtIjotMzMsInlhd19yYW5kb20iOjE5LCJkZWZlbnNpdmVfc2VsZWN0IjpbImppdHRlciIsImJvZHkgWWF3IiwifiJdLCJ5YXdfZGVsYXkiOjEsImZvcmNlX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZV95YXciOiJvZmZzZXQiLCJwaXRjaCI6ImRvd24iLCJzcGluX29mZnNldCI6MzYwLCJkZWZfbW9kX3R5cGUiOiJza2l0dGVyIiwieWF3X3ZhbHVlIjozLCJtb2RfcmFuZG9tIjowLCJkZWZfYm9keV95YXdfdHlwZSI6ImppdHRlciIsInNwaW5fc3BlZWQiOjEwLCJkZWZfYm9keV9zbGlkZXIiOjEsInlhd19vdmVycmlkZSI6dHJ1ZSwieWF3X2xlZnQiOi0yNiwieWF3X3JpZ2h0Ijo0NCwiYm9keV95YXdfdHlwZSI6ImppdHRlciJ9LHsiZW5hYmxlIjpmYWxzZSwiZGVmX21vZF9yYW5kb20iOjAsIm1vZF90eXBlIjoib2ZmIiwieWF3X29mZnNldCI6LTUsInBpdGNoX3NwZWVkIjoyLCJkZWZlbnNpdmVfcGl0Y2giOiJvZmYiLCJwaXRjaF92YWx1ZSI6ODksImJvZHlfc2xpZGVyIjoxLCJkZWxheV9yYW5kb20iOjEsImRlZl9tb2RfZG0iOi02NSwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmUiOmZhbHNlLCJtb2RfZG0iOi00MCwieWF3X3JhbmRvbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJ+Il0sInlhd19kZWxheSI6MiwiZm9yY2VfZGVmIjp0cnVlLCJkZWZlbnNpdmVfeWF3Ijoib2ZmIiwicGl0Y2giOiJkb3duIiwic3Bpbl9vZmZzZXQiOjM2MCwiZGVmX21vZF90eXBlIjoic2tpdHRlciIsInlhd192YWx1ZSI6MywibW9kX3JhbmRvbSI6MCwiZGVmX2JvZHlfeWF3X3R5cGUiOiJqaXR0ZXIiLCJzcGluX3NwZWVkIjoxMCwiZGVmX2JvZHlfc2xpZGVyIjowLCJ5YXdfb3ZlcnJpZGUiOnRydWUsInlhd19sZWZ0IjotMjMsInlhd19yaWdodCI6NDAsImJvZHlfeWF3X3R5cGUiOiJqaXR0ZXIifSx7ImVuYWJsZSI6dHJ1ZSwiZGVmX21vZF9yYW5kb20iOjAsIm1vZF90eXBlIjoiY2VudGVyIiwieWF3X29mZnNldCI6MTksInBpdGNoX3NwZWVkIjowLCJkZWZlbnNpdmVfcGl0Y2giOiJvZmYiLCJwaXRjaF92YWx1ZSI6MCwiYm9keV9zbGlkZXIiOi01OCwiZGVsYXlfcmFuZG9tIjoxLCJkZWZfbW9kX2RtIjotNTAsInBlZWtfZGVmIjpmYWxzZSwiZGVmZW5zaXZlIjpmYWxzZSwibW9kX2RtIjotNywieWF3X3JhbmRvbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJqaXR0ZXIiLCJ+Il0sInlhd19kZWxheSI6NCwiZm9yY2VfZGVmIjpmYWxzZSwiZGVmZW5zaXZlX3lhdyI6Im9mZnNldCIsInBpdGNoIjoiZG93biIsInNwaW5fb2Zmc2V0IjozNjAsImRlZl9tb2RfdHlwZSI6InNraXR0ZXIiLCJ5YXdfdmFsdWUiOjMsIm1vZF9yYW5kb20iOjAsImRlZl9ib2R5X3lhd190eXBlIjoib2ZmIiwic3Bpbl9zcGVlZCI6MTAsImRlZl9ib2R5X3NsaWRlciI6MCwieWF3X292ZXJyaWRlIjp0cnVlLCJ5YXdfbGVmdCI6LTMsInlhd19yaWdodCI6OSwiYm9keV95YXdfdHlwZSI6InN0YXRpYyJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJvZmYiLCJ5YXdfb2Zmc2V0IjoxNywicGl0Y2hfc3BlZWQiOi0xLCJkZWZlbnNpdmVfcGl0Y2giOiJvZmYiLCJwaXRjaF92YWx1ZSI6ODksImJvZHlfc2xpZGVyIjotMTQ3LCJkZWxheV9yYW5kb20iOjIsImRlZl9tb2RfZG0iOi01MSwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmUiOmZhbHNlLCJtb2RfZG0iOi03LCJ5YXdfcmFuZG9tIjowLCJkZWZlbnNpdmVfc2VsZWN0IjpbImppdHRlciIsImJvZHkgWWF3IiwifiJdLCJ5YXdfZGVsYXkiOjEsImZvcmNlX2RlZiI6dHJ1ZSwiZGVmZW5zaXZlX3lhdyI6Im9mZnNldCIsInBpdGNoIjoiZG93biIsInNwaW5fb2Zmc2V0IjozNjAsImRlZl9tb2RfdHlwZSI6InNraXR0ZXIiLCJ5YXdfdmFsdWUiOjMsIm1vZF9yYW5kb20iOjAsImRlZl9ib2R5X3lhd190eXBlIjoiaml0dGVyIiwic3Bpbl9zcGVlZCI6MTAsImRlZl9ib2R5X3NsaWRlciI6MSwieWF3X292ZXJyaWRlIjp0cnVlLCJ5YXdfbGVmdCI6NCwieWF3X3JpZ2h0Ijo0LCJib2R5X3lhd190eXBlIjoiaml0dGVyIn0seyJlbmFibGUiOnRydWUsImRlZl9tb2RfcmFuZG9tIjowLCJtb2RfdHlwZSI6Im9mZiIsInlhd19vZmZzZXQiOjE2LCJwaXRjaF9zcGVlZCI6MCwiZGVmZW5zaXZlX3BpdGNoIjoib2ZmIiwicGl0Y2hfdmFsdWUiOjAsImJvZHlfc2xpZGVyIjotMTQwLCJkZWxheV9yYW5kb20iOjEsImRlZl9tb2RfZG0iOi01MSwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmUiOmZhbHNlLCJtb2RfZG0iOi0zMywieWF3X3JhbmRvbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJqaXR0ZXIiLCJib2R5IFlhdyIsIn4iXSwieWF3X2RlbGF5IjozLCJmb3JjZV9kZWYiOnRydWUsImRlZmVuc2l2ZV95YXciOiJvZmZzZXQiLCJwaXRjaCI6ImRvd24iLCJzcGluX29mZnNldCI6MzYwLCJkZWZfbW9kX3R5cGUiOiJza2l0dGVyIiwieWF3X3ZhbHVlIjoxMCwibW9kX3JhbmRvbSI6MCwiZGVmX2JvZHlfeWF3X3R5cGUiOiJqaXR0ZXIiLCJzcGluX3NwZWVkIjoxMCwiZGVmX2JvZHlfc2xpZGVyIjoxLCJ5YXdfb3ZlcnJpZGUiOnRydWUsInlhd19sZWZ0Ijo0LCJ5YXdfcmlnaHQiOjQsImJvZHlfeWF3X3R5cGUiOiJqaXR0ZXIifSx7ImVuYWJsZSI6dHJ1ZSwiZGVmX21vZF9yYW5kb20iOjEwLCJtb2RfdHlwZSI6Im9mZiIsInlhd19vZmZzZXQiOi0zLCJwaXRjaF9zcGVlZCI6MCwiZGVmZW5zaXZlX3BpdGNoIjoib2ZmIiwicGl0Y2hfdmFsdWUiOi04OSwiYm9keV9zbGlkZXIiOjEsImRlbGF5X3JhbmRvbSI6MiwiZGVmX21vZF9kbSI6MCwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmUiOmZhbHNlLCJtb2RfZG0iOjU1LCJ5YXdfcmFuZG9tIjowLCJkZWZlbnNpdmVfc2VsZWN0IjpbImppdHRlciIsImJvZHkgWWF3IiwifiJdLCJ5YXdfZGVsYXkiOjQsImZvcmNlX2RlZiI6dHJ1ZSwiZGVmZW5zaXZlX3lhdyI6InNwaW4iLCJwaXRjaCI6ImRvd24iLCJzcGluX29mZnNldCI6MzYwLCJkZWZfbW9kX3R5cGUiOiJvZmYiLCJ5YXdfdmFsdWUiOjE4MCwibW9kX3JhbmRvbSI6MTAsImRlZl9ib2R5X3lhd190eXBlIjoic3RhdGljIiwic3Bpbl9zcGVlZCI6OSwiZGVmX2JvZHlfc2xpZGVyIjoxLCJ5YXdfb3ZlcnJpZGUiOnRydWUsInlhd19sZWZ0Ijo0LCJ5YXdfcmlnaHQiOjQsImJvZHlfeWF3X3R5cGUiOiJqaXR0ZXIifSx7ImVuYWJsZSI6dHJ1ZSwiZGVmX21vZF9yYW5kb20iOjEwLCJtb2RfdHlwZSI6Im9mZiIsInlhd19vZmZzZXQiOjYsInBpdGNoX3NwZWVkIjowLCJkZWZlbnNpdmVfcGl0Y2giOiJvZmYiLCJwaXRjaF92YWx1ZSI6LTg5LCJib2R5X3NsaWRlciI6MSwiZGVsYXlfcmFuZG9tIjoxLCJkZWZfbW9kX2RtIjowLCJwZWVrX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZSI6ZmFsc2UsIm1vZF9kbSI6MzMsInlhd19yYW5kb20iOjAsImRlZmVuc2l2ZV9zZWxlY3QiOlsiaml0dGVyIiwiYm9keSBZYXciLCJ+Il0sInlhd19kZWxheSI6NSwiZm9yY2VfZGVmIjp0cnVlLCJkZWZlbnNpdmVfeWF3Ijoic3BpbiIsInBpdGNoIjoiZG93biIsInNwaW5fb2Zmc2V0IjozNjAsImRlZl9tb2RfdHlwZSI6Im9mZiIsInlhd192YWx1ZSI6MTgwLCJtb2RfcmFuZG9tIjoxMiwiZGVmX2JvZHlfeWF3X3R5cGUiOiJzdGF0aWMiLCJzcGluX3NwZWVkIjo1LCJkZWZfYm9keV9zbGlkZXIiOi0xLCJ5YXdfb3ZlcnJpZGUiOnRydWUsInlhd19sZWZ0IjotMjIsInlhd19yaWdodCI6MzksImJvZHlfeWF3X3R5cGUiOiJqaXR0ZXIifSx7ImVuYWJsZSI6ZmFsc2UsImRlZl9tb2RfcmFuZG9tIjowLCJtb2RfdHlwZSI6Im9mZiIsInlhd19vZmZzZXQiOjAsInBpdGNoX3NwZWVkIjowLCJkZWZlbnNpdmVfcGl0Y2giOiJvZmYiLCJwaXRjaF92YWx1ZSI6MCwiYm9keV9zbGlkZXIiOjAsImRlbGF5X3JhbmRvbSI6MSwiZGVmX21vZF9kbSI6MCwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmUiOmZhbHNlLCJtb2RfZG0iOjAsInlhd19yYW5kb20iOjAsImRlZmVuc2l2ZV9zZWxlY3QiOlsifiJdLCJ5YXdfZGVsYXkiOjEsImZvcmNlX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZV95YXciOiJvZmYiLCJwaXRjaCI6Im9mZiIsInNwaW5fb2Zmc2V0IjozNjAsImRlZl9tb2RfdHlwZSI6Im9mZiIsInlhd192YWx1ZSI6MCwibW9kX3JhbmRvbSI6MCwiZGVmX2JvZHlfeWF3X3R5cGUiOiJvZmYiLCJzcGluX3NwZWVkIjoxMCwiZGVmX2JvZHlfc2xpZGVyIjowLCJ5YXdfb3ZlcnJpZGUiOmZhbHNlLCJ5YXdfbGVmdCI6MCwieWF3X3JpZ2h0IjowLCJib2R5X3lhd190eXBlIjoib2ZmIn0seyJlbmFibGUiOnRydWUsImRlZl9tb2RfcmFuZG9tIjowLCJtb2RfdHlwZSI6Im9mZiIsInlhd19vZmZzZXQiOjE4MCwicGl0Y2hfc3BlZWQiOjAsImRlZmVuc2l2ZV9waXRjaCI6Im9mZiIsInBpdGNoX3ZhbHVlIjowLCJib2R5X3NsaWRlciI6MCwiZGVsYXlfcmFuZG9tIjoxLCJkZWZfbW9kX2RtIjowLCJwZWVrX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZSI6ZmFsc2UsIm1vZF9kbSI6MTA2LCJ5YXdfcmFuZG9tIjowLCJkZWZlbnNpdmVfc2VsZWN0IjpbIn4iXSwieWF3X2RlbGF5IjoxLCJmb3JjZV9kZWYiOnRydWUsImRlZmVuc2l2ZV95YXciOiJvZmYiLCJwaXRjaCI6Im9mZiIsInNwaW5fb2Zmc2V0IjozNjAsImRlZl9tb2RfdHlwZSI6Im9mZiIsInlhd192YWx1ZSI6MCwibW9kX3JhbmRvbSI6MCwiZGVmX2JvZHlfeWF3X3R5cGUiOiJvZmYiLCJzcGluX3NwZWVkIjoxMCwiZGVmX2JvZHlfc2xpZGVyIjowLCJ5YXdfb3ZlcnJpZGUiOmZhbHNlLCJ5YXdfbGVmdCI6MCwieWF3X3JpZ2h0IjowLCJib2R5X3lhd190eXBlIjoiaml0dGVyIn0seyJlbmFibGUiOnRydWUsImRlZl9tb2RfcmFuZG9tIjowLCJtb2RfdHlwZSI6Im9mZiIsInlhd19vZmZzZXQiOjUsInBpdGNoX3NwZWVkIjowLCJkZWZlbnNpdmVfcGl0Y2giOiJvZmYiLCJwaXRjaF92YWx1ZSI6LTg5LCJib2R5X3NsaWRlciI6MCwiZGVsYXlfcmFuZG9tIjoxLCJkZWZfbW9kX2RtIjowLCJwZWVrX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZSI6ZmFsc2UsIm1vZF9kbSI6MCwieWF3X3JhbmRvbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJqaXR0ZXIiLCJib2R5IFlhdyIsIn4iXSwieWF3X2RlbGF5IjoxLCJmb3JjZV9kZWYiOnRydWUsImRlZmVuc2l2ZV95YXciOiJvZmYiLCJwaXRjaCI6ImRvd24iLCJzcGluX29mZnNldCI6MzYwLCJkZWZfbW9kX3R5cGUiOiJvZmYiLCJ5YXdfdmFsdWUiOjAsIm1vZF9yYW5kb20iOjAsImRlZl9ib2R5X3lhd190eXBlIjoic3RhdGljIiwic3Bpbl9zcGVlZCI6MTAsImRlZl9ib2R5X3NsaWRlciI6LTEsInlhd19vdmVycmlkZSI6ZmFsc2UsInlhd19sZWZ0IjowLCJ5YXdfcmlnaHQiOjAsImJvZHlfeWF3X3R5cGUiOiJzdGF0aWMifSx7ImVuYWJsZSI6dHJ1ZSwiZGVmX21vZF9yYW5kb20iOjAsIm1vZF90eXBlIjoib2ZmIiwieWF3X29mZnNldCI6NSwicGl0Y2hfc3BlZWQiOjAsImRlZmVuc2l2ZV9waXRjaCI6Im9mZiIsInBpdGNoX3ZhbHVlIjowLCJib2R5X3NsaWRlciI6LTE4MCwiZGVsYXlfcmFuZG9tIjoxLCJkZWZfbW9kX2RtIjowLCJwZWVrX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZSI6ZmFsc2UsIm1vZF9kbSI6MCwieWF3X3JhbmRvbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJ+Il0sInlhd19kZWxheSI6MSwiZm9yY2VfZGVmIjp0cnVlLCJkZWZlbnNpdmVfeWF3Ijoib2Zmc2V0IiwicGl0Y2giOiJkb3duIiwic3Bpbl9vZmZzZXQiOjM2MCwiZGVmX21vZF90eXBlIjoib2ZmIiwieWF3X3ZhbHVlIjoxODAsIm1vZF9yYW5kb20iOjAsImRlZl9ib2R5X3lhd190eXBlIjoib2ZmIiwic3Bpbl9zcGVlZCI6MTAsImRlZl9ib2R5X3NsaWRlciI6MCwieWF3X292ZXJyaWRlIjp0cnVlLCJ5YXdfbGVmdCI6MCwieWF3X3JpZ2h0IjowLCJib2R5X3lhd190eXBlIjoic3RhdGljIn1dXQ=='}}
configs_db.menu_list = configs_db.menu_list or {'unmatched preset'}

configs_db.cfg_list[1][2] = "W3sidmlzdWFscyI6eyJkZWZlbnNpdmVfd2luZG93X3R5cGUiOiJNb2Rlcm4iLCJjcm9zc19jb2xvciI6dHJ1ZSwiZGVmZW5zaXZlX3dpbmRvd19jIjoiI0ZGRkZGRkZGIiwicmFnZWJvdF9sb2dzIjpbIkNvbnNvbGUiLCJTY3JlZW4iLCJ+Il0sInJhZ2Vib3RfbG9nc19taXNzIjoiI0JENjM2MEZGIiwiY3Jvc3NfY29sb3JfYyI6IiM2NDY0NjRGRiIsInJhZ2Vib3RfbG9nc19oaXQiOiIjNzRCRDYwRkYiLCJjcm9zc19pbmQiOnRydWUsImNyb3NzX2luZF9jIjoiI0M4QzhDOEZGIiwia2V5X2NvbG9yIjp0cnVlLCJ2ZWxvY2l0eV93aW5kb3dfYyI6IiNGRkZGRkZGRiIsImtleV9jb2xvcl9jIjoiI0ZGRkZGRkZGIiwiY3Jvc3NfaW5kX3R5cGUiOiJBbHRlcm5hdGl2ZSIsImRlZmVuc2l2ZV93aW5kb3ciOnRydWUsInZlbG9jaXR5X3dpbmRvd190eXBlIjoiTW9kZXJuIiwidmVsb2NpdHlfd2luZG93Ijp0cnVlfSwibWlzYyI6eyJwcmVkaWN0IjpmYWxzZSwiZmFzdF9sYWRkZXIiOnRydWUsInVuc2FmZV9yZWNoYXJnZSI6dHJ1ZSwidW5zYWZlX3R5cGUiOiJBbHRlcm5hdGl2ZSIsImFzcGVjdHJhdGlvIjp0cnVlLCJhaXJxc2JpbmQiOlsxLDYsIn4iXSwiY29uc29sZSI6dHJ1ZSwiYXNwZWN0cmF0aW9fdmFsdWUiOjEzMywiZGVmZW5zaXZlX2ZpeCI6dHJ1ZSwiYWlycXMiOnRydWUsInRoaXJkX3BlcnNvbiI6dHJ1ZSwiYW50aWJhY2tzdGFiIjp0cnVlLCJ0aGlyZF9wZXJzb25fdmFsdWUiOjQ1fSwibWFpbiI6eyJ0YWIiOiLimaYgQ29uZmlnIOKZpiJ9LCJhbnRpYWltIjp7InRhYiI6Ik1haW4iLCJkZWZlbnNpdmVfY29uZGl0aW9uIjpbIn4iXSwieWF3X29wdGlvbnMiOlsifiJdLCJrZXlfbGVmdCI6WzEsOTAsIn4iXSwic2FmZV9oZWFkIjpbIkFpcitDIEtuaWZlIiwiQWlyK0MgWmV1cyIsIkhlaWdodCBEaWZmZXJlbmNlIiwifiJdLCJmcl9vcHRpb25zIjpbIkZyZWVzdGFuZGluZyBPbiBRdWljayBQZWVrIiwifiJdLCJmcl9kaXNhYmxlcnMiOlsifiJdLCJhYV9vdmVycmlkZSI6WyJPbiBXYXJtdXAiLCJObyBFbmVtaWVzIEFsaXZlIiwifiJdLCJ5YXdfYmFzZSI6IkF0IHRhcmdldHMiLCJlZGdlX3lhdyI6WzEsMCwifiJdLCJrZXlfZm9yd2FyZCI6WzEsMCwifiJdLCJtYW51YWxfZGlyZWN0aW9uIjpmYWxzZSwiaGVpZ2h0X2RpZmZlcmVuY2UiOjIwMCwiY29uZGl0aW9uIjoiV2Fsa2luZyIsInlhd19kaXJlY3Rpb24iOnRydWUsImRlZmVuc2l2ZV90cmlnZ2VycyI6WyJ+Il0sImZyZWVzdGFuZGluZyI6WzEsMCwifiJdLCJrZXlfcmlnaHQiOlsxLDY3LCJ+Il19LCJjb25maWciOnsibGlzdCI6MSwibmFtZSI6IiJ9fSxbeyJlbmFibGUiOmZhbHNlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJPZmYiLCJ5YXdfb2Zmc2V0IjowLCJwZWVrX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZV9waXRjaCI6Ik9mZiIsImRlbGF5X3JhbmRvbSI6MSwiYm9keV9zbGlkZXIiOjAsImJvZHlfeWF3X3R5cGUiOiJPZmYiLCJ5YXdfcmFuZG9tIjowLCJkZWZfYm9keV9zbGlkZXIiOjAsImRlZmVuc2l2ZSI6ZmFsc2UsIm1vZF9kbSI6MCwiZGVmX21vZF9kbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJ+Il0sInlhd19yaWdodCI6MCwiZm9yY2VfZGVmIjpmYWxzZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6Ik9mZiIsImRlZmVuc2l2ZV95YXciOiJPZmYiLCJkZWZfbW9kX3R5cGUiOiJPZmYiLCJ5YXdfdmFsdWUiOjAsIm1vZF9yYW5kb20iOjAsInNwaW5fb2Zmc2V0IjozNjAsInNwaW5fc3BlZWQiOjEwLCJwaXRjaF9zcGVlZCI6MCwieWF3X292ZXJyaWRlIjpmYWxzZSwieWF3X2xlZnQiOjAsInBpdGNoX3ZhbHVlIjowLCJwaXRjaCI6IkRvd24ifSx7ImVuYWJsZSI6dHJ1ZSwiZGVmX21vZF9yYW5kb20iOjAsIm1vZF90eXBlIjoiU2tpdHRlciIsInlhd19vZmZzZXQiOjMsInBlZWtfZGVmIjpmYWxzZSwiZGVmZW5zaXZlX3BpdGNoIjoiT2ZmIiwiZGVsYXlfcmFuZG9tIjoxLCJib2R5X3NsaWRlciI6MSwiYm9keV95YXdfdHlwZSI6IkppdHRlciIsInlhd19yYW5kb20iOjAsImRlZl9ib2R5X3NsaWRlciI6MSwiZGVmZW5zaXZlIjp0cnVlLCJtb2RfZG0iOi0zMywiZGVmX21vZF9kbSI6LTUwLCJkZWZlbnNpdmVfc2VsZWN0IjpbIkppdHRlciIsIkJvZHkgWWF3IiwifiJdLCJ5YXdfcmlnaHQiOjAsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6IkppdHRlciIsImRlZmVuc2l2ZV95YXciOiJPZmZzZXQiLCJkZWZfbW9kX3R5cGUiOiJTa2l0dGVyIiwieWF3X3ZhbHVlIjozLCJtb2RfcmFuZG9tIjowLCJzcGluX29mZnNldCI6MzYwLCJzcGluX3NwZWVkIjoxMCwicGl0Y2hfc3BlZWQiOjEsInlhd19vdmVycmlkZSI6ZmFsc2UsInlhd19sZWZ0IjowLCJwaXRjaF92YWx1ZSI6ODksInBpdGNoIjoiRG93biJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJTa2l0dGVyIiwieWF3X29mZnNldCI6MywicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmVfcGl0Y2giOiJPZmYiLCJkZWxheV9yYW5kb20iOjEsImJvZHlfc2xpZGVyIjoxLCJib2R5X3lhd190eXBlIjoiSml0dGVyIiwieWF3X3JhbmRvbSI6MCwiZGVmX2JvZHlfc2xpZGVyIjowLCJkZWZlbnNpdmUiOnRydWUsIm1vZF9kbSI6LTQwLCJkZWZfbW9kX2RtIjotNjUsImRlZmVuc2l2ZV9zZWxlY3QiOlsiSml0dGVyIiwifiJdLCJ5YXdfcmlnaHQiOjAsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6IkppdHRlciIsImRlZmVuc2l2ZV95YXciOiJPZmZzZXQiLCJkZWZfbW9kX3R5cGUiOiJTa2l0dGVyIiwieWF3X3ZhbHVlIjozLCJtb2RfcmFuZG9tIjowLCJzcGluX29mZnNldCI6MzYwLCJzcGluX3NwZWVkIjoxMCwicGl0Y2hfc3BlZWQiOjIsInlhd19vdmVycmlkZSI6ZmFsc2UsInlhd19sZWZ0IjowLCJwaXRjaF92YWx1ZSI6ODksInBpdGNoIjoiRG93biJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJTa2l0dGVyIiwieWF3X29mZnNldCI6MTksInBlZWtfZGVmIjpmYWxzZSwiZGVmZW5zaXZlX3BpdGNoIjoiT2ZmIiwiZGVsYXlfcmFuZG9tIjoxLCJib2R5X3NsaWRlciI6MSwiYm9keV95YXdfdHlwZSI6IkppdHRlciIsInlhd19yYW5kb20iOjAsImRlZl9ib2R5X3NsaWRlciI6MCwiZGVmZW5zaXZlIjp0cnVlLCJtb2RfZG0iOi0zNSwiZGVmX21vZF9kbSI6LTUwLCJkZWZlbnNpdmVfc2VsZWN0IjpbIkppdHRlciIsIn4iXSwieWF3X3JpZ2h0IjozLCJmb3JjZV9kZWYiOnRydWUsInlhd19kZWxheSI6MSwiZGVmX2JvZHlfeWF3X3R5cGUiOiJPZmYiLCJkZWZlbnNpdmVfeWF3IjoiT2Zmc2V0IiwiZGVmX21vZF90eXBlIjoiU2tpdHRlciIsInlhd192YWx1ZSI6MywibW9kX3JhbmRvbSI6MCwic3Bpbl9vZmZzZXQiOjM2MCwic3Bpbl9zcGVlZCI6MTAsInBpdGNoX3NwZWVkIjowLCJ5YXdfb3ZlcnJpZGUiOnRydWUsInlhd19sZWZ0IjozLCJwaXRjaF92YWx1ZSI6MCwicGl0Y2giOiJEb3duIn0seyJlbmFibGUiOnRydWUsImRlZl9tb2RfcmFuZG9tIjowLCJtb2RfdHlwZSI6IlNraXR0ZXIiLCJ5YXdfb2Zmc2V0IjoxNywicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmVfcGl0Y2giOiJPZmYiLCJkZWxheV9yYW5kb20iOjEsImJvZHlfc2xpZGVyIjoxLCJib2R5X3lhd190eXBlIjoiSml0dGVyIiwieWF3X3JhbmRvbSI6MCwiZGVmX2JvZHlfc2xpZGVyIjoxLCJkZWZlbnNpdmUiOnRydWUsIm1vZF9kbSI6LTMzLCJkZWZfbW9kX2RtIjotNTEsImRlZmVuc2l2ZV9zZWxlY3QiOlsiSml0dGVyIiwiQm9keSBZYXciLCJ+Il0sInlhd19yaWdodCI6MywiZm9yY2VfZGVmIjp0cnVlLCJ5YXdfZGVsYXkiOjEsImRlZl9ib2R5X3lhd190eXBlIjoiSml0dGVyIiwiZGVmZW5zaXZlX3lhdyI6Ik9mZnNldCIsImRlZl9tb2RfdHlwZSI6IlNraXR0ZXIiLCJ5YXdfdmFsdWUiOjMsIm1vZF9yYW5kb20iOjAsInNwaW5fb2Zmc2V0IjozNjAsInNwaW5fc3BlZWQiOjEwLCJwaXRjaF9zcGVlZCI6LTEsInlhd19vdmVycmlkZSI6dHJ1ZSwieWF3X2xlZnQiOjMsInBpdGNoX3ZhbHVlIjo4OSwicGl0Y2giOiJEb3duIn0seyJlbmFibGUiOnRydWUsImRlZl9tb2RfcmFuZG9tIjowLCJtb2RfdHlwZSI6IlNraXR0ZXIiLCJ5YXdfb2Zmc2V0IjoxNiwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmVfcGl0Y2giOiJPZmYiLCJkZWxheV9yYW5kb20iOjEsImJvZHlfc2xpZGVyIjoxLCJib2R5X3lhd190eXBlIjoiSml0dGVyIiwieWF3X3JhbmRvbSI6MCwiZGVmX2JvZHlfc2xpZGVyIjoxLCJkZWZlbnNpdmUiOnRydWUsIm1vZF9kbSI6LTMzLCJkZWZfbW9kX2RtIjotNTEsImRlZmVuc2l2ZV9zZWxlY3QiOlsiSml0dGVyIiwiQm9keSBZYXciLCJ+Il0sInlhd19yaWdodCI6MTAsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6IkppdHRlciIsImRlZmVuc2l2ZV95YXciOiJPZmZzZXQiLCJkZWZfbW9kX3R5cGUiOiJTa2l0dGVyIiwieWF3X3ZhbHVlIjoxMCwibW9kX3JhbmRvbSI6MCwic3Bpbl9vZmZzZXQiOjM2MCwic3Bpbl9zcGVlZCI6MTAsInBpdGNoX3NwZWVkIjowLCJ5YXdfb3ZlcnJpZGUiOnRydWUsInlhd19sZWZ0IjoxMCwicGl0Y2hfdmFsdWUiOjAsInBpdGNoIjoiRG93biJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MTAsIm1vZF90eXBlIjoiQ2VudGVyIiwieWF3X29mZnNldCI6NiwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmVfcGl0Y2giOiJDdXN0b20iLCJkZWxheV9yYW5kb20iOjEsImJvZHlfc2xpZGVyIjoxLCJib2R5X3lhd190eXBlIjoiSml0dGVyIiwieWF3X3JhbmRvbSI6MTIsImRlZl9ib2R5X3NsaWRlciI6MSwiZGVmZW5zaXZlIjp0cnVlLCJtb2RfZG0iOjU1LCJkZWZfbW9kX2RtIjowLCJkZWZlbnNpdmVfc2VsZWN0IjpbIkppdHRlciIsIkJvZHkgWWF3IiwifiJdLCJ5YXdfcmlnaHQiOjcsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6IlN0YXRpYyIsImRlZmVuc2l2ZV95YXciOiJTcGluIiwiZGVmX21vZF90eXBlIjoiT2ZmIiwieWF3X3ZhbHVlIjoxODAsIm1vZF9yYW5kb20iOjEwLCJzcGluX29mZnNldCI6MzYwLCJzcGluX3NwZWVkIjo5LCJwaXRjaF9zcGVlZCI6MCwieWF3X292ZXJyaWRlIjpmYWxzZSwieWF3X2xlZnQiOjcsInBpdGNoX3ZhbHVlIjotODksInBpdGNoIjoiRG93biJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MTAsIm1vZF90eXBlIjoiQ2VudGVyIiwieWF3X29mZnNldCI6NiwicGVla19kZWYiOmZhbHNlLCJkZWZlbnNpdmVfcGl0Y2giOiJDdXN0b20iLCJkZWxheV9yYW5kb20iOjEsImJvZHlfc2xpZGVyIjoxLCJib2R5X3lhd190eXBlIjoiSml0dGVyIiwieWF3X3JhbmRvbSI6MTMsImRlZl9ib2R5X3NsaWRlciI6LTEsImRlZmVuc2l2ZSI6dHJ1ZSwibW9kX2RtIjo1MCwiZGVmX21vZF9kbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJKaXR0ZXIiLCJCb2R5IFlhdyIsIn4iXSwieWF3X3JpZ2h0IjoyMiwiZm9yY2VfZGVmIjp0cnVlLCJ5YXdfZGVsYXkiOjEsImRlZl9ib2R5X3lhd190eXBlIjoiU3RhdGljIiwiZGVmZW5zaXZlX3lhdyI6IlNwaW4iLCJkZWZfbW9kX3R5cGUiOiJPZmYiLCJ5YXdfdmFsdWUiOjE4MCwibW9kX3JhbmRvbSI6MTAsInNwaW5fb2Zmc2V0IjozNjAsInNwaW5fc3BlZWQiOjUsInBpdGNoX3NwZWVkIjowLCJ5YXdfb3ZlcnJpZGUiOmZhbHNlLCJ5YXdfbGVmdCI6MCwicGl0Y2hfdmFsdWUiOi04OSwicGl0Y2giOiJEb3duIn0seyJlbmFibGUiOmZhbHNlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJPZmYiLCJ5YXdfb2Zmc2V0IjowLCJwZWVrX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZV9waXRjaCI6Ik9mZiIsImRlbGF5X3JhbmRvbSI6MSwiYm9keV9zbGlkZXIiOjAsImJvZHlfeWF3X3R5cGUiOiJPZmYiLCJ5YXdfcmFuZG9tIjowLCJkZWZfYm9keV9zbGlkZXIiOjAsImRlZmVuc2l2ZSI6ZmFsc2UsIm1vZF9kbSI6MCwiZGVmX21vZF9kbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJ+Il0sInlhd19yaWdodCI6MCwiZm9yY2VfZGVmIjpmYWxzZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6Ik9mZiIsImRlZmVuc2l2ZV95YXciOiJPZmYiLCJkZWZfbW9kX3R5cGUiOiJPZmYiLCJ5YXdfdmFsdWUiOjAsIm1vZF9yYW5kb20iOjAsInNwaW5fb2Zmc2V0IjozNjAsInNwaW5fc3BlZWQiOjEwLCJwaXRjaF9zcGVlZCI6MCwieWF3X292ZXJyaWRlIjpmYWxzZSwieWF3X2xlZnQiOjAsInBpdGNoX3ZhbHVlIjowLCJwaXRjaCI6Ik9mZiJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJPZmYiLCJ5YXdfb2Zmc2V0IjoxODAsInBlZWtfZGVmIjpmYWxzZSwiZGVmZW5zaXZlX3BpdGNoIjoiT2ZmIiwiZGVsYXlfcmFuZG9tIjoxLCJib2R5X3NsaWRlciI6MCwiYm9keV95YXdfdHlwZSI6IkppdHRlciIsInlhd19yYW5kb20iOjAsImRlZl9ib2R5X3NsaWRlciI6MCwiZGVmZW5zaXZlIjpmYWxzZSwibW9kX2RtIjoxMDYsImRlZl9tb2RfZG0iOjAsImRlZmVuc2l2ZV9zZWxlY3QiOlsifiJdLCJ5YXdfcmlnaHQiOjAsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6Ik9mZiIsImRlZmVuc2l2ZV95YXciOiJPZmYiLCJkZWZfbW9kX3R5cGUiOiJPZmYiLCJ5YXdfdmFsdWUiOjAsIm1vZF9yYW5kb20iOjAsInNwaW5fb2Zmc2V0IjozNjAsInNwaW5fc3BlZWQiOjEwLCJwaXRjaF9zcGVlZCI6MCwieWF3X292ZXJyaWRlIjpmYWxzZSwieWF3X2xlZnQiOjAsInBpdGNoX3ZhbHVlIjowLCJwaXRjaCI6Ik9mZiJ9LHsiZW5hYmxlIjp0cnVlLCJkZWZfbW9kX3JhbmRvbSI6MCwibW9kX3R5cGUiOiJPZmYiLCJ5YXdfb2Zmc2V0Ijo1LCJwZWVrX2RlZiI6ZmFsc2UsImRlZmVuc2l2ZV9waXRjaCI6IkN1c3RvbSIsImRlbGF5X3JhbmRvbSI6MSwiYm9keV9zbGlkZXIiOjEsImJvZHlfeWF3X3R5cGUiOiJTdGF0aWMiLCJ5YXdfcmFuZG9tIjowLCJkZWZfYm9keV9zbGlkZXIiOi0xLCJkZWZlbnNpdmUiOnRydWUsIm1vZF9kbSI6MCwiZGVmX21vZF9kbSI6MCwiZGVmZW5zaXZlX3NlbGVjdCI6WyJCb2R5IFlhdyIsIn4iXSwieWF3X3JpZ2h0IjowLCJmb3JjZV9kZWYiOnRydWUsInlhd19kZWxheSI6MSwiZGVmX2JvZHlfeWF3X3R5cGUiOiJTdGF0aWMiLCJkZWZlbnNpdmVfeWF3IjoiT2ZmIiwiZGVmX21vZF90eXBlIjoiT2ZmIiwieWF3X3ZhbHVlIjowLCJtb2RfcmFuZG9tIjowLCJzcGluX29mZnNldCI6MzYwLCJzcGluX3NwZWVkIjoxMCwicGl0Y2hfc3BlZWQiOjAsInlhd19vdmVycmlkZSI6ZmFsc2UsInlhd19sZWZ0IjowLCJwaXRjaF92YWx1ZSI6LTg5LCJwaXRjaCI6IkRvd24ifSx7ImVuYWJsZSI6dHJ1ZSwiZGVmX21vZF9yYW5kb20iOjAsIm1vZF90eXBlIjoiT2ZmIiwieWF3X29mZnNldCI6MjUsInBlZWtfZGVmIjpmYWxzZSwiZGVmZW5zaXZlX3BpdGNoIjoiQ3VzdG9tIiwiZGVsYXlfcmFuZG9tIjoxLCJib2R5X3NsaWRlciI6MSwiYm9keV95YXdfdHlwZSI6IlN0YXRpYyIsInlhd19yYW5kb20iOjAsImRlZl9ib2R5X3NsaWRlciI6MCwiZGVmZW5zaXZlIjp0cnVlLCJtb2RfZG0iOjAsImRlZl9tb2RfZG0iOjAsImRlZmVuc2l2ZV9zZWxlY3QiOlsifiJdLCJ5YXdfcmlnaHQiOjAsImZvcmNlX2RlZiI6dHJ1ZSwieWF3X2RlbGF5IjoxLCJkZWZfYm9keV95YXdfdHlwZSI6Ik9mZiIsImRlZmVuc2l2ZV95YXciOiJPZmZzZXQiLCJkZWZfbW9kX3R5cGUiOiJPZmYiLCJ5YXdfdmFsdWUiOjE4MCwibW9kX3JhbmRvbSI6MCwic3Bpbl9vZmZzZXQiOjM2MCwic3Bpbl9zcGVlZCI6MTAsInBpdGNoX3NwZWVkIjowLCJ5YXdfb3ZlcnJpZGUiOmZhbHNlLCJ5YXdfbGVmdCI6MCwicGl0Y2hfdmFsdWUiOjAsInBpdGNoIjoiRG93biJ9XV0="

cfg_system.save_config = function(id)
    if id == 1 then return end
    if configs_db.cfg_list[id] == nil then
        print("Error: config with id "..id.." does not exist.")
        return
    end

    if configs_db.cfg_list[id][2] == nil then
        print("Error: second part of config with id "..id.." does not exist.")
        return
    end
    
    local raw = package:save()
    configs_db.cfg_list[id][2] = base64.encode(json.stringify(raw))
    database.write(lua_db.configs, configs_db)
end


cfg_system.update_values = function(id)
    local name = configs_db.cfg_list[id][1]
    local new_name = name..'\v - Active'
    for k, v in ipairs(configs_db.cfg_list) do
        configs_db.menu_list[k] = v[1]
    end
    configs_db.menu_list[id] = new_name
end

cfg_system.create_config = function(name)
    if type(name) ~= 'string' then return end

    if name == nil or name == '' or name == ' ' then
        print('Wrong Name')
        return
    end

    for i= #configs_db.menu_list, 1, -1 do
        if configs_db.menu_list[i] == name then
            print('Another config has the same name')
            return
        end
    end

    if #configs_db.cfg_list > 9 then
        print('Maximum number of configs: 10')
        return
    end

    local completed = {name, ''}
    table.insert(configs_db.cfg_list, completed)
    table.insert(configs_db.menu_list, name)
    database.write(lua_db.configs, configs_db)
end

cfg_system.remove_config = function(id)
    if id == 1 then return end
    local item = configs_db.cfg_list[id][1]

    for i= #configs_db.cfg_list, 1, -1 do
        if configs_db.cfg_list[i][1] == item then
            table.remove(configs_db.cfg_list, i)
            table.remove(configs_db.menu_list, i)
        end
    end

    database.write(lua_db.configs, configs_db)
end

cfg_system.load_config = function(id)
    if configs_db.cfg_list[id][2] == nil or configs_db.cfg_list[id][2] == '' then
        print("Problem with: "..id.." Config")
        return
    end

    if id > #configs_db.cfg_list then
        print("Problem with: "..id.." Config")
        return
    end

    package:load(json.parse(base64.decode(configs_db.cfg_list[id][2])))
end

lua_menu.config.create:set_callback(function() 
    cfg_system.create_config(lua_menu.config.name:get())
    lua_menu.config.list:update(configs_db.menu_list)
end)

lua_menu.config.load:set_callback(function() 
    cfg_system.update_values(lua_menu.config.list:get() + 1)
    cfg_system.load_config(lua_menu.config.list:get() + 1)
    lua_menu.config.list:update(configs_db.menu_list)
end)

lua_menu.config.save:set_callback(function() 
    cfg_system.save_config(lua_menu.config.list:get() + 1)
end)

lua_menu.config.delete:set_callback(function() 
    cfg_system.remove_config(lua_menu.config.list:get() + 1)
    lua_menu.config.list:update(configs_db.menu_list)
end)

lua_menu.config.import:set_callback(function() 
    package:load(json.parse(base64.decode(clipboard.get())))
end)

lua_menu.config.export:set_callback(function() 
    clipboard.set(base64.encode(json.stringify(package:save())))
end)
lua_menu.config.list:update(configs_db.menu_list)

client.set_event_callback("setup_command", function(cmd)
    aa_setup(cmd)

    if lua_menu.misc.fast_ladder:get() then
        fastladder(cmd)
    end
end)


client.set_event_callback('net_update_end', function()
    clantag()
end)

client.set_event_callback('paint', function()

    ragebot_logs()

    text_fade_animation(25, center[2] - 20, -1, {r=200, g=200, b=200, a=255}, {r=150, g=150, b=150, a=255}, "lurith ~ gamesense /  ", "")
    renderer.text(25 + renderer.measure_text('', 'lurith ~ gamesense / '), center[2] - 20, 200, 200, 200, 255, '', 0, '\aA4B2F1FFrecode')

    if lua_menu.visuals.velocity_window:get() then
        velocity_ind()
    end
    if lua_menu.visuals.defensive_window:get() then
        defensive_ind()
    end
end)

client.set_event_callback('shutdown', function()
    hide_original_menu(true)
    database.write(lua_db.configs, configs_db)
end)

client.set_event_callback('paint_ui', function()
    hide_original_menu(false)
end)


client.set_event_callback("level_init", function()
    console_filter(lua_menu.misc.console:get())
    alive_players = {}
    logs = {}
    breaker.cmd = 0
    breaker.defensive = 0
    breaker.defensive_check = 0
end)

client.set_event_callback("round_start", function()
    console_filter(lua_menu.misc.console:get())
    alive_players = {}
    logs = {}
    breaker.cmd = 0
    breaker.defensive = 0
    breaker.defensive_check = 0
end)