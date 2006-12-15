package Egg::Plugin::AfterFinalize;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@bomcity.com>
#
# $Id: AfterFinalize.pm 34 2006-12-14 08:17:52Z lushe $
#
use strict;
use warnings;
use NEXT;

our $VERSION= '0.01';

sub setup {
	my($e)= @_;
	no strict 'refs';
	no warnings 'redefine';
	*{"Egg::Engine::after_finalize"}= sub { $_[0] };
	$e->NEXT::setup;
}
sub step3 {
	$e= shift->NEXT::step3;
	$e->after_finalize;
	$e;
}

1;


__END__

=head1 NAME

Egg::Plugin::AfterFinalize
- The chance that Plugin starts after all processing ends is given.

=head1 SYNOPSIS

use Egg qw/AfterFinalize/;


* Code sample of plugin

use Egg::Plugin:Foge;
use strict;
use NEXT;

sub after_finalize {
	my($e)= @_;
	... ban, bo, bo, bon.
	.............
	......
	$e->NEXT::after_finalize;
}

=head1 DESCRIPTION

This is a sample of the code in which basic processing of Egg is taken over.

It is possible to plunder of basic processing of Egg like this at what time
 by the Orbaraided thing. 

=head1 SEE ALSO

L<Egg>

=head1 AUTHOR

Masatoshi Mizuno, <lt>L<mizunoE<64>bomcity.com><gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. <L<http://egg.bomcity.com/>>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
