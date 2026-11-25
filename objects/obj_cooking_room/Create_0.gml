surface=-1;counter_scroll=0;inventory_scroll_row=0;drag=undefined;table_drag=undefined;
cooking_initialize();
if(room==rm_restaurant&&global.cooking_state.phase=="none")cooking_new_customer();

inventory_name="";table_selected=-1;table_last_click=-1;table_last_click_time=-1000;
