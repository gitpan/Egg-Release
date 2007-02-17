package Egg::Plugin::Upload::MP13;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizunoE<64>bomcity.com>
#
# $Id: MP13.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use warnings;
use Apache::Upload;

our $VERSION = '0.02';

sub filename { $_[0]->handle->filename }
sub tempname { $_[0]->handle->tempname }
sub size { $_[0]->handle->size }
sub type { $_[0]->handle->type }
sub info { $_[0]->handle->info }

1;

__END__

=head1 NAME

Egg::Plugin::Upload::MP13 - Subclass of Egg::Plugin::Upload for mod_perl.

=head1 DESCRIPTION

This module is a subclass that is called from Egg::Plugin::Upload.

The function of the method of filename , tempname , size , type , info is
 supplemented for mod_perl.

=head1 SEE ALSO

L<Apache::Upload>,
L<Egg::Plugin::Upload>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut