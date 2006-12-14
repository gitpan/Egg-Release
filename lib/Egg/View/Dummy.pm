package Egg::View::Dummy;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@bomcity.com>
#
# $Id$
#
use strict;
use warnings;
use base qw/Egg::View/;

our $VERSION= '0.01';

sub output {
	my($view, $e)= @_;
	$e->response->body( "" );
	1;
}

1;

__END__

=head1 NAME

Egg::View::Dummy - VIEW is for unnecessary.

=head1 DESCRIPTION

For test chiefly.

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
