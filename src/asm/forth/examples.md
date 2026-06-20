## Forth

def double 
  dup add
enddef

def next_term
  dup
  rot
  add
enddef

def fibonnacci
  1
  print
  1
  print
  begin
    next_term
    print
    dup
    B520
    eql
  until
enddef

def ifr      
  if 
    5555 print
    return 
  endif
  AAAA print
enddef

def ife
  if
    5555 print
  else
    AAAA print
  endif
enddef

def count
  0
  begin
    dup 5 eql eqz
  while
    print
    dup 1 add
  repeat
enddef
