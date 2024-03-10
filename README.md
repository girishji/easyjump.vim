# EasyJump.vim

Jump to any location on screen by typing two characters.

### TL;DR

- `s` + _character1_  + _character2_ to jump
- `ds` + _character1_ + _character2_ to delete (similarly, `v` for visual selection, `c` for change, etc.)
- `<tab>` or `;` or `,` after _character1_ to view additional tag characters (_character2_)

### Features

- Initially bound to `s`, but it can be reassigned to any desired trigger (e.g., `,`).
- Supports essential Vim idioms such as `ds` for deletion, `cs` for change, `vs` for visual selection, and more. Here `s` is the trigger character.
- Updates the jump list (`:jumps`) for easy back-navigation using `<c-o>`.
- Non-disruptive: Does not modify the buffer. Crafted in vim9 script.


🚀 **Jump (`s`)**: Type `s` followed by a character (say `c`). Witness
new tag characters replacing the character `c`. Typing next
character initiates the jump. For instance, typing `e`
navigates the cursor to the `c` under `e`.

<img src='https://gist.githubusercontent.com/girishji/40e35cd669626212a9691140de4bd6e7/raw/6041405e45072a7fbc4e352cbd461e450a7af90e/easyjump-img1.jpeg' width='700'>

🚀 **Jump back**: Type `<c-o>` (control-O) to jump back. Type `<tab>` or `<c-i>` to jump forward.

🚀 **Visual Select (`vs`)**: For visually selecting a block of text from the
cursor position up to an instance of `c`, enter `vsc`, then the highlighted
character (e.g., `e`).

<img src='https://gist.githubusercontent.com/girishji/40e35cd669626212a9691140de4bd6e7/raw/6041405e45072a7fbc4e352cbd461e450a7af90e/easyjump-img2.jpeg' width='700'>

Likewise, use `ds` for deletion or `cs` for text alteration.

Press `<esc>` to cancel the ongoing jump.

Pictures above are based on `:colorscheme quiet`.

**What if the intended jump location is not showing a tag letter?**

This scenario occurs when there aren't enough unique letters available for
tagging. Simply type `<Tab>` (or `,`, or `;`), and you'll see new tag letters
populate the remaining locations.

**Tips:**

- One quick way to navigate without thinking too much is to search for a space
  character. Try '`s `' (`s` followed by `<space>`). Type another character and
  it often puts the cursor in close proximity of your destination.
- Vim's builtin `f/F, t/T` commands are often the quickest way to jump within a line. Use it
  as appropriate.

Over time, I relied on relative line numbers for navigation. However, I found it
distracting to constantly shift
focus to the left to identify line numbers. This plugin enables seamless
targeting and allows users to maintain focus on the task at hand.

# Requirements

- Vim version 9.0 or higher

# Installation

Install using [vim-plug](https://github.com/junegunn/vim-plug). Add the following lines to your `.vimrc` file:

```
vim9script
plug#begin()
Plug 'girishji/easyjump.vim'
plug#end()
```

For legacy scripts, use:

```
call plug#begin()
Plug 'girishji/easyjump.vim'
call plug#end()
```

Alternatively, utilize Vim's built-in package manager.

# Configuration

### Trigger Key

By default, `s` serves as the trigger key. To unmap `s` and restore it to the default (:h s),
include the following line in your .vimrc file:

```
g:easyjump_default_keymap = false
```

To assign `,` as the trigger for jumping, add the following lines to your `.vimrc`
file. You can choose any other key beside `,`.

```
nmap , <Plug>EasyjumpJump;
omap , <Plug>EasyjumpJump;
vmap , <Plug>EasyjumpJump;
```

### Case Sensitivity

Options include 'case' (case sensitive), 'icase' (ignore case), or 'smart'
(smart case). Add the following line to your .vimrc:

```
g:easyjump_case = 'smart' # Can be 'case', 'icase', or 'smart' (default).
```

### Highlight Group

The tag letters displayed alongside destination locations utilize the
highlighted group `EasyJump`. By default, this group is linked to `IncSearch`. Modify its
appearance using the `:highlight` command to change colors.

### Tag Letters

Jump locations prioritize placement based on distance from cursor and
preference for having at least one placement per line.
Letters are picked in the following sequence. Modify the sequence (say, for
Dvorak) as needed. Set the following global variable:

```
g:easyjump_letters = 'asdfgwercvhjkluiopynmbtqxzASDFGWERCVHJKLUIOPYNMBTQXZ0123456789'
```

## Other Plugins to Enhance Your Workflow

1. [**devdocs.vim**](https://github.com/girishji/devdocs.vim) - browse documentation from [devdocs.io](https://devdocs.io).

2. [**fFtT.vim**](https://github.com/girishji/fFtT.vim) - accurately target words in a line.

3. [**scope.vim**](https://github.com/girishji/scope.vim) - fuzzy find anything.

4. [**autosuggest.vim**](https://github.com/girishji/autosuggest.vim) - live autocompletion for Vim's command line.

5. [**vimcomplete**](https://github.com/girishji/vimcomplete) - enhances autocompletion in Vim.
