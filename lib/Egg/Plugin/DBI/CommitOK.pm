package Egg::Plugin::DBI::CommitOK;
#
# Copyright (C) 2006 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: CommitOK.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use warnings;
use base qw/Class::Data::Inheritable/;

our $VERSION = '0.04';

__PACKAGE__->mk_classdata('dbh');
__PACKAGE__->mk_classdata('rollback_ok');

sub setup {
	my($e)= @_;
	my $dbh= $e->model('DBI')
	  || Egg::Error->throw(q/Please build in MODEL DBI./);
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	if ($dbh->{AutoCommit}) {
		*{__PACKAGE__.'::dbh_commit'}  = sub { 1 };
		*{__PACKAGE__.'::dbh_rollback'}= sub { 1 };
	} else {
		*{__PACKAGE__.'::dbh_commit'}= sub {
			$_[0]->dbh->commit;
			$_[0]->debug_out("# + dbh->commit was called.");
		  };
		*{__PACKAGE__.'::dbh_rollback'}= sub {
			eval{ $_[0]->dbh->rollback };
		  };
	}
	$e->next::method;
}
sub prepare {
	my($e)= @_;
	$e->dbh( $e->model('DBI')->dbh );
	$e->next::method;
}
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
sub finalize {
	my($e)= shift->next::method;
	($e->commit_ok && ! $e->rollback_ok) ? $e->dbh_commit: $e->dbh_rollback;
	$e;
}
sub finalize_error {
	my($e)= shift->next::method;
	$e->dbh_rollback;
	$e;
}

1;

__END__

=head1 NAME

Egg::Plugin::DBI::CommitOK - DBI->commit is settled and it does.

=head1 SYNOPSIS

  package MYPROJECT;
  use strict;
  use Egg qw/DBI::CommotOK/;

Example of code.

  my($e)= @_;
  .... ban, ban, ban.
  
  my $sth= $e->dbh->prepare(q{ update table set foo = ? where baa = ? });
  $sth->execute('foo_value', 'baa_value');
  $sth->finish;
  $e->commit_ok(1);
  #
  # Actual $e->dbh->commit is done by $e->finalize after this.
  #

=head1 DESCRIPTION

When commit_ok is false, rollback is always done.

When dbh->{AutoCommit} is effective, nothing is done.

When the error occurs by the application, rollback is done via finalize_error.

=head1 METHODS

=head2 $e->dbh

It is an accessor to $e->model('DBI')->dbh.

=head2 $e->commit_ok([Boolean]);

It is a flag whether to do dbh->commit.

=head2 $e->rollback_ok([Boolean]);

It is a flag whether to do dbh->rollback.

=head2 $e->dbh_commit

$e->dbh->ommit is done at once.
However, nothing is done when dbh->{AutoCommit} is effective.

=head2 $e->dbh_rollback

$e->dbh->rollback is done at once.
However, nothing is done when dbh->{AutoCommit} is effective.

=head1 SEE ALSO

L<Egg::Model::DBI>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2006 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

