<p align="center">
  <pre>
  _______
 < Hoo! >
  ------\ ,_,
 _       (O,o)    _             
( )    _ {`"'}   ( )            
| |_  (_)_-_-   _| |  __    __  
|  _ \| |  __)/ _  |/ __ \/ __ \  ,_,
| |_) ) | |  ( (_| |  ___/  ___/ {O,o}/)
(_ __/(_)_)   \__ _)\____)\____) /)__)'
   B  R  A  I  N  S               " "
  </pre>
</p>

# Birdee Brains a fully Customizable Quiz Mini Game for Neovim

> Named after superuser [Birdee](https://github.com/BirdeeHub/) creator of [nixCats](https://github.com/BirdeeHub/nixCats-nvim)

A quick fun, interactive way to practice flash card style, or multiple choice
vocabulary directly inside your editor with vim motions. Features
multiple-choice and speedrun modes with reinforcement learning for mistakes.
Initially made for language learning and foreign keyboard typing in downtime
between submitting pull request and master-minding. Behold the ability to
communicate. Made to be fully customizable for any subject in true vim spirit.

- Using .csv file (spreadsheet) Enter a question in a column and answer in the
  next followed by incorrect answers.

- Keymaps on input buffer if you want to practice your typing, keybinds
  (Portuguese dvorak, Swedish colmac/w accents).

## Recommended

I highly recommend using (https://github.com/hat0uma/csvview.nvim) for editing
.csv files. Great plugin hats off to hat0uma. You may need to configure toggle
to a keybind. I noticed toggle off and on re-organizes the table better.

### Preview

<div style="overflow-x: auto; display: flex; gap: 10px; padding-bottom: 10px;">
<img height="250" alt="mcm" src="https://github.com/user-attachments/assets/86535930-0111-4d4c-8297-d775560a38ba" />
<img height="250" alt="mc" src="https://github.com/user-attachments/assets/67087ee1-9fe0-4d72-b826-e78d2c29ec47" />
<img height="250" alt="mc1" src="https://github.com/user-attachments/assets/18067ca4-38e6-4eea-8f74-4e4a2bf06ded" />
<img height="250" alt="mc2" src="https://github.com/user-attachments/assets/04512f5c-5965-4e44-b88c-b440d2325e70" />
<img height="250" alt="sr1" src="https://github.com/user-attachments/assets/b9d209e1-3415-4754-89e6-61b475484cb9" />
<img height="250" alt="sr2" src="https://github.com/user-attachments/assets/9e427a45-f59e-4663-99e8-8c39067ba097" />
</div>

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
    "dingbat-rascal/birdee_brains",
    keys = {
        { "<C-g>", function () require("birdee_brains").launch() end, desc = "Start Birdee Brains" },
    },
    opts = {
        -- Leave empty for lesson selection menu or set to load one on start
        csv_file = "",

        -- Data directory (optional - auto-detected if not set)
        -- Set this to use a custom directory for your CSV lessons
        -- Examples: "~/my_lessons/", "/path/to/obsidian/vault/flashcards/"
        data_directory = nil, -- Default: plugin's lua/birdee_brains/data/

        -- CSV column configuration (optional - defaults to first two columns)
        -- Specify which columns contain questions and answers
        question_column = nil, -- Default: first column (e.g., "en")
        answer_column = nil,   -- Default: second column (e.g., "fr")
        -- Note: CSV files can have 2+ columns; only question/answer columns are used

        -- Game mode: "multiple_choice" or "speedrun"
        -- TODO: madlib, matching, timed
        game_mode = "multiple_choice",

        -- Multiple choice settings
        reveal_correct = true, -- Highlight correct answer when you get it wrong
        reveal_delay = 2000,   -- Milliseconds to show correct answer (default: 2000ms / 2 seconds)

        -- Reinforcement learning: re-quiz on mistakes
        reinforce = true,         -- Enable mistake reinforcement
        reinforce_chance = 0.7,   -- Probability (0.0-1.0) to show questions from mistake bucket (default: 0.7 = 70%)

        -- Speedrun mode settings
        input_keymap = "", -- Keymap for speedrun input (e.g., "kana" for Japanese)
        -- View available keymaps: :echo globpath(&rtp, "keymap/*.vim")
        -- Or create custom ones in ~/.config/nvim/keymap/example.vim
    },

    keybinds = {
        submit = "<CR>",           -- speedrun: submit answer
        refresh = "dd",            -- clear and refresh round
        quit = "q",                -- quit game
        escape = "<esc>",          -- escape to quit
        choice_keys = { "j", "k", "l", ";" },  -- multiple choice selection keys
    },
}
```

### Quick Start

1. Install the plugin
2. Press `<C-g>` to launch
3. Select a lesson from the menu (or configure `csv_file` to skip the menu)
4. In **multiple choice** mode: Press `jkl;` to select answers
5. In **speedrun** mode: Type the answer and press Enter

### Creating Custom Lessons

#### Basic CSV Format

Create CSV files with at least 2 columns. The first row contains column headers:

```csv
example - en,fr
Question text here,answer
Another question,another answer
```

By default, the plugin uses:

- **First column** as questions
- **Second column** as answers

#### Custom Column Configuration

You can add more columns and specify which to use:

```csv
en,fr,notes
Je ___ un étudiant,suis,verb: être (to be)
Tu ___ un chat,as,verb: avoir (to have)
or a third translation
```

Then configure which columns to use: by default its 1 and 2.

```lua
opts = {
    question_column = "en",  -- Use the "en" column for questions
    answer_column = "fr",    -- Use the "fr" column for answers
    -- The "notes" column will be ignored
}
```

## History

    Originally conceived as an opensource **Duolingo** alternitive Neovim,
    birdee_brains has evolved into a general purpose learning tool to reinforce
    consepts. Weather its a forign language, keybinds, bash_commands, you fill
    in the blanks. The world is your bash_shell.

## Roadmap
    - [ ] **Emoji to Image:*** Option to enable render of images linked to emojis.
    - [ ] **Curriculum Creator:** Add another app/program to easily add, modify and expand lessons. This
      will let you make your own curriculum.
    - [ ] **Analytics Suit:** A grading/progression system to display highscores and charts of your
      record allowing you to easily identify your strengths, and weak points.
    - [ ] **Streak System:** Reminder to check in. Display steak to insitivise
      daily practice.
    - [ ] **Universal Phonetic Alphabet:** Incorporate a way to display the International
      Phonetic Alphabet.
    - [ ] **Obsidian:** Abillity to use an obsidian vault as a path.
    - [ ] **Matching Mode:** Match asdf to jkl; with a timer.

<img width="500" height="375" alt="ralphlearning" src="https://github.com/user-attachments/assets/272a4a63-e7d7-4713-bce3-6add3333caed" />
