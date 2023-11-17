# EasyJump.vim

Jump to any location by typing 2 characters.

- Mapped to `,` but can choose any other trigger (like `s`).
- Vim idioms supported. Use `d,xy` to delete, `c,xy` to change, `v,xy` to select visually, etc.
- Jump list (`:jumps`) updated so that you can jump back using _<ctrl-o>_.
- Does not alter the buffer. Uses virtual text. Written in vim9 script.
- Does not block the character you are trying to jump to.
- Case sensitive and smart case (default) supported.

Type `,` and `x` and you'll see new destination appear next to all the occurances of `x`. Type `y` (for instance) and cursor jumps to `x` next to the (virtual text) `y`. Trigger - Target - Choose.



To visually select a block of text starting from cursor position to some occurance of `x` type `v,x` and then type the highlighted character (say 'z').



One advantage over using relative number to jump is that you do not have to take your eyes off the character you are trying to jump to. 



# Requirements

- Vim >= 9.0

# Installation

Install using [vim-plug](https://github.com/junegunn/vim-plug). Put the following in `.vimrc` file.

```
vim9script
plug#begin()
Plug 'girishji/easyjump.vim'
plug#end()
```

Legacy script:

```
call plug#begin()
Plug 'girishji/easyjump.vim'
call plug#end()
```

Or use Vim's builtin package manager.

# Configuration

### Trigger Key

Default trigger key is `,`. To change this to `s` (for example) put the following in `.vimrc` file.

```
vim9script
g:easyjump_default_keymap = false
nmap s <Plug>EasyjumpJump;
omap s <Plug>EasyjumpJump;
vmap s <Plug>EasyjumpJump;
```

### Case

The destination character you type is compared against visible buffer text. To make the search case sensitive (case), insensitive (icase), or smart case (smart) put the following in `.vimrc`.

```
g:easyjump_case = 'smart' # Can be 'case', 'icase', or 'smart'.
```

### Highlight

The virtual text that appears next to destination locations uses highlighted group `EasyJump`. It is linked to `MatchParen` by default. Set this appropriately to change colors.

### Letters

The virtual text letters that appear next to the destination you want to jump to are prioritized based on distance from the cursor, with at least one letter per line. The letters appear in the following order of decreasing priority.

```
g:easyjump_letters = 'asdfgwercvhjkluiopynmbtqxzASDFGWERCVHJKLUIOPYNMBTQXZ0123456789'
```
     


