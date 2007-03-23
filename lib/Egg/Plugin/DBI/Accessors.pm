package Egg::Plugin::DBI::Accessors;
#
# Copyright (C) 2006 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Accessors.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Plugin::DBI::CommitOK/;

our $VERSION = '0.03';

sub __args {
	@_ ? (ref($_[0]) eq 'ARRAY' ? $_[0]: [@_]): [];
}
sub dbh_hashref {
	my $e   = shift;
	my $key = shift || return 0;
	my $sql = shift || return 0;
	my $args= &__args(@_);
	my %bind;
	my $sth= $e->dbh->prepare($sql);
	@$args ? $sth->execute(@$args): $sth->execute;
	$sth->bind_columns(\(@bind{map{$_}@{$sth->{NAME_lc}}}));
	$sth->fetch; $sth->finish;
	$bind{$key} ? \%bind: 0;
}
sub dbh_scalarref {
	my $e   = shift;
	my $sql = shift || return 0;
	my $args= &__args(@_);
	my $result;
	my $sth= $e->dbh->prepare($sql);
	@$args ? $sth->execute(@$args): $sth->execute;
	$sth->bind_columns(\$result);
	$sth->fetch; $sth->finish;
	$result ? \$result: 0;
}
sub dbh_arrayref {
	my $e   = shift;
	my $sql = shift || return 0;
	my $args= &__args(@_);
	my(@array, %bind);
	my $sth= $e->dbh->prepare($sql);
	@$args ? $sth->execute(@$args): $sth->execute;
	$sth->bind_columns(\(@bind{map{$_}@{$sth->{NAME_lc}}}));
	while ($sth->fetch) { my %hash= %bind; push @array, \%hash }
	$sth->finish;
	scalar(@array) ? \@array: 0;
}
sub dbh_any {
	my $e   = shift;
	my $sql = shift || return 0;
	my $args= &__args(@_);
	my $sth= $e->dbh->prepare($sql);
	@$args ? $sth->execute(@$args): $sth->execute;
	$sth->finish;
	1;
}

1;

__END__

=head1 NAME

Egg::Plugin::DBI::Accessors - Convenient accessor to dbh.

=head1 SYNOPSIS

  use MYPROJECT;
  use strict;
  use Egg qw/DBI::Accessors/;

Example of code.

  my $scalar= $e->dbh_scalarref(q{ SELECT foo FROM hoge WHERE id = ? }, '123')
    || Egg::Error->error 'Data is not found.';
  
  my $hash= $e->dbh_hashref('foo', q{ SELECT * FROM hoge WHERE id = ? }, '123')
    || Egg::Error->error 'Data is not found.';
  
  my $array= $e->dbh_arrayref(q{ SELECT * FROM hoge WHERE type = ? }, 'udon')
    || Egg::Error->error 'Data is not found.';
  
  $e->dbh_any(
    q{ INSERT INTO hoge (id, type, name) VALUES (?, ?, ?) },
    '124', 'udon', 'banban',
    );

=head1 DESCRIPTION

When the data base handler is treated, it is ..some procedure.. omissible.

It is effective because Egg::Plugin::DBI::CommitOK has been succeeded to even if
 it doesn't describe it in the controller.
However, committing is not done in the automatic operation. 

=head1 METHODS

=head2 $e->dbh_hashref([KEY], [SQL], [ARGS], ...);

The execution result is returned by the HASH reference. 

Please specify the field name of the content's being sure being sure to exist for [KEY].

=head2 $e->dbh_arrayref([SQL], [ARGS], ...);

The execution result is returned by the ARRAY reference.

=head2 $e->dbh_scalarref([SQL], [ARGS], ...);

The execution result is returned by the SCALAR reference.

=head2 $e->dbh_any([SQL], [ARGS], ...);

When it doesn't generate the return value.

=head1 SEE ALSO

L<Egg::Plugin::DBI::CommitOK>
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2006 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

