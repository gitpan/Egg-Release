package Egg::Request::FastCGI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FastCGI.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Request::FastCGI - Request class for FastCGI.

=head1 SYNOPSIS

Example is dispatch.fcgi

  BEGIN {
     $ENV{MYAPP_REQUEST_CLASS}= 'Egg::Request::FastCGI';
   };
  use MyApp;
  
  MyApp->handler;

=head1 DESCRIPTION

It is a request class for FastCGI.

It is necessary to install the FCGI module to use it.

=head1 HTTPD CONFIGURATION

'dispatch.fcgi' generated to the bin directory of the project is copied onto
a suitable place and the execution permission is granted.

=cut
use strict;
use warnings;
use FCGI;
use base qw/Egg::Request::CGI/;

our $VERSION = '2.00';

sub _setup_handler {
	my($class, $e)= @_;
	my $project= $e->{namespace};
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{"${project}::handler"}= sub {
		shift;
		my $fcgi= FCGI::Request();
		while ($fcgi->Accept>= 0) { $project->run }
	  };
	@_;
}

=head1 METHODS

=head2 new

Constructor.

=cut
sub new {
	CGI::_reset_globals();
	shift->SUPER::new(@_);
}

=head1 SEE ALSO

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

1;
