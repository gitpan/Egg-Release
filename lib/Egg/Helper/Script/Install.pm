package Egg::Helper::Script::Install;
use strict;
use Cwd;

sub generate {
	my $self= shift;
	$self->{output} ||= getcwd();
	my $file = "$self->{output}/egg_helper.pl";
	my $value= <<PLAIN;
#!$self->{perl_path}
use Egg::Helper::Script;

Egg::Helper::Script->run(0, { perl_path=> '$self->{perl_path}' });

PLAIN
	$self->output_file($file, $value);
	chmod 0755, $file;
	print STDERR <<END_OF_BODY;
... Done.

* Please do as follows and make Project.

# egg_helper.pl project [option]
  -o = create path, Default is current directory.

END_OF_BODY
	exit;
}

1;
