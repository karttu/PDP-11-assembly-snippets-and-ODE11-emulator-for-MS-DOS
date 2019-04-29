 
To load and execute PDP-11 "programs" in ODE11:

To run OBO stack calculator:
Say: (^I means CTRL-I or TAB. Stuff in parentheses are comments.)
ODE11
OBO.SAV^I   (I.e, load in the binary file OBO.SAV which was compiled in RT-11)
MINIRT.OD^I (Load our minimal version of RT-11 in octal format.)
1000^L      (Set location counter to 1000 (octal))
^G          (And execute OBO. Note that there is one newline missing when
             it outputs the lines, but otherwise it's OK.)
If you give just CR as input for OBO, it exits, and returns control to
ODE11 debugger.

Note that the MUL and other EIS instructions don't always give correct
values in this version of ODE11. See the file OBOTEST.LOG what the real
PDP-11/23+ gives as values and flags with EIS instructions with certain
operands.
 
Enter ODE11 1000 To start executor & debugger, and set location counter to
1000 (in octal).
Load some test-program with CTRL-I:
001000: testi.o11^I
And then set LC back to 1000 with 1000^L command, and start execution
with go: ^G
 
Test also:
001000: iotest2.o11^I
and then intout.o11^I
and 1000^L and ^G
 
AVANTI1.O11 - AVANTI9.O11 are forward-going "worm-pieces", from simplest
to more complex ones. When running them in video memory with VODE.BAT
they make "spectacular" sights.
For example:
100000: avanti2.o11^I
        170001^K (Set breakpoint to 170001 and above it).
        =100000^G Start execution from upper lefthand corner of screen
(be sure that code doesn't scroll out of screen before execution)
 

This is still better:

cls
ode11 -m B000 100000
regcopr.od^I
100000^L
170001^K
^G

REGCOPR.OD is self-copying program, which modifies itself in route
(by using the register permutation technique).
Sources are in the REGCOP.MAC

 
More information about commands & expressions in file ODE11.DOC
 
                                   Cheers, Antti Karttunen,
				     karttu@mits.mdata.fi
