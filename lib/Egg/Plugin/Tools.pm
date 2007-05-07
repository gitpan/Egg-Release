package Egg::Plugin::Tools;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Tools.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Tools - Various function collections.

=head1 SYNOPSIS

  use Egg qw/ Tools /;

  $e->escape_html($html);
  
  $e->unescape_html($plain);
  
  $e->md5_hex('abcdefg');
  
  $e->comma('12345.123');
  
  my @array= (1..100);
  $e->shuffle_array(\@array);

=head1 DESCRIPTION

This plugin offers the method of various functions.

=cut
use strict;
use warnings;
use URI::Escape;
use HTML::Entities;
use Carp qw/croak/;

our $VERSION = 2.00;

{
	no warnings 'redefine';

=head1 METHODS

=head2 encode_entities ( [HTML_TEXT], [ARGS] )

The result of L<HTML::Entities>::encode_entities is returned.

=over 4

=item * Alias: escape_html, eHTML

=back

=cut
	sub encode_entities {
		shift; my $args= $_[1] || q{'"&<>@};
		&HTML::Entities::encode_entities($_[0], $args);
	}
	*escape_html = \&encode_entities;
	*eHTML       = \&encode_entities;

=head2 encode_entities_numeric ( [HTML_TEXT], [ARGS] )

The result of L<HTML::Entities>::encode_entities_numeric is returned.

=cut
	sub encode_entities_numeric
	  { shift; &HTML::Entities::encode_entities_numeric(@_) }

=head2 decode_entities ( [PLAIN_TEXT], [ARGS] )

The result of L<HTML::Entities>::decode_entities is returned.

=over 4

=item * Alias: unescape_html, ueHTML

=back

=cut
	sub decode_entities
	  { shift; &HTML::Entities::decode_entities(@_) }
	*unescape_html = \&decode_entities;
	*ueHTML        = \&decode_entities;

=head2 uri_escape ( [URI_PARTS], [ARGS] )

The result of L<URI::Escape>::uri_escape is returned.

=over 4

=item * Alias: escape_uri, eURI

=back

=cut
	sub uri_escape
	  { shift; &URI::Escape::uri_escape(@_) }
	*escape_uri = \&uri_escape;
	*eURI       = \&uri_escape;

=head2 uri_escape_utf8 ( [URI_PARTS], [ARGS] )

The result of L<URI::Escape>::uri_escape_utf8 is returned.

=cut
	sub uri_escape_utf8
	  { shift; &URI::Escape::uri_escape_utf8(@_) }

=head2 uri_unescape ( [URI], [ARGS] )

The result of L<URI::Escape>::uri_unescape is returned.

=over 4

=item * Alias: unescape_uri, ueURI

=back

=cut
	sub uri_unescape
	  { shift; &URI::Escape::uri_unescape(@_) }
	*unescape_uri = \&uri_unescape;
	*ueURI        = \&uri_unescape;

  };

=head2 md5_hex ( [DATA] )

The result of L<Digest::MD5>::md5_hex is returned.

=cut
sub md5_hex {
	require Digest::MD5;
	my $e   = shift;
	my $data= ref($_[0]) eq 'SCALAR' ? $_[0]: \$_[0];
	Digest::MD5::md5_hex($$data);
}

=head2 comma ( [NUMBER] )

Is put in given NUMBER in each treble and it returns it.

  $e->comma('123456')       =>    123,456
  $e->comma('-654321.123')  =>   -654,321.123
  $e->comma('+123456789.0') => +1,234,567.0

=cut
sub comma {
	my $num= $_[1] || return 0;
	my($a, $b, $c)= $num=~/^([\+\-])?(\d+)(\.\d+)?/;
	1 while $b=~s{(.*\d)(\d{3})} [$1,$2];
	($a || ""). $b. ($c || "");
}

=head2 shuffle_array ( [ARRAY] )

It returns it mixing given ARRAY at random.

  my @array= (1..10);
  $e->shuffle_array(\@array);

* Quotation from perlfaq.

=cut
sub shuffle_array {
	# Quotation from perlfaq.
	my $surf= shift;
	my $deck= $_[0] ? (ref($_[0]) eq 'ARRAY' ? $_[0]: [@_])
	                : croak q{ I want array. };
	my $i = @$deck;
	while ($i--) {
		my $j = int rand ($i+1);
		@$deck[$i,$j] = @$deck[$j,$i];
	}
	wantarray ? @$deck: $deck;
}

1;

=head1 SEE ALSO

L<HTML::Entities>,
L<URI::Escape>,
L<Digest::MD5>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
