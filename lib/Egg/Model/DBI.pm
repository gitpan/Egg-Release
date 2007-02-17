package Egg::Model::DBI;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: DBI.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Model/;
use DBI;

our $VERSION= '0.04';

__PACKAGE__->mk_accessors( qw/pid tid db_handler/ );

sub setup {
	my($class, $e, $conf)= @_;
	$conf->{dsn}  || Egg::Error->throw("Please setup DBI-> 'dsn'.");
	$conf->{user} || Egg::Error->throw("Please setup DBI-> 'user'.");
	@_;
}
sub dbh {
	my($dbi)= @_;
	if ($dbi->connected) {
		$dbi->connect
		  if (($dbi->tid && $dbi->tid ne threads->tid)
		   || ($dbi->pid && $dbi->pid ne $$));
	} else {
		$dbi->db_handler($dbi->connect);
	}
	$dbi->db_handler;
}
sub connect {
	my($dbi)= @_;
	my $conf= $dbi->config;
	my $dbh;
	eval{
		$dbh= DBI->connect(
		  $conf->{dsn},
		  $conf->{user},
		  $conf->{password},
		  $conf->{options},
		  );
	  };
	if (my $err= $@) {
		Egg::Error->throw("Database Connect NG!! dsn: $conf->{dsn} at $err");
	} else {
		$dbi->e->debug_out("# + Database Connect OK!! dsn: $conf->{dsn}");
	}
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

=head1 SEE ALSO

L<Egg::Release>,
L<http://dbi.perl.org/>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
