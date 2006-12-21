package Egg::Response::TieCookie;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: TieCookie.pm 65 2006-12-19 18:38:00Z lushe $
#
use strict;
use warnings;
our $VERSION= '0.01';

sub TIEHASH {
	my($class, $encode_func)= @_;
	my %cookie;
	bless { cookie=> \%cookie, encode=> $encode_func }, shift;
}
sub FETCH {
	$_[0]->{cookie}{$_[1]} || undef;
}
sub STORE {
	my($self, $key, $hash)= @_;
	if (ref($hash) eq 'HASH') {
		my %store= %$hash;
		$store{__encode} = $self->{encode};
		$store{name} ||= $key;
		$self->{cookie}{$key}=
		  Egg::Response::TieCookie::Params->new(\%store);
		return $self->{cookie}{$key};
	} else {
		delete($self->{cookie}{$key}) if $self->{cookie}{$key};
		return (undef);
	}
}
sub DELETE {
	my($self, $key)= @_;
	delete($self->{cookie}{$key});
}
sub CLEAR {
	my($self)= @_;
	%{$self->{cookie}}= ();
}
sub EXISTS {
	my($self, $key)= @_;
	exists($self->{cookie}{$key});
}
sub FIRSTKEY {
	my($self)= @_;
	my $reset= keys %{$self->{cookie}};
	each %{$self->{cookie}};
}
sub NEXTKEY {
	each %{$_[0]->{cookie}};
}

package Egg::Response::TieCookie::Params;
use strict;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors( qw/name expires domain path secure/ );

sub new {
	my($class, $hash)= @_;
	bless $hash, $class;
}
sub value {
	my($self)= @_;
	$self->{__encode}->(\$self->{value});
}
sub plain_value { $_[0]->{value} }

1;

__END__


=head1 NAME

Egg::Response::TieCookie - This is an inventory location of set response cookie.

=head1 SYNOPSIS

 my %cookie
 tie %cookie, 'Egg::Response::TieCookie';
 ...
 ...
 untie %cookie;

=head1 DESCRIPTION

The value is maintained with Egg::Response::TieCookie::Params of the HASH 
reference. 

The HASH reference returns by $->response->cookies->{[KEY_NAME]}.

The reference to the value is $->response->cookies->{[KEY_NAME]}->value.

It is not possible to set it excluding the HASH reference.

=head1 SEE ALSO

L<Egg::Release>, L<Egg::Response>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
