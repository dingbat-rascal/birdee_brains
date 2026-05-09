local M = {}

M.DEFAULTS = {
    -- CSV-based configuration
    csv_file        = "data/lesson1.csv",  -- Path to CSV file relative to config directory
    question_column = "en",                 -- Column to use for questions
    answer_column   = "es",                 -- Column to use for answers

    game_mode       = "multiple_choice",
    -- options "speedrun" or multiple_choice
    reveal_correct = true,
    reinforce      = true, -- reinforce things you get wrong

    input_keymap   = "german-qwertz",

    -- empty "" for english or view available with
    -- :echo globpath(&rtp, "keymap/*.vim")
    -- stored default list in available
    -- or you can use custom ones from ./nvim/keymap/example.vim dir
    -- you dont need full path just example.vim

    keybinds = {
        submit = "<CR>",           -- speedrun: submit answer
        refresh = "dd",            -- clear and refresh round
        quit = "q",                -- quit game
        escape = "<esc>",          -- escape to quit
        choice_keys = { "j", "k", "l", ";" },  -- multiple choice selection keys
    }
}

return M
