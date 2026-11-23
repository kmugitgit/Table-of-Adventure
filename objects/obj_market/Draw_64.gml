if (!surface_exists(market_surface)) market_surface = surface_create(market_width, market_height);
if (!surface_exists(market_surface) || !surface_set_target(market_surface)) exit;

var previous_colour = draw_get_color();
var previous_alpha = draw_get_alpha();
var previous_halign = draw_get_halign();
var previous_valign = draw_get_valign();
var previous_font = draw_get_font();
var previous_filter = gpu_get_texfilter();

gpu_set_texfilter(false);
draw_clear(market_background);
draw_set_alpha(1);
draw_set_font(market_font);
draw_set_valign(fa_middle);

market_panel([16, 43, 623, 346], market_wood, market_bronze);
draw_set_color(market_wood_dark);
for (var plank_y = 57; plank_y < 340; plank_y += 40)
{
    draw_line(21, plank_y, 619, plank_y);
    draw_set_color(market_grain);
    draw_line(23, plank_y + 1, 617, plank_y + 1);
    draw_set_color(market_wood_dark);
}

market_panel([26, 61, 392, 336], market_wood_dark, market_grain);
draw_set_color(market_bronze);
draw_rectangle(401, 70, 402, 328, false);

for (var i = 0; i < array_length(market_tabs); i++)
{
    market_button(market_tab_bounds[i], market_tabs[i], market_category == i, true);
}
market_panel(market_wallet_bounds, market_wood_dark, market_bronze);
draw_set_halign(fa_center);
draw_set_color(market_gold);
var wallet_label = string(global.player_gold) + " G";
draw_text((market_wallet_bounds[0] + market_wallet_bounds[2]) * 0.5,
    (market_wallet_bounds[1] + market_wallet_bounds[3]) * 0.5 + 2,
    market_fit_text(wallet_label, market_wallet_bounds[2] - market_wallet_bounds[0] - 12));
market_button(market_leave_bounds, "나가기 [Esc]", false, true);

var items = market_catalog[market_category];
for (var row = 0; row < market_rows_per_page; row++)
{
    var index = market_page * market_rows_per_page + row;
    if (index >= array_length(items)) break;
    var item = items[index];
    var bounds = market_row(row);
    var selected = market_selected == index;
    var hover = market_hit(bounds);
    var fill = selected ? market_green : (hover ? market_row_fill : market_wood);
    market_panel(bounds, fill, selected || hover ? market_gold : market_grain);
    var centre_y = (bounds[1] + bounds[3]) * 0.5;

    draw_set_color(market_shade);
    draw_rectangle(40, centre_y - 16, 74, centre_y + 16, false);
    market_draw_icon(item, 57, centre_y, 2);
    draw_set_color(market_text);
    draw_set_halign(fa_left);
    draw_text(79, centre_y + 2, market_fit_text(item.name, bounds[2] - 89));
}

var item_count = array_length(items);
if (item_count == 0)
{
    draw_set_halign(fa_center);
    draw_set_color(market_muted);
    draw_text(209, 184, "등록된 품목이 없습니다.");
}

var visible_pages = item_count > 0 ? market_visible_page_count() : 0;
if (market_last_page() > 0)
{
    market_button(market_page_button(-1), "<", false, market_page > 0);
    market_button(market_page_button(visible_pages), ">", false, market_page < market_last_page());
}
for (var i = 0; i < visible_pages; i++)
{
    var page = market_first_visible_page() + i;
    market_button(market_page_button(i), string(page + 1), page == market_page, true);
}

var selected_item = item_count > 0 ? items[market_selected] : undefined;
market_panel(market_preview_bounds, market_green_dark, market_bronze);
draw_set_color(market_green_light);
draw_rectangle(424, 81, 594, 193, true);
draw_set_color(market_green);
draw_rectangle(439, 91, 579, 183, false);
draw_set_color(market_green_dark);
draw_ellipse(472, 166, 546, 179, false);
if (!is_undefined(selected_item)) market_draw_icon(selected_item, 509, 134, 8);

market_panel(market_desc_bounds, market_wood_dark, market_bronze);
if (!is_undefined(selected_item))
{
    var text_x = market_desc_text_bounds[0];
    var text_y = market_desc_text_bounds[1];
    var text_width = market_desc_text_bounds[2] - text_x;
    var text_height = market_desc_text_bounds[3] - text_y;
    var description = selected_item.description;
    market_desc_scroll_max = max(0, string_height_ext(description, market_desc_line_spacing, text_width) - text_height);

    // Clip wrapped text to the panel while preserving the font's native pixel size.
    var previous_scissor = gpu_get_scissor();
    gpu_set_scissor(text_x, text_y, text_width, text_height);
    draw_set_halign(fa_left);
    draw_set_color(market_text);
    draw_set_valign(fa_top);
    draw_text_ext(text_x, text_y - market_desc_scroll, description, market_desc_line_spacing, text_width);
    draw_set_valign(fa_middle);
    gpu_set_scissor(previous_scissor);

    if (market_desc_scroll_max > 0)
    {
        var thumb_height = max(6, round(text_height * text_height / (text_height + market_desc_scroll_max)));
        var thumb_top = text_y + round((text_height - thumb_height) * market_desc_scroll / market_desc_scroll_max);
        draw_set_color(market_grain);
        draw_rectangle(597, text_y, 598, text_y + text_height - 1, false);
        draw_set_color(market_gold);
        draw_rectangle(597, thumb_top, 598, thumb_top + thumb_height - 1, false);
    }
}

market_panel(market_price_bounds, market_wood_dark, market_bronze);
draw_set_halign(fa_center);
draw_set_color(market_gold);
var price_label = is_undefined(selected_item) ? "-" : string(selected_item.price) + " G";
draw_text(459, 307, market_fit_text(price_label, 79));
var can_buy = !is_undefined(selected_item) && inventory_purchase_error(selected_item.id) == "";
var buy_label = !is_undefined(selected_item) && selected_item.kind == "tool" && selected_item.tier > 0
    ? "업그레이드" : "구매";
market_button(market_buy_bounds, buy_label, false, can_buy);

draw_set_color(market_text);
draw_set_halign(fa_center);
draw_text(320, 350, market_message);

surface_reset_target();
draw_set_alpha(1);
draw_set_color(market_background);
draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
var scale = market_scale();
draw_surface_ext(market_surface, market_left(), market_top(), scale, scale, 0, c_white, 1);

draw_set_color(previous_colour);
draw_set_alpha(previous_alpha);
draw_set_halign(previous_halign);
draw_set_valign(previous_valign);
draw_set_font(previous_font);
gpu_set_texfilter(previous_filter);
