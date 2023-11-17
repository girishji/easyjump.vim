vim9script

var propname = 'EasyJump'
var locations: list<list<number>> = [] # A list of positions to jump to
var letters: list<any>
var easyjump_case: string

export def Setup()
    easyjump_case = get(g:, 'easyjump_case', 'smart') # case/icase/smart
    letters = get(g:, 'easyjump_letters', '')->split('\zs')
    if letters->empty()
        var alpha = 'asdfgwercvhjkluiopynmbtqxz'
        letters = $'{alpha}{alpha->toupper()}0123456789'->split('\zs')
    endif
    if letters->copy()->sort()->uniq()->len() != letters->len()
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
        var cnum = line->stridx(ch)
        while cnum != -1 && ([lnum, cnum + 1] != [curpos[1], curpos[2]])
            if ch == ' ' && !locations->empty() && locations[-1] == [lnum, cnum]
                locations[-1][1] = cnum + 1
            else
                locations->add([lnum, cnum + 1])
            endif
            cnum = line->stridx(ch, cnum + 1)
        endwhile
    endfor
enddef


# order locations list by keeping more locations near cursor, and at least one per line
def Prioritize()
    var highpri = []
    var lowpri = []
    var [lstart, lend] = [line('w0'), line('w$')]
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
    try
        for idx in range(letters->len())
            var tidx = group * letters->len() + idx
            if tidx < locations->len()
                var [lnum, cnum] = locations[tidx]
                prop_add(lnum, cnum + 1, {type: propname, text: letters[idx]})
            else
                break
            endif
        endfor
    finally
        :redraw
    endtry
enddef

def JumpTo(tgt: string, group: number)
    var jumpto = letters->index(tgt)
    if jumpto != -1
        var idx = group * letters->len() + jumpto
        if idx < locations->len()
            cursor(locations[idx])
        endif
        # add to jumplist (:jumps)
        :normal! m'
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
            var [lstart, lend] = [line('w0'), line('w$')]
            while prop_remove({type: propname}, lstart, lend) > 0
            endwhile
        endif
        # prop_type_delete(propname) # XXX Vim bug: 'J' after jump causes corruption
    endtry
enddef
