# NAME

Carp::Object - a replacement for Carp or Carp::Clan, object-oriented

# SYNOPSIS

## Object-oriented API

    use Carp::Object ();
    my $carper = Carp::Object->new(%options);

    # warn of error (from the perspective of caller)
    $carper->carp("this is very wrong") if some_bad_condition();

    # die of error (from the perspective of caller)
    $carper->croak("that's a dead end") if some_deadly_condition();
    
    # warn with full stacktrace
    $carper->cluck("this is very wrong");

    # die with full stacktrace
    $carper->confess("that's a dead end");

## Functional API

    use Carp::Object qw/:all/;            # many other import options are available, see below
    our %CARP_OBJECT_CONSTRUCTOR = (...); # optional opportunity to tune the carping behaviour
    our @CARP_NOT = (...);                # optional opportunity to exclude packages from stack traces
    
    # warn of error (from the perspective of caller)
    carp "this is very wrong" if some_bad_condition();
    
    # die of error (from the perspective of caller)
    croak "that's a dead end" if some_deadly_condition();

    # full stacktrace
    cluck "this is very wrong";
    confess "that's a dead end";

    # temporary change some parameters, like for example the "clan" of modules to ignore
    { local %CARP_OBJECT_CONSTRUCTOR = (clan => qw(^(Foo|Bar)));
       croak "wrong call to Foo->.. or to Bar->.." if $something_is_wrong; }

# DESCRIPTION

This is an object-oriented alternative to ["croak" in Carp](https://metacpan.org/pod/Carp#croak) or ["croak" in Carp::Clan](https://metacpan.org/pod/Carp%3A%3AClan#croak),
for reporting errors in modules from the perspective of the caller instead of
reporting the internal implementation line where the error occurs.

[Carp](https://metacpan.org/pod/Carp) or [Carp::Clan](https://metacpan.org/pod/Carp%3A%3AClan) were designed long ago, at a time when Perl
had no support yet for object-oriented programming; therefore they only
have a functional API that is not very well suited for extensions.
The present module attemps to mimic the same behaviour, but
with an object-oriented implementation that offers more tuning options,
and also supports errors raised as Exception objects.

Unlike [Carp](https://metacpan.org/pod/Carp) or [Carp::Clan](https://metacpan.org/pod/Carp%3A%3AClan), where the presentation of stack frames is hard-coded, 
here it is delegated to [Devel::StackTrace](https://metacpan.org/pod/Devel%3A%3AStackTrace). This means that clients can also
take advantage of options in [Devel::StackTrace](https://metacpan.org/pod/Devel%3A%3AStackTrace) to tune the output -- or even replace it by
another class.

Clients can choose between the object-oriented API, presented in the next chapter,
or a traditional functional API compatible with 
[Carp](https://metacpan.org/pod/Carp) or [Carp::Clan](https://metacpan.org/pod/Carp%3A%3AClan), presented in the following chapter.

**DISCLAIMER**: this module is very young and not battle-proofed yet.
Despite many efforts to make it behave as close as possible to the original [Carp](https://metacpan.org/pod/Carp),
there might be some edge cases where it is not strictly equivalent.
If you encounter such situations, please open an issue at
[https://github.com/damil/Carp-Object/issues](https://github.com/damil/Carp-Object/issues).

# METHODS

## new

    use Carp::Object (); # '()' to avoid importing any symbols
    my $carper = Carp::Object->new(%options);

This is the constructor for a "carper" object. Options are :

- verbose

    if true, a 'croak' method call is treated as a 'confess', and a 'carp' is treated as a 'cluck'.

- stacktrace\_class

    The class to be used for inspecting stack traces. Default is [Devel::StackTrace](https://metacpan.org/pod/Devel%3A%3AStackTrace).

- clan

    A regexp for identifying packages that should be skipped in stack traces, like in [Carp::Clan](https://metacpan.org/pod/Carp%3A%3AClan).
    This option internally computes a `frame_filter` and therefore is incompatible with the
    `frame_filter` option.

- display\_frame

    A reference to a subroutine for computing a textual representation of a stack frame.
    The default is [\_default\_display\_frame](https://metacpan.org/pod/_default_display_frame), which is a light wrapper
    on top of ["as\_string" in Devel::StackTrace::Frame](https://metacpan.org/pod/Devel%3A%3AStackTrace%3A%3AFrame#as_string), with improved representation of method calls.
    The given subroutine will receive three arguments :

    1. a reference to a [Devel::StackTrace::Frame](https://metacpan.org/pod/Devel%3A%3AStackTrace%3A%3AFrame) instance
    2. a boolean flag telling if this is the first stack frame in the list (because
    the display algorithm is usually different for the first stack frame).
    3. A hashref of optional parameters. Currently there is only one option `max_arg_length`,
    discribed in ["as\_string(\\%p)" in Devel::StackTrace](https://metacpan.org/pod/Devel%3A%3AStackTrace#as_string-p).

- display\_frame\_param

    The optional hashref to be supplied as third parameter to the `display_frame` subroutine.

- ignore\_class

    an arrayref of classes that will be passed to [Devel::StackTrace](https://metacpan.org/pod/Devel%3A%3AStackTrace); any class
    that belongs to or inherits from that list will be ignored in stack traces.
    `Carp::Object` will automatically add itself to the list supplied by the client.

In addition to these options, the constructor also accepts all options to ["new" in Devel::StackTrace](https://metacpan.org/pod/Devel%3A%3AStackTrace#new),
like for example `ignore_package`, `skip_frames`, `frame_filter`, `indent`, etc.

## croak

Die of error, from the perspective of the caller.

## carp

Warn of error, from the perspective of the caller.

## confess

Die of error, with full stack backtrace.

## cluck

Warn of error, with full stack backtrace.

## msg

    my $msg = $carper->msg($errstr, $n_frames);

Build the message to be used for dieing or warning.
`$errstr` is the initial error message; it may be a plain
string or an exception object with a stringification method.
`$n_frames` is the number of stack frames to display (usually 1); if undefined,
the whole stack trace is displayed.

# FUNCTIONAL API: THE IMPORT() METHOD

    use Carp::Object;                # no import list => defaults to (':carp');
    # or
    use Carp::Object @import_list;

When using this functional API, subroutines equivalent to their corresponding object-oriented
methods are exported into the caller's symbol table: the caller can then call `carp`, `croak`, etc.
like with the venerable [Carp](https://metacpan.org/pod/Carp) module.

## Import list

The import list accepts the following items :

- `carp`, `croak`, `confess` and/or `cluck`

    Individual import of specific routines

- `:carp`

    Import group equivalent to the list `carp`, `croak`, `confess`.

- `:all`

    Import group equivalent to the list `carp`, `croak`, `confess`, `cluck`.

- `\%options`

    A hashref within the import list is interpreted as a collection of importing options,
    in the spirit of [Sub::Exporter](https://metacpan.org/pod/Sub%3A%3AExporter) or [Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny). Admitted options are :

    - `-as`

            use Carp::Object carp => {-as => 'complain'}, croak => {-as => 'explode'};

        Local name for the last imported function.

    - `-prefix`

            use Carp::Object qw/carp croak/, {-prefix => 'CO_'};
            ...
            CO_croak "aargh";

        Names of imported functions will be prefixed by this string.

    - `-prefix`

            use Carp::Object qw/carp croak/, {-suffix => '_CO'};
            ...
            croak_CO "ouch";

        Names of imported functions will be suffixed by this string.

    - `-constructor_args`

            use Carp::Object qw/carp croak/, {-constructor_args => {indent => 0}};

        The given hashref will be passed to ["new" in Carp::Object](https://metacpan.org/pod/Carp%3A%3AObject#new) at each call to an imported function.

- `-reexport`

        use Carp::Object -reexport => qw/carp croak/;

    Imported symbols will be reexported into the caller of the caller !
    This is useful when several modules from a same family share a common carping module.
    See [DBIx::DataModel::Carp](https://metacpan.org/pod/DBIx%3A%3ADataModel%3A%3ACarp) for an example (actually, this was the initial motivation
    for working on `Carp::Object`().

- _regexp_

        use Carp::Object qw(^(MyClan::|FriendlyOther::));

    If the import item "looks like a regexp", it is interpreted as 
    syntactic sugar for `use Carp::Object {-constructor_args => {clan => ..}}`,
    in order to be compatible with the API of [Carp::Clan](https://metacpan.org/pod/Carp%3A%3AClan).

    The import item "looks like a regexp" if it starts with a `'^'` character,
    or contains a `'|'` or a `'('`.

## Global variables

When using the functional API, customization of `Carp::Object`
can be done indirectly through global variables in the calling package.
Such variables can be localized in inner blocks if some specific behaviour
is needed.

### `%CARP_OBJECT_CONSTRUCTOR`

    { local %CARP_OBJECT_CONSTRUCTOR = (indent => 0);
      confess "I'm a great sinner"; # for this call, stack frames will not be indented
    }

The content of this hash will be passed to ["new" in Carp::Object](https://metacpan.org/pod/Carp%3A%3AObject#new) at each call to an imported function.

### `@CARP_NOT`

The content of this array will be passed as `ignore_package` argument to
to ["new" in Carp::Object](https://metacpan.org/pod/Carp%3A%3AObject#new) at each call to an imported function.

### `$Carp::Verbose`

if true, a 'croak' method call is treated as a 'confess', and a 'carp' is treated as a 'cluck'.

# INTERNAL SUBROUTINES

## \_default\_display\_frame

This is the internal routine for displaying a stack frame.

It calls ["as\_string" in Devel::StackTrace::Frame](https://metacpan.org/pod/Devel%3A%3AStackTrace%3A%3AFrame#as_string) for doing
most of the work. An additional feature is that the presentation string
is rewritten for frames that "look like a method call" :
instead of `Foobar::method('Foobar=...', @other_args)`, we
write `Foobar=...->method(@other_args)`, so that method
calls become apparent within the stack trace.

A frame "looks like a method call" if the first argument to the routine
is a string identical to the class, or reference blessed into that class.

# AUTHOR

Laurent Dami, &lt;dami at cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2024 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
