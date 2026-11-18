if (room == rm_market) exit;

var slot_size = 42;
var slot_step = 46;
var frame_padding = 12;
var frame_width = 2 * frame_padding + (inventory_columns - 1) * slot_step + slot_size;
var hotbar_height = 2 * frame_padding + slot_size;
var slot_top = inventory_open ? 47 : frame_padding;
var row_gap = 10;
var row_count = inventory_open ? inventory_rows : 1;
var expanded_height = 47 + (inventory_rows - 1) * slot_step + row_gap + slot_size + frame_padding;
var frame_height = inventory_open ? expanded_height : hotbar_height;

if (!surface_exists(inventory_surface))
{
    inventory_surface = surface_create(frame_width, expanded_height);
}
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
    draw_text_transformed(frame_padding, 24, "인벤토리", 1.4, 1.4, 0);
    draw_set_color(palette.muted);
    draw_set_halign(fa_right);
    draw_text(frame_width - frame_padding, 24, "I / Esc  닫기");
    draw_set_color(palette.bronze);
    draw_line(frame_padding, 38, frame_width - frame_padding, 38);
    draw_line(frame_padding, slot_top + slot_size + 6, frame_width - frame_padding,
        slot_top + slot_size + 6);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
for (var row = 0; row < row_count; row++)
{
    var top = slot_top + row * slot_step + (row > 0 ? row_gap : 0);
    var bottom = top + slot_size - 1;
    for (var column = 0; column < inventory_columns; column++)
    {
        var left = frame_padding + column * slot_step;
        var right = left + slot_size - 1;
        var selected = row == 0 && column == inventory_selected_slot;

        draw_set_color(selected ? palette.gold : palette.wood_highlight);
        draw_rectangle(left + 1, top, right - 1, bottom, false);
        draw_rectangle(left, top + 1, right, bottom - 1, false);
        draw_set_color(palette.shadow);
        draw_rectangle(left + 2, top + 2, right - 2, bottom - 2, false);
        draw_set_color(selected ? palette.selected_well : palette.well);
        draw_rectangle(left + 3, top + 4, right - 3, bottom - 3, false);

        if (row == 0)
        {
            draw_set_color(selected ? palette.parchment : palette.muted);
            draw_text(left + 6, top + 4, string(column + 1));
        }
    }
}
surface_reset_target();

var gui_width = display_get_gui_width();
var gui_height = display_get_gui_height();
var scale = min(gui_width / 960, gui_height / 540) * inventory_scale;
var panel_x = round((gui_width - frame_width * scale) * 0.5);
var panel_y = inventory_open
    ? round((gui_height - frame_height * scale) * 0.5)
    : round(gui_height - (frame_height + 22) * scale);

if (inventory_open)
{
    draw_set_color(c_black);
    draw_set_alpha(0.52);
    draw_rectangle(0, 0, gui_width, gui_height, false);
    draw_set_alpha(1);
}
draw_surface_part_ext(inventory_surface, 0, 0, frame_width, frame_height,
    panel_x, panel_y, scale, scale, c_white, 1);

gpu_set_texfilter(previous_filter);
draw_set_valign(previous_valign);
draw_set_halign(previous_halign);
draw_set_font(previous_font);
draw_set_alpha(previous_alpha);
draw_set_color(previous_colour);
