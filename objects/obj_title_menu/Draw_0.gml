var previous_filter = gpu_get_texfilter();
gpu_set_texfilter(false);

if (menu_page == TitleMenuPage.Title)
{
    var marker_width = sprite_get_width(button_sprite) * button_scale * 0.5 + 17;
    for (var i = 0; i < TitleMenuButton.Count; i++)
    {
        var row_y = button_y(i);
        draw_sprite_ext(button_sprite, i, x, row_y, button_scale, button_scale, 0, c_white, 1);
        if (i == hovered_button)
        {
            var marker_y = row_y + sprite_get_height(button_sprite) * button_scale * 0.5;
            draw_set_color(gold);
            draw_triangle(x - marker_width - 11, marker_y - 8, x - marker_width - 11, marker_y + 8,
                x - marker_width, marker_y, false);
            draw_triangle(x + marker_width + 11, marker_y - 8, x + marker_width + 11, marker_y + 8,
                x + marker_width, marker_y, false);
        }
    }
    draw_set_color(c_white);
    gpu_set_texfilter(previous_filter);
    exit;
}

if (!surface_exists(panel_surface)) panel_surface = surface_create(panel_width, panel_height);
if (surface_exists(panel_surface) && surface_set_target(panel_surface))
{
    draw_clear_alpha(c_black, 0);
    var previous_font = draw_get_font();
    draw_set_font(panel_font);
    draw_set_valign(fa_middle);

    draw_bevel(0, 5, 423, 259, 12, shadow);
    draw_bevel(0, 0, 423, 254, 12, bronze);
    draw_bevel(3, 3, 420, 249, 10, gold);
    draw_bevel(5, 5, 418, 247, 8, shadow);
    draw_bevel(9, 9, 414, 243, 6, wood);
    draw_bevel(11, 11, 412, 46, 5, make_color_rgb(74, 48, 32));

    // Small leaf-green inlays echo the title buttons.
    draw_set_color(moss);
    draw_rectangle(23, 26, 27, 30, false);
    draw_rectangle(28, 23, 32, 27, false);
    draw_rectangle(396, 26, 400, 30, false);
    draw_rectangle(391, 23, 395, 27, false);
    draw_set_color(parchment);
    draw_set_halign(fa_center);
    draw_text_transformed(212, 32, menu_page == TitleMenuPage.Settings ? "설정" : "불러오기",
        2, 2, 0);

    if (menu_page == TitleMenuPage.Settings)
    {
        for (var i = 0; i < array_length(slider_y); i++)
        {
            var row_y = slider_y[i];
            var position;
            var percent;
            if (i == SettingsSlider.InterfaceSize)
            {
                position = (ui_percent - ui_scale_min) / (ui_scale_max - ui_scale_min);
                percent = ui_percent;
            }
            else
            {
                position = volumes[i];
                percent = round(position * 100);
            }
            var knob = round(lerp(slider_left, slider_right, position));

            draw_set_color(parchment);
            draw_set_halign(fa_left);
            draw_text(31, row_y + panel_text_offset_y, slider_labels[i]);
            draw_set_halign(fa_right);
            draw_text(397, row_y + panel_text_offset_y, string(percent) + "%");
            draw_bevel(slider_left - 3, row_y - 5, slider_right + 3, row_y + 5, 2, bronze);
            draw_bevel(slider_left - 2, row_y - 4, slider_right + 2, row_y + 4, 2, shadow);
            draw_set_color(moss);
            draw_rectangle(slider_left, row_y - 3, knob, row_y + 3, false);
            draw_bevel(knob - 5, row_y - 8, knob + 5, row_y + 8, 2, gold);
            draw_bevel(knob - 3, row_y - 6, knob + 3, row_y + 6, 1,
                over_slider(i) || dragged_slider == i ? parchment : bronze);
        }

        draw_set_color(parchment);
        draw_set_halign(fa_left);
        draw_text(31, 143 + panel_text_offset_y, "화면 모드");

        var fullscreen = window_get_fullscreen();
        draw_control(windowed_bounds, "창 모드", !fullscreen);
        draw_control(fullscreen_bounds, "전체 화면", fullscreen);

        draw_set_color(bronze);
        draw_line(31, 206, 392, 206);
    }
    else
    {
        draw_text(212, 123 + panel_text_offset_y, "저장된 게임이 없습니다.");
    }

    draw_control(back_bounds, "뒤로", false);
    draw_set_font(previous_font);
    surface_reset_target();
}

draw_set_color(c_black);
draw_set_alpha(0.62);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(1);
draw_set_color(c_white);
if (surface_exists(panel_surface))
{
    var scale = panel_scale();
    draw_surface_ext(panel_surface, (room_width - panel_width * scale) * 0.5,
        (room_height - panel_height * scale) * 0.5, scale, scale, 0, c_white, 1);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
gpu_set_texfilter(previous_filter);
