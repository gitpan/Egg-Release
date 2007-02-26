package Egg::Const;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Const.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;
use warnings;
use base qw/Exporter/;
no warnings 'redefine';

our $VERSION= '0.02';

our @EXPORT=
  qw/OK AUTH_REQUIRED FORBIDDEN NOT_FOUND SERVER_ERROR TRUE FALSE/;

sub OK            { 200 }
sub AUTH_REQUIRED { 401 }
sub FORBIDDEN     { 403 }
sub NOT_FOUND     { 404 }
sub SERVER_ERROR  { 500 }
sub TRUE  { 1 }
sub FALSE { 0 }

1;

__END__

=head1 NAME

Egg::Const - Constant module for Egg.

=head1 SYNOPSIS

 package Hoge;
 use strict;
 use Egg::Const;
 
 sub foo {
   my($e)= @_;
 
   ....
   ...... kan, ka, ka, kan, kon.
 
   return FORBIDDEN if $bad;
   return OK;
 }

=head1 DESCRIPTION

It is an ordinary constant module.

There is no explained thing.

=head1 SEE ALSO

L<Egg::Dispatch>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
