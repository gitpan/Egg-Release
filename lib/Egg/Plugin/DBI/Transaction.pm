package Egg::Plugin::DBI::Transaction;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Transaction.pm 153 2007-05-16 22:58:27Z lushe $
#

=head1 NAME

Egg::Plugin::DBI::Transaction - Plugin that supports transaction of DBI.

=head1 SYNOPSIS

  use Egg qw/ DBI::Transaction /;

  # It accesses the data base handler.
  $e->dbh;
  
  # Committing then and there.
  $e->dbh_commit;
  
  # Rollback then and there.
  $e->dbh_rollback;
  
  # Committing is issued at the end of processing.
  $e->commit_ok(1);
  
  # The rollback is issued at the end of processing.
  $e->rollback(1);

=head1 DESCRIPTION

This plugin semi-automates the Transaction processing of DBI.

Rollback is done without fail at the end of processing usually.

commit is done when 'Commit_ok' is effective.

When DBI->dbh->{AutoCommit} is effective, any method of the transaction
system is not done.

=cut
use strict;
use warnings;
use base qw/Class::Accessor/;

our $VERSION = '2.01';

=head1 METHODS

=head2 dbh

The data base handler is returned.

=cut
__PACKAGE__->mk_accessors(qw/ dbh rollback_ok /);

sub _setup {
	my($e)= @_;
	my $dbi= $e->model('DBI') || die q{ I want setup 'Model::DBI'. };
	my $dbh= $dbi->dbh;
	return $e->next::method if $dbh->{AutoCommit};

	no warnings 'redefine';
	*is_autocommit= sub { 0 };
	*dbh_rollback = sub {
		eval{
		  $_[0]->dbh->rollback;
		  $_[0]->debug_out("# + dbh->rollback was called.");
		  };
	  };
	*dbh_commit= sub {
		$_[0]->dbh->commit;
		$_[0]->debug_out("# + dbh->commit was called.");
	  };

	$e->next::method;
}
sub _prepare {
	my($e)= @_;
	$e->dbh( $e->model('DBI')->dbh ) unless $e->dbh;
	$e->next::method;
}

=head2 dbh_commit

It commits when it is called and it reports with $e-E<gt>debug_out.

=cut
sub dbh_commit    { 1 }

=head2 commit_ok ( [BOOL] )

The flag to commit it at the end of processing is hoisted.

* It influences rollback_ok.

=head2 dbh_rollback

When it is called, it reports on the rollback by doing $e-E<gt>debug_out.

=cut
sub dbh_rollback { 0 }

=head2 rollback_ok ( [BOOL] )

The flag to do the rollback at the end of processing is hoisted.

=cut
sub commit_ok {
	my $e= shift;
	if (@_) {
		if ($_[0]) {
			$e->{commit_ok}= 1;
			$e->rollback_ok(0);
		} else {
			$e->{commit_ok}= 0;
			$e->rollback_ok(1);
		}
	}
	$e->{commit_ok} || 0;
}

=head2 is_autocommit

The state of DBI->dbh->{AutoCommit} is returned.

=cut
sub is_autocommit { 1 }

sub _finalize_result {
	my($e)= @_;
	$e->commit_ok ? $e->dbh_commit: $e->dbh_rollback;
	$e->next::method;
}
sub _finalize_error {
	my($e)= @_;
	$e->commit_ok(0);
	$e->next::method;
}

=head1 SEE ALSO

L<DBI>,
L<Ima::DBI>,
L<Egg::Model::DBI>,
L<Egg::Plugin::DBI::Easy>,
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
