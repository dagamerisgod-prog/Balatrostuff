# Balatrostuff

A standalone Steamodded content pack with **28 Jokers** covering money, face cards, Aces, Stone and Glass cards, hand levels, discards, shop rerolls, and random bonuses. It uses the game's built-in Joker atlas for now, so the pack does not need separate image assets to load.

## Included Jokers

Lucky Seven, Coin King, Card Shark, Jester's Luck, The Matador, Pixel Perfect, Vortex, The Gambler, Double Trouble, The Alchemist, Time Thief, Void Walker, The Architect, Soulbound, The Collector, Bouncer, The Dreamer, Chaos, The Eternal, Reroll King, Marble Giant, Last Laugh, Lucky Penny, Glass Cannon, Full House Fund, Ace in the Hole, Night Shift, and Tiny Titan.

## Install for testing

1. Your folder already contains Steamodded (`smods-26.829.0`) and Lovely-related files, and it has many other mods installed.
2. The mod is installed at `%AppData%/Balatro/Mods/Balatrostuff/` with `Balatrostuff.json` and `main.lua`.
3. Launch the game, check the Mods menu for Balatrostuff, then start a fresh run and look for the new Jokers in the shop.

The mod's files and metadata have been checked, but I have not confirmed that it loads or that every effect works in a live run. The cards currently use built-in Joker artwork as placeholders. If the game reports an API error, check the newest game log in `%AppData%/Balatro/logs/` and adjust the pack to that installed version.

The standard Steamodded setup does not require signing in to Steam, but the exact game build still needs to be compatible with the installed injector and mod loader. For current setup details, see the [Steamodded documentation](https://docs.smods.dev/).
