package Egg::Helper::P::YAML;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: YAML.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use YAML;
use UNIVERSAL::require;
use base qw/Egg::Component/;

our $VERSION= '0.02';

sub new {
	my $self = shift->SUPER::new();
	my $pname= $self->project_name;
	my $C= do {
	  my $conf_name= "$pname\::config";
	  unless ( $conf_name->require ) {
	  	die "The configuration cannot be read. : $@";
	  }
	  $conf_name->out;
	  };
	my $G= $self->global;
	$G->{etc} ||= $C->{etc} || 'etc';
	my $yaml = $G->{etc}=~m{^/} ? $G->{etc}: "$G->{project_root}/$G->{etc}";
	   $yaml.= "/$pname.yaml";
	my $backup_ok;
	if (-e $yaml && -f _) {
		rename($yaml, "$yaml.save_old");
		++$backup_ok;
	}
	eval{
		$self->save_file( {}, {
		  filename=> $yaml, value=>
		    "#\n"
		  . "# $pname Configuration. - $pname.yaml\n"
		  . "#\n"
		  . "# output date: $G->{gmtime_string} (GMT)\n"
		  . "#\n"
		  . YAML::Dump($C),
		  });
	  };
	if (my $err= $@) {
		rename("$yaml.save_old", $yaml) if $backup_ok;
		die $err;
	} else {
		if ($backup_ok) {
			print <<END_OF_DONE;
... The generation of '$yaml' is completed.

* Data old was backup : '$yaml.save_old'.

END_OF_DONE
		} else {
			print <<END_OF_DONE;
* Edit $pname Control file as follows.

- is old.
use $pname\::config;
__PACKAGE__->__egg_setup( $pname\::config->out );

+ is new.
use Egg qw/YAML/

my \$config= __PACKAGE__->yaml_load('$yaml');
__PACKAGE__->__egg_setup( \$config );

END_OF_DONE
		}
	}
}

1;

__END__

=head1 NAME

Egg::Helper::P::YAML - The configuration is output by the YAML format for Egg.

=head1 SYNOPSIS

  # cd /path/to/MYPROJECT/bin
  
  # ./myproject_helper.pl P:YAML
  
  ... The generation of '[output_path]' is completed.

=head1 DESCRIPTION

When writing in YAML is not understood, it is convenient.

=head1 SEE ALSO

L<Egg::Helper>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
