#|Standard input (STDIN). The 0 file descriptor for the script.
constant FD $?IN = 0;

#| Whether the script should be compiled as an interactive script.
#| Defaults to False.
constant $:interactive = False;

my $~;

#|File descriptor connected to the STDOUT of the script by default.
#|{ $:OUT.write("hello world") # same as print("hello world") }
constant $:OUT = {
    FD<1>.dup(3);
    FD<3>;
}

#| File descriptor connected to the STDERR of the script.  '!' is a
#| short alias for `$:ERR` in `${..}` commands.
#|{
    $:ERR.write("something to script's stderr");
    ${printf "allo earth" > $:ERR};
    ${printf "allo earth" >!}; #shorthand
    ${ls '/I/dont/exist' !> $:OUT}; #redirect STDERR to script's STDOUT
    my $error = ${ls '/I/dont/exist' !>~}; # capture STDERR into return value of cmd
}
constant FD $:ERR = 2;
#|File descriptor used to represent the STDOUT of a cmd inside the
#|script rather than the script itself. '~' is a short alias for
#|`$?CAP` in `${..}` commands.
#|{
    # captures both the STDOUT and STDERR of ls into $res
    my $res = ${ls /etc '/I/dont/exist' *>~};
    say "ls returned $res";
}
constant FD $?CAP = 1;

constant File $?devnull = '/dev/null';

#|File descriptor redirected to '/dev/null' by default. 'X' is a short
#|alias for `$:NULL` in `${..}` commands.
#|{
    if ${command -v perl >X} {
        say "perl exists";
    }
}
constant $:NULL = {
    FD<4>.open-w($?devnull);
    FD<4>;
}
#| The maximum file descriptor number that can be open or can be
#| expressed within the shell interpreter.
constant FD $:max-fd = on {
    Debian { 9 }
    Alpine { 255 }
    RHEL   { 9  }
}

#| The minimum file descriptor number that isn't reserved by Spit
constant FD $?min-fd = 5;

#|FD wraps an integer representing a file descriptor. Usually you
#|don't create these directly but get them through calling other methods
#|like `File.open-w()`.
augment FD {

    #| Returns the next free file descriptor if it can find one.
    #| Dies if it can't.
    static method next-free-->FD {
        my $fdi = $?min-fd;
        $fdi++ while File("/proc/$?PID/fd/$fdi");
        $fdi <= $:max-fd ?? $fdi !! die "All $:max-fd file descriptors depleted";
    }

    #| Opens a file for writing from this file descriptor.
    method open-w(#|[The file to redirect to]File $file) {
        ${exec ($self)› $file}
    }

    #| Opens a file for reading from this file descriptor.
    method open-r(#|[The file to open] File $file) {
        ${exec ($self)‹ $file}
    }

    #| Duplicate the invocant file descriptor into the argument file
    #| descriptor like `DUP(2)` if the argument file descriptor is open
    #| it will be closed before becoming the alias.
    method dup (#|[The file descriptor to use as the alias] FD $new-fd) {
        # you might think we need <> here but actually whether it's >
        # < or <> it does the same thing. The LHS always becomes the
        # alias to the RHS.
        ${exec ($new-fd)> $self}
    }

    #| Closes redirection for this file descriptor.
    method close() {
        ${exec ($self)› (FD(-1)) };
    }

    #| Returns True if the file descriptor is open.
    method is-open? {
        # note this works regardless of whether it's open for reading
        # or writing.
        quietly { ${true ›$self} }
    }

    #| Writes to the file descriptor.
    method write(#|[The data to write to the file descriptor]$data) {
        $data.${ > $self};
    }

    #| Reads all data up to and **including** the next newline or up
    #| to the EOF and puts it into `$~`. The newline (if any) will be
    #| discarded.
    method get? on {
        Debian {
            ${read -r  $~.NAME ‹ $self} || $~;
        }
        Any {
            ${read -r -u $self $~.NAME} || $~;
        }
    }
    #| Reads a fixed number of characters
    method getc(#|[The number of characters to read]Int $n)? on {
        Any {
            ${read -r -u $self -n $n $~.NAME}
                ?? ($~ ||= "\n")
                !! $~;
        }
        Debian {
            $~ = ${ head -c $n ‹ $self };
            $~;
        }
    }

    #| Returns whether this file descriptor is linked to a terminal.
    #|{
        say $:OUT.tty;  #probably true
        say FD<42>.tty; #probably false
    }
    method tty? { ${test -t $self} }
}
