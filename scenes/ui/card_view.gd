class_name CardView
extends PanelContainer

const CARD_SIZE: Vector2 = Vector2(64, 90)
const CORNER_RADIUS: int = 8
const FACE_BG: Color = Color(0.985, 0.976, 0.940)
const FACE_INNER: Color = Color(1.000, 0.996, 0.976)
const FACE_BORDER: Color = Color(0.73, 0.66, 0.52)
const EMPTY_BG: Color = Color(0.045, 0.055, 0.052)
const EMPTY_BORDER: Color = Color(0.14, 0.22, 0.20)
const BACK_BG: Color = Color(0.050, 0.105, 0.235)
const BACK_INK: Color = Color(0.760, 0.840, 1.000)
const BACK_GOLD: Color = Color(0.940, 0.760, 0.360)
const RED_SUIT: Color = Color(0.690, 0.055, 0.075)
const BLACK_SUIT: Color = Color(0.030, 0.036, 0.040)

var stored_code: String = ""
var stored_revealed: bool = true

func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	queue_redraw()

func _get_minimum_size() -> Vector2:
	return CARD_SIZE

func set_card(card: HoldemCard, revealed: bool = true) -> void:
	stored_code = card.code()
	stored_revealed = revealed
	queue_redraw()

func set_back() -> void:
	stored_code = ""
	stored_revealed = false
	queue_redraw()

func set_empty() -> void:
	stored_code = ""
	stored_revealed = true
	queue_redraw()

func _draw() -> void:
	var rect: Rect2 = _card_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return

	if stored_code.is_empty() and stored_revealed:
		_draw_empty(rect)
	elif stored_revealed:
		_draw_face(rect)
	else:
		_draw_back(rect)

func _card_rect() -> Rect2:
	var available: Vector2 = size
	var target_ratio: float = CARD_SIZE.x / CARD_SIZE.y
	var width: float = available.x
	var height: float = width / target_ratio
	if height > available.y:
		height = available.y
		width = height * target_ratio
	var rect_size: Vector2 = Vector2(width, height)
	return Rect2((available - rect_size) * 0.5, rect_size)

func _draw_empty(rect: Rect2) -> void:
	_draw_card_base(rect, EMPTY_BG, EMPTY_BORDER, 1, Color(0, 0, 0, 0.22))
	var inset: Rect2 = rect.grow(-8)
	draw_arc(inset.get_center(), min(inset.size.x, inset.size.y) * 0.26, 0.0, TAU, 48, Color(0.26, 0.34, 0.31, 0.55), 1.4, true)

func _draw_face(rect: Rect2) -> void:
	var rank_text: String = _display_rank(stored_code.substr(0, stored_code.length() - 1))
	var suit_text: String = stored_code.substr(stored_code.length() - 1, 1)
	var suit_symbol: String = _suit_symbol(suit_text)
	var ink: Color = _suit_color(suit_text)

	_draw_card_base(rect, FACE_BG, FACE_BORDER, 2, Color(0, 0, 0, 0.30))
	var inner: Rect2 = rect.grow(-4)
	_draw_round_rect(inner, FACE_INNER, Color(0, 0, 0, 0), 0, CORNER_RADIUS - 2)
	_draw_corner_pip(rect.position + Vector2(12, 8), rank_text, suit_symbol, ink, false)
	_draw_corner_pip(rect.end - Vector2(12, 8), rank_text, suit_symbol, ink, true)

	var center: Vector2 = rect.get_center()
	var watermark: Color = Color(ink.r, ink.g, ink.b, 0.08)
	_draw_center_suit(center + Vector2(0, 1), suit_symbol, watermark, 42)
	_draw_center_suit(center + Vector2(0, 2), suit_symbol, ink, 36)

func _draw_back(rect: Rect2) -> void:
	_draw_card_base(rect, BACK_BG, Color(0.44, 0.58, 0.92), 2, Color(0, 0, 0, 0.42))
	var inner: Rect2 = rect.grow(-6)
	_draw_round_rect(inner, Color(0.075, 0.145, 0.315), Color(0.92, 0.78, 0.42, 0.82), 1, CORNER_RADIUS - 2)

	var center: Vector2 = rect.get_center()
	for radius in [22.0, 16.0, 10.0]:
		draw_arc(center, radius, 0.0, TAU, 64, Color(BACK_INK.r, BACK_INK.g, BACK_INK.b, 0.42), 1.2, true)

	for offset in [-18.0, -9.0, 0.0, 9.0, 18.0]:
		draw_line(Vector2(inner.position.x + 5, center.y + offset), Vector2(inner.end.x - 5, center.y - offset), Color(BACK_INK.r, BACK_INK.g, BACK_INK.b, 0.18), 1.0, true)
		draw_line(Vector2(inner.position.x + 5, center.y - offset), Vector2(inner.end.x - 5, center.y + offset), Color(BACK_INK.r, BACK_INK.g, BACK_INK.b, 0.12), 1.0, true)

	_draw_center_suit(center, "◆", BACK_GOLD, 22)
	_draw_corner_mark(rect.position + Vector2(12, 13), BACK_GOLD)
	_draw_corner_mark(rect.end - Vector2(12, 13), BACK_GOLD)

func _draw_card_base(rect: Rect2, fill: Color, border: Color, border_width: int, shadow: Color) -> void:
	var shadow_rect: Rect2 = rect.grow(-1)
	shadow_rect.position += Vector2(0, 2)
	_draw_round_rect(shadow_rect, shadow, Color(0, 0, 0, 0), 0, CORNER_RADIUS)
	_draw_round_rect(rect.grow(-1), fill, border, border_width, CORNER_RADIUS)

func _draw_round_rect(rect: Rect2, fill: Color, border: Color, border_width: int, radius: int) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	draw_style_box(style, rect)

func _draw_corner_pip(origin: Vector2, rank: String, suit: String, ink: Color, flipped: bool) -> void:
	var font: Font = get_theme_default_font()
	if flipped:
		draw_set_transform(origin, PI, Vector2.ONE)
		_draw_text_centered(font, Vector2(0, 10), rank, 15, ink, 24)
		_draw_text_centered(font, Vector2(0, 25), suit, 13, ink, 24)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	_draw_text_centered(font, origin + Vector2(0, 10), rank, 15, ink, 24)
	_draw_text_centered(font, origin + Vector2(0, 25), suit, 13, ink, 24)

func _draw_corner_mark(origin: Vector2, ink: Color) -> void:
	var font: Font = get_theme_default_font()
	_draw_text_centered(font, origin, "◆", 12, ink, 18)

func _draw_center_suit(center: Vector2, suit: String, ink: Color, font_size: int) -> void:
	var font: Font = get_theme_default_font()
	_draw_text_centered(font, center, suit, font_size, ink, 56)

func _draw_text_centered(font: Font, center: Vector2, text: String, font_size: int, ink: Color, width: float) -> void:
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size)
	var pos: Vector2 = center - Vector2(width * 0.5, text_size.y * 0.5) + Vector2(0, font_size * 0.78)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, ink)

func _suit_symbol(suit: String) -> String:
	match suit:
		"s":
			return "♠"
		"h":
			return "♥"
		"d":
			return "♦"
		"c":
			return "♣"
	return "?"

func _display_rank(rank: String) -> String:
	if rank == "T":
		return "10"
	return rank

func _suit_color(suit: String) -> Color:
	if suit == "h" or suit == "d":
		return RED_SUIT
	return BLACK_SUIT
