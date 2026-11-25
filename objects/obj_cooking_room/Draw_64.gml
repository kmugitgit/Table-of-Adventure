var old_colour=draw_get_color();var old_alpha=draw_get_alpha();var old_font=draw_get_font();var old_h=draw_get_halign();var old_v=draw_get_valign();var old_filter=gpu_get_texfilter();
if(!surface_exists(surface))surface=surface_create(960,540);
if(surface_exists(surface)&&surface_set_target(surface))
{
 cooking_ui_draw(id);surface_reset_target();var layout=cooking_ui_layout();
 gpu_set_texfilter(false);draw_set_alpha(1);draw_set_color(c_black);draw_rectangle(0,0,display_get_gui_width(),display_get_gui_height(),false);
 draw_surface_ext(surface,layout.left,layout.top,layout.scale,layout.scale,0,c_white,1);
}
draw_set_color(old_colour);draw_set_alpha(old_alpha);draw_set_font(old_font);draw_set_halign(old_h);draw_set_valign(old_v);gpu_set_texfilter(old_filter);
