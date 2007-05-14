package Egg::Helper::Plugin::YAML;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: YAML.pm 148 2007-05-14 16:13:31Z lushe $
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

our $VERSION = '2.01';

sub _execute {
	my($self)= @_;
	my $g= $self->global;
	my $project= $self->project_name;
	my $lcname = lc($project);

	return $self->_output_help if $g->{help};

	$self->_setup_module_maker(__PACKAGE__);
	my $c_class= "${project}::config";
	   $c_class->require or die qq{ configuration is not found: $@ };
	my $config= $c_class->out || {};
	$config->{root} || die q{ I want setup 'root'. };
	$config->{dir}  || die q{ I want setup 'dir'.  };
	my $etc= $config->{dir}{etc} || die q{ I want setup 'dir->etc'. };
	$self->replace($config, \$etc);
	my $yaml= "$etc/$lcname.yaml";
	$self->rotate($yaml);
	eval {
		$self->save_file({
		  filename=> $yaml, value=>
		    "#\n"
		  . "# $project Configuration. - $lcname.yaml\n"
		  . "#\n"
		  . "# output date: $g->{gmtime_string} GMT\n"
		  . "#\n"
		  . YAML::Dump($config),
		  });
	  };
	if (my $err= $@) {
		$self->rotate( $yaml, reverse=> 1 );
		$self->_output_help($err);
	} else {
		print <<END_EXEC;

... completed.

  output : $yaml

END_EXEC
	}
}
sub _output_help {
	my $self = shift;
	my $msg  = $_[0] ? "$_[0]\n": "";
	my $pname= lc($self->project_name);
	print <<END_HELP;

${msg}# usage: perl ${pname}_helper.pl Plugin:YAML

END_HELP
	exit;
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
