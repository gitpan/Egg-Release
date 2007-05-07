package Egg::Plugin::ConfigLoader;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: ConfigLoader.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::ConfigLoader - The configuration of Egg is loaded.

=head1 SYNOPSIS

  use Egg qw/ ConfigLoader /;
  
  __PACKAGE__->_egg_setup;

=head1 DESCRIPTION

The configuration of Egg is loaded.

Please pass '_egg_setup' PATH of the place where the project was generated
when you want to make the configuration of the YAML form read.

  __PACKAGE__->_egg_setup('/home/to/MyApp');

/home/to/MyApp/myapp.yaml or/home/to/MyApp/etc/myapp.yaml is read by this.

* The configuration of the YAML form can be output as follows.

  perl MyApp/bin/myapp_helper Plugin::YAML

=cut
use strict;
use warnings;
use UNIVERSAL::require;

our $VERSION = '2.00';

sub _load_config {
	my $class= shift;
	my $conf;
	if (@_) {
		$conf= ref($_[0]) eq 'HASH' ? $_[0]:
		       scalar(@_) > 1 ? {@_}: do {

			YAML->require or die qq{ I want configration. : $@ };

			my $lc_name= lc($class);
			my $yaml=
			    -e "$_[0]/$lc_name.yaml"     ? "$_[0]/$lc_name.yaml"
			  : -e "$_[0]/etc/$lc_name.yaml" ? "$_[0]/etc/$lc_name.yaml"
			  : die q{ Configuration of YAML format is not found. };

			YAML::LoadFile($yaml);
		  };
	} else {
		"${class}::config"->require or die $@;
		$conf= "${class}::config"->out;
	}
	$class->replace_deep($conf, $conf->{dir});
	$class->replace_deep($conf, $conf);
	$conf;
}

=head1 SEE ALSO

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
