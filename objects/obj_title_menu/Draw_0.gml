if (room != rm_title || menu_page != TitleMenuPage.Title) exit;

var previous_filter = gpu_get_texfilter();
gpu_set_texfilter(false);

if (menu_page == TitleMenuPage.Title)
{
    var marker_width = sprite_get_width(button_sprite) * button_scale * 0.5 + 17;
    for (var i = 0; i < TitleMenuButton.Count; i++)
    {
        var row_y = button_y(i);
        var button_tint = i == hovered_button ? make_color_rgb(220, 220, 220) : c_white;
        draw_sprite_ext(button_sprite, i, x, row_y, button_scale, button_scale, 0, button_tint, 1);
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
