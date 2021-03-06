# File
 File is string representing a filesystem path (relative or absolute).
```perl6
my $outdated = 'foo1.myorg.com';
if File</etc/foo.conf>.contains($outdated) {
    note "$outdated exists in $_...fixing!";
    .copy-to('/etc/foo.conf.bak');
    .subst($outdated,'foo2.myorg.com');
}
```
## Bool
>method Bool( ⟶ [Bool](./Bool.md))

 In Bool context, Files return [.exists](#exists)
## add
>method add([Str](./Str.md) **$name** ⟶ [File](./File.md))

 Adds an element to the path. This is the same as concatinating the path with a '/' and the argument.
```perl6
 say File</etc/foo>.add('foo.cfg') #->/etc/foo/foo.cfg
```
## append
>method append([Str](./Str.md) **$data**)

 Appends raw data to the file.

|Parameter|Description|
|---------|-----------|
|**$data**| data to append|
## at-pos
>method at-pos([Int](./Int.md) **$i** ⟶ [Str](./Str.md))

 Returns the line of text at an index. `.at-pos` is the internal method called when using postcircumfix `[]`.
```perl6
my File $file;
$file.write(~<foo bar baz>);
say $file[1] #-> bar
```

|Parameter|Description|
|---------|-----------|
|**$i**| The index of the line to return|
## cd
>method cd()

 Changes directory to the file.
```perl6
File<path/to/my/dir>.mkdir.cd;
say "$?PWD";
```
## chmod
>method chmod([Str](./Str.md) **$mode**)

 Calls chmod(1) with the file as the last argument.
```perl6
 .chmod(400) if File<foo.txt>.writeable
```

|Parameter|Description|
|---------|-----------|
|**$mode**| The argument passed to chmod(1)|
## contains
>method contains([Str](./Str.md) **$needle**, [Bool](./Bool.md) **:$i** ⟶ [Bool](./Bool.md))

 Returns true if the file contains the string
```perl6
 say "we're in trouble" unless File</etc/hosts>.contains("localhost")
```

|Parameter|Description|
|---------|-----------|
|**$needle**| String to be searched for|
|**:$i**| Enable case insensitivity|
## copy-to
>method copy-to([Str](./Str.md) **$dst**, [Bool](./Bool.md) **:$p**)

 Copies the file to another path

|Parameter|Description|
|---------|-----------|
|**$dst**| destination path|
|**:$p**| preserve permissions|
## d
>method d( ⟶ [Bool](./Bool.md))

 Alias for .dir
## dir
>method dir( ⟶ [Bool](./Bool.md))

 Returns True if the file is a directory]
## e
>method e( ⟶ [Bool](./Bool.md))

 Alias for .exists
## empty
>method empty( ⟶ [Bool](./Bool.md))

 Returns True if the file is empty
## executable
>method executable( ⟶ [Bool](./Bool.md))

 Returns True if the file is executable
## exists
>method exists( ⟶ [Bool](./Bool.md))

 Returns True if the file exists.
## f
>method f( ⟶ [Bool](./Bool.md))

 Alias for .file
## file
>method file( ⟶ [Bool](./Bool.md))

 Returns True if the file is file
## find
>method find([Pattern](./Pattern.md) **:$name** ⟶ [List[File]](./List[File].md))

 Returns a list of children that match the criteria.
```perl6
given File("$*HOME/src/spitsh/resources/src") {
    my $loc = 0;
    for .find(name => /\.sp$/) { # or just *.sp
        $loc += .lines;
    }
    say "$loc lines of code";
}
```
## group
>method group( ⟶ [Str](./Str.md))

 Returns the name of the group that own the file.
## mkdir
>method mkdir( ⟶ [File](./File.md))

 Tries to make a directory at the file's path, recursively if need be. Returns whether it succeeds.
```perl6
say "creating " ~ File<path/to/my/dir>.mkdir
```
## move-to
>method move-to([Str](./Str.md) **$destination** ⟶ [Bool](./Bool.md))

 Moves the file to another location. Overwrites pre-existing files at the destination location. Returns whether the move was completed successfully.

|Parameter|Description|
|---------|-----------|
|**$destination**| The path to move the file to|
## name
>method name( ⟶ [Str](./Str.md))

 Returns the name of the file.
```perl6
 say File</etc/hosts>.name #->hosts
```
## open-r
>method open-r( ⟶ [FD](./FD.md))

 Opens the file and returns a FD that can be read from.
```perl6
my File $file = 'foo.txt';
$file.write(<The quick brown fox jumped over the lazy dog>);
my $fd = $file.open-r;
$fd.get() && say $~; #-> The
$fd.get() && say $~; #-> quick
```
## open-w
>method open-w( ⟶ [FD](./FD.md))

 Opens the file and returns a FD that can be written to.
```perl6
my File $file = 'foo.txt';
my $fd = $file.open-w;
$fd.write("written to via file descriptor");
say $file.slurp; #-> written to via file descriptor!
```
## owner
>method owner( ⟶ [Str](./Str.md))

 Returns the name of the user that owns the file.
## parent
>method parent( ⟶ [File](./File.md))

 Returns the parent directory of the file.
```perl6
 say File</etc/foo/foo.cfg>.name #->/etc/foo
```
## path
>method path( ⟶ [Str](./Str.md))

 Returns the file's path (relative or absolute) as a [Str].
```perl6
my File $file = 'foo.text';
$file.subst('foo','bar'); # modifies the file
say $file;
say $file.path.subst('foo','bar');
```
## push
>method push([Str](./Str.md) **$line**)

 Adds a line to a file. If the file doesn't end in a `\n`, a one will be appended before the line being added.

|Parameter|Description|
|---------|-----------|
|**$line**| line to add|
## r
>method r( ⟶ [Bool](./Bool.md))

 Alias for .readable
## readable
>method readable( ⟶ [Bool](./Bool.md))

 Returns True if the file is readable by the current user.
## remove
>method remove( ⟶ [Bool](./Bool.md))

 Removes (unlinks) the file and returns True if it was successful. If the file is a directory it will recursively it's children.
## s
>method s( ⟶ [Int](./Int.md))

 Alias for .size
## size
>method size( ⟶ [Int](./Int.md))

 Returns the size of the file in bytes
## slurp
>method slurp( ⟶ [List](./List.md))

 Reads the file into the file's content as a List of lines
```perl6
my $content = File</etc/hosts>.slurp
say $content[2]; # print the 3rd line
```
## subst
>method subst([Str](./Str.md) **$target**, [Str](./Str.md) **$replacement**, [Bool](./Bool.md) **:$g**)

 Replaces the target strnig with the replacement string in the file. **This modifies the file**.
```perl6
given File.tmp {
    .write("foood");
    .subst("o","e");
    .slurp.say; #-> feood
    .subst("o","e",:g);
    .slurp.say; #-> feeed
}
```

|Parameter|Description|
|---------|-----------|
|**$target**| The string to be replaced|
|**$replacement**| The string to replace it with|
|**:$g**| Turn on global matching|
## tmp
>method tmp([Bool](./Bool.md) **:$dir** ⟶ [File](./File.md))

 Creates a tempfile via mktemp(1) and adds it to a list of files which will be removed at the END.
```perl6
my $tmpfile = File.tmp; # Will be removed at the end
```
## touch
>method touch()

 Calls `touch(1)` on the file.
```perl6
 .touch unless File<foo.txt>
```
## w
>method w( ⟶ [Bool](./Bool.md))

 Alias for .writable
## writable
>method writable( ⟶ [Bool](./Bool.md))

 Returns True if the file is writable by the current user.
## write
>method write([Str](./Str.md) **$data**)

 Sets the file's contents to `$data`. If the file doesn't exist it will be created.

|Parameter|Description|
|---------|-----------|
|**$data**| The string to write to the file|
## x
>method x( ⟶ [Bool](./Bool.md))

 Alias for .executable
