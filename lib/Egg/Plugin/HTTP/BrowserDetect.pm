package Egg::Plugin::HTTP::BrowserDetect;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id$
#
use strict;
use warnings;
use HTTP::BrowserDetect;

our $VERSION = '2.00';

=head1 NAME

Egg::Plugin::HTTP::BrowserDetect - Plugin for HTTP::BrowserDetect.

=head1 SYNOPSIS

  use Egg qw/ HTTP::BrowserDetect /;

  if ($e->browser->windows) {
     # OS is Windows.
  } elsif ($e->browser->mac) {
     # OS is Macintosh.
  } elsif ($e->browser->unix) {
     # OS is Unix.
  } else {
     # Other OS.
  }

=head1 DESCRIPTION

It is a plug-in to obtain browser information on connected client.

see L<HTTP::BrowserDetect>.

=head1 METHODS

=head2 browser ([USER_AGENT])

The object of HTTP::BrowserDetect is returned.

There is usually no [USER_AGENT] needing.
HTTP::BrowserDetect acquires it from the environment variable.

=cut

sub browser { shift->{browser} ||= HTTP::BrowserDetect->new(@_) }

1;

__END__

=head1 SEE ALSO

L<HTTP::BrowserDetect>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
