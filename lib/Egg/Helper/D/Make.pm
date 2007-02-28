package Egg::Helper::D::Make;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Make.pm 261 2007-02-28 19:32:16Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Component/;

our $VERSION= '0.04';

sub new {
	my $self= shift->SUPER::new();
	my $g= $self->global;
	return $self->help_disp if ($g->{help} || ! $g->{any_name});
	my $part= $self->check_module_name
	   ($g->{any_name}, $self->project_name, 'D');

	$self->setup_global_rc;
	$self->setup_document_code;
	$g->{created}= __PACKAGE__. " v$VERSION";
	$g->{lib_dir}= "$g->{project_root}/lib";
	$g->{dispatch_name}    = join('-' , @$part);
	$g->{dispatch_distname}= join('::', @$part);
	$g->{dispatch_filename}= join('/' , @$part). '.pm';
	$g->{dispatch_runname} = join('_', map{lc($_)}@{$part}[2..$#{$part}]);
	$g->{dispatch_new_version}= 0.01;

	-e "$g->{lib_dir}/$g->{dispatch_filename}"
	  and die "It already exists : $g->{lib_dir}/$g->{dispatch_filename}";

	$g->{number}= $self->get_testfile_new_number("$g->{project_root}/t")
	    || die 'The number of test file cannot be acquired.';

	$self->{add_info}= "";
	chdir($g->{project_root});
	eval {
		my @list= $self->parse_yaml(join '', <DATA>);
		$self->save_file($g, $_) for @list;
##		$self->distclean_execute_make;
	  };
	chdir($g->{start_dir});

	if (my $err= $@) {
		$self->remove_file(
		  "$g->{lib_dir}/$g->{dispatch_filename}",
		  "$g->{project_root}/t/$g->{number}_$g->{dispatch_name}.t",
		  );
		die $err;
	} else {
		print <<END_OF_INFO;
... done.$self->{add_info}

Please edit some files. !!

Example of Chenges.

$g->{dispatch_new_version}  $g->{gmtime_string} (GMT)
	- Dispatch was added. with module name $g->{dispatch_distname}.
	   created by $g->{created}

Example of Dispatch.

use $g->{dispatch_distname};

__PACKAGE__->run_modes(
  ..
  ...
  $g->{dispatch_runname} => \\\&$g->{dispatch_distname}::default,
  );

... completed.
END_OF_INFO
	}
}
sub output_manifest {
	my($self)= @_;
	$self->{add_info}= <<END_OF_INFO;

----------------------------------------------------------------
  !! MANIFEST was not able to be adjusted. !!
  !! Sorry to trouble you, but please edit MANIFEST later !!
----------------------------------------------------------------
END_OF_INFO
}
sub help_disp {
	my($self)= @_;
	my $pname= lc($self->project_name);
	print <<END_OF_HELP;
# usage: perl $pname\_helper.pl D:Make [NEW_DISPATCH_NAME]

END_OF_HELP
}

1;

=head1 NAME

Egg::Helper::D::Make - Dispatch module is generated for Egg::Helper.

=head1 SYNOPSIS

  cd /path/to/myproject/bin

  # Help is displayed.
  ./myproject_helper.pl D:Make -h
  
  # A new dispatch module is generated.
  ./myproject_helper.pl D:Make NewDispath

=head1 DESCRIPTION

This module generates the skeleton of the dispatch module and the test file.

MANIFEST is not renewed in OS other than UNIX system.
Please edit it sorry to trouble you, but by yourself.

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

__DATA__
---
filename: lib/<# dispatch_filename #>
value: |
  package <# dispatch_distname #>;
  #
  # Copyright (C) <# headcopy #>, All Rights Reserved.
  # <# author #>
  #
  # <# revision #>
  #
  use strict;
  use warnings;
  use Egg::Const;
  
  our $VERSION= '<# dispatch_new_version #>';
  
  sub default {
  	my($dispatch, $e)= @_;
  	require Egg::Helper::Project::BlankPage;
  	$e->response->body( Egg::Helper::Project::BlankPage->out($e) );
  }
  
  1;
  
  __END__
  <# document #>
---
filename: t/<# number #>_<# dispatch_name #>.t
value: |
  
  use Test::More tests => 1;
  BEGIN { use_ok('<# dispatch_distname #>') };
  
