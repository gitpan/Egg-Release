package Egg::Model::DBI;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: DBI.pm 34 2006-12-14 08:17:52Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Model/;
use DBI;

our $VERSION= '0.01';

sub new {
	my($class, $e)= @_;
	my $option= $e->config->{model_dbi} || {};
	$option->{debug_out}= sub { $e->debug_out(@_) };
	$option->{dbh}= undef;
	bless $option, $class;
}
sub dbh {
	$_[0]->{dbh} || do { $_[0]->{dbh}= $_[0]->connect; $_[0]->{dbh} };
}
sub connected {
	return ($_[0]->{dbh} && $_[0]->{dbh}->{Active} && $_[0]->{dbh}->ping);
}
sub connect {
	my($self)= @_;
	my $dbh;
	eval{
		$dbh= DBI->connect(
		 $self->{dsn},
		 $self->{user},
		 $self->{password},
		 $self->{options},
		 );
	 };
	if (my $err= $@) {
		print STDERR "# + Database Connect NG!! dsn: $self->{dsn} at $err\n";
	} else {
		$self->{debug_out}->("# + Database Connect OK!! dsn: $self->{dsn}");
	}
	$dbh;
}
sub disconnect {
	$_[0]->connected and do {
		$_[0]->{dbh}->{AutoCommit} || $_[0]->{dbh}->rollback;
		$_[0]->{dbh}->disconnect;
		$_[0]->{dbh}= undef;
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
