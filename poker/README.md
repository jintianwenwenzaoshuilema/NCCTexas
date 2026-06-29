# Texas Hold'em Core

Copy this folder to `res://scripts/poker/` in a Godot 4 project.

Main entry point:

```gdscript
var game := HoldemGame.new()

game.setup([
	{"id": "Hero", "chips": 1000},
	{"id": "BotA", "chips": 1000},
	{"id": "BotB", "chips": 1000},
], 5, 10)

game.action_required.connect(func(player, legal_actions):
	print("Acting:", player.id, legal_actions)
)

game.start_hand()
```

Implemented:

- 52-card deck and shuffle/deal.
- Button, small blind, and big blind logic for heads-up and 3+ players.
- Preflop, flop, turn, river, showdown flow.
- Fold/check/call/bet/raise/all-in.
- Betting round completion.
- Seven-card hand evaluation.
- Side pot construction and payout.

Useful actions:

```gdscript
game.act("fold")
game.act("check")
game.act("call")
game.act("bet", 30)    # total bet for this round
game.act("raise", 80)  # total bet for this round
game.act("all_in")
```

The `bet` and `raise` amount is the player's total committed amount in the current betting round, not the extra amount to add.

Run the core regression tests from the project root with:

```sh
godot --headless --path . -s res://tests/poker_core_tests.gd
```
