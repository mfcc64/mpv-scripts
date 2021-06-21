-- various audio visualization



local opts = {
    mode = "force",
    -- off              disable visualization
    -- force           always enable visualization



    name = "off",
    -- off
    -- akatecktronik
	-- zero



    quality = "medium",
    -- medium




}



-- key bindings
-- cycle visualizer
local cycle_key = "y"



if not (mp.get_property("options/lavfi-complex", "") == "") then
    return
end



local visualizer_name_list = {
    "off",
    "akatecktronik",
	"zero",
}





local options = require 'mp.options'
local msg     = require 'mp.msg'



options.read_options(opts)




local function get_visualizer(name, quality)
    local w, h, fps




-- Here we define the quality
    if quality == "medium" then
        w = 1280
        h = 720
        fps = 60
    else
        msg.log("error", "invalid quality")
        return ""
    end



-- Here we define the Graph
   if name == "akatecktronik" then
        return "color=c=black:s="..w.."x"..h.."[black];[vid1]split=3[v1][v2][v3];[aid1]asplit[a1][a2];[a1]avectorscope=s=240x160:zoom=2:rc=2:gc=200:bc=10:rf=1:gf=8:bf=7[avect-out];[a2]showvolume=r=25:w=140:h=10:t=0:f=0.9[vol-out];[v1]scale=640x360[v1-o];[v2]hflip,waveform=m=1:d=0:r=1:c=7,scale=640x360,setsar=1,hflip[v2-o];[v3]vectorscope=m=0:g=green,scale=300x300,setsar=1[vect];[black][v1-o]overlay=0:0[q1];[q1][vol-out]overlay=640:0[q2];[q2][v2-o]overlay=0:360[q3];[q3][avect-out]overlay=1000:490[q4];[q4][vect]overlay=700:390[vo]"
	elseif name == "zero" then
        return "[vid1]"..
		"scale".."="..w.."x"..h.."[vo]"
	elseif name == "off" then
        return "[aid1] afifo [ao]"
    end
    msg.log("error", "invalid visualizer name")
    return ""
end



local function select_visualizer(atrack, vtrack, albumart)
    if opts.mode == "off" then
        return ""
    elseif opts.mode == "force" then
        return get_visualizer(opts.name, opts.quality)



    end



    msg.log("error", "invalid mode")
    return ""
end



local function visualizer_hook()
    local count = mp.get_property_number("track-list/count", -1)
    local atrack = 0
    local vtrack = 0
    local albumart = 0
    if count <= 0 then
        return
    end
    for tr = 0,count-1 do
        if mp.get_property("track-list/" .. tr .. "/type") == "audio" then
            atrack = atrack + 1
        else
            if mp.get_property("track-list/" .. tr .. "/type") == "video" then
                if mp.get_property("track-list/" .. tr .. "/albumart") == "yes" then
                    albumart = albumart + 1
                else
                    vtrack = vtrack + 1
                end
            end
        end
    end



    mp.set_property("options/lavfi-complex", select_visualizer(atrack, vtrack, albumart))
end



mp.add_hook("on_preloaded", 50, visualizer_hook)



local function cycle_visualizer()
    local i, index = 1
    for i = 1, #visualizer_name_list do
        if (visualizer_name_list[i] == opts.name) then
            index = i + 1
            if index > #visualizer_name_list then
                index = 1
            end
            break
        end
    end
    opts.name = visualizer_name_list[index]
    visualizer_hook()
end



mp.add_key_binding(cycle_key, "cycle-visualizer", cycle_visualizer)
