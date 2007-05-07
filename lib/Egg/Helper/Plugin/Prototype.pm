package Egg::Helper::Plugin::Prototype;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Prototype.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Helper::Plugin::Prototype - Helper to generate Prototype library

=head1 SYNOPSIS

    bin/myapp_helper.pl Plugin::Prototype

=head1 DESCRIPTION

Helper to generate Prototype library.

=cut
use strict;
use warnings;
use File::Spec;
use HTML::Prototype;

our $VERSION = '2.00';

sub _execute {
	my($self)= @_;
	return $self->_output_help if $self->global->{help};

	my $conf= $self->load_project_config;
	   $conf->{dir} || die q{ I want setup 'dir' };
	my $static= $conf->{dir}{static} || die q{ I want setup dir-> 'static' };

	my $prototype= File::Spec->catfile( $static, 'prototype.js' );
	$self->save_file({
	  filename => $prototype,
	  value    => $HTML::Prototype::prototype,
	  });

	my $controls= File::Spec->catfile( $static, 'controls.js' );
	$self->save_file({
	  filename => $controls,
	  value    => $HTML::Prototype::controls,
	  });

	my $dragdrop= File::Spec->catfile( $static, 'dragdrop.js' );
	$self->save_file({
	  filename => $dragdrop,
	  value    => $HTML::Prototype::controls,
	  });

	print <<END_EXEC;

... completed.

  prototype.js : $prototype
  controls.js  : $controls
  dragdrop.js  : $dragdrop

END_EXEC
}
sub _output_help {
	my $self = shift;
	my $pname= lc($self->project_name);
	print <<END_HELP;

# usage: perl ${pname}_helper.pl Plugin:Prototype

END_HELP
	exit;
}

=head1 SEE ALSO

L<Catalyst::Helper::Prototype>,
L<Catalyst::Plugin::Prototype>,
L<Egg::Plugin::Prototype>,
L<Egg::Release>,

=head1 AUTHOR

This code is a transplant of 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>'
 of the code of 'L<Catalyst::Helper::Prototype>'.

Therefore, the copyright of this code is assumed to be the one that belongs
 to 'Sebastian Riedel, C<sri@oook.de>'.

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
