extends SceneTree

var _failures: Array = []

func _init() -> void:
	_test_hand_evaluator()
	_test_side_pots_and_cleanup()
	_test_odd_chip_starts_left_of_dealer()
	_test_legal_actions_for_short_stacks()
	_test_heads_up_flow_reaches_flop()

	if _failures.is_empty():
		print("All poker core tests passed.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _test_hand_evaluator() -> void:
	var wheel: Dictionary = HoldemHandEvaluator.evaluate([
		_card(14, HoldemCard.Suit.SPADES),
		_card(2, HoldemCard.Suit.CLUBS),
		_card(3, HoldemCard.Suit.DIAMONDS),
		_card(4, HoldemCard.Suit.HEARTS),
		_card(5, HoldemCard.Suit.SPADES),
	])
	_expect_equal(wheel["category"], HoldemHandEvaluator.Category.STRAIGHT, "A-5 is evaluated as a straight.")
	_expect_equal(wheel["score"][1], 5, "A-5 straight uses 5 as the high card.")

	var straight_flush: Dictionary = HoldemHandEvaluator.evaluate([
		_card(9, HoldemCard.Suit.HEARTS),
		_card(10, HoldemCard.Suit.HEARTS),
		_card(11, HoldemCard.Suit.HEARTS),
		_card(12, HoldemCard.Suit.HEARTS),
		_card(13, HoldemCard.Suit.HEARTS),
		_card(2, HoldemCard.Suit.CLUBS),
		_card(2, HoldemCard.Suit.SPADES),
	])
	var quads: Dictionary = HoldemHandEvaluator.evaluate([
		_card(14, HoldemCard.Suit.CLUBS),
		_card(14, HoldemCard.Suit.DIAMONDS),
		_card(14, HoldemCard.Suit.HEARTS),
		_card(14, HoldemCard.Suit.SPADES),
		_card(13, HoldemCard.Suit.CLUBS),
	])
	_expect_true(HoldemHandEvaluator.compare_result(straight_flush, quads) > 0, "Straight flush beats four of a kind.")

func _test_side_pots_and_cleanup() -> void:
	var players: Array = [
		_player("P0", 0, 0),
		_player("P1", 0, 1),
		_player("P2", 0, 2),
	]
	players[0].total_committed = 50
	players[1].total_committed = 100
	players[2].total_committed = 100
	players[0].is_all_in = true
	players[1].is_all_in = true
	players[2].is_all_in = true

	players[0].hole_cards = [_card(5, HoldemCard.Suit.SPADES), _card(6, HoldemCard.Suit.SPADES)]
	players[1].hole_cards = [_card(13, HoldemCard.Suit.CLUBS), _card(13, HoldemCard.Suit.HEARTS)]
	players[2].hole_cards = [_card(12, HoldemCard.Suit.CLUBS), _card(12, HoldemCard.Suit.HEARTS)]
	var board: Array = [
		_card(2, HoldemCard.Suit.CLUBS),
		_card(3, HoldemCard.Suit.DIAMONDS),
		_card(4, HoldemCard.Suit.HEARTS),
		_card(9, HoldemCard.Suit.SPADES),
		_card(13, HoldemCard.Suit.DIAMONDS),
	]

	HoldemPotManager.award_pots(players, board, 2)
	_expect_equal(players[0].chips, 150, "Main pot is awarded to the short all-in straight.")
	_expect_equal(players[1].chips, 100, "Side pot is awarded to the best remaining hand.")
	_expect_equal(players[2].chips, 0, "Losing side-pot player receives no chips.")
	for player in players:
		_expect_equal(player.total_committed, 0, "Showdown payout clears total_committed.")
		_expect_equal(player.current_bet, 0, "Showdown payout clears current_bet.")

func _test_odd_chip_starts_left_of_dealer() -> void:
	var players: Array = [
		_player("Button", 0, 0),
		_player("SmallBlind", 0, 1),
		_player("Folded", 0, 2),
	]
	for player in players:
		player.total_committed = 1
		player.hole_cards = [_card(2, HoldemCard.Suit.CLUBS), _card(7, HoldemCard.Suit.DIAMONDS)]
	players[2].has_folded = true
	var board: Array = [
		_card(10, HoldemCard.Suit.HEARTS),
		_card(11, HoldemCard.Suit.HEARTS),
		_card(12, HoldemCard.Suit.HEARTS),
		_card(13, HoldemCard.Suit.HEARTS),
		_card(14, HoldemCard.Suit.HEARTS),
	]

	HoldemPotManager.award_pots(players, board, 0)
	_expect_equal(players[0].chips, 1, "Button gets the even split share.")
	_expect_equal(players[1].chips, 2, "Odd chip starts with the first winner left of the button.")

func _test_legal_actions_for_short_stacks() -> void:
	var open_game: HoldemGame = HoldemGame.new()
	open_game.players = [_player("Short", 5, 0)]
	open_game.action_index = 0
	open_game.current_bet = 0
	open_game.big_blind = 10
	var open_actions: Dictionary = open_game.legal_actions_for_current_player()
	_expect_equal(open_actions["bet"], false, "Short stack cannot make a regular opening bet below the big blind.")
	_expect_equal(open_actions["all_in"], true, "Short stack can still move all-in below the big blind.")

	var raise_game: HoldemGame = HoldemGame.new()
	raise_game.players = [_player("Caller", 5, 0)]
	raise_game.players[0].current_bet = 10
	raise_game.action_index = 0
	raise_game.current_bet = 20
	raise_game.min_raise = 20
	var raise_actions: Dictionary = raise_game.legal_actions_for_current_player()
	_expect_equal(raise_actions["call"], true, "Short stack can call all-in for less than the full call amount.")
	_expect_equal(raise_actions["raise"], false, "Short stack cannot make a regular raise below the minimum raise.")
	_expect_equal(raise_actions["all_in"], true, "Short stack can still choose all-in when facing a bet.")

func _test_heads_up_flow_reaches_flop() -> void:
	var game: HoldemGame = HoldemGame.new()
	game.setup([
		{"id": "Hero", "chips": 1000},
		{"id": "Villain", "chips": 1000},
	], 5, 10)
	game.start_hand()
	_expect_equal(game.current_player().id, "Hero", "Heads-up preflop action starts on the small blind/button.")
	game.act("call")
	_expect_equal(game.current_player().id, "Villain", "Big blind acts after the small blind calls.")
	game.act("check")
	_expect_equal(game.stage, HoldemGame.Stage.FLOP, "Completed preflop betting advances to the flop.")
	_expect_equal(game.community_cards.size(), 3, "The flop deals three community cards.")
	_expect_equal(game.current_player().id, "Villain", "Heads-up postflop action starts left of the button.")

func _card(rank: int, suit: int) -> HoldemCard:
	return HoldemCard.new(rank, suit)

func _player(id: String, chips: int, seat_index: int) -> HoldemPlayer:
	return HoldemPlayer.new(id, chips, seat_index)

func _expect_true(value: bool, message: String) -> void:
	if not value:
		_failures.append(message)

func _expect_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s Expected %s, got %s." % [message, str(expected), str(actual)])
