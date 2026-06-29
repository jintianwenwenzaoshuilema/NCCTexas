class_name HoldemCard
extends RefCounted

enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES }

const RANK_NAMES: Dictionary = {
	2: "2",
	3: "3",
	4: "4",
	5: "5",
	6: "6",
	7: "7",
	8: "8",
	9: "9",
	10: "T",
	11: "J",
	12: "Q",
	13: "K",
	14: "A",
}

const SUIT_NAMES: Dictionary = {
	Suit.CLUBS: "c",
	Suit.DIAMONDS: "d",
	Suit.HEARTS: "h",
	Suit.SPADES: "s",
}

var rank: int
var suit: int

func _init(card_rank: int = 2, card_suit: int = Suit.CLUBS) -> void:
	rank = card_rank
	suit = card_suit

func code() -> String:
	return "%s%s" % [RANK_NAMES.get(rank, "?"), SUIT_NAMES.get(suit, "?")]

func same_as(other: HoldemCard) -> bool:
	return rank == other.rank and suit == other.suit
