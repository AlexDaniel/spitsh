#| The List type represents strings separated by newlines `\n`. It
#| provides a familiar way of working with array-like data. However,
#| because of the limitations of shell, you can't have discrete elements
#| with newlines in them. You can type the List's elements by
#| declaring a `@` variable with type before it or by putting `[type]`
#| after `List`.
#|{
    my Int @ints = 1..10;
    my List[Int] $ints = 1..10;
    say @ints[0].WHAT #-> Int
}

augment List {
    #| `at-pos` is the internal method called when the a list is
    #| accessed with the postcircumfix syntax `[..]`. It returns data typed
    #| as the element type (Str by default).
    #|{
        my @list = <one two three>;
        say @list.at-pos(1); #-> two
        say @list[1]; #-> two
    }
    method at-pos(#|[the index to return the line at]Int $i)-->Elem-Type {
        $self.${sed -n ($i+1 ~ 'p') | tr -d '\n'} # this should be awk
    }

    method at-list-pos(Int @pos) --> List[Elem-Type] {
        # converts the indexes to a sed expression
        # like (0,3) -> 1p;4p;
        $self.${sed -n @pos.${ awk '{printf $0 + 1"p;"}' } };
    }
    #| `set-pos` is the internal method called which you set a list
    #| element using the postcircumfix syntax `[..]`.
    #|{
        my @a = <one two three>;
        @a[1] = "deux";
    }
    method set-pos(Int $pos,Elem-Type $item)~ is rw {
        $self.${
          awk -v "pos=$pos" '{ print } END { for (i = (NR-1); i <= pos; i++) print "\n" }'
        | awk -v "pos=$pos" -v "item=$item" '{ print((NR-1) == pos ? item : $0) }'
        }
    }
    #| Returns the number notional elements in the list. This is equal
    #| to the number of lines of text regardless of whether the last
    #| line is terminated by a newline.
    method elems+ { $self.${awk 'END{print NR}'} }
    #| The list in Int context returns `.elems`
    #|{
        my @a = <one two three>;
        say +@a; #-> 3
    }
    method Int { $self.elems }
    #| Push an element onto the end of the list. If the list doesn't
    #| end in a newline one will be added before adding the new data.
    #|{
        my @a;
        for <one two three> {
            @a.push($_);
        }
    }
    method push(#|[The item to add to the list]Elem-Type $item) is rw {
        $self.${awk -v "i=$item" '{print}END{printf "%s", i}'}
    }
    #| Removes the first line from the list
    #|{
        my @a = <one two three>;
        @a.shift;
        say @a;
    }
    method shift is rw { $self.${sed 1d} }

    #| Adds a line to the front of the list.
    #|{
        my @a = <one two three>;
        @a.unshift("zero");
    }
    method unshift(#|[The item to add to the list]Elem-Type $item) is rw {
        $self.${awk -v "item=$item" 'BEGIN { print item } { print }'}
    }
    #| Removes a line from the end of the list
    #|{
        my @a = <one two three>;
        @a.pop;
    }
    method pop is rw { $self.${sed '$d'} }

    #| Returns the result of removing the `\n` between each line and
    #| replacing it with a new separtor.
    method join(#|[The separator to join on]$sep?)~ {
        $self.${awk :s($sep) '{if(NR != 1) printf "%s", ENVIRON["s"]; printf "%s", $0}'}
    }

    method numeric-sort@ {
        $self.${sort -n};
    }

    method grep(Regex $regex)^ {
        $self.${ egrep $regex }
    }

    method first(Regex $regex)-->Elem-Type {
        $self.${ egrep -m1 $regex }
    }

    method JSON {
        ('[' ~ (.JSON for @$self).join(',') ~ ']')-->JSON;
    }

    method pick($n = 1)-->Elem-Type {
        $self.${ shuf -n $n }
    }

    method pairs -->List[Pair[Int,Elem-Type]] {
        $self.${ awk '{print NR-1"\t"$0}' }
    }

}
