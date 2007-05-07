package Egg::Plugin::Filter::Plugin::Japanese::EUC;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: EUC.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Filter::Plugin::Japanese::EUC - The filter for the Japanese sentence character code is added.

=head1 SYNOPSIS

  use Egg qw/ Filter /;
  
  __PACKAGE__->egg_startup(
  
    plugin_filter=> {
      plugin=> [qw/ Japanese::EUC /],
      },
  
    );

  $e->filter(
    myname   => [qw/ h2z j_strip_j j_trim /],
    nickname => [qw/ h2z j_strip j_trim /],
    address  => [qw/ h2z j_hold /],
    );

=head1 DESCRIPTION

It is a plug-in for the filter that can treat Japanese EUC character-code.

Please refer to the document of L<Egg::Plugin::Filter::Plugin::Japanese>.

=cut
use strict;
use warnings;
use base qw/Egg::Plugin::Filter::Plugin::Japanese/;
use Jcode;

our $VERSION= '2.00';

$Egg::Plugin::Filter::Plugin::Japanese::Zspace  = q{(?:\xA1\xA1)};
$Egg::Plugin::Filter::Plugin::Japanese::RZspace = '¡¡';

=head1 SEE ALSO

L<Egg::Plugin::Filter>,
L<Egg::Plugin::Filter::Plugin::Japanese>,
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
