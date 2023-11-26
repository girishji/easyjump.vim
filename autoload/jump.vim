vim9script

var locations: list<list<number>> = [] # A list of {line nr, column nr} to jump to
var letters: string
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
    if get(g:, 'easyjump_default_keymap', true) && !hasmapto('<Plug>EasyjumpJump;', 'n') && mapcheck(',', 'n') ==# ''
        :nmap s <Plug>EasyjumpJump;
        :omap s <Plug>EasyjumpJump;
        :vmap s <Plug>EasyjumpJump;
    endif
enddef

# gather locations to jump to, starting from cursor position and searching outwards
def GatherLocations()
    var [lstart, lend] = [line('w0'), line('w$')]
    var curpos = getcurpos()
    var ch = easyjump_case ==? 'icase' ? getcharstr()->tolower() : getcharstr()
    var ignorecase = (easyjump_case ==? 'icase' || (easyjump_case ==? 'smart' && ch =~ '\U')) ? true : false
    var Ignorecase = (s) => ignorecase ? s->tolower() : s
    locations = []

    var curline = curpos[1]
    var linenrs = [curline]
    for dist in range(1, (lend - lstart))
        if curline + dist <= lend
            linenrs->add(curline + dist)
        endif
        if curline - dist >= lstart
            linenrs->add(curline - dist)
        endif
    endfor
    for lnum in linenrs
        if foldclosed(lnum) != -1
            continue # ignore folded lines
        endif
        var line = Ignorecase(getline(lnum))
        var col = line->stridx(ch)
        while col != -1
            col += 1 # column numbers start from 1
            if ch == ' ' && !locations->empty() && locations[-1] == [lnum, col - 1]
                locations[-1][1] = col
            elseif [lnum, col] != [curpos[1], curpos[2]]
                locations->add([lnum, col])
            endif
            col = line->stridx(ch, col)
        endwhile
    endfor
enddef

# order locations list by keeping more locations near cursor, and at least one per line
def Prioritize()
    var [lstart, lend] = [line('w0'), line('w$')]
    var highpri = []
    var lowpri = []
    var expected = locations->len()
    def FilterLocations(tlinenr: number, tmax: number)
        if tlinenr < lstart || tlinenr > lend
            return
        endif
        var curlocations = locations->copy()->filter((_, v) => v[0] == tlinenr)
        locations->filter((_, v) => v[0] != tlinenr)
        highpri->extend(curlocations->slice(0, tmax))
        lowpri->extend(curlocations->slice(tmax))
    enddef

    var curline = line('.')
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

# column number needs to be adjusted when:
#   - screen column differs from column (ex. tab, non-ascii chars)
#   - concealed text is present
def VisualPos(lnum: number, col: number): list<number>
    var screenpos = win_getid()->screenpos(lnum, col)
    if screenpos == {row: 0, col: 0, endcol: 0, curscol: 0}
        # position is not visible on screen (col too big)
        return [-1, -1]
    endif
    var diff = 0
    for c in range(1, col - 1)
        var res = synconcealed(lnum, c)
        if res[0]
            diff += (1 - res[1]->len())
        endif
    endfor
    return [screenpos.row, screenpos.col - diff]
enddef

def ShowTag(tag: string, lnum: number, col: number)
    var [linenum, colnum] = VisualPos(lnum, col)
    if lnum != -1
        popup_create(tag, {
            line: linenum,
            col: colnum,
            highlight: 'EasyJump',
            wrap: false,
            zindex: 50 - 1,
        })
    endif
enddef

def ShowLocations(group: number)
    try
        popup_clear()
        var ntags = letters->len()
        for idx in range(min([ntags, locations->len() - group * ntags]))
            var [lnum, col] = locations[idx + group * ntags]
            ShowTag(letters[idx], lnum, col)
        endfor
    finally
        :redraw
    endtry
enddef

def JumpTo(tgt: string, group: number)
    var tagidx = letters->stridx(tgt)
    var locidx = tagidx + group * letters->len()
    if tagidx != -1 && locidx < locations->len()
        var loc = locations[locidx]
        :normal! m'
        cursor(loc)
    endif
    popup_clear()
enddef

# main entry point
export def Jump()
    GatherLocations()
    var ngroups = locations->len() / letters->len() + 1
    var group = 0
    if ngroups > 1
        Prioritize()
    endif
    try
        ShowLocations(group)
        if ngroups > 1
            while true
                var ch = getcharstr()
                if ch == ';' || ch == ',' || ch == "\<tab>"
                    group = (group + 1) % ngroups
                    ShowLocations(group)
                else
                    JumpTo(ch, group)
                    break
                endif
            endwhile
        else
            var ch = getcharstr()
            JumpTo(ch, group)
        endif
    finally
        popup_clear()
    endtry
enddef
