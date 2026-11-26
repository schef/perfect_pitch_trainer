extends ScrollContainer

const FADE_HEIGHT := 72.0
const FADE_SHADER = preload("res://assets/scroll_fade.gdshader")

var top_fade: ColorRect
var bottom_fade: ColorRect
@onready var background: TextureRect = get_node("../../..")

func _ready():
	# Add overlays outside the scroll container so they aren't scrolled or laid out
	# as list items. Defer until the shared Display scene has finished entering.
	call_deferred("create_fades")

func create_fades():
	top_fade = make_fade(true)
	bottom_fade = make_fade(false)

func make_fade(top: bool) -> ColorRect:
	var fade = ColorRect.new()
	fade.name = "ScrollFadeTop" if top else "ScrollFadeBottom"
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.z_index = 1
	var shader_material = ShaderMaterial.new()
	shader_material.shader = FADE_SHADER
	shader_material.set_shader_parameter("background_texture", background.texture)
	shader_material.set_shader_parameter("top_edge", top)
	fade.material = shader_material
	background.add_child(fade)
	return fade

func _process(_delta):
	if not is_instance_valid(top_fade):
		return
	var bar = get_v_scroll_bar()
	var remaining = maxf(0.0, bar.max_value - bar.page - bar.value)
	var height = minf(FADE_HEIGHT, size.y * 0.25)
	var origin = global_position - background.global_position
	update_fade(top_fade, origin, height, bar.value)
	update_fade(bottom_fade, origin + Vector2(0, size.y - height), height, remaining)

func update_fade(fade: ColorRect, origin: Vector2, height: float, distance: float):
	fade.visible = distance > 0.5 and height > 0.0
	if not fade.visible:
		return
	fade.position = origin
	fade.size = Vector2(size.x, height)
	var shader_material = fade.material as ShaderMaterial
	shader_material.set_shader_parameter("background_size", background.size)
	shader_material.set_shader_parameter("region_position", origin)
	shader_material.set_shader_parameter("region_size", fade.size)
	shader_material.set_shader_parameter("strength", clampf(distance / height, 0.0, 1.0))
