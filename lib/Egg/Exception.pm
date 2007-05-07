package Egg::Exception;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Exception.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Exception - Exception module for Egg.

=head1 SYNOPSIS

  use Egg::Exception;
  
  Egg::Error->throw('The error occurs.');
  
  sub run {
    my($e)= @_;
    local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };
    eval {
      $e->call_method;
      };
    if ($@) {
      print STDERR "stack: ". $@->stacktrace;
    }
  }

=head1 DESCRIPTION

This is a module to treat the exception handling.

=cut
use strict;

our $VERSION= '2.00';

package Egg::Error;
use strict;
use warnings;
use Devel::StackTrace;
use overload  '""' => 'stacktrace';
use base qw/Class::Accessor::Fast/;

our $IGNORE_PACKAGE= [qw/main Class::C3 Carp NEXT/];
our $IGNORE_CLASS  = [qw/Egg::Error/];

__PACKAGE__->mk_accessors(qw/ errstr frames as_string /);

=head1 METHODS

Egg::Exception doesn't have the method.
Please call the method of Egg::Error.

=head2 new

Constructor.

It processes it by L<Devel::StackTrace>.

=cut
sub new {
	my $class = shift;
	my $errstr= join '', @_;
	my $stacktrace;
	{
		local $@;
		eval{
		  $stacktrace= Devel::StackTrace->new(
		    ignore_package   => $IGNORE_PACKAGE,
		    ignore_class     => $IGNORE_CLASS,
		    no_refs          => 1,
		    respect_overload => 1,
		    );
		  };
	  };
	die $errstr unless $stacktrace;
	bless {
	  errstr   => $errstr,
	  as_string=> $stacktrace->as_string,
	  frames   => [$stacktrace->frames],
	  }, $class;
}

=head2 throw ( [MESSAGE] )

After the exception message is thrown to the constructor, die is done.

  Egg::Error->throw( 'internal error.' );

=cut
sub throw {
	my $error= shift->new(@_);
	die $error;
}

=head2 stacktrace

The stack trace that has accumulated is output.

  local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };
  eval{ ... code. };
  if ($@) { die $@->stacktrace }

=cut
sub stacktrace {
	my($self)= @_;
	my @trace;
	foreach my $f (@{$self->frames}) {
		push @trace, $f->filename. ': '. $f->line;
	}
	"$self->{errstr} \n\n stacktrace: \n [". join("] \n [", @trace). "] \n";
}

=head1 SEE ALSO

L<Devel::StackTrace>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
