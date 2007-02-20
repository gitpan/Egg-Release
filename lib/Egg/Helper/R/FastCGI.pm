package Egg::Helper::R::FastCGI;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: FastCGI.pm 217 2007-02-20 13:11:17Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Component/;

our $VERSION= '0.02';

sub new {
	my $self= shift->SUPER::new;
	my $g= $self->global;
	$g->{example_file}= "etc/$g->{examples}/FastCGI.confg.example";
	$g->{uc_project_name}= uc($self->project_name);

	$self->{add_info}= "";
	chdir($g->{project_root});
	eval{
		my @list= $self->parse_yaml(join '', <DATA>);
		$self->save_file($g, $_) for @list;
		print "# + file generate is completed.\n";
		$self->execute_make;
	  };
	chdir($g->{start_dir});

	if (my $err= $@) {
		die $err;
	} else {
		print <<END_OF_INFO;
... completed.$self->{add_info}

A setup sample was output to '$g->{project_root}/$g->{example_file}'.

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

1;

=head1 NAME

Egg::Helper::R::FastCGI - Helper for Egg::Request::FastCGI.

=head1 SYNOPSIS

  cd MYPROJECT/bin
  
  ./myproject_helper.pl R:FastCGI

=head1 DESCRIPTION

Please see the document of L<Egg::Request::FastCGI> in detail.

=head1 SEE ALSO

L<Egg::Request::FastCGI>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
---
filename: bin/dispatch.fcgi
permission: 0755
value: |
  #!<# perl_path #>
  package <# project_name #>::trigger;
  BEGIN {
    $ENV{<# uc_project_name #>_REQUEST_CLASS} ||= 'Egg::Request::FastCGI';
    };
  use lib qw{ <# project_root #>/lib };
  use <# project_name #>;
  
  <# project_name #>->handler;
---
filename: <# example_file #>
value: |
  
  > For Apache.
  
  まだ Apache でのテストは完了していません。
  
  * Please see http://www.fastcgi.com/docs/faq.html.
  
  
  > For Lighttpd.
  
  server.document-root = "/home/Egg/Forum/htdocs"
  url.rewrite-once = (
    "^/([A-Za-z0-9_\-\+\:\%/]+)?(\.html)?([\?\#].+?)?$"
      => "/dispatch.fcgi/$1$2$3",
    )
  fastcgi.server = ( "dispatch.fcgi" => ((
      "socket"   => "<# project_root #>/tmp/fcgi.socket",
      "bin-path" => "<# project_root #>/htdocs/dispatch.fcgi",
  #    "min-procs" => 1,
  #    "max-procs" => 3,
  #    "idle-timeout" => 20
  #    ))
    )
  
  # * Please see http://www.lighttpd.net/.
