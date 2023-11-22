vim9script

var propname = 'EasyJump'
var locations: list<list<number>> = [] # A list of {line nr, column nr} to jump to
var letters: string
var tags: dict<any>
var easyjump_case: string
var [lstart, lend] = [0, 0]

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
        var cnum = line->stridx(ch)
        while cnum != -1
            cnum += 1 # column numbers start from 1
            if ch == ' ' && !locations->empty() && locations[-1] == [lnum, cnum - 1]
                locations[-1][1] = cnum
            elseif [lnum, cnum] != [curpos[1], curpos[2]]
                locations->add([lnum, cnum])
            endif
            cnum = line->stridx(ch, cnum)
        endwhile
    endfor
    echom locations
enddef

# order locations list by keeping more locations near cursor, and at least one per line
def Prioritize()
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

def ShowLocations(group: number)
    prop_type_delete(propname)
    prop_type_add(propname, {highlight: 'EasyJump', override: true, priority: 11})
    tags = {}
    var tagged = {}
    var ntags = letters->len()
    try
        # try to put tag char that match next char
        for idx in range(group * ntags, min([locations->len() - 1, (group * ntags) + ntags - 1]))
            var [lnum, cnum] = locations[idx]
            var line = getline(lnum)
            if cnum < line->len()
                var nextchar = line[cnum]
                if !tags->has_key(nextchar) && letters->stridx(nextchar) != -1
                    prop_add(lnum, cnum + 1, {type: propname, text: nextchar})
                    tagged[$'{lnum}-{cnum}'] = 1
                    tags[nextchar] = [lnum, cnum]
                endif
            endif
        endfor
        var remaining = letters->split('\zs')->filter((_, v) => !tags->has_key(v))
        # allocate remaining letters
        for idx in range(group * ntags, min([locations->len() - 1, (group * ntags) + ntags - 1]))
            var [lnum, cnum] = locations[idx]
            if !tagged->has_key($'{lnum}-{cnum}')
                prop_add(lnum, cnum + 1, {type: propname, text: remaining[0]})
                tags[remaining[0]] = [lnum, cnum]
                remaining->remove(0) # pop
            endif
        endfor
    finally
        :redraw
    endtry
enddef

def JumpTo(tgt: string, group: number)
    if tags->has_key(tgt)
        :normal! m'
        cursor(tags[tgt])
    endif
enddef

# main entry point
export def Jump()
    [lstart, lend] = [line('w0'), line('w$')] # Cache this since visible lines can change after jump
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
        if !prop_type_get(propname)->empty()
            while prop_remove({type: propname}, lstart, lend) > 0
            endwhile
        endif
        # prop_type_delete(propname) # XXX Vim bug: 'J' after jump causes corruption
    endtry
enddef
