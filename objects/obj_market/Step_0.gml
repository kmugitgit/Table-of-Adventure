if (market_input_blocked()) exit;

var click = mouse_check_button_pressed(mb_left);
if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("F"))
    || (click && market_hit(market_leave_bounds)))
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
                market_select(0);
            }
            exit;
        }
    }
}

var category_direction = keyboard_check_pressed(ord("E")) - keyboard_check_pressed(ord("Q"));
if (category_direction != 0)
{
    var category_count = array_length(market_tabs);
    market_category = (market_category + category_direction + category_count) mod category_count;
    market_select(0);
    exit;
}

var items = market_catalog[market_category];
var row_direction = (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S")))
    - (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W")));
if (row_direction != 0 && array_length(items) > 0)
{
    var next_index = clamp(market_selected + row_direction, 0, array_length(items) - 1);
    if (next_index != market_selected) market_select(next_index);
    exit;
}

var visible_pages = market_visible_page_count();
if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))
    || (click && market_hit(market_page_button(-1))))
{
    market_set_page(market_page - 1);
    exit;
}
if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))
    || (click && market_hit(market_page_button(visible_pages))))
{
    market_set_page(market_page + 1);
    exit;
}

if (market_desc_scroll_max > 0 && market_hit(market_desc_bounds))
{
    var wheel = mouse_wheel_down() - mouse_wheel_up();
    market_desc_scroll = clamp(market_desc_scroll + wheel * market_desc_line_spacing, 0, market_desc_scroll_max);
}

if (keyboard_check_pressed(vk_enter) || (click && market_hit(market_buy_bounds)))
{
    market_purchase();
    exit;
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
