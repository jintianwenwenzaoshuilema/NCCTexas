class_name HoldemGame
extends RefCounted

signal hand_started(dealer_index: int)
signal blinds_posted(small_blind_player: HoldemPlayer, big_blind_player: HoldemPlayer)
signal cards_dealt(player: HoldemPlayer, cards: Array)
signal community_dealt(stage: String, cards: Array)
signal action_required(player: HoldemPlayer, legal_actions: Dictionary)
signal player_acted(player: HoldemPlayer, action: String, amount: int)
signal player_rebought(player: HoldemPlayer, amount: int)
signal pot_awarded(awards: Array)
signal hand_finished(summary: Dictionary)

enum Stage { WAITING, PREFLOP, FLOP, TURN, RIVER, SHOWDOWN, FINISHED }

var players: Array = []
var deck: HoldemDeck = HoldemDeck.new()
var community_cards: Array = []

var dealer_index: int = 0
var small_blind: int = 5
var big_blind: int = 10

var stage: int = Stage.WAITING
var current_bet: int = 0
var min_raise: int = 0
var action_index: int = -1

func setup(player_specs: Array, sb: int = 5, bb: int = 10) -> void:
	players.clear()
	for i in range(player_specs.size()):
		var spec: Dictionary = player_specs[i] as Dictionary
		players.append(HoldemPlayer.new(str(spec.get("id", "P%s" % i)), int(spec.get("chips", 1000)), i))
	small_blind = sb
	big_blind = bb
	dealer_index = 0
	stage = Stage.WAITING

func start_hand() -> void:
	_rebuy_broke_players()
	assert(_active_seat_count() >= 2, "At least two players with chips are required.")
	community_cards.clear()
	deck.reset()
	deck.shuffle()
	for player in players:
		player.reset_for_hand()

	stage = Stage.PREFLOP
	current_bet = big_blind
	min_raise = big_blind
	emit_signal("hand_started", dealer_index)
	_post_blinds()
	_deal_hole_cards()
	action_index = _first_preflop_action_index()
	_request_or_advance()

func legal_actions_for_current_player() -> Dictionary:
	var player: HoldemPlayer = current_player()
	if player == null:
		return {}
	var to_call: int = maxi(current_bet - player.current_bet, 0)
	var max_total_bet: int = player.current_bet + player.chips
	return {
		"fold": to_call > 0,
		"check": to_call == 0,
		"call": to_call > 0,
		"bet": current_bet == 0 and max_total_bet >= big_blind,
		"raise": current_bet > 0 and max_total_bet >= current_bet + min_raise,
		"all_in": player.chips > 0,
		"to_call": to_call,
		"min_bet": big_blind,
		"min_raise_to": current_bet + min_raise,
		"max_total_bet": max_total_bet,
	}

func current_player() -> HoldemPlayer:
	if action_index < 0 or action_index >= players.size():
		return null
	return players[action_index]

func act(action: String, total_bet: int = 0) -> void:
	var player: HoldemPlayer = current_player()
	assert(player != null and player.can_act(), "No player can act now.")
	var paid: int = 0
	var previous_bet: int = player.current_bet
	match action:
		"fold":
			assert(current_bet > player.current_bet, "Cannot fold when checking is available.")
			player.has_folded = true
			player.has_acted = true
		"check":
			assert(current_bet == player.current_bet, "Cannot check facing a bet.")
			player.has_acted = true
		"call":
			paid = player.commit(current_bet - player.current_bet)
			player.has_acted = true
		"bet", "raise":
			_handle_bet_or_raise(player, total_bet)
			paid = player.current_bet - previous_bet
		"all_in":
			_handle_all_in(player)
			paid = player.current_bet - previous_bet
		_:
			assert(false, "Unknown action: %s" % action)

	emit_signal("player_acted", player, action, paid)
	if _finish_if_single_remaining():
		return
	if _is_betting_round_complete():
		_advance_stage()
	else:
		action_index = _next_action_index(action_index)
		_request_or_advance()

func _handle_bet_or_raise(player: HoldemPlayer, total_bet: int) -> void:
	assert(total_bet > current_bet, "Total bet must exceed current bet.")
	var raise_size: int = total_bet - current_bet
	assert(current_bet > 0 or total_bet >= big_blind, "Opening bet is smaller than the big blind.")
	assert(current_bet == 0 or raise_size >= min_raise, "Raise is smaller than minimum raise.")
	assert(total_bet <= player.current_bet + player.chips, "Player does not have enough chips.")
	player.commit(total_bet - player.current_bet)
	min_raise = raise_size
	current_bet = total_bet
	_mark_others_unacted(player)
	player.has_acted = true

func _handle_all_in(player: HoldemPlayer) -> void:
	var old_bet: int = current_bet
	var new_total: int = player.current_bet + player.chips
	player.commit(player.chips)
	if new_total > old_bet:
		var raise_size: int = new_total - old_bet
		current_bet = new_total
		if old_bet == 0 or raise_size >= min_raise:
			min_raise = raise_size
			_mark_others_unacted(player)
	player.has_acted = true

func _post_blinds() -> void:
	var sb_index: int = _small_blind_index()
	var bb_index: int = _big_blind_index()
	players[sb_index].commit(small_blind)
	players[bb_index].commit(big_blind)
	emit_signal("blinds_posted", players[sb_index], players[bb_index])

func _rebuy_broke_players() -> void:
	for player in players:
		var amount: int = player.rebuy_if_broke()
		if amount > 0:
			emit_signal("player_rebought", player, amount)

func _deal_hole_cards() -> void:
	for _round in range(2):
		for offset in range(players.size()):
			var index: int = (dealer_index + 1 + offset) % players.size()
			if players[index].chips > 0 or players[index].total_committed > 0:
				players[index].hole_cards.append(deck.deal_one())
	for player in players:
		emit_signal("cards_dealt", player, player.hole_cards)

func _advance_stage() -> void:
	_reset_round_bets()
	match stage:
		Stage.PREFLOP:
			stage = Stage.FLOP
			deck.burn()
			community_cards.append(deck.deal_one())
			community_cards.append(deck.deal_one())
			community_cards.append(deck.deal_one())
			emit_signal("community_dealt", "flop", community_cards.slice(0, 3))
			_start_postflop_round()
		Stage.FLOP:
			stage = Stage.TURN
			deck.burn()
			var turn_card: HoldemCard = deck.deal_one()
			community_cards.append(turn_card)
			emit_signal("community_dealt", "turn", [turn_card])
			_start_postflop_round()
		Stage.TURN:
			stage = Stage.RIVER
			deck.burn()
			var river_card: HoldemCard = deck.deal_one()
			community_cards.append(river_card)
			emit_signal("community_dealt", "river", [river_card])
			_start_postflop_round()
		Stage.RIVER:
			_showdown()

func _start_postflop_round() -> void:
	if _players_who_can_act().is_empty():
		_advance_stage()
		return
	action_index = _first_postflop_action_index()
	_request_or_advance()

func _showdown() -> void:
	stage = Stage.SHOWDOWN
	var awards: Array = HoldemPotManager.award_pots(players, community_cards, dealer_index)
	emit_signal("pot_awarded", awards)
	_finish_hand({"type": "showdown", "awards": awards})

func _finish_if_single_remaining() -> bool:
	var remaining: Array = _remaining_not_folded()
	if remaining.size() == 1:
		var amount: int = HoldemPotManager.award_all_to(remaining[0], players)
		var award: Array = [{"player": remaining[0], "amount": amount}]
		emit_signal("pot_awarded", award)
		_finish_hand({"type": "fold", "winner": remaining[0], "amount": amount})
		return true
	return false

func _finish_hand(summary: Dictionary) -> void:
	stage = Stage.FINISHED
	action_index = -1
	emit_signal("hand_finished", summary)
	dealer_index = _next_player_with_chips_index(dealer_index)

func _request_or_advance() -> void:
	if _is_betting_round_complete():
		_advance_stage()
		return
	var player: HoldemPlayer = current_player()
	if player != null:
		emit_signal("action_required", player, legal_actions_for_current_player())

func _is_betting_round_complete() -> bool:
	for player in players:
		if not player.can_act():
			continue
		if not player.has_acted:
			return false
		if player.current_bet < current_bet:
			return false
	return true

func _reset_round_bets() -> void:
	current_bet = 0
	min_raise = big_blind
	for player in players:
		player.reset_for_betting_round()

func _mark_others_unacted(raiser: HoldemPlayer) -> void:
	for player in players:
		if player != raiser and player.can_act():
			player.has_acted = false

func _remaining_not_folded() -> Array:
	return players.filter(func(player): return not player.has_folded and (player.chips > 0 or player.total_committed > 0 or player.is_all_in))

func _players_who_can_act() -> Array:
	return players.filter(func(player): return player.can_act())

func _active_seat_count() -> int:
	return players.filter(func(player): return player.chips > 0).size()

func _small_blind_index() -> int:
	if _active_seat_count() == 2:
		return dealer_index
	return _next_occupied_index(dealer_index)

func _big_blind_index() -> int:
	return _next_occupied_index(_small_blind_index())

func _first_preflop_action_index() -> int:
	if _active_seat_count() == 2:
		return _small_blind_index()
	return _next_occupied_index(_big_blind_index())

func _first_postflop_action_index() -> int:
	return _next_action_index(dealer_index)

func _next_action_index(from_index: int) -> int:
	for step in range(1, players.size() + 1):
		var index: int = (from_index + step) % players.size()
		if players[index].can_act():
			return index
	return -1

func _next_occupied_index(from_index: int) -> int:
	for step in range(1, players.size() + 1):
		var index: int = (from_index + step) % players.size()
		if players[index].chips > 0 or players[index].total_committed > 0:
			return index
	return from_index

func _next_player_with_chips_index(from_index: int) -> int:
	for step in range(1, players.size() + 1):
		var index: int = (from_index + step) % players.size()
		if players[index].chips > 0:
			return index
	return from_index
