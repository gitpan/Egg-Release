package Egg::Plugin::Upload;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizunoE<64>bomcity.com>
#
# $Id: Upload.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.03';

sub setup {
	my($e)= @_;
	Egg::Plugin::Upload::base->__setup($e);
	$e->next::method;
}

package Egg::Plugin::Upload::base;
use strict;
use UNIVERSAL::require;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors( qw/name handle/ );

*fh= \&handle;

sub __setup {
	my($class, $e)= @_;
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	my $request= $e->global->{REQUEST_CLASS}
	  || Egg::Error->throw('The request class cannot acquire it.');

	*{"$request\::upload"}= sub {
		my $req= shift;
		__PACKAGE__->new($req, @_) || 0;
	  };

	my $base;
	if (my $version= $Egg::MOD_PERL_VERSION) {
		$base= $version>= 1.99922
		  ? 'Egg::Plugin::Upload::MP20': 'Egg::Plugin::Upload::MP13';
	} else {
		$base= 'Egg::Plugin::Upload::CGI';
	}
	$base->require or Egg::Error->throw($@);
	unshift @{__PACKAGE__."::ISA"}, $base;

	if (Egg::View->require) {
		$Egg::View::PARAMS{enctype}= q{ enctype="multipart/form-data"};
	}
}
sub new {
	my($class, $req, $name)= @_;
	$req->{uploads} ||= [];
	$name || Egg::Error->throw(__PACKAGE__. q/ : I want a form name./);
	my $handle= $req->r->upload($name) || return;
	bless { name=> $name, r=> $req->r, handle=> $handle }, $class;
}
sub catfilename {
	my($up)= @_;
	my $filename= $up->filename || return;
	$filename=~m{([^\\\/]+)$} ? $1: undef;
}
sub copy_to {
	my $up= shift;
	File::Copy->require;
	File::Copy::copy($up->tempname, @_);
}
sub link_to {
	my $up= shift;
	link($up->tempname, @_);
}

1;

__END__

=head1 NAME

Egg::Plugin::Upload - The file uploading is supported. 

=head1 SYNOPSIS

 package [MYPROJECT];
 use strict;
 use Egg qw/-Debug Upload/;

 if ( my $upload= $e->request->upload('field_name') ) {
 
 	my $filename= $upload->catfilename;
 
 	# It copies it to an arbitrary place. 
 	$upload->copy_to( "/path/to/save/$filename" );
 }

=head1 DESCRIPTION

Request driver behavior can be adjusted by setting TEMP_DIR, POST_MAX etc.

=head1 METHODS

upload and uploads are added as a method of Egg::Request.

=head2 my $upload= $e->request->upload([FIELD_NAME]);

The upload object specified by [FIELD_NAME] is returned. 

Undefined returns if there is no specified upload.

 my $upload= $e->request->upload( 'upload_name' );

=head2 $upload->filename

The upload file name is returned.

=head2 $upload->tempname

Path where the file has been temporarily preserved is returned.

=head2 $upload->size

The size of the upload file is returned.

=head2 $upload->type

The contents type of the upload file is returned.

=head2 $upload->info

The HASH reference of various information concerning the up-loading file returns.

=head2 $upload->catfilename

$upload->filename seems to return in shape that local PATH of the client is included
 in case of mod_perl.
Then, after only the file name is extracted, this method is returned.

=head2 $upload->copy_to

The file is temporarily copied to the specified place.

=head2 $upload->link_to

The hard link of files is temporarily made for the specified place.

=head1 SEE ALSO

L<Egg::Request::Apache>,
L<Egg::Request::CGI>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
