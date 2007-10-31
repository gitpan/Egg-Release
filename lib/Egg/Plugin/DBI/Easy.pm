package Egg::Plugin::DBI::Easy;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Easy.pm 200 2007-10-31 04:30:14Z lushe $
#
use strict;
use warnings;
use Time::Piece::MySQL;

our $VERSION = '2.08';

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

* Complex SQL cannot be treated. Please examine the introduction of
  L<Egg::Model::DBIC > wanting the easy treatment of complex SQL.

=head1 CONFIGURATION

It setup it with 'plugin_dbi_easy'.

=head2 table_alias = [HASH_REF]

Alias for the table object is setup.

  table_alias => {
    any_name=> 'real_table_name',
    },
  
  # It comes to be able to operate 'real_table_name' table by $e->db->any_name.

=cut

sub _setup {
	my($e)= @_;
	my $conf= $e->config->{plugin_dbi_easy} ||= {};
	   $conf->{table_alias} ||= {};
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

=head2 dbh

When the DBI::Transaction plug-in is not loaded, the dbh method can be used.

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
	$e->debug_out("# + dbh_hashref: $sql");
	my %bind;
	my $sth= $e->dbh->prepare($sql);
	@$args ? $sth->execute(@$args): $sth->execute;
	$sth->bind_columns(\(@bind{map{$_}@{$sth->{NAME_lc}}}));
	$sth->fetch; $sth->finish;
	$bind{$key} ? \%bind: 0;
}

=head2 jdb ([dbname], [primary key])

=cut
sub jdb {
	Egg::Plugin::DBI::Easy::joindb->new(@_);
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
	$e->debug_out("# + dbh_arrayref: $sql");
	my(@array, %bind);
	my $sth= $e->dbh->prepare($sql);
	@$args ? $sth->execute(@$args): $sth->execute;
	$sth->bind_columns(\(@bind{map{$_}@{$sth->{NAME_lc}}}));
	while ($sth->fetch) { $code->(\@array, %bind) }
	$sth->finish;
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
	$e->debug_out("# + dbh_scalarref: $sql");
	my $result;
	my $sth= $e->dbh->prepare($sql);
	@$args ? $sth->execute(@$args): $sth->execute;
	$sth->bind_columns(\$result);
	$sth->fetch; $sth->finish;
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
	if (my $alias= $e->config->{plugin_dbi_easy}{table_alias}{$dbname}) {
		$dbname= $alias;
	}
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

=head2 insert ( [DATA_HASH] || [PKEY_ARRAY], [DATA_HASH])

The data record is added.

  $e->db->myapp_table->insert(
    user_name => 'hoge',
    email_addr=> 'hoge@domain',
    age       => 20,
    );

When an unpalatable column exists, it is specified for PKEY_ARRAY that it is 
included in the INSERT sentence as the column of the serial form is included
in DATA_HASH by a double ARRAY reference.

  $e->db->myapp_table->insert( [['id']], {
    id        => 1, 
    user_name => 'hoge',
    email_addr=> 'hoge@domain',
    });
  
  # When this form is used, DATA_HASH is a thing passed without fail
  # by the HASH reference.

* The IGNOR_COLUMN specification by the second argument was abolished.

=cut
sub insert {
	my $db   = shift;
	my $args = Egg::Plugin::DBI::Easy::args->new(@_);
	my $items= $args->insert_items;
	my $sql= qq{INSERT INTO $db->{dbname}}
	       . qq{ (}. join(', ', keys %$items). q{) VALUES}
	       . qq{ (}. join(', ', map{"?"}keys %$items). q{)};
	$db->{e}->debug_out("# + dbh_insert : $sql");
	$db->{e}->dbh->do($sql, undef, (values %$items));
}

=head2 update ( [WHERE_COLUMNS], [DATA_HASH] )

The data record is updated.

WHERE_COLUMN is good at the thing specified by the ARRAY reference in
the column name to retrieve data.

Moreover, it develops with following WHERE_COLUMN and the WHERE phrase
is generated.

=over 4

=item * When you give one column by a usual variable.

  $e->db->my_table->update('id', { id=> 1, myname=> 'hoge' });

  WHERE key_name = ?

* This is the same as giving usual HASH to DATA_HASH.

  $e->db->my_table->update( id=> 1, myname=> 'hoge' );

=item * When you delimit all columns with 'and'.

  $e->db->my_table->update(
    [qw/ myname age sex /],
    { myname=> 'hoge', age=> 20, sex=> 'man', email=> 'myname@email' }
    );

  WHERE myname = ? and age = ? and sex and ?

=item * When you want to specify inequitable value, like, and '>', etc.

  $e->db->my_table->update(
    [qw/ myname age:>= sex:like /],
    { myname=> 'hoge', age=> 18, sex=> '%man%', email=> 'myname@email' }
    );

  WHERE myname = ? and age != ? and sex like ?

=item * When you want to place 'or' etc.

  $e->db->my_table->update(
    ['myname', { or => 'age:>=' }, 'sex'],
    { myname=> 'hoge', age=> 20, sex=> 'man', email=> 'myname@email' }
    );

  WHERE myname = ? or age >= ? and sex = ?

=back

* Only the above-mentioned WHERE phrase is generable.

* The column given to WHERE_COLUMN is not reflected in the SET phrase.

The addition and subtraction of a numeric column is set in the value of DATA_HASH
by the SCALAR reference.

  # One value of 'age' is added.
  $e->db->myapp_table->update('id', { id => 1, age=> \'1' });

or

  # One value of 'age' is subtracted.
  $e->db->myapp_table->update('id', { id => 1, age=> \'-1' });

=cut
sub update {
	my $db   = shift;
	my $args = Egg::Plugin::DBI::Easy::args->new(@_);
	my $items= $args->update_items;
	my $sql  = qq{UPDATE $db->{dbname} SET }
	         . join(', ', keys %$items). qq{ WHERE $args->{where}};
	$db->{e}->debug_out("# + dbh_update : $sql");
	$db->{e}->dbh->do($sql, undef,
	   (values %$items), (values %{$args->{unique}}) );
}

=head2 update_insert ( [WHERE_COLUMNS], [DATA_HASH] )

Update and insert are distributed by the existence of the data of WHERE_COLUMNS.

The way to pass WHERE_COLUMNS is similar to update.

  $e->db->my_table->update_insert(
    [qw/ id user_name /],
    { id=> 1, user_name=> 'hoge', email=> 'hoge@domain' },
    );

It is specified that it is included in the VALUES phrase if insert is 
done by using a double ARRAY reference when there is an unpalatable column.

  $e->db->my_table->update_insert(
    [[qw/ id /], qw/ user_name /]
    { id=> 1, user_name=> 'hoge', email=> 'hoge@domain' },
    );

=cut
sub update_insert {
	my $db= shift;
	my $args= Egg::Plugin::DBI::Easy::args->new(@_);
	my $result;
	if ($result= $db->update($args) and $result > 0) {
		return $result;
	} else {
		return $db->insert($args);
	}
}

=head2 noentry_insert ( [WHERE_COLUMNS], [DATA_HASH] )

If the data of WHERE_COLUMNS doesn't exist, insert is done.

Update_insert of the method of specifying the argument is similar.

  $e->db->my_table->noentry_insert(
    user_name => 'hoge',
    email     => 'hoge@domain',
    );

* When data already exists and insert is not done, false is restored.

=cut
sub noentry_insert {
	my $db= shift;
	my $args= Egg::Plugin::DBI::Easy::args->new(@_);
	@{$args->{ukey}} || croak q{ I want  };
	my $pkey= $args->{primary}
	        ? $args->{primary}[0]: (keys %{$args->{unique}})[0];
	$db->{e}->dbh_scalarref(
	  qq{SELECT $pkey FROM $db->{dbname} WHERE $args->{where} },
	  values %{$args->{unique}}
	  ) ? 0: $db->insert($args);
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
	my $in= $_[0] ? ($_[1] ? {@_}: $_[0]): croak q{ I want upgrade data. };
	my $items= Egg::Plugin::DBI::Easy::args->update_items($in);
	my $sql= qq{UPDATE $db->{dbname} SET }. join(', ', keys %$items);
	$db->{e}->debug_out("# + dbh_upgrade : $sql");
	$db->{e}->dbh->do($sql, undef, (values %$items));
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

package Egg::Plugin::DBI::Easy::args;
use strict;

sub new {
	my $class= shift;
	my $ukey = shift || [];
	return $ukey if ref($ukey) eq __PACKAGE__;
	my $data;
	if (ref($ukey) eq 'HASH') { $data= $ukey; $ukey= [] }
	elsif (ref($ukey) ne 'ARRAY') { $ukey= [$ukey] }
	my $primary= ($ukey->[0] and ref($ukey->[0]) eq 'ARRAY')
	   ? do { my $tmp= $ukey->[0]; $ukey->[0]= $ukey->[0][0]; $tmp }: undef;
	my $where= "";
	tie my %unique, 'Tie::Hash::Indexed';
	if (my $key= $ukey->[0]) {
		$where= $key=~m{^([^\:]+\:(.+))}
		      ? do { $ukey->[0]= $primary->[0]= $2; "$2 $1 ?" }: "$key = ?";
	}
	$data ||= $_[0]
	  ? (ref($_[0]) eq 'HASH' ? $_[0]: ($ukey->[0] ? {$ukey->[0], @_}: {@_}))
	  : die q{ I want insert or update data value. };
	if (my $key= $ukey->[0]) {
		$unique{$key}= exists($data->{$key}) ? $data->{$key}: undef;
	}
	for my $key (@{$ukey}[1..$#{$ukey}]) {
		if (ref($key) eq 'HASH') {
			my $tmp;
			while (my($cond, $kname)= each %$key) {
				__ukey_line($cond, \$kname, \$where);
				$tmp= $kname;
				last;
			}
			$key= $tmp;
		} else {
			__ukey_line('and', \$key, \$where);
		}
		$unique{$key}= exists($data->{$key})
		    ? $data->{$key} : die qq{ I want '$key' data. };
	}
	bless {
	  primary=> $primary,
	  ukey   => $ukey,
	  unique => \%unique,
	  data   => $data,
	  where  => $where,
	  }, $class;
}
sub insert_items {
	my($self)= @_;
	if (my $pkey= $self->{primary}) {
		delete($self->{data}{$pkey}) for @$pkey;
	}
	tie my %items, 'Tie::Hash::Indexed';
	while (my($item, $value)= each %{$self->{data}}) {
		$items{$item}= defined($value)
		  ? (ref($value) eq 'SCALAR' ? $$value: $value): undef;
	}
	\%items;
}
sub update_items {
	my $self= shift;
	my $data= shift || $self->{data};
	my $ukey= shift || (ref($self) ? $self->{unique}: {});
	tie my %items, 'Tie::Hash::Indexed';
	while (my($item, $value)= each %$data) {
		next if exists($ukey->{$item});
		if (defined($value)) {
			if (ref($value) eq 'SCALAR') {
				$items{"$item = $item + ?"}= $$value;
			} else {
				$items{"$item = ?"}= $value;
			}
		} else {
			$items{"$item = ?"}= undef;
		}
	}
	\%items;
}
sub __ukey_line {
	my($cond, $kname, $where, $key)= @_;
	$$where.= $$kname=~m{^([^\:]+\:(.+))}
	  ? do { $$kname= $2; " $cond $2 $1 ?" }
	  : " $cond $$kname = ?";
}

package Egg::Plugin::DBI::Easy::joindb;
use strict;
use Tie::Hash::Indexed;

my %ixnames;
{
	my @ixnames= ('a'..'z');
	tie %ixnames, 'Tie::Hash::Indexed';
	%ixnames= map{ $_=> $ixnames[$_] }(0..$#ixnames);
  };

sub new {
	my($class, $e)= splice @_, 0, 2;
	my $dbname= __table_alias($e, shift);
	my $pkey= shift || die q{ I want primary key. };
	my $ix= $ixnames{0};
	bless { e=> $e, dbnames=> [["$dbname $ix","$ix.$pkey"]] }, $class;
}
sub join {
	my($self, $dbname, $pkey, $ix)= __arg(@_);
	push @{$self->{dbnames}},
	["join $dbname $ix", (ref($pkey) eq 'SCALAR' ? $pkey: "$ix.$pkey")];
	$self;
}
sub left {
	my($self, $dbname, $pkey, $ix)= __arg(@_);
	push @{$self->{dbnames}},
	["left join $dbname $ix", (ref($pkey) eq 'SCALAR' ? $pkey: "$ix.$pkey")];
	$self;
}
sub right {
	my($self, $dbname, $pkey, $ix)= __arg(@_);
	push @{$self->{dbnames}},
	["right join $dbname $ix", (ref($pkey) eq 'SCALAR' ? $pkey: "$ix.$pkey")];
	$self;
}
sub hashref {
	my($self, $pkey, $sql)= shift->__fetch(shift);
	$self->{e}->dbh_hashref($pkey, $sql, @_);
}
sub arrayref {
	my($self, $pkey, $sql)= shift->__fetch(shift);
	$self->{e}->dbh_arrayref($sql, @_);
}
sub __fetch {
	my $self= shift;
	my $more= shift || "";
	my $base= shift(@{$self->{dbnames}});
	my $pkey= $base->[1];
	my $key = $pkey; $key=~s{^[^\.]+\.} [];
	my $part= $base->[0];
	for my $q (@{$self->{dbnames}}) {
		$part.= " $q->[0] on "
		. (ref($pkey) eq 'SCALAR' ? ${$q->[1]}: "$pkey = $q->[1]");
	}
	$more= ref($more) eq 'ARRAY'
	       ? (CORE::join(' ', @$more) || ""): qq{where $more};
	($self, $key, qq{select * from $part $more});
}
sub __table_alias {
	my $e= shift;
	my $dbname= shift || die q{ I want dbname. };
	$e->config->{plugin_dbi_easy}{table_alias}{$dbname} || $dbname;
}
sub __arg {
	my $self= shift;
	my $dbname= __table_alias($self->{e}, shift);
	my $pkey  = shift || die q{ I want primary key. };
	my $ix= $ixnames{scalar(@{$self->{dbnames}})};
	($self, $dbname, $pkey, $ix);
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
