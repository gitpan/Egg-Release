package Egg::Model::DBI;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: DBI.pm 203 2007-02-19 14:46:38Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use base qw/Egg::Model/;

Ima::DBI->require;
if ($@) {
	DBI->require or die $@;
} else {
	no strict 'refs';  ## no critic
	unshift @{__PACKAGE__.'::ISA'}, 'Ima::DBI';
	no warnings 'redefine';
	*setup_connect= \&__setup_connect;
	*_connect= sub { $_[0]->db_Main };
}

our $VERSION= '0.06';

__PACKAGE__->mk_accessors( qw/pid tid db_handler/ );

sub setup_connect {}
sub _connect { shift; DBI->connect(@_) }

sub setup {
	my($class, $e, $conf)= @_;
	$conf->{dsn}  || Egg::Error->throw("Please setup DBI-> 'dsn'.");
	$conf->{user} || Egg::Error->throw("Please setup DBI-> 'user'.");
	$conf->{password} ||= "";
	$conf->{options}  ||= {};
	$class->setup_connect($e, $conf);
	@_;
}
sub dbh {
	my($dbi)= @_;
	if ($dbi->connected) {
		$dbi->db_handler($dbi->connect) if (
		    ($dbi->tid && $dbi->tid ne threads->tid)
		 || ($dbi->pid && $dbi->pid ne $$)
		 );
	} else {
		$dbi->db_handler($dbi->connect);
	}
	$dbi->db_handler;
}
sub connect {
	my($dbi)= @_;
	my $conf= $dbi->config;
	my $dbh;
	eval{ $dbh= $dbi->_connect(@{$conf}{qw{ dsn user password options }}) };
	if (my $err= $@) {
		Egg::Error->throw("Database Connect NG!! dsn: $conf->{dsn} at $err");
	}
	$dbi->e->debug_out("# + Database Connect OK!! dsn: $conf->{dsn}");
	$dbi->pid($$);
	$dbi->tid(threads->tid) if $INC{'threads.pm'};
	$dbh;
}
sub connected {
	return ($_[0]->db_handler
	  && $_[0]->db_handler->{Active} && $_[0]->db_handler->ping);
}
sub disconnect {
	my($dbi)= @_;
	$dbi->connected and do {
		$dbi->db_handler->{AutoCommit} || $dbi->db_handler->rollback;
		$dbi->db_handler->disconnect;
		$dbi->db_handler( undef );
	  };
}
sub __setup_connect {
	my($class, $e)= splice @_, 0, 2;
	my $conf= shift || {};

	my($driver)= $conf->{dsn}=~/^dbi:(\w+)/;  $driver= lc($driver);
	my %DefaultAttrDrv= (
	  pg     => { AutoCommit => 0 },
	  oracle => { AutoCommit => 0 },
	  );
	my %default_options= (
	  $class->SUPER::_default_attributes,
	  FetchHashKeyName   => 'NAME_lc',
	  ShowErrorStatement => 1,
	  AutoCommit         => 1,
	  ChopBlanks         => 1,
	  %{ $DefaultAttrDrv{$driver} || {} },
	  %{$conf->{options}},
	  );
	$conf->{options}= \%default_options;

	__PACKAGE__->set_db
	  ('Main'=> @{$conf}{qw{ dsn user password options }});

	$e->debug_out("# + model_dbi : Operating by 'Ima::DBI'.");
}
sub DESTROY { 
	shift->disconnect;
}

1;

__END__

=head1 NAME

Egg::Model::DBI - It is DBI model for Egg.

=head1 SYNOPSIS

This is a sample of the configuration.

  MODEL=> [
    ['DBI'=> {
      dsn     => 'dbi:Pg:dbname=database;host=localhost;port=5432',
      user    => 'db_user',
      password=> 'db_password',
      options => { RaiseError=> 1, AutoCommit=> 0 },
      }],
    ],

* get data base handler.

  my $dbh= $e->model('DBI')->dbh;

=head1 DESCRIPTION

If Ima::DBI can be used, Ima::DBI is succeeded to.

In this case, the data base steering wheel can be received directly from A by
using db_Main.

  $e->model('DBI')->db_Main;

* This has been matched to the function of Class::DBI.

However, I recommend the method of acquiring the data base steering wheel with 
'dbh' as usual.

* It is not necessary to rely on in a continuous connection to the data base
in this and to rely on Apache::DBI.

=head1 SEE ALSO

L<http://dbi.perl.org/>,
L<Ima::DBI>
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
