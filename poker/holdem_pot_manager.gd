class_name HoldemPotManager
extends RefCounted

static func build_pots(players: Array) -> Array:
	var levels: Array = []
	for player in players:
		if player.total_committed > 0 and not levels.has(player.total_committed):
			levels.append(player.total_committed)
	levels.sort()

	var pots: Array = []
	var previous: int = 0
	for level in levels:
		var level_amount: int = int(level)
		var contributors: Array = []
		var eligible: Array = []
		for player in players:
			if player.total_committed >= level_amount:
				contributors.append(player)
				if not player.has_folded:
					eligible.append(player)
		var amount: int = (level_amount - previous) * contributors.size()
		if amount > 0:
			pots.append({
				"amount": amount,
				"eligible": eligible,
				"level": level_amount,
			})
		previous = level_amount
	return pots

static func award_pots(players: Array, community_cards: Array, dealer_index: int) -> Array:
	var awards: Array = []
	for pot in build_pots(players):
		var eligible: Array = pot["eligible"] as Array
		if eligible.is_empty():
			continue
		var winners: Array = _winners_for_pot(eligible, community_cards)
		var pot_amount: int = int(pot["amount"])
		var share: int = pot_amount / winners.size()
		var remainder: int = pot_amount % winners.size()
		var ordered_winners: Array = _order_from_left_of_dealer(winners, dealer_index, players.size())
		for winner in winners:
			winner.receive(share)
			awards.append({"player": winner, "amount": share, "pot": pot})
		for i in range(remainder):
			ordered_winners[i].receive(1)
			awards.append({"player": ordered_winners[i], "amount": 1, "pot": pot})
	_clear_commitments(players)
	return awards

static func award_all_to(player: HoldemPlayer, players: Array) -> int:
	var total: int = 0
	for p in players:
		total += p.total_committed
		p.total_committed = 0
		p.current_bet = 0
	player.receive(total)
	return total

static func _winners_for_pot(eligible: Array, community_cards: Array) -> Array:
	var best_score: Array = []
	var winners: Array = []
	for player in eligible:
		var result: Dictionary = HoldemHandEvaluator.evaluate(player.hole_cards + community_cards)
		var score: Array = result["score"] as Array
		if best_score.is_empty() or HoldemHandEvaluator.compare_score(score, best_score) > 0:
			best_score = score
			winners = [player]
		elif HoldemHandEvaluator.compare_score(score, best_score) == 0:
			winners.append(player)
	return winners

static func _order_from_left_of_dealer(players: Array, dealer_index: int, seat_count: int) -> Array:
	var ordered: Array = players.duplicate()
	ordered.sort_custom(func(a, b): return _distance_from_dealer(a.seat_index, dealer_index, seat_count) < _distance_from_dealer(b.seat_index, dealer_index, seat_count))
	return ordered

static func _distance_from_dealer(seat_index: int, dealer_index: int, seat_count: int) -> int:
	var distance: int = (seat_index - dealer_index + seat_count) % seat_count
	return seat_count if distance == 0 else distance

static func _clear_commitments(players: Array) -> void:
	for player in players:
		player.total_committed = 0
		player.current_bet = 0
