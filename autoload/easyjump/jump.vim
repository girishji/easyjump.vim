vim9script

var locations: list<list<number>> = [] # A list of {line nr, column nr} to jump to
var letters: string
var labels: string
var easyjump_case: string

export def Setup()
    easyjump_case = get(g:, 'easyjump_case', 'smart') # case/icase/smart
    letters = get(g:, 'easyjump_letters', '')
    if letters->empty()
        var alpha = 'asdfgwercvhjkluiopynmbtqxz'
        letters = $'{alpha}{alpha->toupper()}0123456789'
    endif
    if letters->split('\zs')->sort()->uniq()->len() != letters->len()
        echoe 'EasyJump: Letters list has duplicates'
    endif
    # if get(g:, 'easyjump_default_keymap', true) && !hasmapto('<Plug>EasyjumpJump;', 'n') && mapcheck('s', 'n') ==# ''
    if get(g:, 'easyjump_default_keymap', true)
        :nmap s <Plug>EasyjumpJump;
        :omap s <Plug>EasyjumpJump;
        :vmap s <Plug>EasyjumpJump;
    endif
enddef

# get all line numbers in the visible are of the window ordered by distance from cursor
def WindowLineNrs(): list<any>
    # line('w$') does not include a long line (broken into many lines) that is only partly visible
    var [lstart, lend] = [max([1, line('w0')]), min([line('w$') + 1, line('$')])] # lines on screen
    var [curline, curcol] = getcurpos()[1 : 2]
    var lnums = [curline]
    for dist in range(1, (lend - lstart))
        if curline + dist <= lend
            lnums->add(curline + dist)
        endif
        if curline - dist >= lstart
            lnums->add(curline - dist)
        endif
    endfor
    return lnums
enddef

# search for locations to jump to, starting from cursor position and searching outwards
def GatherLocations(ctx: string, filter_label: bool = false)
    var ignorecase = (easyjump_case ==? 'icase' || (easyjump_case ==? 'smart' && ctx =~ '\U')) ? true : false
    var Ignorecase = (s) => ignorecase ? s->tolower() : s
    labels = letters->copy()
    locations = []

    var [curline, curcol] = getcurpos()[1 : 2]
    var lnums = WindowLineNrs()
    for lnum in lnums
        if foldclosed(lnum) != -1
            continue # ignore folded lines
        endif
        var line = Ignorecase(getline(lnum))
        var col = line->stridx(ctx)
        while col != -1
            col += 1 # column numbers start from 1
            if ctx == ' ' && !locations->empty() && locations[-1] == [lnum, col - 1]
                locations[-1][1] = col # one target per cluster of adjacent spaces
            elseif [lnum, col] != [curline, curcol] # no target on cursor position
                locations->add([lnum, col])
                if filter_label && col < line->len()
                    # remove character next to ctx from label chars
                    var idx = labels->stridx(line[col])
                    if idx != -1
                        labels = $'{labels->slice(0, idx)}{labels->slice(idx + 1)}'
                    endif
                endif
            endif
            col = line->stridx(ctx, col)
        endwhile
        if lnum == curline # prioritize based on distance from cursor
            locations->sort((x, y) => abs(x[1] - curcol) - abs(y[1] - curcol))
        endif
    endfor
enddef

# order locations list by keeping more locations near cursor, and at least one per line
def Prioritize()
    var [lstart, lend] = [line('w0'), line('w$')] # lines on screen start/end
    var highpri = []
    var lowpri = []
    var expected = locations->len()
    var curline = line('.')
    def FilterLocations(tlinenr: number, tmax: number)
        if tlinenr < lstart || tlinenr > lend
            return
        endif
        var curlocations = locations->copy()->filter((_, v) => v[0] == tlinenr)
        locations->filter((_, v) => v[0] != tlinenr)
        highpri->extend(curlocations->slice(0, tmax))
        lowpri->extend(curlocations->slice(tmax))
    enddef

    FilterLocations(curline, 10) # 10 locations max
    if locations->len() > (lend - lstart)
        var excess = locations->len() - (lend - lstart)
        FilterLocations(curline + 1, excess / 3)
        FilterLocations(curline - 1, excess / 3)
    endif
    # at least one target per line
    for p in range(locations->len())
        if locations[p][0] != locations[p - 1][0]
            highpri->add(locations[p])
        else
            lowpri->add(locations[p])
        endif
    endfor
    # shuffle the remaining low priority locations
    lowpri = lowpri->mapnew((_, v) => [v, rand()])->sort((a, b) => a[1] < b[1] ? 0 : 1)->mapnew((_, v) => v[0])
    locations = highpri + lowpri
    # error check
    if expected != locations->len()
        echoe 'EasyJump: Locations list filter error'
    endif
    if locations->copy()->sort()->uniq()->len() != locations->len()
        echoe 'EasyJump: Locations list has duplicates'
    endif
enddef

def ShowTag(tag: string, lnum: number, col: number)
    if lnum != -1
        popup_create(tag, {
            line: lnum,
            col: col,
            highlight: 'EasyJump',
            wrap: false,
            zindex: 50 - 1,
        })
    endif
enddef

# NOTE: column number (byte based) is different from screen column when tab or
# utf-8 chars are present. chars like ぬ, і, etc. are 3-byte and double wide.
# popup_create() expects screen column while what we have is byte column. Use
# screenpos() with synconcealed(), or wincol().
# Vim bug: https://github.com/vim/vim/issues/14640

def ShowLocations(group: number)
    var curpos_saved: list<number> = []
    var scrolloff: number
    try
        popup_clear()
        scrolloff = &l:scrolloff  # -1 if this local var is not set. global var defaults to 0
        :setlocal scrolloff=0  # to prevent text from jumping inside the window after cursor()
        curpos_saved = getcurpos()
        var ntags = labels->len()
        var is_invisible = {row: 0, col: 0, endcol: 0, curscol: 0}
        for idx in range(min([ntags, locations->len() - group * ntags]))
            var [lnum, col] = locations[idx + group * ntags]
            var scrpos = win_getid()->screenpos(lnum, col)
            if scrpos != is_invisible && synconcealed(lnum, col)[0] == 0
                cursor(lnum, col)
                :redraw
                ShowTag(labels[idx], scrpos.row, wincol())
            endif
        endfor
    finally
        if !curpos_saved->empty()
            cursor(curpos_saved->slice(1))
        endif
        if scrolloff != null
            :exec $'setlocal scrolloff={scrolloff}'
        endif
        :redraw
    endtry
enddef

def JumpTo(tgt: string, group: number)
    var tagidx = labels->stridx(tgt)
    var locidx = tagidx + group * labels->len()
    if tagidx != -1 && locidx < locations->len()
        var loc = locations[locidx]
        :normal! m'
        cursor(loc)
    endif
    popup_clear()
enddef

def GroupCount(): number
    var ngroups = locations->len() / labels->len() + 1
    ngroups -= (locations->len() % labels->len() == 0) ? 1 : 0
    if ngroups > 1
        Prioritize()
    endif
    return ngroups
enddef

# main entry point
export def Jump(two_chars: bool = false)
    var two_chars_mode = two_chars || get(g:, 'easyjump_two_chars', false)
    var ch = (easyjump_case ==? 'icase') ? getcharstr()->tolower() : getcharstr()
    GatherLocations(ch, two_chars_mode)
    if locations->empty()
        return
    endif
    var ngroups = GroupCount()
    var group = 0
    try
        ShowLocations(group)
        var ctx = ch
        ch = getcharstr()
        if two_chars_mode
            if labels->stridx(ch) != -1
                JumpTo(ch, group)
                return
            elseif [';', ',', "\<tab>", "\<s-tab>"]->index(ch) != -1 # switch to 1-char mode
                labels = letters->copy()
                ngroups = GroupCount()
                if ngroups == 1
                    ShowLocations(group)
                endif
            else
                ctx ..= (easyjump_case ==? 'icase') ? ch->tolower() : ch
                GatherLocations(ctx)
                ngroups = GroupCount()
                ShowLocations(group)
                ch = getcharstr()
            endif
        endif
        while true
            if [';', ',', "\<tab>", "\<s-tab>"]->index(ch) != -1
                if ngroups > 1
                    if ch == ';' || ch == "\<tab>"
                        group = (group + 1) % ngroups
                    else
                        group = (group + ngroups - 1) % ngroups
                    endif
                    ShowLocations(group)
                endif
            else
                JumpTo(ch, group)
                break
            endif
            ch = getcharstr()
        endwhile
    finally
        popup_clear()
    endtry
enddef
