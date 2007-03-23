package Egg::Plugin::Charset;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Charset.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.01';

sub output_content {
	my($e)= @_;
	return $e->next::method unless $e->_charset_convert_type;
	my $body= $e->response->body || return $e->next::method;
	$e->response->body( $e->_output_convert_charset($body) );
	$e->next::method;
}
sub _charset_convert_type {
	Egg::Error->throw
	  (q{ Method of '_charset_convert_type' is not prepared. });
}
sub _charset_convert_type {
	Egg::Error->throw
	  (q{ Method of '_charset_convert_type' is not prepared. });
}

1;

__END__

=head1 NAME

Egg::Plugin::Charset - Base class for module related to Charset for Egg.

=head1 SYNOPSIS

  package MYPROJECT;
  use strict;
  use Egg qw/Charset::UTF8/;

my $config= __PACKAGE__->load('/path/to/config.yaml');

=head1 DESCRIPTION

This module is a base class for Egg::Plugin::Charset::*.

Please use it by way of the subclass. Anything cannot be done in the unit.

'Content-Type' and 'Content-Language' are setup when outputting it, and the
character-code of contents is adjusted.

An original subclass can be made by handling the helper.

* Please see L<Egg::Helper::P::Charset> in detail.

=head1 SEE ALSO

L<Egg::Helper::P:Charset>,
L<Egg::Plugin::Charset::EUT8>,
L<Egg::Plugin::Charset::EUC_JP>,
L<Egg::Plugin::Charset::Shift_JIS>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. <L<http://egg.bomcity.com/>>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
