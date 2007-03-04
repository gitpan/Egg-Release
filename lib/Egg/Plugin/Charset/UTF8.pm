package Egg::Plugin::Charset::UTF8;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: UTF8.pm 278 2007-03-04 00:54:42Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Plugin::Charset/;
use Jcode;

our $VERSION = '0.01';

sub prepare {
	my($e)= @_;
	$e->response->content_type("text/html; charset=UTF-8");
	$e->response->content_language( $e->config->{content_language} || 'jp' );
	$e->next::method;
}
sub _charset_convert_type {
	my($e)= @_;
	$e->response->content_type=~m{^text/html} ? 1: 0;
}
sub _output_convert_charset {
	my($e, $body)= @_;
	Jcode->new($body)->utf8;
}

1;

__END__

=head1 NAME

Egg::Plugin::Charset - Plugin to output contents with EUC-JP.

=head1 SYNOPSIS

  package MYPROJECT;
  use strict;
  use Egg qw/Charset::EUC_JP/;

=head1 SEE ALSO

L<Egg::Plugin::Charset>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. <L<http://egg.bomcity.com/>>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
