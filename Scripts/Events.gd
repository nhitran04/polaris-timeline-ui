extends Node

# high-level control overrides
signal release_click

# Mode switching
signal enter_map
signal exit_map
signal enter_drawing_board
signal exit_drawing_board
signal play

# Emitted when the problem (world or goal automata) has been updated
signal updated_ga

# COMMUNICATION BETWEEN GOAL AUTOMATA AND CHILDREN
signal delete_checkpoint(chkpt: Checkpoint)
signal delete_predicate(pred: CheckpointPredicate)
signal delete_action(action: CheckpointAction)
signal delete_both(both: CheckpointBoth)
signal split_arc(arc: Arc)
signal expand_action_hint(hint: Action)  # ActionHint is sender. Arc is receiver.

# interaction with plan visualizer
signal toggle_hints
signal enter_plan_vis(elements: Array[Control])
signal set_plan_vis_focus(act: Action)

# COMM SIGNALS
signal domain_received  # emitted from the sender when the receiver has ack'ed
# Emitted when changes to the world are made
signal broadcast_world(world: Dictionary)
# Emitted when changes to the goal automata are made
signal push_goal_automaton(goal_automaton: Dictionary)
signal disable_existing_requests(new_request: Node)

# PLAN
signal set_plan(plan_data: Dictionary)

# World Database Signals
signal reset_predicates
signal reset_world

# map UI signals
signal remove_labels_focus
signal activate_build_mode
signal activate_param_mode
signal activate_nav_mesh_mode
signal activate_uncert_mode
signal deactivate_uncert_mode
signal edit_menu_toggle(pos: Vector2, obj: Node3D)
signal edit_menu_show(pos: Vector2, obj: Node3D)
signal edit_menu_hide
signal delete_region(reg: Region)
signal delete_surface(surf: Surface)
signal delete_item(item: Item)
signal delete_person(person: Person)
signal disable_world_entity_raycasts
signal disable_world_entity_raycasts_with_exceptions(exceptions: Array[Node3D])
signal enable_world_entity_raycasts
signal translate_map(delta: Vector3)
signal rotate_map(angle: float)
signal tilt_map(value: float)
signal zoom_map(value: float)
signal mouse_wheel_zoom(value: float)
signal select_uncert_item(str: String)
signal enter_uncert_paint_mode()
signal enter_uncert_erase_mode()
signal uncert_new_slider(area_ent: WorldEntity, pos: Vector3, wp_name: String)
signal hide_control_panel
signal activate_region_paint_mode
signal activate_surface_paint_mode
signal deactivate_paint_mode
signal update_uncert_point_position(uid: int, pos: Vector3)
signal highlight_uncert_entry(uid: int)
signal view_control_activated(val: bool)
signal delete_uncert_point(uid: int)

# tutorial
signal show_uncert_key(show: bool)
signal show_uncert_controls(show: bool)
signal show_tutorial_menu(show: bool)
signal dragging_map
signal arrow_point_at_arrows
signal arrow_point_at_zoom_slider
signal arrow_point_at_tilt_slider
signal arrow_point_at_compass
signal hide_arrow
signal show_arrow

# experimentation
signal load_begin_screen
signal participant_finished
signal add_done_button
signal participant_is_done
signal just_painted
signal set_curr_item(item: String)
signal be_done
signal press_begin
signal analyze_next_user
signal reset_param_panel
signal remove_end_screen
signal completed_analysis_results(results: String)
signal activate_waypoint(name: String, size: int, color: Color)
signal deactivate_waypoints
signal reset_map_in_space

# drawing
signal terminate_area_draw(area: Area)

# saving and loading
signal save_map
signal load_map

# debug
signal broadcast_predicates(pred: Array[Dictionary])
signal broadcast_actions(action: Array[Dictionary])

# CAMERA
signal lock_2D_camera_pan(val: bool)
signal lock_3D_camera_zoom(val: bool)
signal set_camera_simulator_mode(robot: SimulatedRobot)  # sets camera to follow simulated robot

# SIMULATOR ACTIONS
signal current_action_finished
signal approach_tray_finished
signal check_tray_finished
signal push_replan
signal set_replan

# LOGGING
signal log_to_backend(timstamp: int, subject: String, args: Dictionary)
signal dump_frontend_log

# REPLAYING
signal set_map_cam(mode: int, size: int, z: int)
signal set_drawing_board_cam(x: int, y: int, zoomx: int, zoomy: int)
signal toggle_drawing_board
signal toggle_play
signal toggle_map
signal toggle_map_build_mode
signal toggle_map_param_mode
signal toggle_map_nav_mesh_mode
signal toggle_map_uncertainty_mode
signal on_save_map
signal on_load_map
signal set_input_goal_automata(goal_automata: Dictionary)

# webgl
signal send_to_parent_html_frame(category: String, data: String)
