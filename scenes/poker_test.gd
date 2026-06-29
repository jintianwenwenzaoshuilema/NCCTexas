extends Control

const HERO_ID: String = "Hero"
const DESIGN_SIZE: Vector2 = Vector2(1920, 1080)
const CARD_VIEW_SCENE: PackedScene = preload("res://scenes/ui/card_view.tscn")

var game: HoldemGame = HoldemGame.new()
var current_legal_actions: Dictionary = {}
var waiting_for_hero: bool = false

var stage_label: Label
var pot_label: Label
var status_label: Label
var board_cards: HBoxContainer
var player_panels: Dictionary = {}
var action_log: RichTextLabel
var fold_button: Button
var check_call_button: Button
var bet_raise_button: Button
var all_in_button: Button
var confirm_button: Button
var raise_amount: SpinBox
var stage: Control
var ui_scale: float = 1.0

func _ready() -> void:
	_build_ui()
	resized.connect(_on_resized)
	_apply_ui_scale()
	_connect_game_signals()
	_start_new_table()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background: ColorRect = ColorRect.new()
	background.color = Color(0.025, 0.027, 0.030)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var vignette: PanelContainer = PanelContainer.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.add_theme_stylebox_override("panel", _style(Color(0.035, 0.037, 0.040, 0.88), Color(0.035, 0.037, 0.040, 0), 0, 0))
	add_child(vignette)

	stage = Control.new()
	stage.name = "TableStage"
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.custom_minimum_size = DESIGN_SIZE
	add_child(stage)

	var logo: Label = Label.new()
	logo.text = "NCCTEXAS"
	logo.add_theme_font_size_override("font_size", 18)
	logo.add_theme_color_override("font_color", Color(0.92, 0.92, 0.88))
	stage.add_child(logo)
	_pin(logo, 0.000, 0.000, 0.160, 0.060)

	var options: Button = Button.new()
	options.text = "OPTIONS"
	options.disabled = true
	options.add_theme_font_size_override("font_size", 11)
	stage.add_child(options)
	_pin(options, 0.000, 0.090, 0.110, 0.205)

	var stakes: Label = Label.new()
	stakes.text = "NLH ~ 5 / 10"
	stakes.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stakes.add_theme_font_size_override("font_size", 24)
	stakes.add_theme_color_override("font_color", Color(0.78, 0.78, 0.76))
	stage.add_child(stakes)
	_pin(stakes, 0.795, 0.015, 1.000, 0.080)

	var table_shadow: PanelContainer = PanelContainer.new()
	table_shadow.add_theme_stylebox_override("panel", _style(Color(0.010, 0.012, 0.012, 0.75), Color(0.010, 0.012, 0.012, 0), 0, 210))
	stage.add_child(table_shadow)
	_pin(table_shadow, 0.165, 0.170, 0.835, 0.720)

	var table: PanelContainer = PanelContainer.new()
	table.name = "TableFelt"
	table.add_theme_stylebox_override("panel", _style(Color(0.035, 0.45, 0.25), Color(0.030, 0.20, 0.12), 12, 200))
	stage.add_child(table)
	_pin(table, 0.185, 0.195, 0.815, 0.700)

	var table_title: Label = Label.new()
	table_title.text = "No Limit Texas Hold'em"
	table_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	table_title.add_theme_font_size_override("font_size", 22)
	table_title.add_theme_color_override("font_color", Color(0.72, 0.92, 0.75, 0.26))
	table.add_child(table_title)
	table_title.set_anchors_preset(Control.PRESET_FULL_RECT)

	var pot_panel: PanelContainer = PanelContainer.new()
	pot_panel.add_theme_stylebox_override("panel", _style(Color(0.03, 0.18, 0.13, 0.72), Color(0.18, 0.45, 0.30, 0.25), 1, 24))
	stage.add_child(pot_panel)
	_pin(pot_panel, 0.420, 0.240, 0.560, 0.325)

	var pot_box: VBoxContainer = VBoxContainer.new()
	pot_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pot_panel.add_child(pot_box)

	var pot_caption: Label = Label.new()
	pot_caption.text = "total"
	pot_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pot_caption.add_theme_font_size_override("font_size", 10)
	pot_caption.add_theme_color_override("font_color", Color(0.76, 0.86, 0.78))
	pot_box.add_child(pot_caption)

	pot_label = Label.new()
	pot_label.text = "0"
	pot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pot_label.add_theme_font_size_override("font_size", 24)
	pot_label.add_theme_color_override("font_color", Color.WHITE)
	pot_box.add_child(pot_label)

	board_cards = HBoxContainer.new()
	board_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	board_cards.add_theme_constant_override("separation", 6)
	stage.add_child(board_cards)
	_pin(board_cards, 0.355, 0.425, 0.635, 0.560)
	_fill_card_row(board_cards, [], true, 5)

	stage_label = _make_hud_label("PREFLOP")
	stage.add_child(stage_label)
	_pin(stage_label, 0.435, 0.110, 0.520, 0.150)

	status_label = _make_hud_label("Ready")
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage.add_child(status_label)
	_pin(status_label, 0.535, 0.110, 0.655, 0.150)

	stage.add_child(_make_player_seat("BotA", "Dealer floor"))
	_pin(player_panels["BotA"], 0.380, 0.045, 0.610, 0.205)

	stage.add_child(_make_player_seat("BotB", "Side seat"))
	_pin(player_panels["BotB"], 0.760, 0.355, 0.960, 0.535)

	stage.add_child(_make_player_seat(HERO_ID, "You"))
	_pin(player_panels[HERO_ID], 0.410, 0.745, 0.630, 0.965)

	var action_panel: PanelContainer = PanelContainer.new()
	action_panel.name = "ActionPanel"
	action_panel.add_theme_stylebox_override("panel", _style(Color(0.055, 0.060, 0.064, 0.95), Color(0.30, 0.34, 0.33, 0.9), 2, 14))
	stage.add_child(action_panel)
	_pin(action_panel, 0.685, 0.735, 0.980, 0.965)

	var action_box: VBoxContainer = VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 8)
	action_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_panel.add_child(action_box)

	var action_title: Label = Label.new()
	action_title.text = "YOUR ACTION"
	action_title.add_theme_font_size_override("font_size", 13)
	action_title.add_theme_color_override("font_color", Color(0.76, 0.86, 0.80))
	action_box.add_child(action_title)

	var row_one: HBoxContainer = HBoxContainer.new()
	row_one.add_theme_constant_override("separation", 6)
	row_one.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_one.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_box.add_child(row_one)

	fold_button = _make_action_button("Fold", Color(0.50, 0.10, 0.11), Color(0.90, 0.30, 0.26))
	check_call_button = _make_action_button("Check / Call", Color(0.06, 0.38, 0.23), Color(0.32, 0.78, 0.48))
	all_in_button = _make_action_button("All-in", Color(0.58, 0.18, 0.05), Color(1.00, 0.55, 0.24))
	row_one.add_child(fold_button)
	row_one.add_child(check_call_button)
	row_one.add_child(all_in_button)

	var row_two: HBoxContainer = HBoxContainer.new()
	row_two.add_theme_constant_override("separation", 6)
	row_two.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_two.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_box.add_child(row_two)

	raise_amount = SpinBox.new()
	raise_amount.min_value = 10
	raise_amount.max_value = 1000
	raise_amount.step = 10
	raise_amount.value = 20
	raise_amount.custom_minimum_size = Vector2(76, 40)
	raise_amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	raise_amount.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row_two.add_child(raise_amount)

	bet_raise_button = _make_action_button("Bet / Raise", Color(0.55, 0.38, 0.08), Color(1.00, 0.78, 0.30))
	confirm_button = _make_action_button("Confirm", Color(0.16, 0.23, 0.34), Color(0.54, 0.68, 0.88))
	row_two.add_child(bet_raise_button)
	row_two.add_child(confirm_button)

	action_log = RichTextLabel.new()
	action_log.bbcode_enabled = false
	action_log.scroll_following = true
	action_log.add_theme_stylebox_override("normal", _style(Color(0.045, 0.047, 0.050, 0.94), Color(0.20, 0.22, 0.22, 0.8), 1, 10))
	stage.add_child(action_log)
	_pin(action_log, 0.025, 0.775, 0.385, 0.965)

	fold_button.pressed.connect(func() -> void: _hero_act("fold"))
	check_call_button.pressed.connect(_hero_check_or_call)
	bet_raise_button.pressed.connect(_hero_bet_or_raise)
	all_in_button.pressed.connect(func() -> void: _hero_act("all_in"))
	confirm_button.pressed.connect(_confirm_next_hand)

func _make_hud_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.86, 0.90, 0.86))
	return label

func _make_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(82, 34)
	return button

func _make_action_button(text: String, base: Color, accent: Color) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(84, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.98, 0.98, 0.94))
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.56, 0.55))
	button.add_theme_stylebox_override("normal", _button_style(base, accent, 0.92))
	button.add_theme_stylebox_override("hover", _button_style(base.lightened(0.12), accent.lightened(0.08), 1.0))
	button.add_theme_stylebox_override("pressed", _button_style(base.darkened(0.10), accent, 0.95))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.075, 0.082, 0.086), Color(0.22, 0.24, 0.24), 0.55))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button

func _make_player_seat(id: String, subtitle: String) -> PanelContainer:
	var seat: PanelContainer = PanelContainer.new()
	seat.name = id + "Seat"
	seat.add_theme_stylebox_override("panel", _style(Color(0.095, 0.098, 0.102, 0.88), Color(0.20, 0.22, 0.22, 0.75), 1, 8))

	var box: HBoxContainer = HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	seat.add_child(box)

	var card_row: HBoxContainer = HBoxContainer.new()
	card_row.name = "Cards"
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 4)
	box.add_child(card_row)
	_fill_card_row(card_row, [], true, 2)

	var info: VBoxContainer = VBoxContainer.new()
	info.add_theme_constant_override("separation", 1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(info)

	var name: Label = Label.new()
	name.name = "Name"
	name.text = id
	name.add_theme_font_size_override("font_size", 17)
	name.add_theme_color_override("font_color", Color(0.90, 0.90, 0.84))
	info.add_child(name)

	var chips: Label = Label.new()
	chips.name = "Chips"
	chips.text = "0"
	chips.add_theme_font_size_override("font_size", 20)
	chips.add_theme_color_override("font_color", Color.WHITE)
	info.add_child(chips)

	var buy_in: Label = Label.new()
	buy_in.name = "BuyIn"
	buy_in.text = "Buy-in 0"
	buy_in.add_theme_font_size_override("font_size", 11)
	buy_in.add_theme_color_override("font_color", Color(0.76, 0.72, 0.58))
	info.add_child(buy_in)

	var state: Label = Label.new()
	state.name = "State"
	state.text = subtitle
	state.add_theme_font_size_override("font_size", 11)
	state.add_theme_color_override("font_color", Color(0.64, 0.68, 0.66))
	info.add_child(state)

	player_panels[id] = seat
	return seat

func _connect_game_signals() -> void:
	game.hand_started.connect(_on_hand_started)
	game.blinds_posted.connect(_on_blinds_posted)
	game.cards_dealt.connect(_on_cards_dealt)
	game.community_dealt.connect(_on_community_dealt)
	game.action_required.connect(_on_action_required)
	game.player_acted.connect(_on_player_acted)
	game.player_rebought.connect(_on_player_rebought)
	game.pot_awarded.connect(_on_pot_awarded)
	game.hand_finished.connect(_on_hand_finished)

func _start_new_table() -> void:
	game.setup([
		{"id": HERO_ID, "chips": 1000},
		{"id": "BotA", "chips": 1000},
		{"id": "BotB", "chips": 1000},
	], 5, 10)
	_start_hand()

func _start_hand() -> void:
	current_legal_actions.clear()
	waiting_for_hero = false
	action_log.clear()
	game.start_hand()
	_refresh_ui()

func _on_hand_started(dealer_index: int) -> void:
	_log("Hand started. Dealer seat: %s" % dealer_index)
	_refresh_ui()

func _on_blinds_posted(small_blind_player: HoldemPlayer, big_blind_player: HoldemPlayer) -> void:
	_log("%s posts 5, %s posts 10." % [small_blind_player.id, big_blind_player.id])
	_refresh_ui()

func _on_cards_dealt(player: HoldemPlayer, cards: Array) -> void:
	if player.id == HERO_ID:
		_log("Your hand: %s" % _cards_to_text(cards))
	_refresh_ui()

func _on_community_dealt(stage_name: String, cards: Array) -> void:
	_log("%s: %s" % [stage_name.capitalize(), _cards_to_text(cards)])
	_refresh_ui()

func _on_action_required(player: HoldemPlayer, legal_actions: Dictionary) -> void:
	current_legal_actions = legal_actions
	_refresh_ui()

	if player.id == HERO_ID:
		waiting_for_hero = true
		status_label.text = "Your action"
		_update_action_buttons()
		return

	waiting_for_hero = false
	_update_action_buttons()
	_bot_act(player, legal_actions)

func _on_player_acted(player: HoldemPlayer, action: String, amount: int) -> void:
	var suffix: String = ""
	if amount > 0:
		suffix = " %s" % amount
	_log("%s: %s%s" % [player.id, action, suffix])
	_refresh_ui()

func _on_player_rebought(player: HoldemPlayer, amount: int) -> void:
	_log("%s buys in for %s. Total buy-in: %s." % [player.id, amount, player.total_buy_in])
	_refresh_ui()

func _on_pot_awarded(awards: Array) -> void:
	for award in awards:
		var player: HoldemPlayer = award["player"] as HoldemPlayer
		var amount: int = int(award["amount"])
		_log("%s wins %s." % [player.id, amount])
	_refresh_ui()

func _on_hand_finished(summary: Dictionary) -> void:
	waiting_for_hero = false
	current_legal_actions.clear()
	_log("Hand finished: %s" % str(summary.get("type", "unknown")))
	status_label.text = "Confirm next hand"
	_refresh_ui()
	_update_action_buttons()

func _confirm_next_hand() -> void:
	if game.stage != HoldemGame.Stage.FINISHED:
		return
	_start_hand()

func _hero_check_or_call() -> void:
	if bool(current_legal_actions.get("check", false)):
		_hero_act("check")
	elif bool(current_legal_actions.get("call", false)):
		_hero_act("call")

func _hero_bet_or_raise() -> void:
	if bool(current_legal_actions.get("bet", false)):
		_hero_act("bet", int(raise_amount.value))
	elif bool(current_legal_actions.get("raise", false)):
		_hero_act("raise", int(raise_amount.value))

func _hero_act(action: String, total_bet: int = 0) -> void:
	if not waiting_for_hero:
		return
	waiting_for_hero = false
	_update_action_buttons()
	if total_bet > 0:
		game.act(action, total_bet)
	else:
		game.act(action)
	_refresh_ui()

func _bot_act(player: HoldemPlayer, legal_actions: Dictionary) -> void:
	status_label.text = "%s is acting" % player.id
	if bool(legal_actions.get("check", false)):
		game.act("check")
	elif bool(legal_actions.get("call", false)):
		game.act("call")
	else:
		game.act("fold")

func _refresh_ui() -> void:
	stage_label.text = _stage_name()
	var pot_total: int = _pot_amount()
	pot_label.text = "%s" % pot_total
	_fill_card_row(board_cards, game.community_cards, true, 5)

	for player in game.players:
		_refresh_player(player)

	_update_action_buttons()

func _refresh_player(player: HoldemPlayer) -> void:
	var seat: PanelContainer = player_panels.get(player.id, null) as PanelContainer
	if seat == null:
		return
	var box: HBoxContainer = seat.get_child(0) as HBoxContainer
	var card_row: HBoxContainer = box.get_node("Cards") as HBoxContainer
	var info: VBoxContainer = box.get_child(1) as VBoxContainer
	var chips: Label = info.get_node("Chips") as Label
	var buy_in: Label = info.get_node("BuyIn") as Label
	var state: Label = info.get_node("State") as Label
	var reveal: bool = player.id == HERO_ID or game.stage in [HoldemGame.Stage.SHOWDOWN, HoldemGame.Stage.FINISHED]
	_fill_card_row(card_row, player.hole_cards, reveal, 2)
	chips.text = "%s" % player.chips
	buy_in.text = "Buy-in %s" % player.total_buy_in
	state.text = "%s  Bet %s  In %s" % [_player_state(player), player.current_bet, player.total_committed]

func _fill_card_row(row: HBoxContainer, cards: Array, revealed: bool, slot_count: int) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()

	for index in range(slot_count):
		var card_view: PanelContainer = CARD_VIEW_SCENE.instantiate() as PanelContainer
		row.add_child(card_view)
		card_view.call("set_ui_scale", ui_scale)
		if index < cards.size():
			var card: HoldemCard = cards[index] as HoldemCard
			if revealed:
				card_view.call("set_card", card, true)
			else:
				card_view.call("set_back")
		else:
			card_view.call("set_empty")

func _update_action_buttons() -> void:
	var enabled: bool = waiting_for_hero and game.stage != HoldemGame.Stage.FINISHED
	fold_button.disabled = not (enabled and bool(current_legal_actions.get("fold", false)))
	check_call_button.disabled = not (enabled and (bool(current_legal_actions.get("check", false)) or bool(current_legal_actions.get("call", false))))
	bet_raise_button.disabled = not (enabled and (bool(current_legal_actions.get("bet", false)) or bool(current_legal_actions.get("raise", false))))
	all_in_button.disabled = not (enabled and bool(current_legal_actions.get("all_in", false)))
	confirm_button.disabled = game.stage != HoldemGame.Stage.FINISHED
	raise_amount.editable = enabled and not bet_raise_button.disabled

	if bool(current_legal_actions.get("check", false)):
		check_call_button.text = "Check"
	elif bool(current_legal_actions.get("call", false)):
		check_call_button.text = "Call %s" % int(current_legal_actions.get("to_call", 0))
	else:
		check_call_button.text = "Check / Call"

	if bool(current_legal_actions.get("bet", false)):
		bet_raise_button.text = "Bet"
	elif bool(current_legal_actions.get("raise", false)):
		bet_raise_button.text = "Raise"
	else:
		bet_raise_button.text = "Bet / Raise"

	var min_raise_to: int = int(current_legal_actions.get("min_raise_to", game.big_blind))
	var max_total_bet: int = int(current_legal_actions.get("max_total_bet", 1000))
	raise_amount.min_value = min_raise_to
	raise_amount.max_value = max_total_bet
	if raise_amount.value < raise_amount.min_value:
		raise_amount.value = raise_amount.min_value
	if raise_amount.value > raise_amount.max_value:
		raise_amount.value = raise_amount.max_value

func _player_state(player: HoldemPlayer) -> String:
	if player.has_folded:
		return "Folded"
	if player.is_all_in:
		return "All-in"
	if game.current_player() == player:
		return "Acting"
	if player.has_acted:
		return "Acted"
	return "Waiting"

func _stage_name() -> String:
	match game.stage:
		HoldemGame.Stage.WAITING:
			return "WAITING"
		HoldemGame.Stage.PREFLOP:
			return "PREFLOP"
		HoldemGame.Stage.FLOP:
			return "FLOP"
		HoldemGame.Stage.TURN:
			return "TURN"
		HoldemGame.Stage.RIVER:
			return "RIVER"
		HoldemGame.Stage.SHOWDOWN:
			return "SHOWDOWN"
		HoldemGame.Stage.FINISHED:
			return "FINISHED"
	return "UNKNOWN"

func _pot_amount() -> int:
	var total: int = 0
	for player in game.players:
		total += player.total_committed
	return total

func _cards_to_text(cards: Array) -> String:
	if cards.is_empty():
		return "-"
	var parts: Array[String] = []
	for card in cards:
		var holdem_card: HoldemCard = card as HoldemCard
		parts.append(holdem_card.code())
	return " ".join(parts)

func _log(message: String) -> void:
	action_log.append_text(message + "\n")

func _on_resized() -> void:
	_apply_ui_scale()
	if not game.players.is_empty():
		_refresh_ui()

func _apply_ui_scale() -> void:
	ui_scale = _calculate_ui_scale()
	if board_cards != null:
		board_cards.add_theme_constant_override("separation", _scaled_int(6))
	if action_log != null:
		action_log.add_theme_font_size_override("normal_font_size", _scaled_int(16))
		action_log.add_theme_stylebox_override("normal", _style(Color(0.045, 0.047, 0.050, 0.94), Color(0.20, 0.22, 0.22, 0.8), 1, 10))
	if fold_button != null:
		_apply_action_button_scale(fold_button)
		_apply_action_button_scale(check_call_button)
		_apply_action_button_scale(bet_raise_button)
		_apply_action_button_scale(all_in_button)
		_apply_action_button_scale(confirm_button)
	if raise_amount != null:
		raise_amount.custom_minimum_size = _scaled_vec(Vector2(76, 40))
		raise_amount.add_theme_font_size_override("font_size", _scaled_int(14))
	for seat in player_panels.values():
		_apply_player_seat_scale(seat as PanelContainer)
	_update_hud_font_sizes()

func _calculate_ui_scale() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	return clamp(min(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y), 0.60, 1.55)

func _update_hud_font_sizes() -> void:
	if stage_label != null:
		stage_label.add_theme_font_size_override("font_size", _scaled_int(14))
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", _scaled_int(14))
	if pot_label != null:
		pot_label.add_theme_font_size_override("font_size", _scaled_int(24))

func _apply_action_button_scale(button: Button) -> void:
	if button == null:
		return
	button.custom_minimum_size = _scaled_vec(Vector2(84, 40))
	button.add_theme_font_size_override("font_size", _scaled_int(14))

func _apply_player_seat_scale(seat: PanelContainer) -> void:
	if seat == null:
		return
	seat.add_theme_stylebox_override("panel", _style(Color(0.095, 0.098, 0.102, 0.88), Color(0.20, 0.22, 0.22, 0.75), 1, 8))
	var box: HBoxContainer = seat.get_child(0) as HBoxContainer
	box.add_theme_constant_override("separation", _scaled_int(8))
	var card_row: HBoxContainer = box.get_node("Cards") as HBoxContainer
	card_row.add_theme_constant_override("separation", _scaled_int(4))
	var info: VBoxContainer = box.get_child(1) as VBoxContainer
	info.add_theme_constant_override("separation", max(1, _scaled_int(1)))
	(info.get_node("Name") as Label).add_theme_font_size_override("font_size", _scaled_int(17))
	(info.get_node("Chips") as Label).add_theme_font_size_override("font_size", _scaled_int(20))
	(info.get_node("BuyIn") as Label).add_theme_font_size_override("font_size", _scaled_int(11))
	(info.get_node("State") as Label).add_theme_font_size_override("font_size", _scaled_int(11))

func _scaled_int(value: int) -> int:
	return maxi(1, roundi(value * ui_scale))

func _scaled_vec(value: Vector2) -> Vector2:
	return value * ui_scale

func _pin(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.anchor_left = left
	node.anchor_top = top
	node.anchor_right = right
	node.anchor_bottom = bottom
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0

func _style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style

func _button_style(background: Color, border: Color, alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(background.r, background.g, background.b, alpha)
	style.border_color = Color(border.r, border.g, border.b, min(alpha + 0.05, 1.0))
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.22 * alpha)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 1)
	return style
