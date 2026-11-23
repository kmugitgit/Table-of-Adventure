draw_game_hud();
if (item_book_open)
{
    scr_item_book_draw(id);
    exit;
}
if (menu_page == TitleMenuPage.Title || menu_page == TitleMenuPage.Playing) exit;

var previous_filter = gpu_get_texfilter();
var previous_colour = draw_get_color();
var previous_alpha = draw_get_alpha();
var previous_font = draw_get_font();
var previous_halign = draw_get_halign();
var previous_valign = draw_get_valign();
gpu_set_texfilter(false);
draw_set_alpha(1);

if (!surface_exists(panel_surface)) panel_surface = surface_create(panel_width, panel_height);
if (surface_exists(panel_surface) && surface_set_target(panel_surface))
{
    draw_clear_alpha(c_black, 0);

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
    var heading;
    switch (menu_page)
    {
        case TitleMenuPage.Codex: heading = "도감"; break;
        case TitleMenuPage.Settings: heading = "설정"; break;
        case TitleMenuPage.Pause: heading = "일시정지"; break;
        case TitleMenuPage.ExitConfirm: heading = "나가기"; break;
        case TitleMenuPage.SaveName: heading = "저장 이름"; break;
        case TitleMenuPage.DeleteSave: heading = "저장 삭제"; break;
        default: heading = "불러오기"; break;
    }
    draw_text_transformed(212, 32, heading,
        2, 2, 0);

    if (menu_page == TitleMenuPage.Codex)
    {
        for (var tab = 0; tab < array_length(codex_tabs); tab++)
            draw_control(codex_tab_bounds(tab), codex_tabs[tab], codex_category == tab);
        draw_bevel(25, 81, 399, 207, 3, make_color_rgb(64, 44, 31));

        if (codex_category == 1)
        {
            draw_set_color(parchment);
            draw_set_halign(fa_center);
            for (var tier = 0; tier < array_length(codex_tiers); tier++)
                draw_text(140 + tier * 54, 92, codex_tiers[tier]);
            draw_set_halign(fa_left);
            for (var tool = 0; tool < array_length(codex_tool_names); tool++)
                draw_text(34, 121 + tool * 34, codex_tool_names[tool]);
        }

        var items = codex_catalog[codex_category];
        var hover_entry = undefined;
        for (var slot = 0; slot < codex_page_size(); slot++)
        {
            var index = codex_page * codex_page_size() + slot;
            var bounds = codex_slot_bounds(slot);
            var has_entry = index < array_length(items);
            var found = has_entry && codex_was_found(items[index].id);
            var hover = has_entry && over_control(bounds);
            var selected = has_entry && codex_selected == index;
            draw_bevel(bounds[0], bounds[1], bounds[2], bounds[3], 2,
                hover && found ? gold : (selected ? moss : bronze));
            draw_bevel(bounds[0] + 2, bounds[1] + 2, bounds[2] - 2, bounds[3] - 2, 1, shadow);
            if (!has_entry) continue;
            codex_draw_item(items[index], bounds, found);
            if (hover && found) hover_entry = items[index];
        }

        if (codex_last_page() > 0)
        {
            draw_set_color(parchment);
            draw_set_halign(fa_center);
            draw_text(212, 207, string(codex_page + 1) + " / " + string(codex_last_page() + 1));
            if (codex_page > 0) draw_control(load_previous_bounds, "이전 목록", false);
            if (codex_page < codex_last_page()) draw_control(load_next_bounds, "다음 목록", false);
        }

        if (!is_undefined(hover_entry))
        {
            var popup_width = 190;
            var text_width = popup_width - 18;
            var title_height = string_height_ext(hover_entry.name, 20, text_width);
            var desc_height = string_height_ext(hover_entry.description, 20, text_width);
            var popup_height = min(188, title_height + desc_height + 28);
            var popup_x = clamp(round(panel_mouse_x()) + 9, 15, panel_width - popup_width - 15);
            var popup_y = clamp(round(panel_mouse_y()) + 9, 49, panel_height - popup_height - 10);
            draw_bevel(popup_x + 2, popup_y + 3, popup_x + popup_width + 2, popup_y + popup_height + 3, 3, shadow);
            draw_bevel(popup_x, popup_y, popup_x + popup_width, popup_y + popup_height, 3, gold);
            draw_bevel(popup_x + 2, popup_y + 2, popup_x + popup_width - 2, popup_y + popup_height - 2, 2,
                make_color_rgb(226, 200, 149));
            var previous_scissor = gpu_get_scissor();
            gpu_set_scissor(popup_x + 8, popup_y + 8, text_width, popup_height - 16);
            draw_set_color(make_color_rgb(63, 43, 29));
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            draw_text_ext(popup_x + 9, popup_y + 8, hover_entry.name, 20, text_width);
            draw_set_color(bronze);
            draw_line(popup_x + 9, popup_y + title_height + 13, popup_x + popup_width - 9, popup_y + title_height + 13);
            draw_set_color(make_color_rgb(63, 43, 29));
            draw_text_ext(popup_x + 9, popup_y + title_height + 19, hover_entry.description, 20, text_width);
            draw_set_valign(fa_middle);
            gpu_set_scissor(previous_scissor);
        }
    }
    else if (menu_page == TitleMenuPage.Settings)
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
    else if (menu_page == TitleMenuPage.Pause)
    {
        draw_control(pause_continue_bounds, "계속하기", false);
        draw_control(pause_settings_bounds, "설정", false);
        draw_control(pause_exit_bounds, "나가기", false);
    }
    else if (menu_page == TitleMenuPage.ExitConfirm)
    {
        draw_control(exit_save_bounds, "저장하고 나가기", false);
        draw_control(exit_discard_bounds, "저장하지 않고 나가기", false);
        if (menu_error != "")
        {
            draw_set_color(parchment);
            draw_text(212, 187, menu_error);
        }
    }
    else if (menu_page == TitleMenuPage.SaveName)
    {
        draw_set_color(parchment);
        draw_set_halign(fa_left);
        draw_text(35, 70, "저장 이름을 입력하세요.");
        draw_set_halign(fa_right);
        draw_text(389, 70, string(string_length(save_name)) + " / " + string(save_name_limit));

        draw_bevel(save_name_bounds[0], save_name_bounds[1], save_name_bounds[2],
            save_name_bounds[3], 3, gold);
        draw_bevel(35, 88, 389, 122, 2, shadow);
        var caret = (current_time mod 900 < 450) ? "_" : "";
        var input_text = save_name + caret;
        // Keep the caret visible when the typed name exceeds the field width.
        while (string_width(input_text) > 334)
        {
            input_text = string_delete(input_text, 1, 1);
        }
        draw_set_color(parchment);
        draw_set_halign(fa_left);
        draw_text(43, 107, input_text);

        draw_set_halign(fa_center);
        if (menu_error != "") draw_text(212, 145, menu_error);
        var label = overwrite_name == "" ? "저장하고 나가기" : "덮어쓰기";
        draw_control(save_submit_bounds, label, overwrite_name != "");
    }
    else if (menu_page == TitleMenuPage.DeleteSave)
    {
        draw_set_color(parchment);
        draw_text(212, 75, "이 저장을 삭제할까요?");

        var confirm_name = delete_entry.name;
        if (string_width(confirm_name) > 360)
        {
            confirm_name = string_insert("\n", confirm_name, (string_length(confirm_name) div 2) + 1);
        }
        draw_set_color(gold);
        draw_set_valign(fa_top);
        draw_text(212, 103, confirm_name);
        draw_set_valign(fa_middle);

        draw_control(delete_cancel_bounds, "취소", false);
        draw_control(delete_submit_bounds, "삭제", false);
        if (menu_error != "")
        {
            draw_set_color(parchment);
            draw_text(212, 221, menu_error);
        }
    }
    else if (array_length(load_entries) > 0)
    {
        for (var i = 0; i < load_page_size; i++)
        {
            var index = load_page * load_page_size + i;
            if (index >= array_length(load_entries)) break;
            var entry = load_entries[index];
            var bounds = load_row_bounds(i);
            draw_control(bounds, "", false);
            draw_control(load_delete_bounds(i), "삭제", false);

            draw_set_color(parchment);
            draw_set_halign(fa_left);
            var display_name = entry.name;
            var name_width = bounds[2] - 57;
            if (string_width(display_name) > name_width)
            {
                while (string_width(display_name + "...") > name_width)
                {
                    display_name = string_delete(display_name, string_length(display_name), 1);
                }
                display_name += "...";
            }
            var name_y = bounds[1] + (entry.saved_at > 0 ? 9 : 18);
            draw_text(46, name_y, display_name);
            if (entry.saved_at > 0)
            {
                draw_set_color(gold);
                var date_label = date_date_string(entry.saved_at) + "  " + date_time_string(entry.saved_at);
                draw_text(46, bounds[1] + 25, date_label);
            }
        }
        if (load_last_page() > 0)
        {
            draw_set_color(parchment);
            draw_set_halign(fa_center);
            draw_text(212, 207, string(load_page + 1) + " / " + string(load_last_page() + 1));
            if (load_page > 0) draw_control(load_previous_bounds, "이전 목록", false);
            if (load_page < load_last_page()) draw_control(load_next_bounds, "다음 목록", false);
        }
    }
    else
    {
        draw_text(212, 123 + panel_text_offset_y, menu_error);
    }

    if (menu_page != TitleMenuPage.Pause && menu_page != TitleMenuPage.DeleteSave)
        draw_control(back_bounds, menu_page == TitleMenuPage.Codex ? "닫기 [R]" : "뒤로", false);
    surface_reset_target();
}

draw_set_color(c_black);
draw_set_alpha(0.58);
draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
draw_set_alpha(1);
draw_set_color(c_white);
if (surface_exists(panel_surface))
{
    var scale = panel_scale();
    draw_surface_ext(panel_surface, panel_left(), panel_top(), scale, scale, 0, c_white, 1);
}

draw_set_font(previous_font);
draw_set_halign(previous_halign);
draw_set_valign(previous_valign);
draw_set_color(previous_colour);
draw_set_alpha(previous_alpha);
gpu_set_texfilter(previous_filter);
