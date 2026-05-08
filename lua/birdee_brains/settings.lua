local M = {}

M.DEFAULTS = {
    -- You can also point both bird_dir to the same ex (english, and english) to get a typing trainer.
    bird_a         = "spanish",
    bird_b         = "english",
    course_number  = 1,

    game_mode      = "multiple_choice",
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
