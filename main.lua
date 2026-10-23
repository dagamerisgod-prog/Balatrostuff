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
