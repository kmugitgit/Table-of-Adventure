var click = mouse_check_button_pressed(mb_left);

if (menu_page == TitleMenuPage.Title)
{
    var left = x + (sprite_get_bbox_left(button_sprite) - sprite_get_xoffset(button_sprite)) * button_scale;
    var right = x + (sprite_get_bbox_right(button_sprite) - sprite_get_xoffset(button_sprite)) * button_scale;
    var top = (sprite_get_bbox_top(button_sprite) - sprite_get_yoffset(button_sprite)) * button_scale;
    var bottom = (sprite_get_bbox_bottom(button_sprite) - sprite_get_yoffset(button_sprite)) * button_scale;

    hovered_button = -1;
    for (var i = 0; i < TitleMenuButton.Count; i++)
    {
        var row_y = button_y(i);
        if (point_in_rectangle(mouse_x, mouse_y, left, row_y + top, right, row_y + bottom))
        {
            hovered_button = i;
            break;
        }
    }

    if (click)
    {
        switch (hovered_button)
        {
            case TitleMenuButton.New: room_goto(rm_main); break;
            case TitleMenuButton.Load: menu_page = TitleMenuPage.Load; break;
            case TitleMenuButton.Settings: menu_page = TitleMenuPage.Settings; break;
            case TitleMenuButton.Exit: game_end(); break;
        }
    }
    exit;
}

if (keyboard_check_pressed(vk_escape) || (click && over_control(back_bounds)))
{
    if (dragged_slider != -1) save_settings();
    dragged_slider = -1;
    hovered_button = -1;
    menu_page = TitleMenuPage.Title;
    exit;
}

if (menu_page == TitleMenuPage.Load) exit;

if (click)
{
    for (var i = 0; i < array_length(slider_y); i++)
    {
        if (over_slider(i))
        {
            drag_start_scale = panel_scale();
            dragged_slider = i;
            break;
        }
    }

    if (over_control(windowed_bounds) || over_control(fullscreen_bounds))
    {
        var fullscreen = over_control(fullscreen_bounds);
        if (window_get_fullscreen() != fullscreen)
        {
            window_set_fullscreen(fullscreen);
            save_settings();
        }
    }
}

if (dragged_slider != -1)
{
    var holding = mouse_check_button(mb_left);
    if (click || holding || mouse_check_button_released(mb_left))
    {
        var position = clamp((panel_mouse_x() - slider_left) / (slider_right - slider_left), 0, 1);
        if (dragged_slider == SettingsSlider.InterfaceSize)
        {
            ui_percent = round(lerp(ui_scale_min, ui_scale_max, position));
        }
        else
        {
            var gain = round(position * 100) / 100;
            if (volumes[dragged_slider] != gain)
            {
                volumes[dragged_slider] = gain;
                audio_group_set_gain(volume_groups[dragged_slider], gain, 0);
            }
        }
    }
    if (!holding)
    {
        save_settings();
        dragged_slider = -1;
    }
}
