package Egg::Plugin::YAML;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@bomcity.com>
#
# $Id: YAML.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use warnings;
use YAML;

our $VERSION= '0.05';

sub yaml_load {
	my $e= shift;
	my $yaml= shift || return 0;
	$yaml=~/[\r\n]/ ? YAML::Load($yaml): YAML::LoadFile($yaml);
}
sub loadrc {
	my $e= shift;
	Egg::Plugin::YAML::Tool->loadrc || {};
}

package Egg::Plugin::YAML::Tool;
use strict;
use warnings;
use UNIVERSAL::require;
sub loadrc {
	my $class= shift;
	Cwd->require;
	my $current= Cwd::getcwd();
	my $rc_name= $ENV{EGG_RCNAME} || 'egg_releaserc';
	my $yaml=
	   -f "$current/.$rc_name" ? "$current/.$rc_name"
	 : -f "~/.$rc_name"        ? "~/.$rc_name"
	 : -f "/etc/$rc_name"      ? "/etc/$rc_name"
	 : return (0);

	YAML::LoadFile($yaml);
}

1;

__END__

=head1 NAME

Egg::Plugin::YAML - YAML can be treated.

=head1 SYNOPSIS

package MYPROJECT;
use strict;
use Egg qw/YAML/;

my $config= __PACKAGE__->load('/path/to/config.yaml');

=head1 DESCRIPTION

 Let's write the configuration of Egg with YAML.

 Moreover, it is possible to misappropriate it also to other processing. 

=head1 METHODS

=head2 load ([YAML FILE PATH] or [YAML DATA]);

* YAML data when changing line is included in argument,
  It treats as a file name if not included.
* The result of doing parse is returned by HASH reference.

=head1 SEE ALSO

L<YAML>,

=head1 AUTHOR

Masatoshi Mizuno, <lt>L<mizunoE<64>bomcity.com><gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. <L<http://egg.bomcity.com/>>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
