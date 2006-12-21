package Egg::Config;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Config.pm 70 2006-12-21 16:40:31Z lushe $
#
use strict;
use warnings;
use NEXT;
use base qw/Egg::Appli/;

our $VERSION= '0.02';

sub setup {
	my($class, $e, $config, $name)= @_;
	if ($config && $name) {
		$name=~s/\:\:/_/g;
		$e->config->{lc($name)}= $config;
	}
	$class->NEXT::setup;
}
sub config {
}

1;

__END__

=head1 NAME

Egg::Config - It is a base class for MODEL and VIEW.

=head1 DESCRIPTION

This module is used to succeed to from a common of MODEL and VIEW module.

Each setting of MODEL and VIEW is done by this module.

=head1 SEE ALSO

L<Egg::Release>, L<Egg::View>, L<Egg::Model>

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
