class_name HoldemDeck
extends RefCounted

var cards: Array = []

func _init() -> void:
	reset()

func reset() -> void:
	cards.clear()
	for suit in range(4):
		for rank in range(2, 15):
			cards.append(HoldemCard.new(rank, suit))

func shuffle() -> void:
	cards.shuffle()

func deal_one() -> HoldemCard:
	assert(cards.size() > 0, "Cannot deal from an empty deck.")
	return cards.pop_back()

func burn() -> HoldemCard:
	return deal_one()

func remaining_count() -> int:
	return cards.size()
