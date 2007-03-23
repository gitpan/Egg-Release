package Egg::Model;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Model.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Component/;

our $VERSION= '0.04';

1;

__END__

=head1 NAME

Egg::Model - Common package for MODEL module.

=head1 SYNOPSIS

 package Egg::Model::[Foo];
 use strict;
 use base qw/Egg::Model/;
 
 ... ban, bo, bo, bon.

=head1 DESCRIPTION

This module has succeeded to Egg::Component.

=head1 SEE ALSO

L<Egg::Component>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
