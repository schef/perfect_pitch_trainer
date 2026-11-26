extends SceneTree

# Also run against an exported PCK, passing this script by its absolute path.
# Export serialization can drop anchors when a Control lacks its layout_mode.
func _initialize():
	call_deferred("run")

func settle():
	for i in 6:
		await process_frame

func check_layout(scene):
	await settle()
	var viewport_size = root.get_visible_rect().size
	var display = scene.get_node("Display")
	var margins = display.get_node("MarginContainer")
	assert(display.size.is_equal_approx(viewport_size), "Background must fill viewport")
	assert(display.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert(margins.size.is_equal_approx(viewport_size), "Content anchors must survive export")
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
			menu.scroll_container.scroll_vertical = int(max_scroll)
			await settle()
			assert(top_fade.visible)
			assert(not bottom_fade.visible)
		menu.queue_free()
		await process_frame
		for masterclass_index in global.root.masterclasses.size():
			global.set_masterclass_index(masterclass_index)
			for practice_index in global.get_masterclass().practices.size():
				global.set_practice_index(practice_index)
				var scene = load("res://scenes/practice_%s.tscn" % global.get_field("practiceType").to_lower()).instantiate()
				root.add_child(scene)
				await check_layout(scene)
				scene.queue_free()
				await process_frame
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
