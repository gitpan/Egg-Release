package Egg::Helper::P::Charset;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Make.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Component/;

our $VERSION= '0.02';

sub new {
	my $self= shift->SUPER::new();
	my $g= $self->global;
	return $self->help_disp if ($g->{help} || ! $g->{any_name});

	my $part= $self->check_module_name
	   ($g->{any_name}, qw{ Egg Plugin Charset });
	$part->[$#{$part}]= ucfirst($part->[$#{$part}]);

	$self->setup_global_rc;
	$self->setup_document_code;
	$g->{lib_dir}= "$g->{project_root}/lib";
	$g->{plugin_name}    = join('-' , @$part);
	$g->{plugin_distname}= join('::', @$part);
	$g->{plugin_filename}= join('/' , @$part). '.pm';
	$g->{plugin_new_version}= 0.01;

	-e "$g->{lib_dir}/$g->{plugin_filename}"
	  and die "It already exists : $g->{lib_dir}/$g->{plugin_filename}";

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
		  "$g->{lib_dir}/$g->{plugin_filename}",
		  "$g->{project_root}/t/$g->{number}_$g->{plugin_name}.t",
		  );
		die $err;
	} else {
		my $code_name= join '::', @{$part}[3..$#{$part}];
		print <<END_OF_INFO;
... done.$self->{add_info}

Please edit the controller. !!

Example of controller.

  package $g->{project_name};
  use strict;
  use Egg qw/Charset::$code_name/;

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
# usage: perl $pname\_helper.pl P:Chaset [CHARSET_NAME]

END_OF_HELP
}

1;

=head1 NAME

Egg::Helper::P::Charset - Helper for plugin charset.

=head1 SYNOPSIS

  % cd /MYPROJECT_ROOT/bin
  
  % perl myproject_helper.pl P:Charset [CHARCODE_NAME]
  
  output file: /MYPROJECT_ROOT/lib/Egg/Plugin/Charset/CHARCODE_NAME.pm

=head1 

This module is a helper who generates the skeleton of the module for plugin Charset.

  perl myproject_helper.pl P:Charset [CHARCODE_NAME]

'Egg::Plugin::Charset::[CHARCODE_NAME]' can be done /MYPROJECT_ROOT/lib in this.

This is edited, and an original Charset::* plugin is made.

=over 4

=item * prepare

  $e->response->content_type("text/html; charset=[CHARSET]");
  $e->response->content_language('[LANGUAGE]');

'Content-Type' and 'Content-Language' must be setup by processing's beginning.

=item * _charset_convert_type

  $e->response->content_type=~m{^text/html} ? 1: 0;

It is called when there is no 'Content-Type' in the text.
Return ture to the call that may convert the character-code.

* The code conversion processing is done in the example only at text/html.

=item * _output_convert_charset

The character-code conversion processing must be done by this method.

Because the value of body is passed to the argument by the SCALAR reference,
it is processed.

=back

* There is especially no prepare needing.
  It becomes an error if there are neither '_charset_convert_type' nor
  '_output_convert_charset'.

It registers to the controller as follows when completing it.

  use Egg qw/Charset::[CHARCODE_NAME]/;

It is built in the project by this.

=head1 SEE ALSO

L<Egg::Plugin::Charset>,
L<Egg::Plugin::Charset::EUT8>,
L<Egg::Plugin::Charset::EUC_JP>,
L<Egg::Plugin::Charset::Shift_JIS>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. <L<http://egg.bomcity.com/>>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
---
filename: lib/<# plugin_filename #>
value: |
  package <# plugin_distname #>;
  #
  # Copyright (C) <# headcopy #>, All Rights Reserved.
  # <# author #>
  #
  # <# revision #>
  #
  use strict;
  use warnings;
  use base qw/Egg::Plugin::Charset/;
  # use Jcode;
  
  our $VERSION = '<# plugin_new_version #>';
  
  # * Method of setup 'Content-Type' and 'Conent-Language'.
  #
  # sub prepare {
  #   my($e)= @_;
  #   $e->response->content_type("text/html; charset=UTF-8");
  #   $e->response->content_language( $e->config->{content_language} || 'jp' );
  #   $e->next::method;
  # }
  
  
  # * Method of judging whether to do code conversion.
  #
  # sub _charset_convert_type {
  #   my($e)= @_;
  #   $e->response->content_type=~m{^text/html} ? 1: 0;
  # }
  
  
  # * Method of executing code conversion.
  #
  # sub _output_convert_charset {
  #   my($e, $body)= @_;
  #   Jcode->new($body)->utf8;
  # }
  
  1;
  
  __END__
  <# document #>
---
filename: t/<# number #>_<# plugin_name #>.t
value: |
  
  use Test::More tests => 1;
  BEGIN { use_ok('<# plugin_distname #>') };
  
