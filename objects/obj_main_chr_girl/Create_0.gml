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

inventory_open = false;
inventory_columns = 9;
inventory_rows = 3;
inventory_selected_slot = 0;
inventory_surface = -1;

ini_open("settings.ini");
var old_ui_size = clamp(round(ini_read_real("display", "ui_size", 1)), 0, 2);
inventory_scale = clamp(ini_read_real("display", "ui_scale_percent", 80 + old_ui_size * 20), 80, 120) / 100;
ini_close();

var previous_font_aa = font_add_get_enable_aa();
font_add_enable_aa(false);
inventory_font = font_add("Galmuri14.ttf", 11, false, false, 32, 126);
font_add_enable_aa(previous_font_aa);

inventory_colors = {
    shadow: make_color_rgb(29, 22, 18),
    wood: make_color_rgb(65, 44, 33),
    wood_highlight: make_color_rgb(95, 63, 43),
    bronze: make_color_rgb(153, 105, 58),
    gold: make_color_rgb(236, 188, 103),
    parchment: make_color_rgb(255, 232, 179),
    muted: make_color_rgb(190, 157, 119),
    well: make_color_rgb(44, 32, 26),
    selected_well: make_color_rgb(91, 98, 52)
};

if (!instance_exists(obj_title_menu)) instance_create_depth(0, 0, 0, obj_title_menu);
