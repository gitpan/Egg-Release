package Egg::Plugin::Log;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Log.pm 111 2007-05-09 21:31:43Z lushe $
#

=head1 NAME

Egg::Plugin::Log - Plugin concerning log.

=head1 SYNOPSIS

  use Egg qw/ Log /;

  $e->log->notes(' ... ');
  $e->log->debug(' ... ');
  $e->log->error(' ... ');

=head1 DESCRIPTION

It is a plug-in that offers the function concerning the log.

If $e-E<gt>config->{log_file} is set, the log is preserved.

* The log is always only added.
  It is necessary to prepare another means to rotate.

=cut
use strict;
use warnings;

our $VERSION = '2.01';

sub _setup {
	my($e)= @_;
	my $logfile= $e->config->{log_file} || return $e->next::method;

	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*_finalize_result= sub {
		my($egg)= @_;
		return $egg->next::method unless $egg->{log_body};
		open FH, ">> $logfile" || die "$logfile : $!";  ## no critic
		print FH $egg->{log_body};
		close FH;
		$egg->next::method;
	  };

	$e->next::method;
}

=head1 METHODS

=head2 log

The handler object of this plug-in is returned.

=cut
sub log { $_[0]->{Log} ||= Egg::Plugin::Log::handler->new(@_) }

package Egg::Plugin::Log::handler;
use strict;

=head1 HANDLER METHODS

=head2 new

Constructor.

=cut
sub new {
	bless {
	  e=> $_[1], req=> $_[1]->request,
	  date=> scalar(localtime(time)),
	  }, $_[0];
}

=head2 notes

The log is written. 'Notes' adheres to the header.

=cut
sub notes  { shift->_log('notes', [caller()], @_) }

=head2 debug

The log is written. 'Debug' adheres to the header.

=cut
sub debug  { shift->_log('debug', [caller()], @_) }

=head2 error

The log is written. 'Error' adheres to the header.

It outputs it to STDERR at the same time.

=cut
sub error  { warn shift->_log('error', [caller()], @_) }

sub _log {
	my $self= shift;
	$self->{e}{log_body}.= my $line= $self->_line(@_);
	$line;
}
sub _line {
	my($self, $label, $call)= splice @_, 0, 3;
	my $msg= $_[1] ? join(' : ', @_): ($_[0] || 'none.');
	   $msg=~s{^\s+} []s;
	   $msg=~s{\s+$} []s;
	   $msg=~s{(\s)\s+} [$1]sg;
	  "$self->{date} [$label] "
	. (join(' - ', ($self->{req}->path, $msg, $self->{req}->uri)) || "")
	. " at $call->[0] line $call->[2]\n";
}

=head1 SEE ALSO

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
