var old_colour=draw_get_color();var old_alpha=draw_get_alpha();var old_font=draw_get_font();var old_h=draw_get_halign();var old_v=draw_get_valign();var old_filter=gpu_get_texfilter();
if(!surface_exists(surface))surface=surface_create(960,540);
if(surface_exists(surface)&&surface_set_target(surface))
{
 cooking_ui_draw(id);surface_reset_target();var layout=cooking_ui_layout();
 gpu_set_texfilter(false);draw_set_alpha(1);draw_set_color(c_black);draw_rectangle(0,0,display_get_gui_width(),display_get_gui_height(),false);
 draw_surface_ext(surface,layout.left,layout.top,layout.scale,layout.scale,0,c_white,1);
 // Reuse the exact inventory surface drawn by the player, above the kitchen canvas.
 // The player draw event intentionally omits only its full-screen dimmer in this room.
 if(room==rm_kitchen){
  var hero=instance_find(obj_main_chr_girl,0);
  if(hero!=noone&&surface_exists(hero.inventory_surface)){
   var inv=hero.inventory_layout();
   draw_surface_part_ext(hero.inventory_surface,0,0,inv.width,inv.height,inv.x,inv.y,inv.scale,inv.scale,c_white,1);
   var inventory_pointer=cooking_ui_pointer();var hovered_index=cooking_ui_inventory_at(inventory_pointer);
   var active_item=undefined;
   if(is_struct(hero.inventory_held_stack))active_item=inventory_get_item(hero.inventory_held_stack.id);
   else if(is_struct(drag)&&drag.kind=="table")active_item=inventory_get_item(drag.id);
   else if(table_selected>=0&&table_selected<array_length(global.cooking_state.table_items))
    active_item=inventory_get_item(global.cooking_state.table_items[table_selected].id);
   else{
    var active_index=hovered_index>=0?hovered_index:hero.inventory_selected_slot;
    var slot=global.inventory_slots[active_index];
    if(is_struct(slot))active_item=inventory_get_item(slot.id);
   }
   if(!is_undefined(active_item)&&variable_struct_exists(active_item,"name")){
    draw_set_font(hero.inventory_font);draw_set_halign(fa_center);draw_set_valign(fa_bottom);
    draw_set_color(hero.inventory_colors.shadow);
    draw_text_transformed(display_get_gui_width()*0.5+inv.scale,inv.y-5*inv.scale,active_item.name,inv.scale,inv.scale,0);
    draw_set_color(hero.inventory_colors.parchment);
    draw_text_transformed(display_get_gui_width()*0.5,inv.y-6*inv.scale,active_item.name,inv.scale,inv.scale,0);
   }
   if(is_struct(hero.inventory_held_stack)){
    var held=hero.inventory_held_stack;var held_item=inventory_get_item(held.id);
    if(!is_undefined(held_item)){
     var held_size=32*inv.scale+8;var held_left=device_mouse_x_to_gui(0)+8*inv.scale;var held_top=device_mouse_y_to_gui(0)-38*inv.scale;
     draw_set_color(c_white);codex_draw_item(held_item,[held_left,held_top,held_left+held_size,held_top+held_size],true);
     if(held.quantity>1){
      draw_set_font(hero.inventory_quantity_font);draw_set_halign(fa_right);draw_set_valign(fa_bottom);
      draw_set_color(hero.inventory_colors.shadow);
      draw_text_transformed(held_left+4+32*inv.scale+inv.scale,held_top+4+32*inv.scale+inv.scale,string(held.quantity),inv.scale,inv.scale,0);
      draw_set_color(hero.inventory_colors.parchment);
      draw_text_transformed(held_left+4+32*inv.scale,held_top+4+32*inv.scale,string(held.quantity),inv.scale,inv.scale,0);
     }
    }
   }
   if(is_struct(drag)&&(drag.kind=="table"?(drag.moved||mouse_check_button(mb_left)):(drag.moved&&drag.kind=="station"))){
    var drag_pointer=cooking_ui_pointer();var size=(drag.kind=="table"?96*1.2:44)*layout.scale;
    var dragged_item=inventory_get_item(drag.id);
    if(!is_undefined(dragged_item)){
     var drag_x=drag_pointer.x+(drag.kind=="table"&&variable_struct_exists(drag,"offset_x")?drag.offset_x:0);
     var drag_y=drag_pointer.y+(drag.kind=="table"&&variable_struct_exists(drag,"offset_y")?drag.offset_y:0);
     var gx=layout.left+drag_x*layout.scale;var gy=layout.top+drag_y*layout.scale;
     draw_set_color(c_white);codex_draw_item(dragged_item,[gx-size/2,gy-size/2,gx+size/2,gy+size/2],true);
    }
   }
  }
 }
}
draw_set_color(old_colour);draw_set_alpha(old_alpha);draw_set_font(old_font);draw_set_halign(old_h);draw_set_valign(old_v);gpu_set_texfilter(old_filter);
