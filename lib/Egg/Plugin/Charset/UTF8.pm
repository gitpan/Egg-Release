package Egg::Plugin::Charset::UTF8;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: UTF8.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Charset::UTF8 - Plugin to output contents with UTF-8.

=head1 SYNOPSIS

  use Egg qw/ Charset::Shift_JIS /;

=head1 DESCRIPTION

It is a plugin to output contents with UTF-8.

If 'content_type' of default is assumed to be 'text/html; charset=utf-8',
and 'content_language' is undefined, it sets it to 'ja'.

The code conversion of contents is done by '_finalize_output'.

=cut
use strict;
use warnings;
use Jcode;
use base qw/Egg::Plugin::Charset/;

our $VERSION = '2.00';

sub _setup {
	my($e)= @_;
	my $conf= $e->config;
	$conf->{content_language} ||= 'ja';
	$conf->{content_type}     = 'text/html; charset=utf-8';
	$e->next::method;
}
sub _convert_body {
	my $e    = shift;
	my $body = shift || return 0;
	Jcode->new($body)->utf8;
}

=head1 SEE ALSO

L<Egg::Plugin::Charset>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
