#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: install-helper.pl 34 2006-12-14 08:17:52Z lushe $
#
use strict;
use warnings;
use lib qw(lib ../lib);
use Egg::Helper::Script;

our $VERSION= '0.01';

Egg::Helper::Script->run('install');

__END__

=head1 NAME

install-helper.pl - It is a program for the installation of the helper script. 

=head1 SYNOPSIS

 # perl /path/to/install-helper.pl -o [output path]

=head1 DESCRIPTION

Please execute it immediately after the installation of Egg. 

The script for the project making is installed in the specified place.

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
