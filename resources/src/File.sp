augment List[File] {
    method remove? { $self.${xargs rm -rf !>X} }

    method cat@ { $self.${xargs cat} }
}

my File $?file-cleanup = ${mktemp};

#| File is string representing a filesystem path (relative or absolute).
#|{
    my $outdated = 'foo1.myorg.com';
    if File</etc/foo.conf>.contains($outdated) {
        note "$outdated exists in $_...fixing!";
        .copy-to('/etc/foo.conf.bak');
        .subst($outdated,'foo2.myorg.com');
    }
}
augment File {
    #| Returns True if the file exists.
    method exists? { ${test -e $self}  }
    #| Alias for .exists
    method e?      { $self.exists }
    #| In Bool context, Files return [.exists](#exists)
    method Bool { $self.exists }
    #| Returns True if the file is a directory]
    method dir?    { ${test -d $self} }
    #| Alias for .dir
    method d?      { $self.dir }
    #| Returns True if the file is file
    method file?   { ${test -f $self}  }
    #| Alias for .file
    method f?      { $self.file }
    #| Removes (unlinks) the file and returns True if it was successful.
    #| If the file is a directory it will recursively it's children.
    method remove? ${rm -rf $self}
    #| Returns True if the file is empty
    method empty?  { ! ${test -s $self} }
    #| Returns True if the file is writable by the current user.
    method writable? { ${test -w $self}  }
    #| Alias for .writable
    method w?        { $self.writable        }
    #| Returns True if the file is executable
    method executable? { ${test -x $self} }
    #| Alias for .executable
    method x?          { $self.executable     }
    #| Returns True if the file is readable by the current user.
    method readable?   { ${test -r $self} }
    #| Alias for .readable
    method r?          { $self.readable }
    #| Returns the size of the file in bytes
    method size+   { ${wc -c < $self}  }
    #| Alias for .size
    method s+      { $self.size }

    method mtime-->DateTime on {
        GNU     ${ date -u -r $self '+%FT%T.%3N' !>X}
        BusyBox ${ stat -c '%y' $self !>X| sed -r 's/ /T/;s/0{6}$//' }
    }

    method ctime-->DateTime on {
        #TODO: roll these into one
        GNU     ${ stat -c '%z' $self !>X | sed -r 's/ /T/;s/[0-9]{6} \S*$//' }
        BusyBox ${ stat -c '%z' $self !>X | sed -r 's/ /T/;s/0{6}$//' }
    }

    method lines+ { ${wc -l < $self} }
    #| Returns the line of text at an index. `.at-pos` is the
    #| internal method called when using postcircumfix `[]`.
    #|{
        my File $file;
        $file.write(~<foo bar baz>);
        say $file[1] #-> bar
    }
    method at-pos(#|[The index of the line to return]Int $i)~ {
        ${sed -n ($i+1 ~ 'p') $self}
    }
    #| Calls chmod(1) with the file as the last argument.
    #|{ .chmod(400) if File<foo.txt>.writeable }
    method chmod(#|[The argument passed to chmod(1)]$mode)^ {
        ${chmod $mode $self !>error} ?? $self !! die "Failed to run ‘chmod $mode’ on $self";
    }
    #| Returns the name of the user that owns the file.
    method owner~ ${ stat -c '%U' $self }

    #| Returns the name of the group that own the file.
    method group~ ${ stat -c '%G' $self }

    #| Appends raw data to the file.
    method append(#|[data to append] $data) { $data.${ >> $self } }

    #| Appends a string to a file,. If the file doesn't end in a
    #| newline, one will be prepended to the string. A newline is
    #| appended to the string regardless of whether it already ends in
    #| a string. Returns the invocant File.
    method push(#|[string to push] $str)^ {
        $self.try-slurp.${
            awk :l($str) -v "f=$self"
             '{print>f}END{l=ENVIRON["l"];print l>f}'
        };
        $self;
    }

    method unshift($str)~ {
        $self.try-slurp.${
            awk :l($str) -v "f=$self" -v 'RS=^$'
              'END{l=ENVIRON["l"];printf "%s",l;print l>f;printf "%s",$0>f}'
        }
    }

    method shift~   ${sed -nri -e '1!p;1w/dev/stdout' $self}
    method pop~     ${sed -nri -e '$!p;$w/dev/stdout' $self}

    #| Calls `touch(1)` on the file.
    #|{ .touch unless File<foo.txt> }
    method touch? {
        # Ohhh when I think about you I
        ${touch $self}
    }
    #| Copies the file to another path
    method copy-to(#|[destination path] $dst,
                   #|[preserve permissions] Bool :$p){
        ${cp "-r{$p && 'p'}" $self $dst}
    }

    #| Moves the file to another location. Overwrites pre-existing
    #| files at the destination location. Returns whether the move
    #| was completed successfully.
    method move-to(#|[The path to move the file to] $destination)^ {
        ${mv $self $destination} ?? $destination !! ()
    }

    #| Sets the file's contents to `$data`. If the file doesn't exist
    #| it will be created.
    method write(#|[The string to write to the file] $data)^  {
        $data.${ > $self  } ?? $self !! ()
    }

    #| Returns true if the file contains the string
    #|{ say "we're in trouble" unless File</etc/hosts>.contains("localhost") }
    method contains(#|[String to be searched for] $needle,
                    #|[Enable case insensitivity] Bool :$i)? {
        $self.slurp.contains($needle,:$i);
    }

    #| Replaces the target strnig with the replacement string in the file.
    #| **This modifies the file**.
    #|{
        given File.tmp {
            .write("foood");
            .subst("o","e");
            .slurp.say; #-> feood
            .subst("o","e",:g);
            .slurp.say; #-> feeed
        }
    }
    method subst(#|[The string to be replaced]$target,
                 #|[The string to replace it with]$replacement,
                 #|[Turn on global matching]Bool :$g){
        $self.slurp.subst($target,$replacement,:$g).write-to($self);
    }

    #| Reads the file into the file's content as a List of lines
    #|{
        my $content = File</etc/hosts>.slurp
        say $content[2]; # print the 3rd line
    }
    method slurp@ {
        $self ?? ${cat $self} !! die "$self could't be slurped because it doesn't exist"
    }

    method try-slurp@ {
        $self.f ?? ${cat $self} !! ()
    }
    #| Opens the file and returns a FD that can be written to.
    #|{
        my File $file = 'foo.txt';
        my $fd = $file.open-w;
        $fd.write("written to via file descriptor");
        say $file.slurp; #-> written to via file descriptor!
    }
    method open-w-->FD is return-by-var {
        my $fd = FD.next-free;
        $fd.open-w($self);
        $fd;
    }

    #| Opens the file and returns a FD that can be read from.
    #|{
        my File $file = 'foo.txt';
        $file.write(<The quick brown fox jumped over the lazy dog>);
        my $fd = $file.open-r;
        $fd.get() && say $~; #-> The
        $fd.get() && say $~; #-> quick
    }
    method open-r-->FD is return-by-var {
        my $fd = FD.next-free;
        $fd.open-r($self);
        $fd;
    }

    #| Returns the file's path (relative or absolute) as a [Str].
    #|{
        my File $file = 'foo.text';
        $file.subst('foo','bar'); # modifies the file
        say $file;
        say $file.path.subst('foo','bar');
    }
    method path~ { $self }
    #| Returns the name of the file.
    #|{ say File</etc/hosts>.name #->hosts }
    method name~ { ${basename $self} }
    #| Returns the parent directory of the file.
    #|{ say File</etc/foo/foo.cfg>.name #->/etc/foo }
    method parent-->File{ ${dirname $self} }
    #| Adds an element to the path. This is the same as concatinating
    #| the path with a '/' and the argument.
    #|{ say File</etc/foo>.add('foo.cfg') #->/etc/foo/foo.cfg }
    method add($name)-->File { $self.path ~ '/' ~ $name }

    #| Creates a tempfile via mktemp(1) and adds it to a list of
    #| files which will be removed at the END.
    #|{
      my $tmpfile = File.tmp; # Will be removed at the end
    }
    static method tmp(Bool :$dir)-->File {
        ${mktemp ('-d' if $dir)}-->File.cleanup
    }

    method cleanup^ {
        $?file-cleanup.push($self);
        $self;

        FILE-CLEAN ${rm -rf @($?file-cleanup.slurp) $?file-cleanup }
    }

    #| Returns a list of children that match the criteria.
    #|{
        given File("$:HOME/src/spitsh/resources/src") {
            my $loc = 0;
            for .find(name => /\.sp$/) { # or just *.sp
                $loc += .lines;
            }
            say "$loc lines of code";
        }
    }
    method find(Pattern :$name)-->List[File] {
        ${find $self ('-name', $name if $name)}
    }

    method ls(:$all)-->List[File] {
        ${ls ('-A' if $all) $self }
    }

    static method tmp-fifo-->File {
        my File $tmpfifo .= tmp;
        $tmpfifo.remove;
        ${mkfifo $tmpfifo};
        $tmpfifo;
    }

    #| Tries to make a directory at the file's path, recursively if need
    #| be. Returns whether it succeeds.
    #|{
       say "creating " ~ File<path/to/my/dir>.mkdir
    }
    method mkdir-->File {
        ${ mkdir -p $self};
        $self;
    }
    #| Changes directory to the file.
    #|{
        File<path/to/my/dir>.mkdir.cd;
        say "$?PWD";
    }
    method cd {
        ${ cd $self }
    }

    method archive(:$to)-->File {
        my $out = ($to || "$self.tgz");
        ?${ tar -C $self.parent -czf $out  $self.name } && $out;
    }

    method extract-->File {
        ${ tar xvf $self | sed -n '1s/\/.*//p' };
    }

    method grep(Regex $regex)@ {
        ${egrep $regex $self}
    }

    method first(Regex $regex)~ {
        ${egrep -m1 $regex $self}
    }

    method remove-lines(Regex $regex)@ {
        on {
            GNU ${sed -rni "\\§$regex§!\{p;b;\};w/dev/stdout" $self}
            # BB sed doesn't likebranch inside {} without \n following
            BusyBox ${sed -rni "\\§$regex§!\{p;b\n\};w/dev/stdout" $self}
        }
    }

    method filter(Regex $regex, $replacement, :$g)@ {
        ${sed -rni "s§$regex§$replacement§{$g && 'g'}p" $self}
    }

    method line-subst(Regex $regex, $replacement, :$g)@ {
        ${sed -ri "s§$regex§$replacement§{$g && 'g'}" $self}
    }

    method capture(Regex $regex)~ {
        ${sed -rn "s§$regex§\\1§;T;s/^.*//p;q" $self}
    }

    method sha256~ ${ sha256sum -b $self | awk '{print $1}' }
    method sha256-ok($sha256-expected, :$what) {
        my $sha256-got = $self.sha256;
        $sha256-got eq $sha256-expected or
        die "SHAsum didn't match for {$what || $self}\n" ~
        "Got:      $sha256-got\n" ~
        "Expected: $sha256-expected";
    }

}

sub cd(File $dir){ $dir.cd }
