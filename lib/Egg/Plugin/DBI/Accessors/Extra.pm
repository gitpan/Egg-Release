package Egg::Plugin::DBI::Accessors::Extra;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Extra.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Plugin::DBI::Accessors/;

our $VERSION = '0.04';

sub db {
	$_[0]->{plugin_dbi_accessors_extra}
	  ||= Egg::Plugin::DBI::Accessors::Extra::handler->new(@_);
}

package Egg::Plugin::DBI::Accessors::Extra::handler;
use strict;

our $AUTOLOAD;

sub new {
	my($class, $e)= @_;
	bless { e=> $e }, $class;
}
sub AUTOLOAD {
	my($db)= @_;
	my($dbname)= $AUTOLOAD=~/([^\:]+)$/;
	my $pkg= __PACKAGE__."::$dbname";
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	@{"$pkg\::ISA"}= 'Egg::Plugin::DBI::Accessors::Extra::accessors';
	*{__PACKAGE__."::$dbname"}= sub {
		my($self)= @_;
		$self->{$dbname} ||= $pkg->new($self->{e}, $dbname);
	  };
	$db->{$dbname}= $pkg->new($db->{e}, $dbname);
}
sub DESTROY {}

package Egg::Plugin::DBI::Accessors::Extra::accessors;
use strict;

sub new {
	my($class, $e, $dbname)= @_;
	bless { e=> $e, dbname=> $dbname }, $class;
}
sub scalarref {
	my $db= shift;
	my $item = shift || Egg::Error->throw(q/I want filed name./);
	my $where= $_[0] ? " WHERE ". shift: (shift || "");
	$db->{e}->dbh_scalarref
	  (qq{ SELECT $item FROM $db->{dbname}$where}, @_);
}
sub hashref {
	my $db= shift;
	my $items= shift;
	my $where= $_[0] ? " WHERE ". shift: (shift || "");
	my($pkey, %bind);
	if (ref($items) eq 'ARRAY') {
		$pkey= $items->[0];
		$items= join ', ', @$items;
	} else {
		($pkey, $items)= ($items, '*');
	}
	$db->{e}->dbh_hashref
	  ($pkey, qq{ SELECT $items FROM $db->{dbname}$where }, @_);
}
sub arrayref {
	my $db= shift;
	my $items= shift || '*';
	my $where= $_[0] ? " WHERE ". shift: (shift || "");
	$items= join ', ', @$items if ref($items) eq 'ARRAY';
	$db->{e}->dbh_arrayref
	  (qq{ SELECT $items FROM $db->{dbname}$where }, @_);
}
sub insert {
	my $db= shift;
	my $in= shift || Egg::Error->throw(q/I want insert fields./);
	my($items, $boxs)= ref($in) eq 'ARRAY'
	  ? (join(', ', @$in), join(', ', map{'?'}@$in)): ($in, '?');
	$db->{e}->dbh_any(qq{INSERT INTO $db->{dbname} ($items) VALUES ($boxs)}, @_);
}
sub update {
	my $db= shift;
	my $set= shift || Egg::Error->throw(q/I want SQL statement parts./);
	my $where= shift || Egg::Error->throw(q/I want SQL statement parts./);
	$set= join ', ', map{"$_ = ?"}@$set if ref($set) eq 'ARRAY';
	$db->{e}->dbh_any(qq{UPDATE $db->{dbname} SET $set WHERE $where}, @_);
}
sub upgrade {
	my $db= shift;
	my $set= shift || Egg::Error->throw(q/I want SQL statement parts./);
	$set= join ', ', map{"$_ = ?"}@$set if ref($set) eq 'ARRAY';
	$db->{e}->dbh_any(qq{UPDATE $db->{dbname} SET $set});
}
sub any {
	my $db= shift;
	my $sql= shift || Egg::Error->throw(q/I want SQL statement/);
	$sql=~s{-DB-} [$db->{dbname}]ig;
	$db->{e}->dbh_any($sql, @_);
}
sub delete {
	my $db= shift;
	my $where= shift || Egg::Error->throw(q/I want SQL statement parts./);
	$db->{e}->dbh_any(qq{DELETE FROM $db->{dbname} WHERE $where }, @_);
}
sub clear {
	my $db= shift;
	my $flag= shift || Egg::Error->throw(q/I want exec flag./);
	$db->{e}->dbh_any(qq{DELETE FROM $db->{dbname}});
}

1;

__END__

=head1 NAME

Egg::Plugin::DBI::Accessors::Extra - Accessor to convenient dbh that can write SQL short.

=head1 SYNOPSIS

  use MYPROJECT;
  use strict;
  use Egg qw/DBI::Accessors::Extra/;

Example code.

  my $scalar= $e->db->table_name->scalarref
    ('name', 'id = ?', $id) || die 'fails in acquisition.';
  
  my $array= $e->db->table_name->arrayref
    ([qw/id name email/], 'group = ?', $group) || die 'fails in acquisition.';
  for my $hash (@$array) {
  	print "$hash->{id} : $hash->{name} : $hash->{email}";
  }
  
  my $hash= $e->db->table_name->hashref
    ([qw/id name email/], 'id = ?', $id); || die 'fails in acquisition.';
  print "$hash->{id} : $hash->{name} : $hash->{email}";
  
  $e->db->table_name->insert([qw/id name email/], $id, $name, $email);
  
  $e->db->table_name->update([qw/name email/], 'id = ?', $name, $email, $id);
  
  # All data is updated.
  $e->db->table_name->upgrade([qw/group/], 'general');
  
  $e->db->table_name->delete('group = ?', $group);
  
  # All data is deleted.
  $e->db->table_name->clear(1);

=head1 DESCRIPTION

This module is made to be able to write the inquiry of the data table easily.

Because this module has succeeded to Egg::Plugin::Accessors, it is not necessary to
 read separately.

The function to unite two or more tables is not provided.
Only a single table can be treated.

When the application as DBIx::Class etc. are not used is made, it might be convenient.

When the table name that actually exists in $e->db is called as a method, Abject with
 the accessor to 'dbh' is restored.

  Table "mambers"
  Column    |  Type
  ----------+---------
  id        | serial
  user_name | verchar
  email     | verchar

  $e->db->members->insert([qw/user_name email/], $user_name, $email);
  
  my $array= $e->db->members->arrayref([qw/id user_name email/]);

=head1 METHODS

=head2 my $db= $e->db;

The object for handling to the data table is returned.

=head2 my $table= $db->[TABLE_NAME];

The object with the accessor to the data table is returned.

=head2 my $scalar= $table->scalarref('[FIELD_NAME]', '[WHERE]', [EXECUTE_VARS]);

The acquired single data is returned by the Scalar reference.
When two or more data exists, the value of the data acquired first is returned. 

0 returns when pertinent data is not found.

The name of the data field that wants to be acquired to the first argument is 
specified.

[WHERE] and [EXECUTE_VAR] can be omitted.

[WHERE] is not cared about including the statement such as 'ORDER BY' etc.

=head2 my $hash= $table->hashref([qw/[FIELD_NAME].../], '[WHERE]', [EXECUTE_VARS]);

The acquired data is returned by the HASH reference.
When two or more data exists, the value of the data acquired first is returned. 

0 returns when pertinent data is not found.

The data field name that wants to be acquired is given to the first argument 
with the ARRAY reference or Scalar.

The first value treats the first argument most as a field to check the presence 
of data.

[WHERE] and [EXECUTE_VAR] can be omitted.

[WHERE] is not cared about including the statement such as 'ORDER BY' etc.

=head2 my $array= $table->arrayref([qw/[FIELD_NAME].../], '[WHERE]', [EXECUTE_VARS]);

Two or more acquired data records are returned by the ARRAY reference.
The data of each record becomes HASH reference.

0 returns when pertinent data is not found.

The data field name that wants to be acquired is given to the first argument 
with the ARRAY reference or Scalar.

[WHERE] and [EXECUTE_VAR] can be omitted.

[WHERE] is not cared about including the statement such as 'ORDER BY' etc.

=head2 $table->insert([qw/[FIELD_NAME].../], [EXECUTE_VARS]);

Data is added to the table.

=head2 $table->update([qw/[FIELD_NAME].../], [WHERE], [EXECUTE_VARS]);

Data is updated.

When [FIELD_NAME] is ARRAY reference, it converts it into an appropriate SET sentence.

  $table->update([qw/uid email address/] ...);

  'uid = ?, email = ?, address = ?'

When [FIELD_NAME] is given with Scalar, it is evaluated as it is.

  $table->update('uid = ?, email = ?, address = ?', ...)

=head2 $table->upgrade([qw/[FIELD_NAME]/], [EXECUTE_VARS]);

The value of the specified field on all the records is changed.

Similar $table->update is operated about [FIELD_NAME]. 

=head2 $table->any([SQL_STATEMENT], [EXECUTE_VARS]);

It is a general method.

The part written '-db-' of [SQL_STATEMENT] is replaced with the table name.

  $table->any("SELECT * FROM -db- WHERE a = ?", ...);
  
  'SELECT * FROM table_name WHERE a = ?';

=head2 $table->delete([WHERE], [EXECUTE_VARS]);

The specified record is deleted.

=head2 $table->clear([BOOLEAN]);

All the records are deleted.
[WHERE] must be sure to be in $table->delete and there not be here needing though it
 is necessary. 

If one is not given for safety, it doesn't operate.

=head1 SEE ALSO

L<Egg::Plugin::DBI::Accessors>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

