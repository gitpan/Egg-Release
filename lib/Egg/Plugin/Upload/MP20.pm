package Egg::Plugin::Upload::MP20;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: MP20.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;
use warnings;
use Apache2::Upload;

our $VERSION = '0.02';

sub filename { $_[0]->handle->filename }
sub tempname { $_[0]->handle->tempname }
sub size { $_[0]->handle->size }
sub type { $_[0]->handle->type }
sub info { $_[0]->handle->info }

1;

__END__

=head1 NAME

Egg::Plugin::Upload::MP20 - Subclass of Egg::Plugin::Upload for mod_perl2.

=head1 DESCRIPTION

This module is a subclass that is called from Egg::Plugin::Upload.

The function of the method of filename , tempname , size , type , info is
 supplemented for mod_perl2.

=head1 SEE ALSO

L<Apache2::Upload>,
L<Egg::Plugin::Upload>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
