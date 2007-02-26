package Egg::Debug::Log;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Log.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;
use warnings;
use FileHandle;

our $VERSION= '0.01';

*info= \&notes;

sub new {
	my($class, $e)= @_;
	bless {
	 debug=> $e->debug,
	 log_file=> ($e->config->{log_file} || ""),
	 }, $class;
}
sub debug {
	my $self= shift;
	$self->{debug} and $self->write(shift || 'Internal Error.');
	0;
}
sub notes {
	shift->write(@_);
	1;
}
sub write {
	my $self= shift;
	my $str = shift || return 0;
	my @caller= caller(1);
	warn "> $caller[0]: $caller[2] - $str";
	$self->{log_file} and do {
		my $time= localtime time;
		my $fh= FileHandle->new(">>$self->{log_file}") || die $!;
		print $fh "[$time] $str";
		$fh->close;
	 };
	1;
}

1;

__END__

=head1 NAME

Egg::Debug::Log - For output of Log.

=head1 SYNOPSIS

$e->log->debug([MESSAGE]);

$e->log->info([MESSAGE]);

$e->log->notes([MESSAGE]);

=head1 DESCRIPTION

Anything can hardly be done only by making it by one respondent for the
intercha ngeability of Catalyst.

=head1 SEE ALSO

L<Egg::Release>

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
