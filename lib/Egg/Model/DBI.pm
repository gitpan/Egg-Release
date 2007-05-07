package Egg::Model::DBI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBI.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Model::DBI - DBI for Egg Model.

=head1 SYNOPSIS

  __PACKAGE__->egg_startup(
  
    MODEL => [
      [ DBI => {
        dsn      => 'dbi:Pg:dbname=hogedb;host=localhost;port=5432',
        user     => 'myapp_user',
        password => 'myapp_password',
        options  => { AutoCommit=> 1, RaiseError=> 1 },
        } ],
      ],
  
    );

  # The DBI model is acquired.
  my $model = $e->model('DBI');
  
  # dbh is acquired.
  my $dbh= $model->dbh;
  
  # The data base is disconnect.
  $model->disconnect;

=head1 DESCRIPTION

MODEL for Egg to use DBI.

If Ima::DBI can be used, L<Ima::DBI> is used.

* Ima::DBI supports the perpetuity connection with the data base because it
has the data base connection with Closure.
It comes do not to have to set Apache::DBI separately for the perpetuity 
connection.

=cut
use strict;
use warnings;
use base qw/Egg::Model/;

eval{ require Ima::DBI };  ## no critic
if ($@) {
	require DBI;
} else {
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	unshift @{__PACKAGE__.'::ISA'}, 'Ima::DBI';
	*_setup= \&_setup_imadbi;
	*_connect= sub { $_[0]->db_Main };
}

our $VERSION= '2.00';

__PACKAGE__->mk_accessors( qw/pid tid db_handler/ );

sub _connect { shift; DBI->connect(@_)  }
sub _setup   { shift->_config_check(@_) }

=head1 METHODS

=head2 connect

The connection with the data base is established.

see L<DBI> or L<Ima::DBI>.

=cut
sub connect {
	my($dbi)= @_;
	my $conf= $dbi->config;
	my $dbh;
	eval{ $dbh= $dbi->_connect(@{$conf}{qw{ dsn user password options }}) };
	$@ and die qq{ Database Connect NG!! dsn: $conf->{dsn} at $@ };
#	$dbi->e->debug_out("# + Database Connect OK!! dsn: $conf->{dsn}");
	$dbi->pid($$);
	$dbi->tid(threads->tid) if $INC{'threads.pm'};
	$dbh;
}

=head2 dbh

The data base handler is returned.

* If connect is not done, connect is done still.

=cut
sub dbh {
	my($dbi)= @_;
	if ($dbi->_connected) {
		$dbi->db_handler($dbi->connect) if (
		    ($dbi->tid and $dbi->tid ne threads->tid)
		 or ($dbi->pid and $dbi->pid ne $$)
		 );
	} else {
		$dbi->db_handler($dbi->connect);
	}
	$dbi->db_handler;
}

=head2 disconnect

The connection with the data base is cut.

=cut
sub disconnect {
	my($dbi)= @_;
	return 0 unless $dbi->_connected;
	$dbi->db_handler->{AutoCommit} or $dbi->db_handler->rollback;
	$dbi->db_handler->disconnect;
	$dbi->db_handler( undef );
	1;
}

sub _connected {
	return ($_[0]->db_handler
	  && $_[0]->db_handler->{Active} && $_[0]->db_handler->ping);
}
sub _setup_imadbi {
	my($class, $e, $conf)= shift->_config_check(@_);

	$conf->{options}= {
	  $class->SUPER::_default_attributes,
	  FetchHashKeyName => 'NAME_lc',
	  %{$conf->{options}},
	  };

	__PACKAGE__->set_db('Main'=> @{$conf}{qw{ dsn user password options }});
	$e->debug_out("# + model_dbi : Operating by 'Ima::DBI'.");
	@_;
}
sub _config_check {
	my($class, $e)= splice @_, 0, 2;
	my $conf= shift || {};

	$conf->{dsn}  || die q{ I want setup MODEL->DBI-> 'dsn'.  };
	$conf->{user} || die q{ I want setup MODEL->DBI-> 'user'. };
	$conf->{password} ||= "";
	$conf->{options}  ||= {};

	my($driver)= $conf->{dsn}=~/^dbi:(\w+)/;
	   $driver= lc($driver);
	my %DefaultAttrDrv= (
	  pg     => { AutoCommit => 0 },
	  oracle => { AutoCommit => 0 },
	  );
	$conf->{options}= {
	  ShowErrorStatement => 1,
	  AutoCommit         => 1,
	  ChopBlanks         => 1,
	  %{ $DefaultAttrDrv{$driver} || {} },
	  %{$conf->{options}},
	  };

	if ($e->debug) {
		my $psswd = '---';  ## $conf->{password} || '---';
		my $option= $conf->{options};
		my $report=
		  qq{  DSN     : $conf->{dsn}\n}
		. qq{  USER    : $conf->{user}\n}
		. qq{  OPTIONS : }
		. join(", ", map{"$_ = $option->{$_}"}keys %$option);
		$e->debug_out(qq{# + model_dbi : connected profile.\n$report});
	}

	($class, $e, $conf);
}

=head2 DESTROY

When the object disappears, disconnect is called.

=cut
sub DESTROY {
	shift->disconnect;
}

=head1 SEE ALSO

L<DBI>,
L<Ima::DBI>,
L<Egg::Model>,
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
