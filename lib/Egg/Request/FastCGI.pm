package Egg::Request::FastCGI;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FastCGI.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use FCGI;
use base qw{ Egg::Request::CGI };

our $VERSION = '0.02';

sub new {
	CGI::_reset_globals();
	shift->SUPER::new(@_);
}
sub setup {
	my($class, $e)= @_;
	$class->setup_config($e->config->{request});
	no strict 'refs';  ## no critic
	*{"Egg::handler"}= sub {
		shift;
		my $base= $e->namespace;
		my $fcgi= FCGI::Request();
		while ($fcgi->Accept>= 0) { $base->run }
	  };
}

1;

__END__

=head1 NAME

Egg::Request::FastCGI - FastCGI for Egg.

=head1 DESCRIPTION

It is necessary to install the FCGI module.

  perl -MCPAN -e 'install FCGI'

A necessary script is obtained by handling the helper of the project.

  cd MYPROJECT
  
  ./bin/mypoject_helper.pl R:FastCGI

* 'dispatch.fcgi' and the sample of the configuration are output by this.

dispatch.fcgi is done and copy is done to the web directory.

  cp ./bin/dispatch.fcgi  ./htdocs

The suitable permission that can be written from the WEB server temporary
is granted. This is for the socket.

  chmod 777 ./tmp

The configuration of the WEB server is setup.

For Apache.

  It apologizes.
  
  The test by Apache has not been completed yet.

* Please see http://www.fastcgi.com/docs/faq.html.

For Lighttpd.

   server.document-root = "/home/Egg/Forum/htdocs"
   fastcgi.server = ( "dispatch.fcgi" => ((
      "socket"   => "/PROJECT_ROOT/tmp/fcgi.socket",
      "bin-path" => "/PROJECT_ROOT/htdocs/dispatch.fcgi",
  #   "min-procs" => 1,
  #   "max-procs" => 3,
  #   "idle-timeout" => 20
      ))

* Only when it is this, it is necessary to call __PACKAGE__->mode_param by
  'lib/MYPROJECT/D.pm'.

Or,

  $HTTP["host"] == "domain.name" {
    server.document-root = "/home/Egg/Forum/htdocs"
    url.rewrite-once = (
      "^/([A-Za-z0-9_\-\+\:\%/]+)?(\.html)?([\?\#].+?)?$"
        => "/dispatch.fcgi/$1$2$3",
      )
    fastcgi.server = ( "/dispatch.fcgi" => ((
        "socket"   => "/PROJECT_ROOT/tmp/fcgi.socket",
        "bin-path" => "/PROJECT_ROOT/htdocs/dispatch.fcgi",
        ))
      )
    }

If it is this, it is possible to use it with URI when Apache::Handler is used.

* Please see http://www.lighttpd.net/.

=head1 BUGS

It did not move vomiting the following errors in lighttpd of Windows.

  2007-02-20 15:13:15: (mod_fastcgi.c.3366) fcgi: got a FDEVENT_ERR. Don't know why.

Installed lighttpd is lighttpd-1.4.9-win-setup.exe.

* Is there incompleteness in this module or whether it is a bug of the servers
  end doesn't understand the place today.

=head1 SEE ALSO

L<FCGI>,
L<Egg::Request>,
L<Egg::Request::CGI>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
