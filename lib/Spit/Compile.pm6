# A home for the main compilation pipeline entrypoint
unit module Spit::Compile;

use Spit::Util :get-globalish, :light-load;

sub compile  ($input is copy,
              :$*SETTING is copy,
              :$debug,
              :$target = 'compile',
              :%opts,
              :$outer,
              :$name is required,
              :$no-inline,
              *%,
             ) is export {

    # SETTING being false
    without $*SETTING {
        $_ = (once light-load 'Spit::PRECOMP', export-target => '&get-SETTING')()
    }

    my $*CU-name = $name;
    if $input ~~ Str {
        my $parser  = (once light-load 'Spit::Parser::Grammar', target => 'Spit::Grammar').new;
        my $actions = (once light-load 'Spit::Parser::Actions', target => 'Spit::Actions').new(:$outer,:$debug);
        my $*ACTIONS = $actions;
        note "$name parsing.. " if $debug;
        my \before = now;
        my $match = $parser.parse($input,:$actions);
        die "Parser completely failed to match inptu($name)" unless $match;
        note "$name parsing ✔ {now - before}" if $debug;
        $input = $match.made;
        return $match if $target eq 'parse';
        return $input if $target eq 'stage1';
    }

    if $input.isa('SAST::CompUnit') and not $input.stage2-done {
        note "$name contextualzing.." if $debug;
        my \before = now;
        $input .= do-stage2();
        note "$name contextualzing ✔ {now - before}" if $debug;
        return $input if $target eq 'stage2';
    }

    my $compiler = (once light-load 'Spit::Sh::Compiler').new(:%opts);

    if $input.isa('SAST::CompUnit') and $input.stage2-done {
        note "$name composing.." if $debug;
        my \before = now;
        (once light-load 'Spit::Sh::Composer').new(
            :%opts,
            scaffolding => $compiler.scaffolding,
            :$no-inline,
        ).walk($input);
        note "$name composing ✔ {now - before}" if $debug;
        return $input if $target eq 'stage3'
    }

    if $input.isa('SAST::CompUnit') and $input.stage3-done {
        note "$name compiling.." if $debug;
        my \before = now;
        $input = $compiler.compile($input);
        note "$name compiling ✔ {now - before}" if $debug;
    }

    $input;
}
