-- Balatrostuff: a starter pack of original Jokers for Steamodded.
-- The pack intentionally uses the game's built-in Joker atlas for now, so
-- it does not need a custom sprite sheet to load.

local joker_index = 0
local function register_joker(def)
    local sprite_pos = def.pos
    if not sprite_pos then
        sprite_pos = { x = joker_index % 6, y = math.floor(joker_index / 6) }
        joker_index = joker_index + 1
    end
    SMODS.Joker {
        key = def.key,
        name = def.name,
        rarity = def.rarity or 1,
        cost = def.cost or 5,
        blueprint_compat = def.blueprint_compat ~= false,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        -- The atlas is Balatro's built-in Joker sheet, not an atlas owned by this mod.
        -- Prevent Steamodded from rewriting it to the nonexistent `bstf_Joker` key.
        prefix_config = { atlas = false },
        atlas = 'Joker',
        pos = sprite_pos,
        config = def.config or { extra = def.extra or {} },
        loc_vars = def.loc_vars,
        loc_txt = {
            name = def.name,
            text = def.text,
        },
        calculate = def.calculate,
        add_to_deck = def.add_to_deck,
    }
end

register_joker {
    key = 'lucky_seven', name = 'Lucky Seven', cost = 4,
    text = { 'Played {C:attention}7s{} give', '{C:mult}+7{} Mult when scored' },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card:get_id() == 7 and not context.other_card.debuff then
            return { mult = 7, card = card }
        end
    end
}

register_joker {
    key = 'coin_king', name = 'Coin King', cost = 7,
    text = { '{C:mult}+1{} Mult for every {C:money}$5{} you have', '{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)' },
    extra = { mult = 0 },
    loc_vars = function(self, info_queue, card) return { vars = { math.min(50, math.floor((G.GAME.dollars or 0) / 5)) } } end,
    calculate = function(self, card, context)
        if context.joker_main then
            local value = math.min(50, math.floor(math.max(0, G.GAME.dollars or 0) / 5))
            if value > 0 then return { mult = value } end
        end
    end
}

register_joker {
    key = 'card_shark', name = 'Card Shark', cost = 5,
    text = { '{C:chips}+15{} Chips for each face card', 'held in your hand' },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand and context.other_card:is_face() and not context.other_card.debuff then
            return { chips = 15, card = card }
        end
    end
}

register_joker {
    key = 'jester_luck', name = "Jester's Luck", cost = 6,
    text = { '{C:mult}+20{} Mult if your hand is empty', 'after playing cards' },
    calculate = function(self, card, context)
        if context.joker_main and G.hand and #G.hand.cards == 0 then return { mult = 20 } end
    end
}

register_joker {
    key = 'matador', name = 'The Matador', cost = 6,
    text = { '{C:mult}+2{} Mult for each card', 'discarded this round' },
    config = { extra = { discarded = 0 } },
    calculate = function(self, card, context)
        if context.pre_discard and not context.blueprint then
            card.ability.extra.discarded = card.ability.extra.discarded + #G.hand.highlighted
            return { message = 'Counting!', card = card }
        end
        if context.joker_main then return { mult = math.min(40, card.ability.extra.discarded * 2) } end
        if context.end_of_round and context.main_eval and not context.blueprint then card.ability.extra.discarded = 0 end
    end
}

register_joker {
    key = 'pixel_perfect', name = 'Pixel Perfect', cost = 6,
    text = { '{C:chips}+8{} Chips for each different rank', 'in your scoring hand' },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local ranks = {}
            for _, playing_card in ipairs(context.scoring_hand) do ranks[playing_card:get_id()] = true end
            local count = 0
            for _ in pairs(ranks) do count = count + 1 end
            return { chips = count * 8 }
        end
    end
}

register_joker {
    key = 'vortex', name = 'Vortex', rarity = 2, cost = 8,
    text = { '{X:mult,C:white} X1.5 {} Mult if you have', 'a Spectral card in consumables' },
    calculate = function(self, card, context)
        if context.joker_main then
            for _, item in ipairs(G.consumeables.cards) do
                if item.config and item.config.center and item.config.center.set == 'Spectral' then return { xmult = 1.5 } end
            end
        end
    end
}

register_joker {
    key = 'the_gambler', name = 'The Gambler', rarity = 2, cost = 7,
    text = { '{C:green}1 in 3{} chance to give', '{X:mult,C:white} X3 {} Mult when scoring' },
    calculate = function(self, card, context)
        if context.joker_main and pseudorandom('bstf_gambler') < G.GAME.probabilities.normal / 3 then return { xmult = 3 } end
    end
}

register_joker {
    key = 'double_trouble', name = 'Double Trouble', rarity = 2, cost = 8,
    text = { '{X:mult,C:white} X1.5 {} Mult for each other', 'Joker you own (max X6)' },
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = math.min(6, 1 + 0.5 * math.max(0, #G.jokers.cards - 1)) } end
    end
}

register_joker {
    key = 'alchemist', name = 'The Alchemist', rarity = 2, cost = 7,
    text = { 'Creates a {C:tarot}Tarot{} card when', 'a {C:attention}Boss Blind{} is defeated', '{C:inactive}(Must have room)' },
    calculate = function(self, card, context)
        if context.end_of_round and context.main_eval and G.GAME.blind.boss and not context.blueprint and #G.consumeables.cards < G.consumeables.config.card_limit then
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
                if #G.consumeables.cards < G.consumeables.config.card_limit then
                    local created = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'bstf_alchemist')
                    created:add_to_deck(); G.consumeables:emplace(created)
                end
                return true
            end }))
            return { message = '+1 Tarot', colour = G.C.PURPLE, card = card }
        end
    end
}

register_joker {
    key = 'time_thief', name = 'Time Thief', cost = 6,
    text = { '{C:mult}+3{} Mult for each hand', 'played this round (max +30)' },
    calculate = function(self, card, context)
        if context.joker_main then return { mult = math.min(30, (G.GAME.current_round.hands_played or 0) * 3) } end
    end
}

register_joker {
    key = 'void_walker', name = 'Void Walker', rarity = 2, cost = 7,
    text = { '{C:chips}+20{} Chips for each {C:attention}Stone{} card', 'in your full deck (max +200)' },
    calculate = function(self, card, context)
        if context.joker_main then
            local count = 0
            for _, playing_card in ipairs(G.playing_cards or {}) do
                if SMODS.has_enhancement(playing_card, 'm_stone') then count = count + 1 end
            end
            if count > 0 then return { chips = math.min(200, count * 20) } end
        end
    end
}

register_joker {
    key = 'architect', name = 'The Architect', cost = 6,
    text = { '{C:chips}+30{} Chips if every card', 'in your scoring hand is enhanced' },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand and #context.scoring_hand > 0 then
            for _, playing_card in ipairs(context.scoring_hand) do
                if not (playing_card.config and playing_card.config.center and playing_card.config.center ~= G.P_CENTERS.c_base) then return end
            end
            return { chips = 30 }
        end
    end
}

register_joker {
    key = 'soulbound', name = 'Soulbound', rarity = 2, cost = 8,
    text = { '{C:mult}+4{} Mult for each {C:attention}Joker{}', 'you own, including this one' },
    calculate = function(self, card, context)
        if context.joker_main then return { mult = #G.jokers.cards * 4 } end
    end
}

register_joker {
    key = 'collector', name = 'The Collector', rarity = 2, cost = 7,
    text = { '{C:mult}+5{} Mult for each different', 'edition among your Jokers' },
    calculate = function(self, card, context)
        if context.joker_main then
            local editions = {}
            for _, joker in ipairs(G.jokers.cards) do if joker.edition then for edition in pairs(joker.edition) do editions[edition] = true end end end
            local count = 0; for _ in pairs(editions) do count = count + 1 end
            return { mult = count * 5 }
        end
    end
}

register_joker {
    key = 'bouncer', name = 'Bouncer', cost = 5,
    text = { '{C:chips}+4{} Chips for each card', 'remaining in your hand' },
    calculate = function(self, card, context)
        if context.joker_main then return { chips = #G.hand.cards * 4 } end
    end
}

register_joker {
    key = 'dreamer', name = 'The Dreamer', rarity = 2, cost = 8,
    text = { '{X:mult,C:white} X1.2 {} Mult for every', 'level your scoring hand has above 1' },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_name and G.GAME.hands[context.scoring_name] then
            local level = G.GAME.hands[context.scoring_name].level or 1
            if level > 1 then return { xmult = math.min(4, 1 + (level - 1) * 0.2) } end
        end
    end
}

register_joker {
    key = 'chaos', name = 'Chaos', rarity = 2, cost = 8,
    text = { 'Gives a random bonus each hand:', '{C:chips}+40{} Chips, {C:mult}+12{} Mult, or {X:mult,C:white} X2 {} Mult' },
    calculate = function(self, card, context)
        if context.joker_main then
            local roll = pseudorandom('bstf_chaos', 1, 3)
            if roll == 1 then return { chips = 40 } end
            if roll == 2 then return { mult = 12 } end
            return { xmult = 2 }
        end
    end
}

register_joker {
    key = 'the_eternal', name = 'The Eternal', rarity = 3, cost = 10,
    text = { '{X:mult,C:white} X1.5 {} Mult', 'This Joker cannot be debuffed' },
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = 1.5 } end
    end,
    add_to_deck = function(self, card, from_debuff) card.ability.eternal = true end,
}

register_joker {
    key = 'reroll_king', name = 'Reroll King', rarity = 2, cost = 7,
    text = { '{C:mult}+2{} Mult for each shop reroll', 'while you own this Joker (max +40)' },
    config = { extra = { rerolls = 0 } },
    calculate = function(self, card, context)
        if context.reroll_shop and not context.blueprint then card.ability.extra.rerolls = card.ability.extra.rerolls + 1 end
        if context.joker_main then return { mult = math.min(40, card.ability.extra.rerolls * 2) } end
    end
}

register_joker {
    key = 'marble_giant', name = 'Marble Giant', cost = 6,
    text = { '{C:chips}+50{} Chips if your scoring', 'hand contains a Stone card' },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            for _, playing_card in ipairs(context.scoring_hand) do
                if SMODS.has_enhancement(playing_card, 'm_stone') then return { chips = 50 } end
            end
        end
    end
}

register_joker {
    key = 'last_laugh', name = 'Last Laugh', rarity = 2, cost = 7,
    text = { '{C:mult}+25{} Mult on your final hand', 'of each round' },
    calculate = function(self, card, context)
        if context.joker_main and G.GAME.current_round.hands_left == 0 then return { mult = 25 } end
    end
}

register_joker {
    key = 'lucky_penny', name = 'Lucky Penny', cost = 5,
    text = { '{C:green}1 in 2{} chance to earn {C:money}$2{}', 'when a scoring card triggers' },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and pseudorandom('bstf_penny') < G.GAME.probabilities.normal / 2 then
            ease_dollars(2); return { message = '+$2', colour = G.C.MONEY, card = card }
        end
    end
}

register_joker {
    key = 'glass_cannon', name = 'Glass Cannon', rarity = 2, cost = 8,
    text = { '{X:mult,C:white} X3 {} Mult if your scoring hand', 'contains a Glass card' },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            for _, playing_card in ipairs(context.scoring_hand) do
                if SMODS.has_enhancement(playing_card, 'm_glass') then return { xmult = 3 } end
            end
        end
    end
}

register_joker {
    key = 'full_house_fund', name = 'Full House Fund', cost = 6,
    text = { 'Earn {C:money}$3{} when you play', 'a {C:attention}Full House{}' },
    calculate = function(self, card, context)
        if context.joker_main and next(context.poker_hands['Full House'] or {}) then ease_dollars(3); return { message = '+$3', colour = G.C.MONEY } end
    end
}

register_joker {
    key = 'ace_in_the_hole', name = 'Ace in the Hole', rarity = 2, cost = 7,
    text = { '{C:mult}+8{} Mult for each Ace', 'in your scoring hand' },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local count = 0; for _, playing_card in ipairs(context.scoring_hand) do if playing_card:get_id() == 14 then count = count + 1 end end
            if count > 0 then return { mult = count * 8 } end
        end
    end
}

register_joker {
    key = 'night_shift', name = 'Night Shift', rarity = 2, cost = 7,
    text = { '{X:mult,C:white} X2 {} Mult on the first hand', 'played after each blind begins' },
    config = { extra = { used = false } },
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then card.ability.extra.used = false end
        if context.joker_main and not card.ability.extra.used then card.ability.extra.used = true; return { xmult = 2 } end
    end
}

register_joker {
    key = 'tiny_titan', name = 'Tiny Titan', cost = 5,
    text = { '{C:chips}+6{} Chips for each card', 'in your deck with rank 2, 3, or 4' },
    calculate = function(self, card, context)
        if context.joker_main then
            local count = 0
            for _, playing_card in ipairs(G.playing_cards or {}) do local rank = playing_card:get_id(); if rank >= 2 and rank <= 4 then count = count + 1 end end
            if count > 0 then return { chips = count * 6 } end
        end
    end
}

-- The following additions are intentionally ridiculous. Balance is not the goal.
register_joker {
    key = 'multiverse_engine', name = 'Multiverse Engine', rarity = 3, cost = 20,
    text = { '{X:mult,C:white} X5 {} Mult and {C:chips}+500{} Chips', 'every scoring hand' },
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = 5, chips = 500 } end
    end
}

register_joker {
    key = 'seven_singularity', name = 'Seven Singularity', rarity = 3, cost = 15,
    text = { 'Every played {C:attention}7{} gives {C:mult}+77{} Mult', 'and {X:mult,C:white} X2 {} Mult when scored' },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card:get_id() == 7 and not context.other_card.debuff then
            return { mult = 77, card = card }
        end
        if context.joker_main then return { xmult = 2 } end
    end
}

register_joker {
    key = 'infinite_wallet', name = 'Infinite Wallet', rarity = 3, cost = 25,
    text = { 'Earn {C:money}$10{} at the end of each hand', 'and {C:mult}+1{} Mult for every $10 you have (max +100)' },
    calculate = function(self, card, context)
        if context.joker_main then
            local value = math.min(100, math.floor(math.max(0, G.GAME.dollars or 0) / 10))
            return { mult = value }
        end
        if context.after and context.main_eval and not context.blueprint then
            ease_dollars(10)
            return { message = '+$10', colour = G.C.MONEY, card = card }
        end
    end
}

register_joker {
    key = 'hand_of_gods', name = 'Hand of Gods', rarity = 3, cost = 20,
    text = { '{C:chips}+100{} Chips and {C:mult}+25{} Mult', 'for every card in your scoring hand' },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local n = #context.scoring_hand
            return { chips = n * 100, mult = n * 25 }
        end
    end
}

register_joker {
    key = 'the_red_button', name = 'The Red Button', rarity = 3, cost = 30,
    text = { 'Retrigger every other Joker', '{C:inactive}(plus X3 Mult)' },
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = 3 } end
        if context.retrigger_joker_check and not context.retrigger_joker then
            return { repetitions = 1, card = card }
        end
    end
}

register_joker {
    key = 'planet_eater', name = 'Planet Eater', rarity = 3, cost = 20,
    text = { 'When a hand scores, upgrade its level', 'and give {C:mult}+20{} Mult' },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_name and not context.blueprint then
            level_up_hand(card, context.scoring_name, true, 1)
            return { mult = 20, message = 'LEVEL UP!' }
        end
    end
}

register_joker {
    key = 'glass_god', name = 'Glass God', rarity = 3, cost = 18,
    text = { 'Each scoring card gives', '{X:mult,C:white} X2 {} Mult' },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card and not context.other_card.debuff then
            return { xmult = 2, card = card }
        end
    end
}

register_joker {
    key = 'joker_black_hole', name = 'Joker Black Hole', rarity = 3, cost = 30,
    text = { '{X:mult,C:white} X2 {} Mult for each Joker you own', 'and {C:chips}+100{} Chips for each Joker' },
    calculate = function(self, card, context)
        if context.joker_main then
            local n = #G.jokers.cards
            return { xmult = 2 ^ math.max(1, n), chips = n * 100 }
        end
    end
}

-- Custom Tarot consumables use Balatro's built-in Tarot atlas as placeholder art.
local function register_broken_tarot(def)
    SMODS.Consumable {
        key = def.key,
        set = 'Tarot',
        name = def.name,
        cost = def.cost or 4,
        unlocked = true,
        discovered = true,
        prefix_config = { atlas = false },
        atlas = 'Tarot',
        pos = def.pos or { x = 0, y = 0 },
        loc_txt = { name = def.name, text = def.text },
        can_use = def.can_use,
        use = def.use,
    }
end

register_broken_tarot {
    key = 'money_printer', name = 'Money Printer', cost = 0,
    text = { 'Create {C:money}$100{}' },
    use = function(self, card, area, copier) ease_dollars(100) end,
}

register_broken_tarot {
    key = 'hand_of_fate', name = 'Hand of Fate', cost = 0,
    text = { 'Upgrade every poker hand', '{C:attention}5{} times' },
    use = function(self, card, area, copier)
        for hand_key, hand in pairs(G.GAME.hands) do
            if type(hand) == 'table' and hand.level then
                level_up_hand(card, hand_key, true, 5)
            end
        end
    end,
}

register_broken_tarot {
    key = 'joker_festival', name = 'Joker Festival', cost = 0,
    text = { 'Create up to {C:attention}2{} random Jokers', '{C:inactive}(Must have room)' },
    can_use = function(self, card)
        return G.jokers and #G.jokers.cards < G.jokers.config.card_limit
    end,
    use = function(self, card, area, copier)
        for i = 1, 2 do
            if #G.jokers.cards < G.jokers.config.card_limit then
                local joker = create_card('Joker', G.jokers, nil, nil, nil, nil, nil, 'bstf_festival')
                joker:add_to_deck()
                G.jokers:emplace(joker)
            end
        end
    end,
}

register_broken_tarot {
    key = 'the_big_bang', name = 'The Big Bang', cost = 0,
    text = { 'Gain {C:attention}+3{} hands this round', 'and {C:money}$50{}' },
    use = function(self, card, area, copier)
        ease_hands_played(3)
        ease_dollars(50)
    end,
}

-- v0.3.0: arithmetic operators, reality-breaking consumables, decks and stakes.
-- The balance target is intentionally absurd; the effects are still bounded where
-- an unbounded loop or recursive scoring would risk locking up a run.

register_joker {
    key = 'operator_plus', name = 'Operator: PLUS', rarity = 3, cost = 20,
    text = { 'Add {C:chips}+777{} Chips and {C:mult}+77{} Mult', 'then add another +7 Mult per Joker' },
    calculate = function(self, card, context)
        if context.joker_main then return { chips = 777, mult = 77 + (#G.jokers.cards * 7) } end
    end
}

register_joker {
    key = 'operator_times', name = 'Operator: TIMES', rarity = 3, cost = 25,
    text = { 'Multiply Mult by {X:mult,C:white} X7 {}', 'and gain {C:chips}+777{} Chips' },
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = 7, chips = 777, message = 'TIMES SEVEN!' } end
    end
}

register_joker {
    key = 'operator_power', name = 'Operator: POWER', rarity = 4, cost = 40,
    text = { 'Multiply final Mult by {X:mult,C:white} X10 {}', '{C:inactive}(The exponential operator is too unstable)' },
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = 10, message = 'EXPONENTIATED' } end
    end
}

register_joker {
    key = 'operator_factorial', name = 'Operator: FACTORIAL', rarity = 4, cost = 50,
    text = { 'Gain {C:mult}+25{} Mult for each card scored', 'and {X:mult,C:white} X3 {} Mult for each Ace' },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local aces = 0
            for _, c in ipairs(context.scoring_hand) do if c:get_id() == 14 then aces = aces + 1 end end
            return { mult = #context.scoring_hand * 25, xmult = 3 ^ math.min(aces, 8) }
        end
    end
}

register_joker {
    key = 'blue_screen', name = 'Blue Screen of God', rarity = 4, cost = 50,
    text = { '{X:mult,C:white} X25 {} Mult and {C:chips}+2500{} Chips', 'if your hand contains a Pair or better' },
    calculate = function(self, card, context)
        if context.joker_main and context.poker_hands then
            for _, hand_name in ipairs({'Pair','Two Pair','Three of a Kind','Straight','Flush','Full House','Four of a Kind','Straight Flush','Five of a Kind','Flush House','Flush Five'}) do
                if next(context.poker_hands[hand_name] or {}) then return { xmult = 25, chips = 2500 } end
            end
        end
    end
}

register_joker {
    key = 'ante_eater', name = 'Ante Eater', rarity = 4, cost = 45,
    text = { 'At end of round, gain {C:money}$20{}', 'and {X:mult,C:white} X2 {} Mult per Ante (max X64)' },
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = math.min(64, 2 ^ math.max(0, (G.GAME.round_resets.ante or 1) - 1)) } end
        if context.end_of_round and context.main_eval and not context.blueprint then
            ease_dollars(20); return { message = '+$20', colour = G.C.MONEY, card = card }
        end
    end
}

register_joker {
    key = 'duplicate_machine', name = 'Duplicate Machine', rarity = 4, cost = 40,
    text = { 'Create a copy of a random Joker', 'when a Boss Blind is defeated (room required)' },
    calculate = function(self, card, context)
        if context.end_of_round and context.main_eval and G.GAME.blind.boss and not context.blueprint and #G.jokers.cards < G.jokers.config.card_limit then
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
                if #G.jokers.cards < G.jokers.config.card_limit and #G.jokers.cards > 0 then
                    local source = pseudorandom_element(G.jokers.cards, pseudorandom('bstf_dup_machine'))
                    if source then local copy = copy_card(source); copy:add_to_deck(); G.jokers:emplace(copy) end
                end
                return true
            end }))
            return { message = 'COPY MACHINE!', colour = G.C.PURPLE, card = card }
        end
    end
}

register_joker {
    key = 'infinity_loop', name = 'Infinity Loop', rarity = 4, cost = 50,
    text = { 'Retrigger each played card {C:attention}3{} times', 'and gain {C:mult}+3{} Mult per retrigger' },
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and not context.repetition_only then
            return { repetitions = 3, message = 'AGAIN!' }
        end
        if context.joker_main then return { mult = 3 * #G.play.cards } end
    end
}

register_broken_tarot {
    key = 'operator_add', name = 'Operator: Add', cost = 0,
    text = { 'Gain {C:money}$777{} and {C:chips}+777{} chips this round' },
    use = function(self, card, area, copier)
        ease_dollars(777)
        G.GAME.chips = (G.GAME.chips or 0) + 777
    end,
}

register_broken_tarot {
    key = 'operator_multiply', name = 'Operator: Multiply', cost = 0,
    text = { 'Upgrade every poker hand {C:attention}10{} times' },
    use = function(self, card, area, copier)
        for hand_key, hand in pairs(G.GAME.hands) do
            if type(hand) == 'table' and hand.level then level_up_hand(card, hand_key, true, 10) end
        end
    end,
}

register_broken_tarot {
    key = 'operator_power', name = 'Operator: Power', cost = 0,
    text = { 'Create {C:attention}3{} random Jokers', 'and make them {C:dark_edition}Polychrome{}' },
    can_use = function(self, card) return G.jokers and #G.jokers.cards < G.jokers.config.card_limit end,
    use = function(self, card, area, copier)
        for i = 1, 3 do
            if #G.jokers.cards < G.jokers.config.card_limit then
                local joker = create_card('Joker', G.jokers, nil, nil, nil, nil, nil, 'bstf_op_power')
                joker:set_edition({polychrome = true}, true)
                joker:add_to_deck(); G.jokers:emplace(joker)
            end
        end
    end,
}

register_broken_tarot {
    key = 'reality_reset', name = 'Reality Reset', cost = 0,
    text = { 'Create a random {C:spectral}Spectral{} card', 'and gain {C:money}$1000{}' },
    use = function(self, card, area, copier)
        ease_dollars(1000)
        if #G.consumeables.cards < G.consumeables.config.card_limit then
            local created = create_card('Spectral', G.consumeables, nil, nil, nil, nil, nil, 'bstf_reality')
            created:add_to_deck(); G.consumeables:emplace(created)
        end
    end,
}

-- A small set of deliberately unfair custom stakes. Effects are applied only at run start.
local function register_unfair_stake(key, name, description, colour, scaling_add, dollars, above, applied)
    SMODS.Stake {
        key = key,
        name = name,
        above_stake = above,
        applied_stakes = applied,
        prefix_config = { atlas = false, sticker_atlas = { mod = false }, above_stake = { mod = false }, applied_stakes = { mod = false } },
        unlocked = true,
        discovered = true,
        colour = colour,
        atlas = 'Joker',
        pos = { x = 0, y = 0 },
        sticker_pos = { x = 0, y = 0 },
        sticker_atlas = 'Joker',
        loc_txt = { name = name, text = { description } },
        modifiers = function(self)
            G.GAME.modifiers = G.GAME.modifiers or {}
            G.GAME.modifiers.scaling = (G.GAME.modifiers.scaling or 1) + scaling_add
            G.GAME.starting_params.dollars = (G.GAME.starting_params.dollars or 4) - dollars
        end,
    }
end

register_unfair_stake('apocalypse', 'Apocalypse Stake', 'Blinds scale 2x faster and start with $2 less.', G.C.RED, 1, 2, 'stake_gold', {'stake_gold'})
register_unfair_stake('cataclysm', 'Cataclysm Stake', 'Blinds scale 4x faster and start with $4 less.', G.C.PURPLE, 2, 2, 'bstf_apocalypse', {'stake_gold', 'bstf_apocalypse'})
register_unfair_stake('unfair', 'UNFAIR Stake', 'Blinds scale 8x faster. Start broke. Good luck.', G.C.BLACK, 4, 4, 'bstf_cataclysm', {'stake_gold', 'bstf_apocalypse', 'bstf_cataclysm'})

-- New decks use the built-in back atlas to avoid requiring extra sprite files.
SMODS.Back {
    key = 'operator_deck',
    name = 'Operator Deck',
    atlas = 'Joker',
    prefix_config = { atlas = false },
    pos = { x = 0, y = 0 },
    config = { joker_slot = 2, consumable_slot = 2 },
    loc_txt = { name = 'Operator Deck', text = { 'Start with {C:attention}+2{} Joker slots', 'and {C:attention}+2{} consumable slots', 'All Operator consumables cost $0' } },
}

SMODS.Back {
    key = 'chaos_deck',
    name = 'Chaos Deck',
    atlas = 'Joker',
    prefix_config = { atlas = false },
    pos = { x = 1, y = 0 },
    config = { dollars = 100, hands = 2, discards = 2 },
    loc_txt = { name = 'Chaos Deck', text = { 'Start with {C:money}$100{}', '{C:attention}+2{} hands and discards', 'Boss Blinds are stronger' } },
}
