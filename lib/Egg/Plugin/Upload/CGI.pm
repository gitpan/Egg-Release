package Egg::Plugin::Upload::CGI;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: CGI.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.02';

sub filename { $_[0]->{r}->param( $_[0]->name ) }
sub tempname { $_[0]->{r}->tmpFileName( $_[0]->handle ) }
sub size { -s $_[0]->handle }
sub type { $_[0]->info->{'Content-Type'} }
sub info { $_[0]->{r}->uploadInfo( $_[0]->handle ) }

1;

__END__

=head1 NAME

Egg::Plugin::Upload::CGI - Subclass of Egg::Plugin::Upload for CGI.

=head1 DESCRIPTION

This module is a subclass that is called from Egg::Plugin::Upload.

The function of the method of filename , tempname , size , type , info is
 supplemented for CGI.pm.

=head1 SEE ALSO

L<CGI>,
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
