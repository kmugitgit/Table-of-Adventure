if (instance_exists(obj_title_menu) && obj_title_menu.gameplay_input_blocked) exit;

var click = mouse_check_button_pressed(mb_left);
if (keyboard_check_pressed(ord("F")) || (click && market_hit(market_leave_bounds)))
{
    var destination = rm_main;
    if (variable_global_exists("windmill_return") && is_struct(global.windmill_return))
    {
        destination = global.windmill_return.room_id;
    }
    room_goto(destination);
    exit;
}

if (click)
{
    for (var i = 0; i < array_length(market_tabs); i++)
    {
        if (market_hit(market_tab_bounds[i]))
        {
            if (market_category != i)
            {
                market_category = i;
                market_page = 0;
                market_select(0);
            }
            exit;
        }
    }
}

var visible_pages = market_visible_page_count();
if (keyboard_check_pressed(vk_left) || (click && market_hit(market_page_button(-1))))
{
    market_set_page(market_page - 1);
    exit;
}
if (keyboard_check_pressed(vk_right) || (click && market_hit(market_page_button(visible_pages))))
{
    market_set_page(market_page + 1);
    exit;
}

if (market_desc_scroll_max > 0 && market_hit(market_desc_bounds))
{
    var wheel = mouse_wheel_down() - mouse_wheel_up();
    market_desc_scroll = clamp(market_desc_scroll + wheel * market_desc_line_spacing, 0, market_desc_scroll_max);
}

if (!click) exit;

for (var i = 0; i < visible_pages; i++)
{
    if (market_hit(market_page_button(i)))
    {
        market_set_page(market_first_visible_page() + i);
        exit;
    }
}

var items = market_catalog[market_category];
for (var row = 0; row < market_rows_per_page; row++)
{
    var index = market_page * market_rows_per_page + row;
    if (index >= array_length(items)) break;
    if (market_hit(market_row(row)))
    {
        if (index != market_selected) market_select(index);
        break;
    }
}
