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

- 


 - change highlight using EasyJump group
 - remap keys after g:easyjump_mapkeys=false
 - case sensitive and smart case
