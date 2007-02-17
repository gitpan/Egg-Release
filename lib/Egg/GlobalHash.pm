package Egg::GlobalHash;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: GlobalHash.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use Egg::Exception;

our $VERSION= '0.01';

sub TIEHASH {
	my($class, $hash)= @_;
	bless $hash, $class;
}
sub FETCH {
	$_[0]->{$_[1]} || undef;
}
sub STORE {
	my $self= shift;
	my $key = &__check_global_key_format(shift) || return(undef);
	$self->{$key} and Egg::Error->throw('A specified key already exists.');
	return(undef) unless defined($_[0]);
	$self->{$key}= $_[0];
}
sub DELETE {
	Egg::Error->throw('Delete is improper.');
}
sub CLEAR {
	Egg::Error->throw('Clear is improper.');
}
sub EXISTS {
	exists($_[0]->{$_[1]});
}
sub FIRSTKEY {
	my $reset= keys %{$_[0]};
	each %{$_[0]};
}
sub NEXTKEY {
	each %{$_[0]};
}
sub flags {
	[ grep /^[a-z0-9_]+$/, keys %{$_[0]} ];
}
sub globals {
	[ grep /^[A-Z0-9_]+$/, keys %{$_[0]} ];
}
sub flag_set {
	my $self= shift;
	my $key = shift || return(undef);
	return(undef) unless defined($_[0]);
	ref($_[0]) and Egg::Error->throw('Reference is not good.');
	$self->{lc($key)}= $_[0] ? 1: 0;
}
sub global_overwrite {
	my $self= shift;
	my $key = &__check_global_key_format(shift) || return(undef);
	return(undef) unless defined($_[0]);
	$self->{$key}= $_[0];
}
sub __check_global_key_format {
	my $key= shift || return 0;
	$key!~/^[A-Z_][A-Z0-9_]+$/
	  and Egg::Error->throw('The key name is a breach of rules.');
	return $key;
}

1;

__END__

=head1 NAME

Egg::GlobalHash - A constant rule is given to a global HASH for Egg.

=head1 SYNOPSIS

  my %global;
  tie %global, 'Egg::GlobalHash', (
    key1 => 'hooo',
    key2 => 'booo',
    ...
    );
  
  $global{'abc123'}= 'hoge';  # The error happens. 
  
  $global{'ABC123'}= 'hoge';  # It succeeds. 
  
  $global{'ABC123'}= 'bomb';  # It makes an error because it has defined it.
  
  $global{'123ABC'}= 'hiii';  # The head makes an error and the figure makes an error.
  
  tied($global)->global_overwrite( ABC123=> 'hoge' );
  # It is allowed that it does in this manner.
  
  tied($global)->global_overwrite( abc123=> 'hoge' );
  # This makes an error. The key is an always capital letter. 
  
  tied($global)->flag_set( abc123=> 'hoge' );
  # It enters if it is this call. However, it is 0 or 1 to enter.
  
  print $global{abc123};  => 1
  
  for (@{tied(%global)->flags}) { print "[$_]" }   => [abc123]
  
  for (@{tied(%global)->globals}) { print "[$_]" } => [ABC123]

=head1 DESCRIPTION

An unpleasant thing happens when a global variable is readily put in and out.
It is a module to restrict it.

However, it is possible to put it in and out from the second key quite freely 
because it is not severe.

  $global{ABC123}{abc123}= 'OK';
  $global{ABC123}{abc123}= 'OVERWRIE';

=head1 METHODS

=head2 flags

The list only of the data of the key to the small letter is returned by the 
ARRAY reference.

=head2 globals

The list only of the data of the key to the capital letter is returned by the 
ARRAY reference.

=head2 flag_set

Only the value of the small letter key is put. The superscription is allowed.
However, the reference is not put, and the value becomes 0 or 1, too.

=head2 global_overwrite

Only the value of the capital letter key is put. The superscription is allowed.
The value is freely put by an arbitrary type. 

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
