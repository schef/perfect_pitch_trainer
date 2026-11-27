extends SceneTree

# Also run against an exported PCK, passing this script by its absolute path.
# Export serialization can drop anchors when a Control lacks its layout_mode.
func _initialize():
	call_deferred("run")

func settle():
	for i in 6:
		await process_frame

func check_page_drag(scene):
	# Exercise Godot's touch emulation instead of only assigning scroll_vertical.
	# Start in the page's side padding, outside the old inset scrolling panel.
	scene.scroll_container.scroll_vertical = 0
	await settle()
	var title_y = scene.title.global_position.y
	var position = Vector2(20, root.size.y * 0.65)
	var down = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = position
	down.pressed = true
	Input.parse_input_event(down)
	for i in 5:
		var drag = InputEventMouseMotion.new()
		drag.button_mask = MOUSE_BUTTON_MASK_LEFT
		position.y -= 30
		drag.position = position
		drag.relative = Vector2(0, -30)
		drag.velocity = Vector2(0, -300)
		Input.parse_input_event(drag)
		await process_frame
	var up = InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = position
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	assert(scene.scroll_container.scroll_vertical > 0, "Swiping page padding must scroll")
	assert(scene.title.global_position.y < title_y, "Touch dragging must move the heading")

func check_layout(scene):
	await settle()
	var viewport_size = root.get_visible_rect().size
	var display = scene.get_node("Display")
	var margins = display.get_node("ScrollContainer/MarginContainer")
	assert(display.size.is_equal_approx(viewport_size), "Background must fill viewport")
	assert(display.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert(scene.scroll_container.size.is_equal_approx(viewport_size), "The whole page must scroll, not an inset panel")
	assert(margins.size.y >= viewport_size.y, "Page must fill the viewport")
	assert(margins.size.x <= viewport_size.x, "Long names must not widen the page")
	assert(scene.scroll_container.size.y > 600, "Button list collapsed or clipped")
	assert(scene.scroll_container.get_global_rect().end.y <= viewport_size.y)
	assert(scene.scroll_container.size.x <= viewport_size.x)
	assert(scene.scroll_array.get_child_count() > 0)
	for child in scene.scroll_array.get_children():
		if child is Control:
			assert(child.size.x <= scene.scroll_container.size.x + 1, "Content overflows horizontally")

func run():
	var global = root.get_node("Global")
	for window_size in [Vector2i(540, 960), Vector2i(540, 1206), Vector2i(720, 1600)]:
		root.size = window_size
		var menu = load("res://scenes/root.tscn").instantiate()
		root.add_child(menu)
		await check_layout(menu)
		assert(menu.scroll_container.get_global_rect().intersects(menu.scroll_array.get_child(0).get_global_rect()))
		var top_fade = menu.get_node("Display/ScrollFadeTop")
		var bottom_fade = menu.get_node("Display/ScrollFadeBottom")
		var bar = menu.scroll_container.get_v_scroll_bar()
		var max_scroll = maxf(0, bar.max_value - bar.page)
		assert(not top_fade.visible)
		assert(bottom_fade.visible == (max_scroll > 0.5))
		assert(top_fade.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		if max_scroll > 0:
			var title_y = menu.title.global_position.y
			menu.scroll_container.scroll_vertical = int(max_scroll)
			await settle()
			assert(is_equal_approx(menu.title.global_position.y, title_y - menu.scroll_container.scroll_vertical), "Heading must scroll with content")
			assert(top_fade.visible)
			assert(not bottom_fade.visible)
			await check_page_drag(menu)
		menu.queue_free()
		await process_frame
		for masterclass_index in global.root.masterclasses.size():
			global.set_masterclass_index(masterclass_index)
			var class_menu = load("res://scenes/masterclass.tscn").instantiate()
			root.add_child(class_menu)
			await check_layout(class_menu)
			for child in class_menu.scroll_array.get_children():
				assert(child.get_global_rect().position.x >= 0)
				assert(child.get_global_rect().end.x <= root.get_visible_rect().size.x)
			class_menu.queue_free()
			await process_frame
			for practice_index in global.get_masterclass().practices.size():
				global.set_practice_index(practice_index)
				var scene = load("res://scenes/practice_%s.tscn" % global.get_field("practiceType").to_lower()).instantiate()
				root.add_child(scene)
				await check_layout(scene)
				if global.get_field("practiceType") == "COMMENTS":
					assert(scene.comments.fit_content and not scene.comments.scroll_active)
					var scroll = scene.scroll_container
					var range_end = scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page
					if range_end > 100:
						var title_y = scene.title.global_position.y
						var text_y = scene.comments.global_position.y
						scroll.scroll_vertical = 100
						await settle()
						assert(is_equal_approx(scene.title.global_position.y, title_y - 100))
						assert(is_equal_approx(scene.comments.global_position.y, text_y - 100))
				scene.queue_free()
				await process_frame
			global.reset_practice_index()
		global.reset_practice_index()
		global.reset_masterclass_index()
		var instruments = load("res://scenes/settings_instrument.tscn").instantiate()
		root.add_child(instruments)
		await check_layout(instruments)
		instruments.queue_free()
		await process_frame
		print("Layout passed: ", window_size)
	root.get_node("MidiPlayer").synth.queue_free()
	await create_timer(0.25).timeout
	print("Layout tests passed: menus, practices and instruments at three portrait sizes.")
	quit()
