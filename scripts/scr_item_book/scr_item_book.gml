/// @func scr_item_book_step(_controller)
/// @desc R로 도감을 열고, 북마크·획득 필터·목록 스크롤 입력을 처리합니다.
function scr_item_book_step(_controller)
{
    var toggle_pressed = keyboard_check_pressed(ord("R"));
    var close_pressed = keyboard_check_pressed(vk_escape);

    if (!_controller.item_book_open && toggle_pressed)
    {
        with (obj_main_chr_girl) inventory_close();
        _controller.item_book_open = true;
        _controller.item_book_scroll_row = 0;
        _controller.item_book_selected_index = 0;
    }
    else if (_controller.item_book_open && (toggle_pressed || close_pressed))
    {
        _controller.item_book_open = false;
        _controller.item_book_dragging_scrollbar = false;
    }

    _controller.gameplay_input_blocked = _controller.item_book_open || toggle_pressed;
    if (!_controller.item_book_open) return;

    var gui_width = display_get_gui_width();
    var gui_height = display_get_gui_height();
    var scale = min(gui_width / 640, gui_height / 360);
    var left = (gui_width - 640 * scale) * 0.5;
    var top = (gui_height - 360 * scale) * 0.5;
    var mouse_x_book = (device_mouse_x_to_gui(0) - left) / scale;
    var mouse_y_book = (device_mouse_y_to_gui(0) - top) / scale;
    var click = mouse_check_button_pressed(mb_left);

    // 북마크를 누르면 해당 분류의 첫 항목부터 보여줍니다.
    if (click)
    {
        for (var tag_index = 0; tag_index < array_length(_controller.item_book_tags); tag_index++)
        {
            var bookmark_top = 91 + tag_index * 38;
            if (mouse_x_book >= 40 && mouse_x_book <= 88
                && mouse_y_book >= bookmark_top && mouse_y_book < bookmark_top + 34)
            {
                _controller.item_book_tag_index = tag_index;
                _controller.item_book_scroll_row = 0;
                _controller.item_book_selected_index = 0;
                _controller.item_book_dragging_scrollbar = false;
                return;
            }
        }
    }

    // 체크박스와 문구 모두 누를 수 있습니다.
    if (click && mouse_x_book >= 100 && mouse_x_book <= 210
        && mouse_y_book >= 94 && mouse_y_book <= 112)
    {
        _controller.item_book_found_only = !_controller.item_book_found_only;
        _controller.item_book_scroll_row = 0;
        _controller.item_book_selected_index = 0;
    }

    var current_tag = _controller.item_book_tags[_controller.item_book_tag_index];
    var visible_entries = scr_item_book_filtered_entries(_controller, current_tag);
    var metrics = scr_item_book_scroll_metrics(array_length(visible_entries),
        _controller.item_book_scroll_row);
    _controller.item_book_scroll_row = metrics.scroll_row;

    var grid_x = 102;
    var grid_y = 116;
    var grid_width = 198;
    var grid_height = 165;
    var track_x = grid_x + grid_width + 3;

    // 마우스 휠은 6×5 아이템 목록 안에서만 작동합니다.
    if (point_in_rectangle(mouse_x_book, mouse_y_book,
        grid_x, grid_y, grid_x + grid_width, grid_y + grid_height))
    {
        var wheel = mouse_wheel_down() - mouse_wheel_up();
        if (wheel != 0)
        {
            _controller.item_book_scroll_row = clamp(
                _controller.item_book_scroll_row + wheel, 0, metrics.max_scroll);
            metrics = scr_item_book_scroll_metrics(array_length(visible_entries),
                _controller.item_book_scroll_row);
        }
    }

    // 스크롤바 손잡이는 드래그할 수 있고, 트랙을 누르면 그 위치로 이동합니다.
    if (click && metrics.max_scroll > 0
        && point_in_rectangle(mouse_x_book, mouse_y_book,
            track_x - 2, metrics.track_y, track_x + 8, metrics.track_y + metrics.track_height))
    {
        _controller.item_book_dragging_scrollbar = true;
        if (point_in_rectangle(mouse_x_book, mouse_y_book,
            track_x - 2, metrics.thumb_y, track_x + 8, metrics.thumb_y + metrics.thumb_height))
            _controller.item_book_scroll_drag_offset = mouse_y_book - metrics.thumb_y;
        else
            _controller.item_book_scroll_drag_offset = metrics.thumb_height * 0.5;
    }

    if (_controller.item_book_dragging_scrollbar)
    {
        if (mouse_check_button(mb_left) && metrics.max_scroll > 0)
        {
            var thumb_travel = metrics.track_height - metrics.thumb_height;
            var thumb_top = clamp(mouse_y_book - _controller.item_book_scroll_drag_offset,
                metrics.track_y, metrics.track_y + thumb_travel);
            if (thumb_travel > 0)
                _controller.item_book_scroll_row = round(
                    (thumb_top - metrics.track_y) / thumb_travel * metrics.max_scroll);
            metrics = scr_item_book_scroll_metrics(array_length(visible_entries),
                _controller.item_book_scroll_row);
        }
        else _controller.item_book_dragging_scrollbar = false;
    }

    // 목록 클릭으로 오른쪽 상세 항목을 선택합니다.
    if (click && point_in_rectangle(mouse_x_book, mouse_y_book,
        grid_x, grid_y, grid_x + grid_width, grid_y + grid_height))
    {
        var local_x = mouse_x_book - grid_x;
        var local_y = mouse_y_book - grid_y;
        var column = floor(local_x / 33);
        var row = floor(local_y / 33);
        if (column >= 0 && column < 6 && row >= 0 && row < 5
            && (local_x - column * 33) < 32 && (local_y - row * 33) < 32)
        {
            var selected_index = _controller.item_book_scroll_row * 6 + row * 6 + column;
            if (selected_index < array_length(visible_entries))
                _controller.item_book_selected_index = selected_index;
        }
    }
}

/// @func scr_item_book_filtered_entries(_controller, _tag)
/// @desc Returns catalogue indexes in their authored order, optionally filtered by discovery.
function scr_item_book_filtered_entries(_controller, _tag)
{
    var result = [];
    for (var i = 0; i < array_length(_controller.item_book_entries); i++)
    {
        var entry = _controller.item_book_entries[i];
        if (entry.tag != _tag) continue;
        if (_controller.item_book_found_only && !codex_was_found(entry.id)) continue;
        array_push(result, i);
    }
    return result;
}

/// @func scr_item_book_scroll_metrics(_item_count, _scroll_row)
/// @desc Calculates the 30-slot viewport and proportional scrollbar thumb.
function scr_item_book_scroll_metrics(_item_count, _scroll_row)
{
    var rows = ceil(_item_count / 6);
    var max_scroll = max(0, rows - 5);
    var track_height = 165;
    var thumb_height = rows <= 5 ? track_height : max(18, floor(track_height * 5 / rows));
    thumb_height = min(thumb_height, track_height);
    var scroll_row = clamp(_scroll_row, 0, max_scroll);
    var thumb_travel = track_height - thumb_height;
    var thumb_y = 116;
    if (max_scroll > 0 && thumb_travel > 0)
        thumb_y += round(scroll_row / max_scroll * thumb_travel);
    return {
        row_count: rows,
        max_scroll: max_scroll,
        scroll_row: scroll_row,
        track_y: 116,
        track_height: track_height,
        thumb_y: thumb_y,
        thumb_height: thumb_height
    };
}

/// @func scr_item_book_wrap_text(_text, _max_width)
/// @desc Wraps text by glyph width for the small details panel.
function scr_item_book_wrap_text(_text, _max_width)
{
    var lines = [];
    var current_line = "";
    for (var i = 1; i <= string_length(_text); i++)
    {
        var glyph = string_char_at(_text, i);
        if (glyph == "\n")
        {
            array_push(lines, current_line);
            current_line = "";
            continue;
        }
        if (current_line != "" && string_width(current_line + glyph) > _max_width)
        {
            array_push(lines, current_line);
            current_line = glyph;
        }
        else current_line += glyph;
    }
    if (current_line != "" || array_length(lines) == 0) array_push(lines, current_line);
    return lines;
}

/// @func scr_item_book_draw(_controller)
/// @desc Draws the book, category tabs, 6×5 scrolling inventory and selected item details.
function scr_item_book_draw(_controller)
{
    var gui_width = display_get_gui_width();
    var gui_height = display_get_gui_height();
    var scale = min(gui_width / 640, gui_height / 360);
    var left = (gui_width - 640 * scale) * 0.5;
    var top = (gui_height - 360 * scale) * 0.5;
    var previous_filter = gpu_get_texfilter();
    var previous_colour = draw_get_color();
    var previous_alpha = draw_get_alpha();
    var previous_font = draw_get_font();
    var previous_halign = draw_get_halign();
    var previous_valign = draw_get_valign();
    var previous_scissor = gpu_get_scissor();
    var dark = make_color_rgb(65, 43, 29);
    var frame_list = [0, 2, 4, 6, 8];

    gpu_set_texfilter(false);
    draw_sprite_ext(spr_item_book, 0, left + 320 * scale, top + 180 * scale,
        scale, scale, 0, c_white, 1);

    // Unselected tabs use frames 1/3/5/7/9; selection uses the next frame in each pair.
    for (var tab = 0; tab < array_length(frame_list); tab++)
    {
        var tab_frame = frame_list[tab] + (tab == _controller.item_book_tag_index ? 1 : 0);
        draw_sprite_ext(spr_item_book_bookmark, tab_frame,
            left + 55 * scale, top + (108 + tab * 38) * scale,
            scale, scale, 0, c_white, 1);
    }

    var tag = _controller.item_book_tags[_controller.item_book_tag_index];
    var entries = scr_item_book_filtered_entries(_controller, tag);
    var metrics = scr_item_book_scroll_metrics(array_length(entries),
        _controller.item_book_scroll_row);

    draw_set_font(_controller.panel_font);
    var tag_labels = ["작물", "조미료", "고기", "물고기", "음식"];
    draw_set_color(c_black);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(left + 151 * scale, top + 75 * scale,
        tag_labels[_controller.item_book_tag_index],
        0.9 * scale, 0.9 * scale, 0);

    draw_set_color(dark);
    draw_text_transformed(left + 234 * scale, top + 75 * scale, "정렬",
        0.7 * scale, 0.7 * scale, 0);

    draw_set_halign(fa_left);
    draw_text_transformed(left + 107 * scale, top + 105 * scale,
        "획득한 항목만 보기", 0.56 * scale, 0.56 * scale, 0);
    if (_controller.item_book_found_only)
    {
        draw_sprite_ext(spr_item_book_check, 0,
            left + 191 * scale, top + 103 * scale,
            scale, scale, 0, c_white, 1);
    }

    var total_count = 0;
    var found_count = 0;
    for (var i = 0; i < array_length(_controller.item_book_entries); i++)
    {
        var count_entry = _controller.item_book_entries[i];
        if (count_entry.tag != tag) continue;
        total_count++;
        if (codex_was_found(count_entry.id)) found_count++;
    }
    var percent = total_count > 0 ? floor(found_count * 100 / total_count) : 0;
    var count_label = "종류: " + string(found_count) + "/" + string(total_count)
        + " (" + string(percent) + "%)";
    draw_set_color(dark);
    draw_set_halign(fa_center);
    draw_text_transformed(left + 250 * scale, top + 105 * scale, count_label,
        0.56 * scale, 0.56 * scale, 0);
    draw_set_halign(fa_left);

    // The 6×5 list uses the 32px cell sprite with a 1px gutter.
    var grid_x = 102;
    var grid_y = 116;
    var grid_width = 198;
    var grid_height = 165;
    var scroll_x = grid_x + grid_width + 3;
    for (var row = 0; row < 5; row++)
    {
        for (var column = 0; column < 6; column++)
        {
            var cell_x = grid_x + column * 33;
            var cell_y = grid_y + row * 33;
            var visible_index = _controller.item_book_scroll_row * 6 + row * 6 + column;
            if (visible_index >= array_length(entries)) continue;
            var is_selected = visible_index < array_length(entries)
                && visible_index == _controller.item_book_selected_index;
            var item = _controller.item_book_entries[entries[visible_index]];
            var found_high_quality = codex_was_high_quality(item.id);
            var frame = found_high_quality ? (is_selected ? 3 : 2) : (is_selected ? 1 : 0);
            draw_sprite_ext(spr_item_book_frame, frame,
                left + (cell_x + 16) * scale, top + (cell_y + 32) * scale,
                scale, scale, 0, c_white, 1);
            var found = codex_was_found(item.id);
            if (item.sprite != noone && sprite_exists(item.sprite))
            {
                var crop_sprite_frame = !found ? 2 : (found_high_quality ? 1 : 0);
                crop_sprite_frame = clamp(crop_sprite_frame, 0, sprite_get_number(item.sprite) - 1);
                draw_sprite_ext(item.sprite, crop_sprite_frame,
                    left + (cell_x + 16) * scale, top + (cell_y + 16) * scale,
                    scale, scale, 0, c_white, 1);
            }
        }
    }

    // Proportional scrollbar beside the list.
    if (metrics.max_scroll > 0)
    {
        draw_set_color(make_color_rgb(196, 130, 72));
        draw_rectangle(left + scroll_x * scale, top + metrics.track_y * scale,
            left + (scroll_x + 5) * scale,
            top + (metrics.track_y + metrics.track_height) * scale, false);
        draw_set_color(make_color_rgb(164, 79, 17));
        draw_rectangle(left + scroll_x * scale, top + metrics.thumb_y * scale,
            left + (scroll_x + 5) * scale,
            top + (metrics.thumb_y + metrics.thumb_height) * scale, false);
    }

    if (_controller.item_book_selected_index < array_length(entries))
    {
        var selected_entry = _controller.item_book_entries[entries[_controller.item_book_selected_index]];
        var selected_found = codex_was_found(selected_entry.id);
        var item_name = selected_found ? selected_entry.name : "???";

        draw_set_font(_controller.panel_font);
        draw_set_color(dark);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text_transformed(left + 439 * scale, top + 76 * scale, item_name,
            1.15 * scale, 1.15 * scale, 0);

        if (selected_entry.sprite != noone && sprite_exists(selected_entry.sprite))
        {
            var detail_frame = !selected_found ? 2 : (codex_was_high_quality(selected_entry.id) ? 1 : 0);
            detail_frame = clamp(detail_frame, 0, sprite_get_number(selected_entry.sprite) - 1);
            draw_sprite_ext(selected_entry.sprite, detail_frame,
                left + 439 * scale, top + 144 * scale,
                3 * scale, 3 * scale, 0, c_white, 1);
        }

        var effects = variable_struct_exists(selected_entry, "effects")
            && is_array(selected_entry.effects) ? selected_entry.effects : [];
        var effect_count = min(3, array_length(effects));
        for (var effect_index = 0; effect_index < effect_count; effect_index++)
        {
            var effect_y = 110 + effect_index * 35;
            var effect = effects[effect_index];
            var effect_sprite = codex_effect_sprite(effect);
            if (effect_sprite != noone && sprite_exists(effect_sprite))
            {
                var effect_width = sprite_get_width(spr_item_book_effect_frame) * scale;
                var effect_height = sprite_get_height(spr_item_book_effect_frame) * scale;
                var effect_scale_x = effect_width / sprite_get_width(effect_sprite);
                var effect_scale_y = effect_height / sprite_get_height(effect_sprite);
                draw_sprite_ext(effect_sprite, 0,
                    left + 513 * scale, top + effect_y * scale,
                    effect_scale_x, effect_scale_y, 0, c_white, 1);
                if (!selected_found)
                {
                    var effect_left = left + 513 * scale - effect_width * 0.5;
                    var effect_top = top + effect_y * scale - effect_height * 0.5;
                    draw_set_color(c_black);
                    draw_rectangle(effect_left, effect_top, effect_left + effect_width,
                        effect_top + effect_height, false);
                    draw_set_color(c_white);
                }
            }
            else
            {
                var effect_label = string(effect_index + 1);
                if (is_string(effect)) effect_label = string_copy(effect, 1, 2);
                else if (is_struct(effect) && variable_struct_exists(effect, "name"))
                    effect_label = string_copy(effect.name, 1, 2);
                draw_set_font(_controller.panel_font);
                draw_set_color(dark);
                draw_set_halign(fa_center);
                draw_text_transformed(left + 513 * scale, top + effect_y * scale,
                    effect_label, 0.7 * scale, 0.7 * scale, 0);
            }
            draw_sprite_ext(spr_item_book_effect_frame, 0,
                left + 513 * scale, top + effect_y * scale,
                scale, scale, 0, c_white, 1);
        }

        // Description, effects, and cultivated land are separate catalogue fields.
        draw_set_font(_controller.panel_font);
        draw_set_color(dark);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        var text_scale = 0.72 * scale;
        draw_text_transformed(left + 426 * scale, top + 207 * scale, "설명",
            text_scale, text_scale, 0);
        var description = selected_found ? selected_entry.description : "???";
        var description_lines = scr_item_book_wrap_text(description, 220);
        draw_set_halign(fa_center);
        for (var line = 0; line < min(2, array_length(description_lines)); line++)
            draw_text_transformed(left + 437 * scale, top + (235 + line * 10) * scale,
                description_lines[line], text_scale, text_scale, 0);

    }

    draw_set_color(previous_colour);
    draw_set_alpha(previous_alpha);
    draw_set_font(previous_font);
    draw_set_halign(previous_halign);
    draw_set_valign(previous_valign);
    gpu_set_scissor(previous_scissor);
    gpu_set_texfilter(previous_filter);
}
