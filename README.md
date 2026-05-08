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
(_ __/(_)_)   \__ _)\____)\____) /)__)-
   B  R  A  I  N  S               " "
  </pre>
</p>

# Birdee Brains a fully Customizable Quiz Mini Game for Neovim
> Named after wicked smart nix_cats creator Birdee (https://github.com/BirdeeHub)

A quick fun, interactive way to practice flash card style, or multiple choice vocabulary directly inside your editor with vim motions. 
Features multiple-choice and speedrun modes with reinforcement learning for mistakes.
Initially made for language learning and foreign keyboard typing in downtime between master-minding. Behold the ability to communicate. But also made to
be fully customizable for any subject or topic that you need to reinforce.
Sweet tasty delicious strength training for your brain mhmm goooood delicious.
Oh the burn do you feel it, get those neurons fired up and smoking.

Two directories bird_a and bird_b (interchangable answer and key). Simply set both to the same
bird and course/brain If you want to practice your
typing, keybinds (Portuguese dvorak, Swedish colmac/w accents).

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
return {
    "dingbat-rascal/birdee_brains",
    keys = {
        { "<C-g>", function () require("birdee_brains").launch( ) end, desc = "Start" },
    },
  opts = {
    bird_a = "spanish",
    bird_b = "english", -- Doesn't need to be languages, can be anything. But
    -- both directories must have the same number of indexes, and questions
    -- must correlate to answers question_1 : answer_1.
    course_number = 1,
    game_mode = "multiple_choice", -- or "speedrun"
    reveal_correct = true, -- highlights the correct answer on wrong entry.
    reinforcement = true, -- a chance to loop answers you got wrong.
    input_keymap = "kana" -- these are toggled only on input of prompt.
    -- empty "" for english or view default available with
    -- :echo globpath(&rtp, "keymap/*.vim")
    -- or you can use custom ones make dir ./nvim/keymap/example.vim dir
    -- you dont need full path just "example" this is default vim behavior.
  },
}
```

## History
    Originally conceived as an opensource **Duolingo** alternitive Neovim, birdee_brains
    has evolved into a general purpose learning tool to reinforce consepts.
    "HOOOO!". No more pencils no more books. Weather its a forign language,
    keybinds, bash_commands, you fill in the blanks. The world is your bash_shell.

## Roadmap
    - [ ] **Curriculum Creator:** Add another app/program to easily add, modify and expand lessons. This
      will let you make your own curriculum.
    - [ ] **Analytics Suit:** A grading/progression system to display highscores and charts of your
      record allowing you to easily identify your strengths, and weak points.
    - [ ] **Streak System:** Reminder to check in. Display steak to insitivise
      daily practice. 
    - [ ] **Phonetic Alphabet:** Incorporate a way to display the International
      Phonetic Alphabet.
    - [ ] **UserDefined Directories:** Allow users to easily set bird directory.
      Abillity to use an obsidian vault as a path.
