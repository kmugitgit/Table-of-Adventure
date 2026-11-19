enum HeroFacing { Down, Up, Right, Left }

// spr_main_chr starts with a front idle, then has four six-frame walk cycles.
walk_start_frames = [1, 7, 13, 19];
idle_frames = [0, 7, 13, 19];
walk_frame_count = 6;
walk_frames_per_step = 6 / game_get_speed(gamespeed_fps);
walk_phase = 0;
move_speed = 70 / game_get_speed(gamespeed_fps);
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

depth = -round(y + (sprite_get_bbox_bottom(sprite_index)
    - sprite_get_yoffset(sprite_index)) * image_yscale);

// Keep the camera and the drawn sprite on the same pixel grid.
follow_camera = -1;
previous_camera_update = -1;
if (room == rm_main && view_enabled && view_camera[0] != -1)
{
    follow_camera = view_camera[0];
    previous_camera_update = camera_get_update_script(follow_camera);
    camera_set_update_script(follow_camera, function()
    {
        var width = camera_get_view_width(follow_camera);
        var height = camera_get_view_height(follow_camera);
        var camera_x = clamp(round(x) - width * 0.5, 0, max(0, room_width - width));
        var camera_y = clamp(round(y) - height * 0.5, 0, max(0, room_height - height));
        camera_set_view_pos(follow_camera, round(camera_x), round(camera_y));
    });
}

inventory_open = false;
inventory_columns = 9;
inventory_rows = 3;
inventory_selected_slot = 0;
inventory_surface = -1;
inventory_slot_size = 42;
inventory_slot_step = 46;
inventory_padding = 12;
inventory_row_gap = 10;
inventory_grid_top = 47;

inventory_close = function()
{
    inventory_open = false;
    inventory_selected_slot = inventory_selected_slot mod inventory_columns;
};

inventory_row_top = function(_row, _first_top)
{
    return _first_top + _row * inventory_slot_step + (_row > 0 ? inventory_row_gap : 0);
};

inventory_layout = function()
{
    var gui_width = display_get_gui_width();
    var gui_height = display_get_gui_height();
    var scale = min(gui_width / 960, gui_height / 540) * inventory_scale;
    var rows = inventory_open ? inventory_rows : 1;
    var first_top = inventory_open ? inventory_grid_top : inventory_padding;
    var width = 2 * inventory_padding + (inventory_columns - 1) * inventory_slot_step + inventory_slot_size;
    var height = inventory_row_top(rows - 1, first_top) + inventory_slot_size + inventory_padding;
    var surface_height = inventory_row_top(inventory_rows - 1, inventory_grid_top)
        + inventory_slot_size + inventory_padding;
    return {
        x: round((gui_width - width * scale) * 0.5),
        y: round(gui_height - height * scale),
        scale: scale,
        width: width,
        height: height,
        surface_height: surface_height,
        rows: rows,
        first_top: first_top
    };
};

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
