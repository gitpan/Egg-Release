package Egg::Request::Apache;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Apache.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Request::Apache - Base class for mod_perl request class.

=cut
use strict;
use warnings;
use Carp qw/croak/;
use base qw/Egg::Request/;

our $VERSION= '2.00';

sub _setup_output {
	my($class, $e)= @_;
	no warnings 'redefine';
	*Egg::Response::output= sub {
		my $res = shift;
		my $head= shift || croak q{ I want response header. };
		my $body= shift || croak q{ I want response body.   };
		my $r= $res->request->r;
		$r->send_cgi_header($$head);
		$r->print($$body || "");
	  };
	@_;
}
sub _setup_handler {
	my($class, $e)= @_;
	my $project= $e->{namespace};
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{"${project}::handler"}= sub : method { shift; $project->run(@_) };
	@_;
}

=head1 SEE ALSO

L<Egg::Request::Apache::MP13>,
L<Egg::Request::Apache::MP19>,
L<Egg::Request::Apache::MP20>,
L<Egg::Request>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
