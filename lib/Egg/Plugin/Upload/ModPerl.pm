package Egg::Plugin::Upload::ModPerl;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: ModPerl.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Upload::ModPerl - mod_perl support of Egg plugin Upload.

=head1 SYNOPSIS

  use Egg qw/ Upload /;

  if (my $upload= $e->request->upload('upload_param')) {
    
    # upload filename.
    print " File Name: ". $upload->catfilename;
  
    # upload file size.
    print " File Size: ". $upload->size;
    
    # The upload file is read.
    my $up_value= join '', $upload->handle->getlines;
    
  }

=head1 DESCRIPTION

It is a plug-in to be able to use L<Egg::Plugin::Upload> in the mod_perl
environment.

L<Egg::Plugin::Upload > judges the environment and this plugin is read by
the automatic operation.

It is not necessary to load it specifying it.

=cut
use strict;
use warnings;

our $VERSION = '2.00';

=head1 UPLOAD HANDLER METHODS

The method of E::P::Upload is supplemented as follows.

Please refer to the document of L<Egg::Plugin::Upload>::handler.

=cut

sub _startup {
	my($class, $mpversion)= @_;
	$mpversion>= 1.99922
	   ? require 'Apache2::Upload': require 'Apache::Upload';
}

=head2 filename

The upload file name is returned.

=cut
sub filename { $_[0]->handle->filename }

=head2 tempname

PATH of the place where the up-loading file has been temporarily preserved is
returned.

=cut
sub tempname { $_[0]->handle->tempname }

=head2 size

The size of the upload file is returned.

=cut
sub size { $_[0]->handle->size }

=head2 type

The contents type of the upload file is returned.

=cut
sub type { $_[0]->handle->type }

=head2 info

Failinfo of the upload file is returned.

=cut
sub info { $_[0]->handle->info }


=head1 SEE ALSO

L<Apache::Upload>,
L<Apache2::Upload>,
L<Egg::Plugin::Upload>,
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
