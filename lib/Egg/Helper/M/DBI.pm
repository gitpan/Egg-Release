package Egg::Helper::M::DBI;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: DBI.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Component/;

our $VERSION= '0.01';

sub new {
	my $self= shift->SUPER::new;
	my $g= $self->global;
	$g->{example_file}= "etc/$g->{examples}/model_dbi.config";
	chdir($g->{project_root});
	eval{
		-e $g->{example_file} and die
		  "The file already exists. : $g->{project_root}/$g->{example_file}";

		my $hash= $self->parse_yaml(join '', <DATA>);
		$self->save_file($g, $hash);

	  };
	chdir($g->{start_dir});
	if (my $err= $@) {
		die $err;
	} else {
		print <<END_OF_INFO;
... completed.

A setup sample was output to '$g->{project_root}/$g->{example_file}'.

END_OF_INFO
	}
}

1;

=head1 NAME

Egg::Helper::M::DBI - Model::DBI setup sample of I is generated.

=head1 SYNOPSIS

  cd /path/to/myproject/bin

  # A setup sample is generated.
  ./myproject_helper.pl M::DBI

=head1 SEE ALSO

L<Egg::Helper>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
filename: <# example_file #>
value: |
 
 Example of configuration.
 
 __PACKAGE__->__egg_setup(
 
   MODEL => [
     [
       'DBI' => {
         dsn     => 'dbi:DBD:dbname=dbname;host=localhost;port=5432',
         user    => 'dbuser',
         password=> '%password%',
         options => { AutoCommit => 1, RaiseError => 1 },
       },
     ],
   ],
 
 );