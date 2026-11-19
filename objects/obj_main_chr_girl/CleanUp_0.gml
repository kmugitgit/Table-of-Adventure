if (surface_exists(inventory_surface)) surface_free(inventory_surface);
if (inventory_font != -1) font_delete(inventory_font);

if (follow_camera != -1)
{
    camera_set_update_script(follow_camera, previous_camera_update);
}
