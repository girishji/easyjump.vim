vim9script

var locations: list<list<number>> = [] # A list of {line nr, column nr} to jump to
var letters: string
var tags: dict<any>
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
        :nmap , <Plug>EasyjumpJump;
        :omap , <Plug>EasyjumpJump;
        :vmap , <Plug>EasyjumpJump;
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
    echom locations
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

def ShowTag(tag: string, lnum: number, col: number)
    var screenpos = win_getid()->screenpos(lnum, col)
    if screenpos == {row: 0, col: 0, endcol: 0, curscol: 0}
        return
    endif
    popup_create(tag, {
        line: screenpos.row,
        col: screenpos.col,
        highlight: 'EasyJump',
        wrap: false,
        zindex: 50 - 1,
        })
enddef

def ShowLocations(group: number)
    tags = {}
    var tagged = {}
    var ntags = letters->len()
    # try to put tag char that match next char
    for idx in range(group * ntags, min([locations->len() - 1, (group * ntags) + ntags - 1]))
        var [lnum, col] = locations[idx]
        var line = getline(lnum)
        if col < line->len()
            var nextchar = line[col]
            if !tags->has_key(nextchar) && letters->stridx(nextchar) != -1
                # ShowTag(nextchar, lnum, col + 1)
                # prop_add(lnum, col + 1, {type: propname, text: nextchar})
                # prop_add(lnum, col + 1, {type: 'EasyJump', bufnr: buf, length: 1})
                tagged[$'{lnum}-{col}'] = 1
                tags[nextchar] = [lnum, col]
            endif
        endif
    endfor
    var remaining = letters->split('\zs')->filter((_, v) => !tags->has_key(v))
    # allocate remaining letters
    for idx in range(group * ntags, min([locations->len() - 1, (group * ntags) + ntags - 1]))
        var [lnum, col] = locations[idx]
        if !tagged->has_key($'{lnum}-{col}')
            # prop_add(lnum, col + 1, {type: propname, text: remaining[0]})
            tags[remaining[0]] = [lnum, col]
            remaining->remove(0) # pop
        endif
    endfor
    try
        # InitTextProp()
        for [tag, location] in tags->items()
            var [lnum, col] = location
            ShowTag(tag, lnum, col)
            # prop_add(lnum, col + 1, {type: 'EasyJump', bufnr: buf, length: 1})
        endfor
    finally
        :redraw
    endtry
enddef

def JumpTo(tgt: string)
    if tags->has_key(tgt)
        :normal! m'
        cursor(tags[tgt])
    endif
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
                    JumpTo(ch)
                    break
                endif
            endwhile
        else
            var ch = getcharstr()
            JumpTo(ch)
        endif
    finally
        popup_clear()
        # if !prop_type_get(propname)->empty()
        #     while prop_remove({type: propname}, lstart, lend) > 0
        #     endwhile
        # endif
        # # prop_type_delete(propname) # XXX Vim bug: 'J' after jump causes corruption
    endtry
enddef
