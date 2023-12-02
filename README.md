# EasyJump.vim

Jump to any location on screen by typing two characters.

- Initially bound to `s`, but it can be reassigned to any desired trigger (e.g., `,`).
- Supports essential Vim idioms such as `ds` for deletion, `cs` for change, `vs` for visual selection, and more.
- Updates the jump list (`:jumps`) for easy navigation back using `<c-o>`.
- Non-disruptive: Does not modify the buffer. Crafted in vim9 script.


🚀 **Jump (`s`)**: Input `s` followed by another character (like `c`). Witness
new tag characters replacing the specified character. For instance, typing `e`
navigates the cursor to the `c` under `e`.

<img src='img/img1.jpeg' width='700'>

🚀 **Jump back**: Type `<c-o>` (control-O). Jump forward using `<tab>` or `<c-i>'.

🚀 **Visual Select (`vs`)**: For visually selecting a block of text from the
cursor position up to an instance of `c`, enter `vsc`, then the highlighted
character (e.g., `e`).

<img src='img/img2.jpeg' width='700'>

Likewise, use `ds` for deletion or `cs` for text alteration.

Press `<esc>` to cancel the ongoing jump.

The displayed illustrations are based on `:colorscheme quiet`.

**What if the intended jump location lacks a nearby tag letter?**

This scenario occurs when there aren't enough unique letters available for
tagging. Simply use `<Tab>` (or `,`, or `;`), and you'll observe tag letters
populating the remaining locations.

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

For defining case sensitivity in search (options include 'case', 'icase', or
'smart'), add the following line to your .vimrc:

```
g:easyjump_case = 'smart' # Can be 'case', 'icase', or 'smart' (default).
```

### Highlight

The tag letters displayed alongside destination locations utilize the
highlighted group `EasyJump`. By default, this group is linked to `IncSearch`. Modify its
appearance using the `:highlight` command to change colors.

### Tag Letters

Jump locations prioritize placement based on distance from cursor. Tag letters are
arranged in a specific order, with at least one letter per line. Adjust the
sequence of letters using the global variable:

```
g:easyjump_letters = 'asdfgwercvhjkluiopynmbtqxzASDFGWERCVHJKLUIOPYNMBTQXZ0123456789'
```
