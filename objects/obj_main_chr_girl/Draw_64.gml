if (room == rm_market) exit;

var layout = inventory_layout();
var frame_width = layout.width;
var frame_height = layout.height;

if (surface_exists(inventory_surface)
    && (surface_get_width(inventory_surface) != frame_width
        || surface_get_height(inventory_surface) != layout.surface_height))
    surface_free(inventory_surface);
if (!surface_exists(inventory_surface))
    inventory_surface = surface_create(frame_width, layout.surface_height);
if (!surface_exists(inventory_surface) || !surface_set_target(inventory_surface)) exit;

var previous_colour = draw_get_color();
var previous_alpha = draw_get_alpha();
var previous_font = draw_get_font();
var previous_halign = draw_get_halign();
var previous_valign = draw_get_valign();
var previous_filter = gpu_get_texfilter();
var palette = inventory_colors;
gpu_set_texfilter(false);
draw_set_alpha(1);
draw_set_font(inventory_font);
draw_clear_alpha(c_black, 0);

// Offset the wood frame's corners by a few whole pixels.
draw_set_color(palette.shadow);
draw_rectangle(4, 3, frame_width - 5, frame_height - 1, false);
draw_rectangle(0, 7, frame_width - 1, frame_height - 5, false);
draw_set_color(palette.bronze);
draw_rectangle(4, 0, frame_width - 5, frame_height - 4, false);
draw_rectangle(0, 4, frame_width - 1, frame_height - 8, false);
draw_set_color(palette.wood);
draw_rectangle(4, 3, frame_width - 5, frame_height - 7, false);
draw_rectangle(3, 6, frame_width - 4, frame_height - 10, false);
draw_set_color(palette.wood_highlight);
draw_rectangle(7, 4, frame_width - 8, 5, false);

if (inventory_open)
{
    draw_set_color(palette.parchment);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text_transformed(inventory_padding, 24, "인벤토리", 1.4, 1.4, 0);
    draw_set_color(palette.muted);
    draw_set_halign(fa_right);
    draw_text(frame_width - inventory_padding, 24, "Tab  닫기");
    draw_set_color(palette.bronze);
    draw_line(inventory_padding, 38, frame_width - inventory_padding, 38);
    var divider_y = layout.first_top + inventory_slot_size + 6;
    draw_line(inventory_padding, divider_y, frame_width - inventory_padding, divider_y);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
for (var row = 0; row < layout.rows; row++)
{
    var top = inventory_row_top(row, layout.first_top);
    var bottom = top + inventory_slot_size - 1;
    for (var column = 0; column < inventory_columns; column++)
    {
        var left = inventory_padding + column * inventory_slot_step;
        var right = left + inventory_slot_size - 1;
        var slot_index = row * inventory_columns + column;
        var selected = slot_index == inventory_selected_slot;
        var moving = slot_index == inventory_move_source;

        draw_set_color(moving ? palette.parchment : (selected ? palette.gold : palette.wood_highlight));
        draw_rectangle(left + 1, top, right - 1, bottom, false);
        draw_rectangle(left, top + 1, right, bottom - 1, false);
        draw_set_color(palette.shadow);
        draw_rectangle(left + 2, top + 2, right - 2, bottom - 2, false);
        draw_set_color(selected ? palette.selected_well : palette.well);
        draw_rectangle(left + 3, top + 4, right - 3, bottom - 3, false);

        var slot = global.inventory_slots[slot_index];
        if (is_struct(slot))
        {
            var item = inventory_get_item(slot.id);
            codex_draw_item(item, [left + 3, top + 3, right - 3, bottom - 3], true);
            if (item.kind == "seed" && slot.quantity > 1)
            {
                draw_set_font(inventory_quantity_font);
                draw_set_halign(fa_right);
                draw_set_valign(fa_bottom);
                draw_set_color(palette.shadow);
                draw_text(right - 2, bottom - 1, string(slot.quantity));
                draw_set_color(palette.parchment);
                draw_text(right - 3, bottom - 2, string(slot.quantity));
                draw_set_font(inventory_font);
                draw_set_halign(fa_left);
                draw_set_valign(fa_top);
            }
        }
        if (row == 0)
        {
            draw_set_color(selected ? palette.parchment : palette.muted);
            draw_text(left + 6, top + 4, string(column + 1));
        }
    }
}
surface_reset_target();

if (inventory_open)
{
    draw_set_color(c_black);
    draw_set_alpha(0.52);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);
}
draw_surface_part_ext(inventory_surface, 0, 0, frame_width, frame_height,
    layout.x, layout.y, layout.scale, layout.scale, c_white, 1);

gpu_set_texfilter(previous_filter);
draw_set_valign(previous_valign);
draw_set_halign(previous_halign);
draw_set_font(previous_font);
draw_set_alpha(previous_alpha);
draw_set_color(previous_colour);


// Anchor the screen-sized prompt to the windmill doorway.
var windmill = instance_nearest(x, y, obj_windmill);
var feet_y = y + (sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index)) * image_yscale;
var input_blocked = instance_exists(obj_title_menu) && obj_title_menu.gameplay_input_blocked;
if (!inventory_open && !input_blocked && windmill != noone && windmill.player_at_door(x, feet_y))
{
    var camera = view_camera[0];
    var application_rect = application_get_position();
    var screen_width = application_rect[2] - application_rect[0];
    var screen_height = application_rect[3] - application_rect[1];
    var gui_per_pixel_x = display_get_gui_width() / screen_width;
    var gui_per_pixel_y = display_get_gui_height() / screen_height;
    var doorway_hint = windmill.windmill_point(28, 13);
    var screen_x = round((doorway_hint.x - camera_get_view_x(camera)) * screen_width / camera_get_view_width(camera));
    var screen_y = round((doorway_hint.y - camera_get_view_y(camera)) * screen_height / camera_get_view_height(camera));

    gpu_set_texfilter(false);
    draw_set_alpha(1);
    draw_set_font(inventory_font);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    var key_pixels = 55;
    var font_info = font_get_info(inventory_font);
    var glyph = font_info.glyphs[$ "F"];
    var glyph_scale = max(1, floor((key_pixels - 12) / glyph.h));
    var glyph_x = floor((key_pixels - glyph.w * glyph_scale) * 0.5) - glyph.offset * glyph_scale;
    var glyph_y = floor((key_pixels - glyph.h * glyph_scale) * 0.5) - glyph.yoffset * glyph_scale;
    var hint_left = screen_x * gui_per_pixel_x;
    var hint_top = screen_y * gui_per_pixel_y;
    var hint_right = (screen_x + key_pixels) * gui_per_pixel_x;
    var hint_bottom = (screen_y + key_pixels) * gui_per_pixel_y;
    draw_set_color(make_color_rgb(49, 35, 24));
    draw_rectangle(hint_left, hint_top, hint_right, hint_bottom, false);
    draw_set_color(make_color_rgb(250, 222, 163));
    draw_rectangle(hint_left, hint_top, hint_right, hint_bottom, true);
    draw_text_transformed((screen_x + glyph_x) * gui_per_pixel_x,
        (screen_y + glyph_y) * gui_per_pixel_y,
        "F", gui_per_pixel_x * glyph_scale, gui_per_pixel_y * glyph_scale, 0);

    gpu_set_texfilter(previous_filter);
    draw_set_valign(previous_valign);
    draw_set_halign(previous_halign);
    draw_set_font(previous_font);
    draw_set_alpha(previous_alpha);
    draw_set_color(previous_colour);
}
