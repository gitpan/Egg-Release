package Egg::Plugin::Debugging::Report;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Report.pm 154 2007-05-17 03:01:31Z lushe $
#
use strict;
use warnings;

our $VERSION = '2.01';

=head1 NAME

Egg::Plugin::Debugging::Report - debug report for Egg Plugin.

=head1 DESCRIPTION

This module is read from L<Egg::Debugging>.

Please refer to the document of L<Egg::Debugging> for details.

=head1 METHODS

=head2 report

The debugging report is output to STDERR.

=cut
sub report {
	my($debug)= @_;  my $e= $debug->e;
	my $project= $e->namespace. '-'. $e->VERSION;
	my $path   = $e->request->path || '---';
	my $report = ($debug->{notes} || ""). "\n"
	 . "# $project -< Process >-----------------------\n"
	 . "# + Request path     : $path\n";
	my $param;
	if ($param= $e->request->{parameters} and %$param) {
		$report.= "# + in request querys:\n"
		 . (join "\n", map{"# +   - $_ = $param->{$_}"}keys %$param)
		 . "\n# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
	}
	print STDERR $report;
}

=head2 simple_bench

E::P::Debugging::Report::SimpleBench object is returned.

=cut
sub simple_bench {
	$_[0]->{simple_bench}
	   ||= Egg::Plugin::Debugging::Report::SimpleBench->new;
}

package Egg::Plugin::Debugging::Report::SimpleBench;
use strict;
use Time::HiRes qw/gettimeofday tv_interval/;

=head1 SIMPLE BENCH METHODS

An easy bench mark is done.

=head2 new

Constructor of E::P::Debugging::Report::SimpleBench.

=cut
sub new { bless { report=> [] }, shift }

=head2 stock ( [ANNOTATION] )

The delimitation between each bench mark is put.

=cut
sub stock {
	my($self, $key)= @_;
	my $elapsed= tv_interval ($self->{is_time} || $self->_settime);
	push @{$self->{report}},
	  [ $key, sprintf('%.6f', $elapsed == 0 ? '?': $elapsed ) ];
	$self->_settime;
}
sub _settime { $_[0]->{is_time}= [gettimeofday] }

=head2 finish

The bench mark is completed, and the result is output to STDERR.

=cut
sub finish {
	my $self= shift;
	my($label, $elapsed);
	print STDERR "\n# >> simple bench = -------------------\n";
	my $total= 0;
	for (@{$self->{report}}) {
		($label, $elapsed)= @$_;
		$total+= $elapsed;
		write STDERR;
	}
	($label, $elapsed)= ('======= Total >>', sprintf('%.6f', $total));
	write STDERR;
	print STDERR   "# -------------------------------------\n";

	format STDERR =
  * @<<<<<<<<<<<<<<< : @>>>>>>>>> sec.
    $label,            $elapsed
.
}

=head1 SEE ALSO

L<Egg::Debugging>,
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
