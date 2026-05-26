## Forth

- add the ability to do int and hex numbers
- add print_hex, print_char, and print_int
- allow for character literals


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

    def if_ret
      if 
        5555 print
        return 
      then
      AAAA print
    enddef

    def if_else
      if
        1 print
      else
        0 print
      endif
    enddef