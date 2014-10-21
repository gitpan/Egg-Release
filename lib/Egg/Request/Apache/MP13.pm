package Egg::Request::Apache::MP13;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: MP13.pm 226 2008-01-27 10:23:16Z lushe $
#
use strict;
use warnings;
use Apache          ();
use Apache::Request ();
use base qw/ Egg::Request::Apache /;

our $VERSION= '3.00';

sub _init_handler {
	my($class, $e)= @_;
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{$e->namespace. '::handler'}= sub ($$) { shift->run(@_) };
	@_;
}
sub new {
	my($class, $e, $r)= @_;
	my $req= $class->SUPER::new($e);
	my $conf= $req->e->config->{request} ||= {};
	$req->r( Apache::Request->new($r, %$conf) );
	$req;
}

1;

__END__

=head1 NAME

Egg::Request::Apache::MP13 - mod_perl1.3x for Egg request.

=head1 DESCRIPTION

It is a request class for mod_perl1.3x.

This module is read by the automatic operation if L<Egg::Request> investigates
the environment and it is necessary. Therefore, it is not necessary to read
specifying it.

=head1 METHODS

=head2 new

The object is received from the constructor of the succession class, 
and L<Apache::Request> object is defined in 'r' method.

=head1 SEE ALSO

L<Apache::Request>,
L<Egg::Request>,
L<Egg::Request::Apache>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
