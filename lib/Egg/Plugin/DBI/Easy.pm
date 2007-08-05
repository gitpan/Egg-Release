package Egg::Plugin::DBI::Easy;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Easy.pm 182 2007-08-05 17:25:44Z lushe $
#
use strict;
use warnings;
use Time::Piece::MySQL;

our $VERSION = '2.03';

=head1 NAME

Egg::Plugin::DBI::Easy - Plugin of an easy doing as for treatment of DBI.

=head1 SYNOPSIS

  use Egg qw/ DBI::Easy /;

  # The result of SELECT is received with HASH.
  my $hash= $e->dbh_hashref( 'id',
     q{ SLECT id, name, email FROM myapp_table WHERE id = ? }, $id)
     || return 0;
  
  # The data table object is used.
  my $hash= $e->db->myapp_table->hashref
     ([qw/ id name email /], ' id = ? ', $id) || return 0;
  
  # Data is added.
  $e->db->myapp_table->insert
     ({ id => $id, name => 'myname', emai => 'myname@domain.name' });
  
  # Specified data is deleted.
  $e->db->myapp_table->delete(' id = ? ', $id);
  
  # All data is deleted.
  $e->db->myapp_table->clear(1);

=head1 DESCRIPTION

It is a plug-in to be able to write the description of the DBI processing
that tends to become tedious easily.

* However, complex SQL cannot be treated.

=cut

sub _setup {
	my($e)= @_;
	return $e->next::method if $e->isa('Egg::Plugin::DBI::Transaction');
	$e->mk_accessors('dbh');
	$e->next::method;
}
sub _prepare {
	my($e)= @_;
	$e->dbh( $e->model('DBI')->dbh ) unless $e->dbh;
	$e->next::method;
}

=head1 METHODS

=head2 sql_datetime ( [TIME] )

L<Time::Piece::MySQL>-E<gt>mysql_datetime is returned.

An arbitrary date can be acquired by passing TIME the value of time.

  # Time of the day before of the seventh is acquired.
  $e->sql_datetime( time- (7* 24* 60* 60) );

* Please look at the document of L<Time::Piece::MySQL>.

=cut
sub sql_datetime {
	my $e   = shift;
	my $time= localtime (shift || time);
	$time->mysql_datetime;
}

=head2 dbh_hashref ( [TRUE_CHECK_COLUMN], [SQL], [EXECUTE_ARGS] )

It is dbh-E<gt>prepare( [SQL] ), and sth->execute( [EXECUTE_ARGS] ).

If the result is preserved in HASH and the value of TRUE_CHECK_COLUMN is 
effective, the HASH reference is returned.

 * The result returns only one record.
 * When two or more records become a hit, the first data is returned.

  my $hash= $e->dbh_hashref
            ('id', 'SELECT * FROM myapp_table WHERE id = ?', $id)
            || return 0;
  
  print $hash->{id};

=cut
sub dbh_hashref {
	my $e   = shift;
	my $key = shift || return 0;
	my $sql = shift || return 0;
	my($args)= &__args(@_);
	my %bind;
	my $sth= $e->dbh->prepare($sql);
	@$args ? $sth->execute(@$args): $sth->execute;
	$sth->bind_columns(\(@bind{map{$_}@{$sth->{NAME_lc}}}));
	$sth->fetch; $sth->finish;
	$e->debug_out("# + dbh_hashref: $sql");
	$bind{$key} ? \%bind: 0;
}

=head2 dbh_arrayref ( [SQL], [EXECUTE_ARGS], [CODE_REF] )

The result is returned by the ARRAY reference.

* Each data of the ARRAY inside becomes HASH.

  my $array= $e->dbh_arrayref
           ('SELECT * FROM myapp_table WHERE email like ?', '%name%')
           || return 0;
  
  for my $db (@$array) {
    print "$db->{id} = $db->{name} : $db->{email} \n";
  }

If EXECUTE_ARGS is ARRAY reference, CODE_REF can be passed.

  my $code= sub {
  	my($array, %hash)= @_;
  	return 0 unless ($hash{name} and $hash{email});
  	push @$array, "$hash{id} = $hash{name}:$hash{email}\n";
    };
  my $array= $e->dbh_arrayref
      ('SELECT * FROM myapp_table WHERE email like ?', ['%name%'], $code)
      || return 0;
  print join('', @$array);

Or

  my $output;
  my $code= sub {
  	my($array, %hash)= @_;
  	return 0 unless ($hash{name} and $hash{email});
  	$output.= "$hash{id} = $hash{name}:$hash{email} \n";
    };
  $e->dbh_arrayref
     ('SELECT * FROM myapp_table WHERE email like ?', ['%name%'], $code);
  $output || return 0;
  print $output;

=cut
sub dbh_arrayref {
	my $e   = shift;
	my $sql = shift || return 0;
	my($args, $code)= &__args(@_);
	$code ||= sub {
		my($array, %hash)= @_;
		push @$array, \%hash
	  };
	my(@array, %bind);
	my $sth= $e->dbh->prepare($sql);
	@$args ? $sth->execute(@$args): $sth->execute;
	$sth->bind_columns(\(@bind{map{$_}@{$sth->{NAME_lc}}}));
	while ($sth->fetch) { $code->(\@array, %bind) }
	$sth->finish;
	$e->debug_out("# + dbh_arrayref: $sql");
	scalar(@array) ? \@array: 0;
}

=head2 dbh_scalarref ( [SQL], [EXECUTE_ARGS] )

The result is returned by the SCALAR reference.

* When two or more records become a hit, the first data is returned.

  my $scalar= $e->dbh_scalarref
            ('SELECT email FROM myapp_table WHERE id = ?', $id)
            || return 0;
  
  print $$scalar;

=cut
sub dbh_scalarref {
	my $e   = shift;
	my $sql = shift || return 0;
	my($args)= &__args(@_);
	my $result;
	my $sth= $e->dbh->prepare($sql);
	@$args ? $sth->execute(@$args): $sth->execute;
	$sth->bind_columns(\$result);
	$sth->fetch; $sth->finish;
	$e->debug_out("# + dbh_scalarref: $sql");
	$result ? \$result: 0;
}

=head2 db

The object that generates the data table object is returned.

  $e->db->table_name->...

 * The table name is used and the comeback call is used for the method
   putting it.
 * When the table name is improper as the method name of Perl, it is not
   possible to use it.

=cut
sub db {
	$_[0]->{plugin_dbi_easy} ||= Egg::Plugin::DBI::Easy::handler->new(@_);
}

sub __args {
	return [] unless @_;
	ref($_[0]) eq 'ARRAY' ? @_: [@_];
}

package Egg::Plugin::DBI::Easy::handler;
use strict;

our $AUTOLOAD;

=head1 DB METHODS

=head2 new

Constructor who returns DB object.

=cut
sub new { bless { e=> $_[1] }, $_[0] }

=head2 AUTOLOAD

The method of returning the handler object recognizing the table name the 
method of no existence is dynamically generated.

=cut
sub AUTOLOAD {
	my($self)= @_;
	my($dbname)= $AUTOLOAD=~/([^\:]+)$/;
	my $class= __PACKAGE__."::$dbname";
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	@{"${class}::ISA"}= 'Egg::Plugin::DBI::Easy::accessors';
	*{__PACKAGE__."::$dbname"}= sub {
		my($proto)= @_;
		$proto->{$dbname} ||= $class->new($proto->{e}, $dbname);
	  };
	$self->$dbname;
}

=head2 DESTROY

It doesn't do at all.

=cut
sub DESTROY {}


package Egg::Plugin::DBI::Easy::accessors;
use strict;
use Carp qw/croak/;
use Tie::Hash::Indexed;

=head1 HANDLER METHODS

=head2 new

Constructor who returns handler object. 

=cut
sub new {
	my($class, $e, $dbname)= @_;
	bless { e=> $e, dbname=> $dbname }, $class;
}

=head2 hashref ( [GET_COLUMN], [WHERE_SQL], [EXECUTE_ARGS] )

The result of dbh_hashref is returned. 

If GET_COLUMN is ARRAY, the first column is treated most as TRUE_CHECK_COLUMN.

If GET_COLUMN is usual SCALAR, it is treated as TRUE_CHECK_COLUMN, and '*' is
continued to SELECT.

* Please write ORDER BY etc. following WHERE in WHERE_SQL.

  my $hash= $e->db->myapp_table->hashref('id', 'id = ?', $id)
         || return 0;
  
  print $hash->{id};

=cut
sub hashref {
	my $db= shift;
	my $items= shift;
	my $where= _get_sql(shift);
	my($pkey, %bind);
	if (ref($items) eq 'ARRAY') {
		$pkey= $items->[0];
		$items= join ', ', @$items;
	} else {
		($pkey, $items)= ($items, '*');
	}
	$db->{e}->dbh_hashref
	  ($pkey, qq{SELECT $items FROM $db->{dbname}$where }, @_);
}

=head2 arrayref ( [GET_COLUMN], [WHERE_SQL], [EXECUTE_ARGS], [CODE_REF] )

The result of dbh_arrayref is returned.

GET_COLUMN accepts the ARRAY reference.

When GET_COLUMN is omitted, '*' is used.

  my $array= $e->db->myapp_table->arrayref(0, 'email like ?', '%name%')
          || return 0;
  
  for my $db (@$array) {
    print "$db->{id} = $db->{name} : $db->{email} \n";
  }

If EXECUTE_ARGS is ARRAY reference, CODE_REF can be passed.
* Please refer to 'dbh_array_ref' for the example of the code.

=cut
sub arrayref {
	my $db   = shift;
	my $items= shift || '*';
	my $where= _get_sql(shift);
	$items= join ', ', @$items if ref($items) eq 'ARRAY';
	$db->{e}->dbh_arrayref
	  (qq{SELECT $items FROM $db->{dbname}$where }, @_);
}

=head2 scalarref ( [GET_COLUMN], [WHERE_SQL], [EXECUTE_ARGS] )

The result of dbh_scalarref is returned.

  my $scalar= $e->db->myapp_table->scalarref('email', 'id = ?', $id)
           || return 0;
  
  print $$scalar;

=cut
sub scalarref {
	my $db= shift;
	my $item = shift || croak q{ I want filed name. };
	my $where= _get_sql(shift);
	$db->{e}->dbh_scalarref
	  (qq{SELECT $item FROM $db->{dbname}$where}, @_);
}

=head2 scalar ( [GET_COLUMN], [WHERE_SQL], [EXECUTE_ARGS] )

  print $e->db->myapp_table->scalar('email', 'id = ?', $id);

=cut
sub scalar {
	my $result= shift->scalarref(@_) || return 0;
	$$result;
}

=head2 insert ( [DATA_HASH], [IGNOR_COLUMN] )

The data record is added.

IGNOR_COLUMN is included in DATA_HASH, and it specifies it when there is
column that wanting the inclusion is not in SQL.
* Being able to specify is 1 It is only column.

  # Do not include the data type of id in DATA_HASH for Serial etc.
  $e->db->myapp_table->insert({ name => 'myname', email => 'email@addr' });

=cut
sub insert {
	my $db  = shift;
	my $in  = shift || croak q{ I want insert fields. };
	my $pkey= shift || 0;
	tie my %items, 'Tie::Hash::Indexed';
	while (my($item, $value)= each %$in) {
		next if $item eq $pkey;
		$items{$item}= defined($value) ? $value: undef;
	}
	my $sql= qq{INSERT INTO $db->{dbname}}
	       . qq{ (}. join(', ', keys %items). q{) VALUES}
	       . qq{ (}. join(', ', map{"?"}keys %items). q{)};
	$db->{e}->debug_out("# + dbh_insert : $sql");
	$db->{e}->dbh->do($sql, undef, (values %items));
}

=head2 update ( [PRIMARY_COLUMN], [DATA_HASH] )

The data record is updated.

* The value of PRIMARY_COLUMN is excluded from the set sentence.

  $e->db->myapp_table->update('id', { id => 1, name=> 'yurname' });

* Addition and subtraction of numeric column.

  $e->db->myapp_table->update('id', { id => 1, name=> 'yurname', age=> \"1" });

=cut
sub update {
	my $db  = shift;
	my $pkey= shift || croak q{ I want primary_key };
	my $in  = shift || croak q{ I want update data };
	$in->{$pkey}
	  || croak qq{ Value of '$pkey' is not found from update data. };
	tie my %items, 'Tie::Hash::Indexed';
	while (my($item, $value)= each %$in) {
		next if $item eq $pkey;
		if (defined($value)) {
			ref($value) eq 'SCALAR'
			  ? $items{"$item = $item + ?"}= $$value
			  : $items{"$item = ?"}= $value;
		} else {
			$items{"$item = ?"}= undef;
		}
	}
	my $sql= qq{UPDATE $db->{dbname} SET }
	       . join(', ', keys %items). qq{ WHERE $pkey = ? };
	$sql.= " ". (shift || "");
	$db->{e}->debug_out("# + dbh_update : $sql");
	$db->{e}->dbh->do($sql, undef, (values %items), $in->{$pkey});
}

=head2 upgrade ( [DATA_HASH] )

Update that doesn't need WHERE is done. For two or more data update in a word.

  $e->db->myapp_table->upgrade({ age => 18 });

* Addition and subtraction of numeric column.

  my $num= -1;
  $e->db->myapp_table->update({ age => \$num });

=cut
sub upgrade {
	my $db= shift;
	my $in= shift || croak q{ I want update data };
	tie my %items, 'Tie::Hash::Indexed';
	while (my($item, $value)= each %$in) {
		if (defined($value)) {
			ref($value) eq 'SCALAR'
			  ? $items{"$item = $item + ?"}= $$value
			  : $items{"$item = ?"}= $value;
		} else {
			$items{"$item = ?"}= undef;
		}
	}
	my $sql= qq{UPDATE $db->{dbname} SET }. join(', ', keys %items);
	$db->{e}->debug_out("# + dbh_upgrade : $sql");
	$db->{e}->dbh->do($sql, undef, (values %items));
}

=head2 update_insert ( [PRIMARY_COLUMN], [DATA_HASH] )

If the data of PRIMARY_COLUMN exists, update is done and insert is done if
not existing.

  $e->db->myapp_table->update_insert('id', { id => 1, name=> 'yurname' });

=cut
sub update_insert {
	my $db  = shift;
	my $pkey= shift || croak q{ I want primary_key };
	my $in  = shift || croak q{ I want update data };
	$in->{$pkey} || croak qq{ Value of '$pkey' is not found from update data. };
	my $true;
	my $sth= $db->{e}->dbh->prepare
	   (qq{SELECT $pkey FROM $db->{dbname} WHERE $pkey = ? });
	$sth->execute($in->{$pkey});
	$sth->bind_columns(\$true);
	$sth->fetch; $sth->finish;
	$true ? $db->update($pkey, $in): $db->insert($in, $pkey);
}

=head2 delete ( [WHERE_SQL] )

The data deletion with the condition is done.

  $e->db->myapp_table->delete('age < ?', 18);

=cut
sub delete {
	my $db   = shift;
	my $where= _get_sql(shift) || croak q{ I want SQL statement parts. };
	my $sql  = qq{DELETE FROM $db->{dbname}$where};
	$db->{e}->debug_out("# + dbh_delete : $sql");
	$db->{e}->dbh->do($sql, undef, @_);
}

=head2 clear ( [TRUE] )

All the data of the table inside is deleted.

* If TRUE is not given, the exception is generated.

  $e->db->myapp_table->clear(1);

=cut
sub clear {
	my $db= shift;
	my $flag= shift || croak q{ I want exec flag. };
	$db->{e}->debug_out("# + dbh_delete : DELETE FROM $db->{dbname}");
	$db->{e}->dbh->do(qq{DELETE FROM $db->{dbname}});
}

sub _get_sql {
	my $sql= shift || return "";
	ref($sql) eq 'ARRAY' ? ' '. join(' ', @$sql): " WHERE $sql";
}

=head1 SEE ALSO

L<Egg::Model::DBI>,
L<Egg::Plugin::DBI::Transaction>,
L<Egg::Release>,
L<Tie::Hash::Indexed>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
