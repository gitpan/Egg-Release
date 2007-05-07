package Egg::Helper::Plugin::YAML;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: YAML.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Helper::Plugin::YAML - Helper who output configuration of YAML format.

=head1 SYNOPSIS

  perl MyApp/bin/myapp_helper.pl Plugin:YAML -o /path/to/output

=head1 DESCRIPTION

The configuration of the YAML form is output.

The output destination can be specified by passing PATH to '-o' option.
It outputs it to the etc directory of the project when omitted.

When the configuration module doesn't exist, the exception is generated
because MyApp::config is read.

It rotates by L<Egg::Plugin::File::Rotate> if there is a file output before.

=cut
use strict;
use warnings;
use UNIVERSAL::require;
use File::Spec;
use YAML;
use base qw/ Egg::Plugin::File::Rotate /;

our $VERSION = '2.00';

sub _execute {
	my($self)= @_;
	my $g= $self->global;

	return $self->_output_help if $g->{help};

	$self->project_root->require or die $@;
	my $orign= $self->project_root->out;

	my $conf= $self->load_project_config(1);  ## pm only.
	   $conf->{dir} || die q{ I want setup 'dir' };
	my $etc = $g->{output_path}
	       || $conf->{dir}{etc}
	       || die q{ I want setup dir-> 'etc' };

	my $yaml_file= "$etc/". lc($self->project_name). ".yaml";

	$self->rotate($yaml_file);

	eval{
		$self->
	  };

	if ($@) {
		$self->rotate( $yaml_file, reverse=> 1 );
	} else {
	}


	my $yaml= "$etc/";

}

=head1 SEE ALSO

L<YAML>,
L<Egg::Plugin::File::Rotate>,
L<Egg::Helper>,
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
