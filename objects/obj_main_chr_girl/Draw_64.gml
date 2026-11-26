if (room == rm_market) exit;

var layout = inventory_layout();
var frame_width = layout.width;
var frame_height = layout.height;
var hover_enabled = !instance_exists(obj_title_menu) || !obj_title_menu.gameplay_input_blocked;
var local_mouse_x = (device_mouse_x_to_gui(0) - layout.x) / layout.scale;
var local_mouse_y = (device_mouse_y_to_gui(0) - layout.y) / layout.scale;

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
var hovered_item = undefined;
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
        var hovered = hover_enabled && point_in_rectangle(local_mouse_x, local_mouse_y,
            left, top, right, bottom);

        draw_set_color(selected ? palette.gold : palette.wood_highlight);
        draw_rectangle(left + 1, top, right - 1, bottom, false);
        draw_rectangle(left, top + 1, right, bottom - 1, false);
        draw_set_color(palette.shadow);
        draw_rectangle(left + 2, top + 2, right - 2, bottom - 2, false);
        draw_set_color(hovered ? palette.selected_well : palette.well);
        draw_rectangle(left + 3, top + 4, right - 3, bottom - 3, false);

        var slot = global.inventory_slots[slot_index];
        if (is_struct(slot))
        {
            var item = inventory_get_item(slot.id);
            if (hovered) hovered_item = item;
            codex_draw_item(item, [left + 3, top + 3, right - 3, bottom - 3], true, true);
            if (item.kind == "tool" && item.tool_kind == "can")
            {
                var amount = inventory_water_amount(slot);
                var gauge_left = left + 5;
                var gauge_right = right - 5;
                draw_set_color(palette.shadow);
                draw_rectangle(gauge_left - 1, bottom - 7, gauge_right + 1, bottom - 2, false);
                draw_set_color(make_color_rgb(29, 58, 83));
                draw_rectangle(gauge_left, bottom - 6, gauge_right, bottom - 3, false);
                if (amount > 0)
                {
                    draw_set_color(make_color_rgb(65, 165, 225));
                    draw_rectangle(gauge_left, bottom - 6,
                        gauge_left + (gauge_right - gauge_left) * amount / inventory_water_capacity(slot), bottom - 3, false);
                }
            }
            if (inventory_item_stackable(item) && slot.quantity > 1)
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

// The kitchen controller composites this shared surface with its scene and cursor layer.
// Avoid drawing a second inventory panel here, which could cover the held-item preview.
if (room == rm_kitchen)
{
    gpu_set_texfilter(previous_filter);
    draw_set_valign(previous_valign);
    draw_set_halign(previous_halign);
    draw_set_font(previous_font);
    draw_set_alpha(previous_alpha);
    draw_set_color(previous_colour);
    exit;
}

if (inventory_open && room != rm_kitchen)
{
    draw_set_color(c_black);
    draw_set_alpha(0.52);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);
}
draw_surface_part_ext(inventory_surface, 0, 0, frame_width, frame_height,
    layout.x, layout.y, layout.scale, layout.scale, c_white, 1);

// Show the selected inventory item's name without adding tool-specific stats.
if (!instance_exists(obj_title_menu) || !obj_title_menu.gameplay_input_blocked)
{
    var active_item = hovered_item;
    if (is_undefined(active_item))
    {
        var active_slot = global.inventory_slots[inventory_selected_slot];
        if (is_struct(active_slot)) active_item = inventory_get_item(active_slot.id);
    }
    if (!is_undefined(active_item) && variable_struct_exists(active_item, "name"))
    {
        var status = active_item.name;
        draw_set_font(inventory_font);
        draw_set_halign(fa_center);
        draw_set_valign(fa_bottom);
        draw_set_color(palette.shadow);
        draw_text_transformed(display_get_gui_width() * 0.5 + layout.scale,
            layout.y - 5 * layout.scale, status, layout.scale, layout.scale, 0);
        draw_set_color(palette.parchment);
        draw_text_transformed(display_get_gui_width() * 0.5,
            layout.y - 6 * layout.scale, status, layout.scale, layout.scale, 0);
    }
}

// Gain notices stack from the lower-left. Older fourth-and-beyond lines fade immediately.
if (variable_global_exists("inventory_gain_notices"))
{
    var notices = global.inventory_gain_notices;
    var notice_delta = delta_time / 1000000;
    for (var n = array_length(notices) - 1; n >= 0; n--)
    {
        notices[n].age += notice_delta;
        if (notices[n].overflow_age >= 0) notices[n].overflow_age += notice_delta;
        if (notices[n].age >= 2.5) array_delete(notices, n, 1);
    }
    var notice_scale = 3;
    var notice_spacing = 24 * notice_scale;
    for (var n = 0; n < array_length(notices); n++)
    {
        var notice = notices[n];
        var alpha = notice.age <= 1 ? 1 : 1 - clamp((notice.age - 1) / 1.5, 0, 1);
        var notice_y = display_get_gui_height() - 66
            - (array_length(notices) - 1 - n) * notice_spacing;
        // During the fade, drift the line upward as it disappears.
        if (notice.age > 1)
            notice_y -= clamp((notice.age - 1) / 1.5, 0, 1) * 18 * notice_scale;
        if (notice.overflow_age >= 0)
        {
            alpha = min(alpha, 1 - clamp(notice.overflow_age / 0.4, 0, 1));
            notice_y -= notice.overflow_age * 18 * notice_scale;
        }
        if (alpha <= 0) continue;
        var label = notice.name + " x " + string(notice.quantity);
        draw_set_font(inventory_font);
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_alpha(alpha);
        draw_set_color(palette.shadow);
        draw_text_transformed(17 + notice_scale, notice_y + notice_scale,
            label, notice_scale, notice_scale, 0);
        draw_set_color(palette.parchment);
        draw_text_transformed(16, notice_y, label, notice_scale, notice_scale, 0);
    }
    draw_set_alpha(1);
}

// Draw the picked-up item just above and to the right of the pointer.
if ((inventory_open || room == rm_restaurant) && is_struct(inventory_held_stack))
{
    var dragged_item = inventory_get_item(inventory_held_stack.id);
    if (!is_undefined(dragged_item))
    {
        // Keep the carried sprite at a 32x32 source-pixel size, like slot icons.
        var drag_size = 32 * layout.scale + 8;
        var drag_left = device_mouse_x_to_gui(0) + 8 * layout.scale;
        var drag_top = device_mouse_y_to_gui(0) - 38 * layout.scale;
        codex_draw_item(dragged_item,
            [drag_left, drag_top, drag_left + drag_size, drag_top + drag_size], true);
        if (inventory_held_stack.quantity > 1)
        {
            var count_x = drag_left + 4 + 32 * layout.scale;
            var count_y = drag_top + 4 + 32 * layout.scale;
            var count_text = string(inventory_held_stack.quantity);
            draw_set_font(inventory_quantity_font);
            draw_set_halign(fa_right);
            draw_set_valign(fa_bottom);
            draw_set_color(palette.shadow);
            draw_text_transformed(count_x + layout.scale, count_y + layout.scale,
                count_text, layout.scale, layout.scale, 0);
            draw_set_color(palette.parchment);
            draw_text_transformed(count_x, count_y, count_text,
                layout.scale, layout.scale, 0);
        }
    }
}

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
    var key_pixels = interaction_key_size;
    var glyph_scale = interaction_key_scale;
    var glyph_x = interaction_key_x;
    var glyph_y = interaction_key_y;
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

fishing_draw_gui(id);

cooking_draw_exterior_hint(id);
