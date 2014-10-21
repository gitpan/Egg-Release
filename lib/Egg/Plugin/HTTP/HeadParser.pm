package Egg::Plugin::HTTP::HeadParser;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: HeadParser.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::HTTP::HeadParser - Analysis of request header and response header.

=head1 SYNOPSIS

  use Egg qw/ HTTP::HeadParser /;

  $header= <<END_HEADER;
  Content-Tyle: text/html
  Content-Language: ja
  
  content ....
  END_HEADER
  
  my $hash= $e->parse_http_header($header);

=cut
use strict;
use warnings;
use Egg::Response;

our $VERSION = '2.00';

my $cregix= qr{(?:$Egg::Response::CRLF|\r\n|\r|\n)};

=head1 METHODS

=head2 parse_http_header ( [HEADER_TEXT] )

HEADER_TEXT is analyzed and the result is returned by the HASH reference.

* Even if contents are included following two changing line or more, it operates well.

* GET of the request header and the header such as POST preserve the content in 'method' key.

* The header following the response header HTTP/\d + preserves the content in 'status' key.

=cut
sub parse_http_header {
	my $e   = shift;
	my $head= shift || return 0;
	   $head=~s{^$cregix+} [];
	   $head=~s{$cregix+$} [];
	my %header;
	for (split /$cregix/, $head) {
		$_ || last;
		if (my($name, $value)= m{^(.+?)\s*\:\s+(.+)}) {
			$name=~s{\-} [_]g;
			$header{lc($name)}= $value;
		}
	}
	if ($head=~m{^(HTTP/[\d\.]+) +(\d+( +[^\r\n]+)?)[\r\n]+}) {
		$header{status}= "$1 $2";
	} elsif ($head=~m{^(GET|POST|HEAD|PUT|DELETE) +([^\:\r\n]+)[\r\n]+}) {
		$header{method}= "$1 $2";
	}
	\%header;
}

=head1 SEE ALSO

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
