#| Regex is the type for POSIX extended regex (ERE).
augment Regex {
    #| Returns the value of calling .match on the argument with the
    #| invocant regex as the argument.
    method ACCEPTS($b)? { $b.match($self) }
}
