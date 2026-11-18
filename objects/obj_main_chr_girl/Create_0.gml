enum HeroFacing { Down, Up, Right, Left }

// spr_main_chr starts with a front idle, then has four six-frame walk cycles.
walk_start_frames = [1, 7, 13, 19];
idle_frames = [0, 7, 13, 19];
walk_frame_count = 6;
walk_frames_per_step = 8 / game_get_speed(gamespeed_fps);
walk_phase = 0;
move_speed = 150 / game_get_speed(gamespeed_fps);
facing = HeroFacing.Down;

image_speed = 0;
image_index = idle_frames[facing];

if (variable_global_exists("windmill_return") && is_struct(global.windmill_return))
{
    var entrance = global.windmill_return;
    if (room == entrance.room_id)
    {
        x = entrance.x;
        y = entrance.y;
        global.windmill_return = undefined;
    }
}

depth = -round(y);
