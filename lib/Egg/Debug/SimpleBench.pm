package Egg::Debug::SimpleBench;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: SimpleBench.pm 99 2007-01-15 06:33:14Z lushe $
#
use strict;
use warnings;
use Time::HiRes qw/gettimeofday tv_interval/;

our $VERSION= '0.02';

sub new {
	bless { elapseds=> {} }, shift;
}
sub settime {
	$_[0]->{settime}= [gettimeofday()];
}
sub stock {
	my($self, $key)= @_;
	print STDERR "# = $key completed.\n";
	$self->{elapseds}{$key}= sprintf '%f', tv_interval($self->{settime});
	$self->{stock}.= " $key $self->{elapseds}{$key} sec.\n";
	$self->settime;
}
sub out {
	my $self= shift;
	my $total;
	$total+= $_ for (values %{$self->{elapseds}});
	$total ||= '---';
	$self->{stock} ||= "";
	print STDERR
	   "# >> simple bench = -----------\n"
	 . $self->{stock}. " Total: $total sec.\n"
	 . "# ----------------------------\n";
}

1;

__END__


=head1 NAME

Egg::Debug::SimpleBench - The bench mark of easy Egg is taken.

=head1 SYNOPSIS

 package MYPROJECT;
 use strict;
 use Egg qw/-Debug/;
 ...
 ...

=head1 DESCRIPTION


This module functions when Egg operates by debug mode.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Engine>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
