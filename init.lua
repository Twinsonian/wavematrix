local music_dir = minetest.get_modpath("wavematrix") .. "/sounds"
local tracks = {}
local current_track = nil
local handle = nil
local playing = false
local playback_mode = "shuffle"
local music_volume = 0.3 -- default to 30%
local active_huds = {}
local delay_active = false
local delay_duration = 0
local delay_elapsed = 0

-- Load and sort music files
local function load_tracks()
    tracks = {}
    for _, file in ipairs(minetest.get_dir_list(music_dir, false)) do
        if file:match("%.ogg$") then
            local name = file:match("(.+)%.ogg$")
            table.insert(tracks, name)
        end
    end
    table.sort(tracks)
end

-- HUD notification
local function notify(player, text)
    local name = player:get_player_name()
    if active_huds[name] then
        player:hud_remove(active_huds[name])
        active_huds[name] = nil
    end
    local hud_id = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.05, y = 0.1},
        offset = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        scale = {x = 100, y = 100},
        text = text,
        number = 0xFFFFFF,
    })
    active_huds[name] = hud_id

    minetest.after(10, function()
        if active_huds[name] == hud_id then
            player:hud_remove(hud_id)
            active_huds[name] = nil
        end
    end)
end

-- Play a track
local function play_track(name, player)
    if handle then
        minetest.sound_stop(handle)
    end
    handle = minetest.sound_play(name, {gain = music_volume})
    current_track = name
    playing = true

    local suffix = ""
    if playback_mode == "loop" then
        suffix = " | Loop On"
    elseif playback_mode == "shuffle" then
        suffix = " | Shuffle On"
    end
    notify(player, "Playing: " .. name .. suffix)
end

-- Stop playback
local function stop_track(player)
    if handle then
        minetest.sound_stop(handle)
        handle = nil
    end
    playing = false
    delay_active = false
    delay_duration = 0
    delay_elapsed = 0
    notify(player, "Stopped")
end

-- Get next track in order
local function get_next_track()
    if not current_track then return tracks[1] end
    for i, name in ipairs(tracks) do
        if name == current_track then
            return tracks[(i % #tracks) + 1]
        end
    end
    return tracks[1]
end

-- Delay before next track
local function delayed_next(player, elapsed_override)
    if delay_active or not playing then return end
    delay_active = true
    delay_duration = math.random(300, 420)
    delay_elapsed = elapsed_override or 0
    minetest.after(delay_duration - delay_elapsed, function()
        delay_active = false
        delay_duration = 0
        delay_elapsed = 0
        if not playing then return end
        local next_track = current_track
        if playback_mode == "shuffle" then
            next_track = tracks[math.random(#tracks)]
        elseif playback_mode == "loop" then
            -- keep current_track
        else
            next_track = get_next_track()
        end
        play_track(next_track, player)
    end)
end

-- Register starter item
minetest.register_craftitem("wavematrix:music_controller", {
    description = "Wave Matrix Music Controller",
    inventory_image = "wavematrix_button.png",
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if minetest.chatcommands["wm"] then
            minetest.chatcommands["wm"].func(name)
        end
        return itemstack
    end,
})

-- Crafting recipe for controller
minetest.register_craft({
    output = "wavematrix:music_controller",
    recipe = {
        {"group:stone", "group:stone", "group:stone"},
        {"group:stone", "", "group:stone"},
        {"group:stone", "group:stone", "group:stone"},
    }
})

-- On join: give starter item and start music
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    local meta = player:get_meta()

    if not meta:get("wavematrix_received") then
        local inv = player:get_inventory()
        if not inv:contains_item("main", "wavematrix:music_controller") then
            inv:add_item("main", "wavematrix:music_controller")
        end
        meta:set_string("wavematrix_received", "true")
    end

    load_tracks()
    if not playing and #tracks > 0 then
        current_track = tracks[math.random(#tracks)]
        playing = true
        delayed_next(player, 270) -- simulate initial delay
    end
end)

-- GUI command
minetest.register_chatcommand("wm", {
    description = "Open Wave Matrix music player",
    func = function(name)
        load_tracks()
        local track_list = table.concat(tracks, ",")
        minetest.show_formspec(name, "wavematrix:player",
            "size[8,6]" ..
            "label[2.75,0;Wave Matrix Music Player]" ..
            "dropdown[0.5,1;7;track;" .. track_list .. ";1]" ..
            "button[2.35,2;1.5,1;play;Play]" ..
            "button[3.85,2;1.5,1;stop;Stop]" ..
            "label[0.5,3.2;Playback Mode:]" ..
            "dropdown[0.5,3.7;4;mode;play in order,loop,shuffle;" ..
                (playback_mode == "order" and "1" or playback_mode == "loop" and "2" or "3") .. "]" ..
            "label[0.5,4.5;Volume:]" ..
            "dropdown[0.5,5;4;volume;10,20,30,40,50,60,70,80,90,100;" .. math.floor(music_volume * 10) .. "]" ..
            "button[5,5;2,1;setvol;Set Volume]"
        )
    end
})

-- Handle GUI input
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "wavematrix:player" then return end
    local name = player:get_player_name()

    if fields.track then
        current_track = fields.track
    end
    if fields.play then
        if playback_mode == "shuffle" then
            current_track = tracks[math.random(#tracks)]
        elseif playback_mode == "order" and not current_track then
            current_track = tracks[1]
        end
        play_track(current_track, player)
    end
    if fields.stop then
        stop_track(player)
    end
    if fields.mode then
        playback_mode = fields.mode
    end
    if fields.setvol and fields.volume then
        local percent = tonumber(fields.volume)
        if percent and percent >= 10 and percent <= 100 then
            music_volume = percent / 100
            minetest.chat_send_player(name, "Volume set to " .. percent .. "%")

            -- Restart current track with new volume
            if playing and current_track then
                play_track(current_track, player)
            end
        else
            minetest.chat_send_player(name, "Invalid volume. Choose between 10 and 100.")
        end
    end

end)

-- Debug command
minetest.register_chatcommand("wmdebug", {
    description = "Show time remaining until next track",
    func = function(name)
        local message
        if not delay_active then
            message = "No delay active. Music may be stopped or just started."
        else
            local remaining = delay_duration - delay_elapsed
            message = "Time remaining until next track: " .. remaining .. " seconds"
        end
        minetest.chat_send_player(name, message)
        return true
    end
})

-- Globalstep to track delay time
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer >= 1 then
        timer = 0
        if delay_active then
            delay_elapsed = delay_elapsed + 1
        end
        for _, player in ipairs(minetest.get_connected_players()) do
            if playing then
                delayed_next(player)
            end
        end
    end
end)

