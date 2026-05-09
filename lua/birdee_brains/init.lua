local M = {}

local settings_module = require("birdee_brains.settings")
local dictionary_module = require("birdee_brains.dictionary")
local game_engine_module = require("birdee_brains.game_engine")
local ui_module = require("birdee_brains.ui")
local keymaps_module = require("birdee_brains.keymaps")

function M.setup(opts)
    vim.keymap.set('n', '<C-g>', M.launch, { silent = true, desc = "Start Game" })
    M.SETTINGS = vim.tbl_deep_extend("force", settings_module.DEFAULTS, opts or {})
end

function M.launch()
    local SETTINGS = M.SETTINGS

    -- Load dictionaries from CSV
    local questions, answers, csv_metadata = dictionary_module.load_dictionary(SETTINGS)

    -- Create game engine
    local engine = game_engine_module.create_engine(SETTINGS)
    engine.csv_metadata = csv_metadata  -- Store metadata for potential future use

    -- Create buffer and window
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = 45,
        height = 12,
        col = (vim.o.columns - 50) / 2,
        row = (vim.o.lines - 12) / 2,
        style = 'minimal',
        border = 'rounded'
    })
    local ns_id = vim.api.nvim_create_namespace("game_feedback")

    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })

    vim.api.nvim_buf_call(buf, function()
        -- Disable autocomplete
        vim.cmd("setlocal completeopt=")
        vim.cmd("setlocal completefunc=")
        vim.cmd("setlocal omnifunc=")

        if SETTINGS.game_mode == "speedrun" and SETTINGS.input_keymap ~= "" then
            vim.cmd("setlocal keymap=" .. SETTINGS.input_keymap)
            vim.cmd("setlocal iminsert=1")
        else
            vim.cmd("setlocal keymap=")
            vim.cmd("setlocal iminsert=0")
        end
    end)

    -- Setup UI
    ui_module.setup_highlights()

    -- Next round function
    local function next_round()
        engine:select_target(questions)

        local choices
        if SETTINGS.game_mode == "multiple_choice" then
            choices = engine:generate_choices(answers, answers[engine.target_idx])
            engine.current_choices = choices
        end

        local layout = ui_module.build_layout(engine, questions, choices, SETTINGS.game_mode)
        ui_module.render(buf, win, layout, SETTINGS.game_mode)
    end

    -- Setup keymaps
    keymaps_module.setup_keymaps(buf, win, engine, questions, answers, SETTINGS, next_round)

    -- Setup game-specific input handlers
    if SETTINGS.game_mode == "speedrun" then
        keymaps_module.setup_speedrun_input(buf, engine, questions, answers, SETTINGS, ns_id, next_round)
    else
        keymaps_module.setup_multiple_choice_input(buf, engine, answers, SETTINGS, ns_id, next_round)
    end

    -- Start the game
    next_round()
end

return M
