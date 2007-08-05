package Egg::Plugin::Upload;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Upload.pm 181 2007-08-02 18:28:43Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use Egg::View;

our $VERSION= '2.00';

=head1 NAME

Egg::Plugin::Upload - Plugin to support file upload.

=head1 DESCRIPTION

This is a base class for the file upload plugin.

However, it is good only to describe Upload in Egg.
The subclass judges the environment and reads by the automatic operation.

=cut
sub _setup {
	my($e)= @_;

	my $version;
	my $handler= ($version= $e->mp_version)
	   ? 'Egg::Plugin::Upload::ModPerl': 'Egg::Plugin::Upload::CGI';
	$handler->require or die $@;

	no strict 'refs';  ## no critic
	no warnings 'redefine';
	push @{"$handler\::ISA"}, 'Egg::Plugin::Upload::handler';
	*Egg::Request::upload= sub { $handler->new(@_) || 0 };

	$handler->_startup($version);

	$Egg::View::PARAMS{upload_enctype}= q{ enctype="multipart/form-data"};

	$e->next::method;
}


package Egg::Plugin::Upload::handler;
use strict;
use warnings;
use Carp qw/croak/;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors( qw/name handle/ );

=head1 UPLOAD METHODS

It is a method that can be used with the object received by $e-E<gt>request-E<gt>upload.

=head2 new

Constructor who returns up-loading object.

=cut
sub new {
	my($class, $req)= splice @_, 0, 2;
	my $name  = shift || croak q{ I want upload param name. };
	my $handle= $req->r->upload($name) || return 0;
	bless { name=> $name, r=> $req->r, handle=> $handle }, $class;
}

=head2 name

The parameter name is returned.

=over 4

=item * Alias: key

=back

=cut
*key = \&name;

=head2 handle

The file steering wheel of the preservation file is temporarily returned.

=over 4

=item * Alias: fh

=back

=cut
*fh = \&handle;

=head2 catfilename

Only the file name that doesn't contain PATH is returned.

=cut
sub catfilename {
	my($up)= @_;
	my $filename= $up->filename || return;
	$filename=~m{([^\\\/]+)$} ? $1: undef;
}

=head2 copy_to ( [COPY_PATH] )

The preservation file is temporarily copied onto COPY_PATH.

=cut
sub copy_to {
	my $up= shift;
	File::Copy->require;
	File::Copy::copy($up->tempname, @_);
}

=head2 link_to ( [LINK_PATH] )

The hard link of the preservation file is temporarily made.

=cut
sub link_to {
	my $up= shift;
	link($up->tempname, @_);
}

sub _startup { }

=head1 SEE ALSO

L<Egg::Plugin::Upload::CGI>,
L<Egg::Plugin::Upload::ModPerl>,
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
