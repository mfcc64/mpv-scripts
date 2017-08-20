--[[
Linear Phase 15-Bands Equalizer
Key:
   - toggle equalizer control: ctrl+e
   - prev/next gain control: UP / DOWN
   - decrease/increase gain: LEFT / RIGHT
   - copy gain value from prev gain control: [
   - copy gain value from next gain control: ]
Note that ~~/lua-settings directory should exist to save gain values.
--]]

local options = require "mp.options"
local msg = require "mp.msg"

local key_toggle_control = "ctrl+e"
local key_prev_entry = "UP"
local key_next_entry = "DOWN"
local key_decrease = "LEFT"
local key_increase = "RIGHT"
local key_copy_prev = "["
local key_copy_next = "]"

local control_enabled = false
local num_entry = 15
local selected_entry = 0
local min_val = -360
local max_val = 120
local stale_gain_entry = ""

local function eq(x)
    return "eq" .. x
end

local gain_table = {
    eq0 = 0,
    eq1 = 0,
    eq2 = 0,
    eq3 = 0,
    eq4 = 0,
    eq5 = 0,
    eq6 = 0,
    eq7 = 0,
    eq8 = 0,
    eq9 = 0,
    eq10 = 0,
    eq11 = 0,
    eq12 = 0,
    eq13 = 0,
    eq14 = 0
}

local freq_label = {
    eq0  = "#   0 Hz:",
    eq1  = "#  65 Hz:",
    eq2  = "# 157 Hz:",
    eq3  = "# 288 Hz:",
    eq4  = "# 472 Hz:",
    eq5  = "# 733 Hz:",
    eq6  = "# 1k1 Hz:",
    eq7  = "# 1k6 Hz:",
    eq8  = "# 2k4 Hz:",
    eq9  = "# 3k4 Hz:",
    eq10 = "# 4k9 Hz:",
    eq11 = "# 7k0 Hz:",
    eq12 = "# 10k Hz:",
    eq13 = "# 14k Hz:",
    eq14 = "# 20k Hz:"
}

options.read_options(gain_table)

for x = 0, num_entry-1 do
    gain_table[eq(x)] = math.min(math.max(gain_table[eq(x)], min_val), max_val)
end

local function save_gain_table()
    local settingdir = mp.find_config_file("lua-settings")
    local fp = settingdir and io.open(settingdir .. "/" .. mp.get_script_name() .. ".conf", "w")
    if fp == nil then
        msg.warn("Cannot save gain table.")
    else
        for x = 0, num_entry-1 do
            fp:write(eq(x) .. "=" .. gain_table[eq(x)] .. "\n")
        end
        fp:close()
    end
end

local normalcolor = "ffffff"
local selectedcolor = "00ffff"
local fontsize = 70
local fontfamily = "mono"
local pdefault  = "{\\fn" .. fontfamily .. "\\fscx" .. fontsize .. "\\fscy" .. fontsize .. "\\1c&" .. normalcolor .. "&}"
local pselected = "{\\fn" .. fontfamily .. "\\fscx" .. fontsize .. "\\fscy" .. fontsize .. "\\1c&" .. selectedcolor .. "&}"

local function gain_line(x)
    local val = gain_table[eq(x)] - min_val;
    local str = ""
    local x = 10
    while x <= val do
        str = str .. "="
        x = x + 20
    end
    return str
end

local function show_osd_ass()
    local str = pdefault  .. "Linear Phase 15-Bands Equalizer\n"
    for x = 0, num_entry-1 do
        local pval = pdefault
        if x == selected_entry then
            pval = pselected
        end
        str = str .. pval .. freq_label[eq(x)] .. string.format("%7.1f", gain_table[eq(x)]*0.1) .. " dB |" .. gain_line(x) .. "\n"
    end
    mp.set_osd_ass(0, 0, str)
end

local function hide_osd_ass()
    mp.set_osd_ass(0, 0, "{}")
end

local function gen_gain_entry()
    local str = string.format("entry(0,%.1f)", gain_table[eq(0)]*0.1)
    for x = 1, num_entry-1 do
        str = str .. string.format(";entry(%d,%.1f)", x, gain_table[eq(x)]*0.1)
    end
    return str
end

local function insert_filter(gain_entry)
    local graph = "firequalizer = " ..
        "wfunc      = tukey:" ..
        "delay      = 0.028:" ..
        "scale      = linlog:" ..
        "zero_phase = on:" ..
        "gain_entry = '" .. gain_entry .. "':" ..
        "gain       = 'cubic_interpolate(2.8853900817779269*log(f/157.48+1))'"
    mp.commandv("af", "add", "@" .. mp.get_script_name() .. ":lavfi=graph=[" .. graph .. "]")
end

local function audio_reconfig()
    local gain_entry = gen_gain_entry()
    if not (stale_gain_entry == gain_entry) then
        insert_filter(gain_entry)
        stale_gain_entry = gain_entry
    end
end

audio_reconfig()
mp.register_event("playback-restart", audio_reconfig)

local function send_command()
    mp.commandv("af-command", mp.get_script_name(), "gain_entry", gen_gain_entry())
end

local function prev_entry()
    selected_entry = math.max(selected_entry-1, 0)
    show_osd_ass()
end

local function next_entry()
    selected_entry = math.min(selected_entry+1, num_entry-1)
    show_osd_ass()
end

local function decrease_gain()
    gain_table[eq(selected_entry)] = math.max(gain_table[eq(selected_entry)]-1, min_val)
    send_command()
    show_osd_ass()
    save_gain_table()
end

local function increase_gain()
    gain_table[eq(selected_entry)] = math.min(gain_table[eq(selected_entry)]+1, max_val)
    send_command()
    show_osd_ass()
    save_gain_table()
end

local function copy_prev()
    gain_table[eq(selected_entry)] = gain_table[eq(math.max(selected_entry-1, 0))]
    send_command()
    show_osd_ass()
    save_gain_table()
end

local function copy_next()
    gain_table[eq(selected_entry)] = gain_table[eq(math.min(selected_entry+1, num_entry-1))]
    send_command()
    show_osd_ass()
    save_gain_table()
end

local function binding_name(name)
    return mp.get_script_name() .. "-" .. name
end

local function toggle_control()
    control_enabled = not control_enabled
    if control_enabled then
        show_osd_ass()
        mp.add_forced_key_binding(key_prev_entry, binding_name("prev"), prev_entry, {repeatable=true})
        mp.add_forced_key_binding(key_next_entry, binding_name("next"), next_entry, {repeatable=true})
        mp.add_forced_key_binding(key_decrease, binding_name("decrease"), decrease_gain, {repeatable=true})
        mp.add_forced_key_binding(key_increase, binding_name("increase"), increase_gain, {repeatable=true})
        mp.add_forced_key_binding(key_copy_prev, binding_name("copy_prev"), copy_prev)
        mp.add_forced_key_binding(key_copy_next, binding_name("copy_next"), copy_next)
    else
        hide_osd_ass()
        mp.remove_key_binding(binding_name("prev"))
        mp.remove_key_binding(binding_name("next"))
        mp.remove_key_binding(binding_name("decrease"))
        mp.remove_key_binding(binding_name("increase"))
        mp.remove_key_binding(binding_name("copy_prev"))
        mp.remove_key_binding(binding_name("copy_next"))
    end
end

mp.add_forced_key_binding(key_toggle_control, binding_name("toggle_control"), toggle_control)
