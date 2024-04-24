=begin TODO

 - functional API to simulate Carp;
      - global options in "our @CARP_OBJECT_ARGS;
      - THINK : common @CARP_OBJECT_ARGS for all importing modules ?
      - renaming symbols through Sub::Exporter or Exporter::Tiny

  - use Carp::Object qw/:std/; ==> default export carp, croak and confess

    use Carp::Object qw/:std verbose/, -args => {frame_filter => ...}
      :carp  # carp croak confess
      :all   # carp croak confess cluck

      -all => {prefix => 'co_'}


    package DBIx::DataModel::Carp;
    use Carp::Object -re_export => qw/carp croak confess/;
    our %CARP_OBJECT_ARGS = ();
    sub im


=end TODO

=cut



package Carp::Object;
use utf8;
use strict;
use warnings;
use Devel::StackTrace;

# ======================================================================
# METHODS
# ======================================================================


sub new {
  my ($class, %args) = @_;
  
  # create $self, consume the 'verbose' arg
  my $self = {verbose => delete $args{verbose}};

  # compute a frame filter sub from the 'clan' argument -- see L<Devel::StackFrame/frame_filter>
  if (my $clan = delete $args{clan}) {
    not $args{frame_filter} or $class->new->croak("can't have arg 'clan' if arg 'frame_filter' is present");
    $args{frame_filter} = sub {my $raw_frame_ref = shift;
                               my $pkg = $raw_frame_ref->{caller}[0];
                               return $pkg !~ /$clan/};
  }

  # default handler for displaying frames
  $self->{display_frame}       = delete $args{display_frame} // \&default_display_frame;
  $self->{display_frame_param} = delete $args{display_frame_param};

  # classes to be ignored by Devel::StackTrace : list supplied by caller + current class
  my $ignore_class = delete $args{ignore_class} // [];
  $ignore_class    = [$ignore_class] if not ref $ignore_class;
  push @$ignore_class, $class;
  $args{ignore_class} = $ignore_class;

  # create a Devel::StackTrace instance from remaining args (with defaults)
  $args{message} //= ''; # to avoid the 'Trace begun' string from StackFrame::Frame::as_string
  $args{indent}  //= 1;
  $self->{trace} = Devel::StackTrace->new(%args);

  # return the carper object
  bless $self, $class;
}



sub croak   {my $self = shift; die  $self->msg(join("", @_), 1)} # 1 means "just one frame"
sub carp    {my $self = shift; warn $self->msg(join("", @_), 1)} # idem
sub confess {my $self = shift; die  $self->msg(join("", @_)   )}
sub cluck   {my $self = shift; warn $self->msg(join("", @_)   )}


sub msg {
  my ($self, $errstr, $n_frames) = @_;
  $errstr //= "Died";
  
  # get stack frames. If not doing a "confess", just keep the required number of frames.
  my  @frames = $self->{trace}->frames;
  no warnings 'once';       # because of $Carp::* below
  splice @frames, $n_frames if defined $n_frames and not $self->{verbose} || $Carp::Verbose || $Carp::Clan::Verbose;


  # add frame descriptions to the original $errstr
  if (my $first_frame = shift @frames) {
    my $p    = $self->{display_frame_param};                   # see L<Devel::StackFrame/as_string>
    $errstr .= $self->{display_frame}->($first_frame, 1, $p);  # 1 means "is first"
    $errstr .= $self->{display_frame}->($_, undef, $p)  foreach @frames;
  }

  return $errstr;
}

# ======================================================================
# SUBROUTINES (NOT METHODS)
# ======================================================================

sub default_display_frame {
  my ($frame, @other_args) = @_;

  # let Devel::StackTrace::Frame compute a string representation
  my $str = $frame->as_string(@other_args);

  # if this seems to be a method call, make it look like so
  $str =~ s{^ (\t)?              # optional tab    -- capture in $1
              ([\w:]+)           # class name      -- capture in $2
              ::
              (\w+)              # method name     -- capture in $3
              \('                # beginning arg list
                 ( \2            # first arg: again the class name
                   (?: = [^']+)? # .. possibly followed by the ref addr
                 )
                '                # end of fist arg -- capture in $4
                (?: ,\h* )?      # possibly followed by a comma
            }
           {$1$4->$3(}x;               

  return "$str\n";
}
  


# ======================================================================
# IMPORT API (CLASS METHOD)
# ======================================================================

sub import {
  my ($class, @imported_symbols) = @_;
  my $calling_pkg = caller(0);

  while (my $symbol = shift @imported_symbols) {
    $symbol =~ /^(croak|carp|confess|cluck)$/
      or $class->new->croak("can't import symbol '$symbol'");
    no strict "refs";
    *{"$calling_pkg\::co_$symbol"} = sub {
      my $constructor_args = *{"$calling_pkg\::CARP_OBJECT_ARGS"} // {};
      $class->new(%$constructor_args)->$symbol(@_);
    };
  }
}


  

  



1;


__END__

=head1 NAME

Carp::Object - an object for carping

=head1 SYNOPSIS


  my $carper = Carp::Object->new(%options);
  $carper->carp("this is very wrong") if some_bad_condition();


=head1 DESCRIPTION

Carp
  - lots of backcompat code
  - cannot handle exception objects
  - no support for clans
  ++ @CARP_NOT can be localized


Carp::Clan
  - regexp must be known statically
  - cannot handle exception objects


Advantages
  - full OO
  - filtering
  - customizing frame rendering
  - show method calls
  - could display 2, 3, .. n frames
  - 



______________
package Carp::Trace;
use strict;
use Data::Dumper;
use Devel::Caller::Perl qw[called_args];

BEGIN {
    use     vars qw[@ISA @EXPORT $VERSION $DEPTH $OFFSET $ARGUMENTS];
    use     Exporter;

    @ISA    = 'Exporter';
    @EXPORT = 'trace';
}

$OFFSET     = 0;
$DEPTH      = 0;
$ARGUMENTS  = 0;
$VERSION    = '0.12';


__END__

=head1 NAME

Carp::Trace - simple traceback of call stacks

=head1 SYNOPSIS

    use Carp::Trace;

    sub flubber {
        die "You took this route to get here:\n" .
            trace();
    }

=head1 DESCRIPTION

Carp::Trace provides an easy way to see the route your script took to
get to a certain place. It uses simple C<caller> calls to determine
this.

=head1 FUNCTIONS

=head2 trace( [DEPTH, OFFSET, ARGS] )

C<trace> is a function, exported by default, that gives a simple
traceback of how you got where you are. It returns a formatted string,
ready to be sent to C<STDOUT> or C<STDERR>.

Optionally, you can provide a DEPTH argument, which tells C<trace> to
only go back so many levels. The OFFSET argument will tell C<trace> to
skip the first [OFFSET] layers up.

If you provide a true value for the C<ARGS> parameter, the arguments
passed to each callstack will be dumped using C<Data::Dumper>.
This might slow down your trace, but is very useful for debugging.

See also the L<Global Variables> section.

C<trace> is able to tell you the following things:

=over 4

=item *

The name of the function

=item *

The number of callstacks from your current location

=item *

The context in which the function was called

=item *

Whether a new instance of C<@_> was created for this function

=item *

Whether the function was called in an C<eval>, C<require> or C<use>

=item *

If called from a string C<eval>, what the eval-string is

=item *

The file the function is in

=item *

The line number the function is on

=back

The output from the following code:

    use Carp::Trace;

    sub foo { bar() };
    sub bar { $x = baz() };
    sub baz { @y = zot() };
    sub zot { print trace() };

    eval 'foo(1)';

Might look something like this:

    main::(eval) [5]
        foo(1);
        void - no new stash
        x.pl line 1
    main::foo [4]
        void - new stash
        (eval 1) line 1
    main::bar [3]
        void - new stash
        x.pl line 1
    main::baz [2]
        scalar - new stash
        x.pl line 1
    main::zot [1]
        list - new stash
        x.pl line 1

=head1 Global Variables

=head2 $Carp::Trace::DEPTH

Sets the depth to be used by default for C<trace>. Any depth argument
to C<trace> will override this setting.

=head2 $Carp::Trace::OFFSET

Sets the offset to be used by default for C<trace>. Any offset
argument to C<trace> will override this setting.

=head2 $Carp::Trace::ARGUMENTS

Sets a flag to indicate that a C<trace> should dump all arguments for
every call stack it's printing out. Any C<args> argument to C<trace>
will override this setting.

=head1 AUTHOR

This module by
Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

This module is
copyright (c) 2002 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut
