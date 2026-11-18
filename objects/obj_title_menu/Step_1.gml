var click = mouse_check_button_pressed(mb_left);
var escape_pressed = keyboard_check_pressed(vk_escape);
var in_title = room == rm_title;
gameplay_input_blocked = !in_title && (menu_page != TitleMenuPage.Playing || escape_pressed);

switch (menu_page)
{
    case TitleMenuPage.Playing:
        if (escape_pressed)
        {
            with (obj_main_chr_girl) inventory_open = false;
            menu_page = TitleMenuPage.Pause;
        }
        else play_time_ms += delta_time / 1000;
        exit;

    case TitleMenuPage.Pause:
        if (escape_pressed || (click && over_control(pause_continue_bounds)))
        {
            menu_page = TitleMenuPage.Playing;
        }
        else if (click && over_control(pause_settings_bounds))
        {
            menu_page = TitleMenuPage.Settings;
        }
        else if (click && over_control(pause_exit_bounds))
        {
            menu_error = "";
            menu_page = TitleMenuPage.ExitConfirm;
        }
        exit;

    case TitleMenuPage.ExitConfirm:
        if (escape_pressed || (click && over_control(back_bounds)))
        {
            menu_page = TitleMenuPage.Pause;
        }
        else if (click && over_control(exit_save_bounds))
        {
            save_name = "";
            overwrite_name = "";
            menu_error = "";
            keyboard_string = "";
            menu_page = TitleMenuPage.SaveName;
        }
        else if (click && over_control(exit_discard_bounds))
        {
            return_to_title();
        }
        exit;

    case TitleMenuPage.SaveName:
        if (escape_pressed || (click && over_control(back_bounds)))
        {
            keyboard_string = "";
            menu_error = "";
            menu_page = TitleMenuPage.ExitConfirm;
            exit;
        }

        var entered = keyboard_string;
        if (keyboard_check(vk_control) && keyboard_check_pressed(ord("V")) && clipboard_has_text())
        {
            entered += clipboard_get_text();
        }
        entered = clean_save_input(entered);
        keyboard_string = entered;
        if (entered != save_name)
        {
            save_name = entered;
            overwrite_name = "";
            menu_error = "";
        }

        if (keyboard_check_pressed(vk_enter) || (click && over_control(save_submit_bounds)))
        {
            var name_to_save = string_trim(save_name);
            if (name_to_save == "")
            {
                menu_error = "저장 이름을 입력해 주세요.";
                exit;
            }
            var files = named_save_files(save_name_key(name_to_save));
            var previous = latest_progress(files, 2);
            if (is_struct(previous) && overwrite_name != name_to_save)
            {
                overwrite_name = name_to_save;
                menu_error = "같은 이름의 저장이 있습니다.";
                exit;
            }
            if (write_progress(name_to_save, files, previous))
            {
                keyboard_string = "";
                return_to_title();
            }
            else
            {
                menu_error = "저장하지 못했습니다. 다시 시도해 주세요.";
            }
        }
        exit;

    case TitleMenuPage.Load:
        if (escape_pressed || (click && over_control(back_bounds)))
        {
            hovered_button = -1;
            menu_page = TitleMenuPage.Title;
            exit;
        }

        if (keyboard_check_pressed(vk_left) || mouse_wheel_up()
            || (click && over_control(load_previous_bounds)))
        {
            load_page = max(0, load_page - 1);
            exit;
        }
        if (keyboard_check_pressed(vk_right) || mouse_wheel_down()
            || (click && over_control(load_next_bounds)))
        {
            load_page = min(load_last_page(), load_page + 1);
            exit;
        }
        if (click)
        {
            for (var i = 0; i < load_page_size; i++)
            {
                var index = load_page * load_page_size + i;
                if (index >= array_length(load_entries)) break;
                if (over_control(load_row_bounds(i)))
                {
                    pending_load = load_entries[index].data;
                    room_goto(asset_get_index(pending_load.room_name));
                    break;
                }
            }
        }
        exit;

    case TitleMenuPage.Title:
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
                case TitleMenuButton.New:
                    play_time_ms = 0;
                    global.player_gold = 0;
                    global.windmill_return = undefined;
                    room_goto(rm_main);
                    break;
                case TitleMenuButton.Load:
                    refresh_load_entries();
                    menu_page = TitleMenuPage.Load;
                    break;
                case TitleMenuButton.Settings: menu_page = TitleMenuPage.Settings; break;
                case TitleMenuButton.Exit: game_end(); break;
            }
        }
        exit;
}

if (escape_pressed || (click && over_control(back_bounds)))
{
    if (dragged_slider != -1) save_settings();
    dragged_slider = -1;
    hovered_button = -1;
    menu_page = in_title ? TitleMenuPage.Title : TitleMenuPage.Pause;
    exit;
}

if (menu_page != TitleMenuPage.Settings) exit;

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
