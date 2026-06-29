class_name HoldemHandEvaluator
extends RefCounted

enum Category {
	HIGH_CARD,
	ONE_PAIR,
	TWO_PAIR,
	THREE_OF_A_KIND,
	STRAIGHT,
	FLUSH,
	FULL_HOUSE,
	FOUR_OF_A_KIND,
	STRAIGHT_FLUSH,
}

const CATEGORY_NAMES: Dictionary = {
	Category.HIGH_CARD: "High Card",
	Category.ONE_PAIR: "One Pair",
	Category.TWO_PAIR: "Two Pair",
	Category.THREE_OF_A_KIND: "Three of a Kind",
	Category.STRAIGHT: "Straight",
	Category.FLUSH: "Flush",
	Category.FULL_HOUSE: "Full House",
	Category.FOUR_OF_A_KIND: "Four of a Kind",
	Category.STRAIGHT_FLUSH: "Straight Flush",
}

static func evaluate(cards: Array) -> Dictionary:
	assert(cards.size() >= 5, "At least 5 cards are required.")
	var ranks_by_count: Dictionary = _ranks_by_count(cards)
	var unique_ranks: Array = _unique_ranks(cards)
	var flush_cards: Array = _best_flush_cards(cards)

	if flush_cards.size() >= 5:
		var straight_flush_high: int = _straight_high(_unique_ranks(flush_cards))
		if straight_flush_high > 0:
			return _result(Category.STRAIGHT_FLUSH, [straight_flush_high])

	var four_rank: int = _first_rank_with_count(ranks_by_count, 4)
	if four_rank > 0:
		return _result(Category.FOUR_OF_A_KIND, [four_rank, _highest_excluding(unique_ranks, [four_rank], 1)[0]])

	var trips: Array = _ranks_with_at_least(ranks_by_count, 3)
	var pairs: Array = _ranks_with_at_least(ranks_by_count, 2)
	if trips.size() > 0:
		var trip_rank: int = int(trips[0])
		var pair_candidates: Array = []
		for rank in pairs:
			if rank != trip_rank:
				pair_candidates.append(rank)
		for rank in trips:
			if rank != trip_rank:
				pair_candidates.append(rank)
		pair_candidates.sort()
		pair_candidates.reverse()
		if pair_candidates.size() > 0:
			return _result(Category.FULL_HOUSE, [trip_rank, int(pair_candidates[0])])

	if flush_cards.size() >= 5:
		return _result(Category.FLUSH, _top_ranks(flush_cards, 5))

	var straight_high: int = _straight_high(unique_ranks)
	if straight_high > 0:
		return _result(Category.STRAIGHT, [straight_high])

	if trips.size() > 0:
		var trip_rank: int = int(trips[0])
		var kickers: Array = _highest_excluding(unique_ranks, [trip_rank], 2)
		return _result(Category.THREE_OF_A_KIND, [trip_rank] + kickers)

	if pairs.size() >= 2:
		var high_pair: int = int(pairs[0])
		var low_pair: int = int(pairs[1])
		var kicker: int = int(_highest_excluding(unique_ranks, [high_pair, low_pair], 1)[0])
		return _result(Category.TWO_PAIR, [high_pair, low_pair, kicker])

	if pairs.size() == 1:
		var pair_rank: int = int(pairs[0])
		return _result(Category.ONE_PAIR, [pair_rank] + _highest_excluding(unique_ranks, [pair_rank], 3))

	return _result(Category.HIGH_CARD, _highest_excluding(unique_ranks, [], 5))

static func compare_score(a: Array, b: Array) -> int:
	var size: int = mini(a.size(), b.size())
	for i in range(size):
		if a[i] > b[i]:
			return 1
		if a[i] < b[i]:
			return -1
	return 0

static func compare_result(a: Dictionary, b: Dictionary) -> int:
	return compare_score(a["score"], b["score"])

static func _result(category: int, kickers: Array) -> Dictionary:
	return {
		"category": category,
		"name": CATEGORY_NAMES[category],
		"score": [category] + kickers,
	}

static func _ranks_by_count(cards: Array) -> Dictionary:
	var counts: Dictionary = {}
	for card in cards:
		counts[card.rank] = counts.get(card.rank, 0) + 1
	return counts

static func _unique_ranks(cards: Array) -> Array:
	var seen: Dictionary = {}
	for card in cards:
		seen[card.rank] = true
	var ranks: Array = seen.keys()
	ranks.sort()
	ranks.reverse()
	return ranks

static func _ranks_with_at_least(counts: Dictionary, amount: int) -> Array:
	var ranks: Array = []
	for rank in counts.keys():
		if counts[rank] >= amount:
			ranks.append(rank)
	ranks.sort()
	ranks.reverse()
	return ranks

static func _first_rank_with_count(counts: Dictionary, amount: int) -> int:
	var ranks: Array = _ranks_with_at_least(counts, amount)
	return int(ranks[0]) if ranks.size() > 0 else 0

static func _best_flush_cards(cards: Array) -> Array:
	var by_suit: Dictionary = {}
	for card in cards:
		if not by_suit.has(card.suit):
			by_suit[card.suit] = []
		by_suit[card.suit].append(card)
	var best: Array = []
	for suited_cards in by_suit.values():
		if suited_cards.size() >= 5 and suited_cards.size() > best.size():
			best = suited_cards
	return best

static func _straight_high(ranks: Array) -> int:
	var normalized: Array = ranks.duplicate()
	if normalized.has(14):
		normalized.append(1)
	normalized.sort()
	normalized.reverse()

	var run: int = 1
	for i in range(1, normalized.size()):
		if normalized[i] == normalized[i - 1]:
			continue
		if normalized[i] == normalized[i - 1] - 1:
			run += 1
			if run >= 5:
				return int(normalized[i - 4])
		else:
			run = 1
	return 0

static func _top_ranks(cards: Array, amount: int) -> Array:
	var ranks: Array = _unique_ranks(cards)
	return ranks.slice(0, amount)

static func _highest_excluding(ranks: Array, excluded: Array, amount: int) -> Array:
	var picked: Array = []
	for rank in ranks:
		if not excluded.has(rank):
			picked.append(rank)
			if picked.size() == amount:
				break
	return picked
