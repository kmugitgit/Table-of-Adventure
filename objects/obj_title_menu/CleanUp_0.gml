if (surface_exists(panel_surface)) surface_free(panel_surface);
if (panel_font != -1) font_delete(panel_font);

if (surface_exists(game_hud_surface)) surface_free(game_hud_surface);
