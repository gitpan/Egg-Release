package Egg::Const;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Const.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Const - Constant module for Egg.

=head1 SYNOPSIS

  use Egg::Const;
  
  if ( OK            == 200 ) { ... }
  if ( AUTH_REQUIRED == 401 ) { ... }
  if ( FORBIDDEN     == 403 ) { ... }
  if ( NOT_FOUND     == 404 ) { ... }
  if ( SERVER_ERROR  == 500 ) { ... }
  
  if     ( OK )    { ... }
  unless ( FALSE ) { ... }

=head1 DESCRIPTION

It is an ordinary constant module.

There is no explained thing.

=cut
use strict;
use warnings;
use base qw/Exporter/;

our $VERSION= '2.00';
{
	no warnings 'redefine';

	our @EXPORT=
	  qw/OK AUTH_REQUIRED FORBIDDEN NOT_FOUND SERVER_ERROR TRUE FALSE/;

=head1 EXPORT METHODS

=head2 OK 200

=cut
	sub OK { 200 }

=head2 AUTH_REQUIRED 401

=cut
	sub AUTH_REQUIRED { 401 }

=head2 FORBIDDEN 403

=cut
	sub FORBIDDEN { 403 }

=head2 NOT_FOUND 404

=cut
	sub NOT_FOUND { 404 }

=head2 SERVER_ERROR 500

=cut
	sub SERVER_ERROR { 500 }

=head2 TRUE 1

=cut
	sub TRUE  { 1 }

=head2 FALSE 0

=cut
	sub FALSE { 0 }
};

=head1 SEE ALSO

L<Egg::Plugin::Dispatch>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
