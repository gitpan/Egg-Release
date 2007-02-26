package Egg::Exception;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Exception.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;

our $VERSION= '0.01';

package Egg::Error;
use strict;
use warnings;
use Devel::StackTrace;
use overload  '""' => 'stacktrace';
use base qw/Class::Accessor::Fast/;

our $IGNORE_PACKAGE= [qw/main Class::C3 Carp NEXT/];
our $IGNORE_CLASS  = [qw/Egg::Error/];

__PACKAGE__->mk_accessors(qw/errstr frames as_string/);

sub throw {
	my $error= shift->new(@_);
	die $error;
}
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
sub stacktrace {
	my($self)= @_;
	my @trace;
	foreach my $f (@{$self->frames}) {
		push @trace, $f->filename. ': '. $f->line;
	}
	"$self->{errstr} \n\n stacktrace: \n [". join("] \n [", @trace). "] \n";
}

1;

__END__

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

=head1 METHODS

=head2 errstr

The error message is returned. 

=head2 frames

Trace information is returned by the ARRAY reference.

=head2 as_string

The error of the Carp style is returned.

=head2 stacktrace

The error message and trace information are assembled and it returns it.

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

