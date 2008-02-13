package Egg::Helper::Build::Plugin;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Plugin.pm 227 2008-01-29 12:26:27Z lushe $
#
use strict;
use warnings;
use base qw/ Egg::Helper::Build::Module /;

our $VERSION= '3.00';

sub _start_helper {
	my($self)= @_;
	my $c= $self->config;
	$c->{helper_option}{project_root} || return $self->_helper_help
	   ('I want you to start from helper of the project.');
	my $plugin_name= shift(@ARGV)
	   || return $self->_helper_help('I want plugin name.');
	if ($plugin_name=~m{^\+}) {
		$plugin_name=~s{^\++} [];
	} elsif ($plugin_name!~m{^Egg(?:\:+|\-)Plugin}) {
		$plugin_name=~s{^(?:\:|\-)+} [];
		$plugin_name= "Egg::Plugin::$plugin_name";
	}
	my $parts= $self->helper_mod_name_split($plugin_name)
	   || return $self->_helper_help('Bad format of plugin name.');
	my $o= $self->_helper_get_options;
	my $version= $self->helper_valid_version_number($o->{version}) || return 0;
	my $param  = $self->helper_prepare_param({
	   output_path      => ($o->{output} || undef),
	   module_version   => $version,
	   module_generator => __PACKAGE__,
	   });
	$self->helper_prepare_param_module($param, $parts);
	my $plugin_path= $param->{module_output_filepath}=
	                "$param->{output_path}/lib/$param->{module_filepath}";
	-e $plugin_path
	   and return $self->_helper_help("$plugin_path A already exists.");
	$self->helper_generate_files(
	  param        => $param,
	  chdir        => [$param->{output_path}],
	  create_files => [$self->helper_mod_template->[0]],
	  errors       => { unlink=> [$plugin_path] },
	  complete_msg => "\nPlugin generate is completed.\n\n"
	               .  "output path : $plugin_path\n"
	  );
	$self;
}
sub _helper_help {
	my $self = shift;
	my $msg  = shift || "";
	my $pname= lc $self->project_name;
	$msg= "ERROR: ${msg}\n\n" if $msg;
	print <<END_HELP;
${msg}% perl ${pname}_helper.pl Build::Plugin [PLUGIN_NAME] [-o OUTPUT_PATH] [-v VERSION]

END_HELP
	0;
}

1;

__END__

=head1 NAME

Egg::Helper::Build::Plugin - The template of the plugin module is generated.

=head1 SYNOPSIS

  % cd /path/to/MyApp/bin
  % ./myapp_helper.pl Build::Plugin PluginName

=head1 DESCRIPTION

It is a plugin to generate the templete of plugin module.

The name of the option to start this module and the generated plugin is specified
for the helper of the project.

  % ./myapp_helper.pl Build::Plugin [PLUGIN_NAME]

It is treated as a name of the plugin putting up 'Egg::Plugin' to the head of
PLUGIN_NAME usually.

When the full name is specified for the plug-in name, it specifies it applying
'+' to the head.

  % ./myapp_helper.pl Build::Plugin +MyAApp::Plugin::Any

The template of the module is generated by the subordinate of passing the library
of the project.

  % vi /path/to/MyApp/lib/Egg/Plugin/PluginName.pm

Please refer to the document of L<Egg> for the method of making the plugin module.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Helper>,
L<Egg::Helper::Build::Module>,
L<Egg>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

