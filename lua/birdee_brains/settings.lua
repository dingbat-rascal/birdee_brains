local M = {}

M.DEFAULTS = {
    -- CSV-based configuration
    csv_file = "",                            -- Will be set dynamically from lesson selection
    data_directory = "lua/birdee_brains/data/",  -- Directory containing CSV lesson files
    question_column = nil,                    -- Column to use for questions
    answer_column = nil,                      -- Column to use for answers

    game_mode = "multiple_choice",            -- options: "speedrun" or "multiple_choice"
    
    -- Multiple choice settings
    reveal_correct = true,                    -- Highlight correct answer when wrong
    reveal_delay = 2000,                      -- Milliseconds to show correct answer (2 seconds)
    
    -- Reinforcement learning
    reinforce = true,                         -- Reinforce things you get wrong
    reinforce_chance = 0.7,                   -- Probability (0.0-1.0) to show mistake bucket questions

    -- Speedrun settings
    input_keymap = "",                        -- Keymap for speedrun input (e.g., "kana", "german-qwertz")
    -- empty "" for english or view available with
    -- :echo globpath(&rtp, "keymap/*.vim")
    -- or you can use custom ones from ./nvim/keymap/example.vim dir
    -- you dont need full path just example.vim

    keybinds = {
        submit = "<CR>",                      -- speedrun: submit answer
        refresh = "dd",                       -- clear and refresh round
        quit = "q",                           -- quit game
        escape = "<esc>",                     -- escape to quit
        choice_keys = { "j", "k", "l", ";" }, -- multiple choice selection keys
    },

    debug = false,
}

return M
