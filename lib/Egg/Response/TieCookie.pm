package Egg::Response::TieCookie;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: TieCookie.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
our $VERSION= '0.04';

sub TIEHASH {
	my($class, $e)= @_;
	bless {
	  cookies=> {},
	  secure => $e->request->secure,
	  default=> ($e->config->{cookie_default} || {}),
	  }, $class;
}
sub FETCH {
	$_[0]->{cookies}{$_[1]} || undef;
}
sub STORE {
	my $self= shift;
	my $key = shift || return 0;
	my $hash= $_[0] ? (ref($_[0]) eq 'HASH' ? $_[0]: { value=> $_[0] })
	                : { value => 0 };

	exists($hash->{value}) or die q{ I want cookie 'value'. };
	$hash->{name} ||= $key;

	$hash->{$_} ||= $self->{default}{$_} || undef
	  for qw/ domain expires path /;

	$hash->{secure}= $self->{default}{secure} || $self->{secure}
	  unless defined($hash->{secure});

	$self->{cookies}{$key}= $hash;
	return $hash;
}
sub DELETE {
	my($self, $key)= @_;
	delete($self->{cookies}{$key});
}
sub CLEAR {
	my($self)= @_;
	%{$self->{cookies}}= ();
}
sub EXISTS {
	my($self, $key)= @_;
	exists($self->{cookies}{$key});
}
sub FIRSTKEY {
	my($self)= @_;
	my $reset= keys %{$self->{cookies}};
	each %{$self->{cookies}};
}
sub NEXTKEY {
	each %{$_[0]->{cookies}};
}

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

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
