package Egg::Helper::Script::Install;
use strict;
use warnings;
use Cwd;

our $VERSION= '0.03';

sub generate {
	my $self= shift;
	$self->{output} ||= getcwd();
	my $file = "$self->{output}/egg_helper.pl";
	my $value= <<PLAIN;
#!$self->{perl_path}
use Egg::Helper::Script;

Egg::Helper::Script->run(0, { perl_path=> '$self->{perl_path}' });

PLAIN
	$self->output_file( {}, {
	  filename  => $file,
	  value     => $value,
	  permission=> 0755,  ## no critic
	  } );
	print <<END_OF_BODY;
... Done.

* Please do as follows and make Project.

# egg_helper.pl project -p [project_name] [option]
  -o = create path, Default is current directory.

END_OF_BODY
	exit;
}

1;

__END__

=head1 NAME

Egg::Helper::Script::Install - The helper script is output.

=head1 SEE ALSO

L<Egg::Helper::Script>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
