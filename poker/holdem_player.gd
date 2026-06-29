class_name HoldemPlayer
extends RefCounted

var id: String
var seat_index: int
var chips: int
var hole_cards: Array = []

var current_bet: int = 0
var total_committed: int = 0
var has_folded: bool = false
var is_all_in: bool = false
var has_acted: bool = false

func _init(player_id: String = "", starting_chips: int = 0, seat: int = 0) -> void:
	id = player_id
	chips = starting_chips
	seat_index = seat

func reset_for_hand() -> void:
	hole_cards.clear()
	current_bet = 0
	total_committed = 0
	has_folded = false
	is_all_in = chips <= 0
	has_acted = false

func reset_for_betting_round() -> void:
	current_bet = 0
	has_acted = false

func can_act() -> bool:
	return not has_folded and not is_all_in and chips > 0

func commit(amount: int) -> int:
	var paid: int = mini(maxi(amount, 0), chips)
	chips -= paid
	current_bet += paid
	total_committed += paid
	if chips == 0:
		is_all_in = true
	return paid

func receive(amount: int) -> void:
	chips += maxi(amount, 0)
	if chips > 0:
		is_all_in = false
