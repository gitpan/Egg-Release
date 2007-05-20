package Egg::Plugin::Debugging;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Debugging.pm 155 2007-05-20 04:05:33Z lushe $
#
use strict;
use warnings;

our $VERSION = '2.03';

=head1 NAME

Egg::Plugin::Debugging - Debugging function is offered for Egg.

=head1 SYNOPSIS

  use Egg qw/Debugging/;

=head1 DESCRIPTION

The function concerning debugging is offered to Egg.

Egg doesn't operate if there is no debugging method.

Therefore, it is necessary to load the plugin with the debugging method.

=head1 METHODS

=head2 debugging

The handler object of this plug-in is returned.

=cut
sub debugging {
	$_[0]->{Debugging} ||= Egg::Plugin::Debugging::handler->new(@_);
}

package Egg::Plugin::Debugging::handler;
use strict;
use base qw/Egg::Base/;

=head1 HANDLER METHODS

=head2 notes ( [MESSAGE] )

The received message is output to STDERR.

* $e-E<gt>debug_out calls this method.

=cut
sub notes {
	my $self= shift;
	my $msg = $_[1] ? join("\n", @_): ($_[0] || return 0);
	   $msg =~s{[\r\n]+$} [];
	print STDERR "$msg\n";
}

=head2 output

Processing is thrown into Egg::Plugin::Debugging::Screen::output.

=cut
sub output {
	require Egg::Plugin::Debugging::Screen;
	Egg::Plugin::Debugging::Screen::output(@_);
}

=head2 simple_bench

Processing is thrown into Egg::Plugin::Debugging::Report::simple_bench.

=cut
sub simple_bench {
	require Egg::Plugin::Debugging::Report;
	Egg::Plugin::Debugging::Report::simple_bench(@_);
}

=head2 report

Processing is thrown into Egg::Plugin::Debugging::Report::output.

=cut
sub report {
	require Egg::Plugin::Debugging::Report;
	Egg::Plugin::Debugging::Report::report(@_);
}

=head1 SEE ALSO

L<Egg::Plugin::Debugging::Screen>
L<Egg::Plugin::Debugging::Report>
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
