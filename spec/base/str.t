use Test;

plan 34;

{
    ok "0","'0' is true";
    is "".WHAT,Str,'empty string .WHAT is Str';
    is "foo".WHAT,Str,'non-empty strnig .WHAT is Str';
    is "1".WHAT,Str,'"1" .WHAT is Str';
    nok ?"", '?""';
    ok ?" ", '?" "';
}

{
    is "foo".uc ,"FOO",'.uc';
    is "FOO".lc,'foo','.lc';
}

{
    my @words = <foo møøse rántottcsirke>;
    my @bytes = 3,     7,    14;

    #XXX: Temporarily (hopefully) cheating for non-utf8 terminals.
    #Needed because wc uses the locale to do char count
    my @chars = Locale.encoding eq 'UTF-8' ?? <3 5 13>  !! <3 7 14>;

    for ^@words {
        is @words[$_].chars,@chars[$_],"$_ correct chars";
        is @words[$_].bytes,@bytes[$_],"$_ correct bytes";
    }
}

{
    my $str = "foo|bar|baz";
    my @str = <foo bar baz>;
    is $str.split('|'),@str,'split on |';
    is @str.elems,3,'correct elems from split';
}

{
    my $str = 'foo"bar"baz';
    my @str = <foo bar baz>;
    is $str.split('"'),@str,'split on "';
}

{
    my $str = "abc";
    my @str = <a b c>;
    is $str.split(""),@str,"split on ''";
}

{
    my $str = "lor.+em ipsum";
    ok $str.contains('or.+em'),'contains treats string literally';
    nok $str.contains('or.*em'),'contains treats string literaly';
}

{
    my $str = "lorem\nipsum";
    ok $str.contains("m\ni"),'needle with newline';
}

{
    my $str = "\nfoo";
    ok $str.contains("\nfo"),'needle starting with newline (true)';
    nok $str.contains("\na"),'needle starting with newline (false)';
}

{
    my $str = "lOrEm ipsum";
    nok $str.contains("lorem ipsum"),'contains is case sensitive by default';
    ok $str.contains("lorem ipsum",:i),'.contains :i';
    ok $str.contains('LOREM',:i),'.contains with uc arg :i';
    ok qq{if True {\n    foo\n}}.contains(qq{if True {\n    foo\n}}),
        'multi-line contains';
    nok qq{if True {\n    foo\n}}.contains(qq{if True {\n    foo\n after}}),
        'multi-line contains (false)';
}

{
    nok "".contains("a"), '"".contains("a")';
    ok "".contains(""), '"".contains("")';
}

{
    given File.tmp {
        .write('%foo');
        is .slurp.uc.write-to($_), '%FOO', '.write-to returns what it writes';
        is .slurp, '%FOO', '.slurp...write-to($_)';
    }
}


{
    File.tmp(:dir).cd;
    my $to-archive = File.tmp(:dir);
    $to-archive.add('foo.txt').touch;
    my $archive = $to-archive.archive;
    File.tmp(:dir).cd;
    my $extracted = $archive.slurp.extract;
    $archive.remove;
    ok $extracted.d, 'Str.extract result is a directory';
    ok $extracted.add('foo.txt'), 'foo.txt exists inside';
}
