package Egg::Helper::Project::Test;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Test.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Helper::Project::Test - The operation test of Project Application is done.

=head1 SYNOPSIS

  # Test of GET request.
  perl MyApp/bin/myapp_tester.pl /
  
  # Test of POST request.
  perl MyApp/bin/myapp_tester.pl / -m post
  
  # The parameter is passed by the POST request.
  # * ./test-param.yaml is prepared beforehand.
  perl MyApp/bin/myapp_tester.pl / -m post -p ./test-param.yaml
  
  # The response contents are output.
  perl MyApp/bin/myapp_tester.pl / -r 1

=head1 DESCRIPTION

It is a helper module that tests the project application under making.

A virtual request is started when suitable URI is passed from the command line
of the console and doing project CGI is started.

Output debugging and error message are confirmed.

The source of output contents can be confirmed by specifying the option.

The script to start is bin/project_name_tester.pl output when the project is
generated. equest URI and the option are passed and tested to this script.

The following options are accepted.

=over 4

=item * -m

It is a request method. GET is requested at the unspecification.

=item * -r

The output contents are output to STDOUT.

=item * -p

To include the parameter at the POST request, the parameter file that wants 
to be passed by the YAML form is made, and the PATH is passed to this option.

  param1: test_ok1
  param2: test_ok2

If it wants to do the upload test, it should be defined that it becomes a
form passed to L<HTTP::Request::Common> that contains 'Content_Type' item.

  Content_Type: form-data
  Content:
    - param1
    - test_ok1
    - param2
    - test_ok2
    - upload1
      - /path/to/upload.txt
    - upload2
      - /path/to/upload.html

=back

=cut
use strict;
use warnings;
use WWW::Mechanize::CGI;
use YAML;

our $VERSION= '2.00';

sub _setup_get_options {
	shift->SUPER::_setup_get_options(" m-method= p-param= r-response= ");
}
sub _execute {
	my($self)= @_;
	my $g= $self->global;
	return $self->_output_help if $g->{help};

	my $uri  = $g->{any_name} || "/";
	my $pname= $self->project_name;
	my $proot= $self->project_root;
	unshift @INC, "$proot/lib";
	$pname->require or die $@;

	my $mech = WWW::Mechanize::CGI->new;
	$mech->cgi_application("$proot/bin/trigger.cgi");
	$mech->cgi( sub {
	  eval{ $pname->handler };
	  $@ and die $@;
	  });

	if ($g->{method}=~m{^P(?:OST)?}i) {
	## POST request.
		my $param= $g->{param} ? YAML::LoadFile($g->{param}): {};
		if ($param->{Content_Type}) {
			require HTTP::Request::Common;
			$mech->request( HTTP::Request::Common::POST($uri, %$param) );
		} else {
			$mech->post($uri, $param);
		}
	} else {
	## GET request.
		$mech->get($uri);
	}

	$g->{response}= 1 unless defined($g->{response});
	if (my $num= $g->{response}) {
		print $mech->content || "";
	}
	$mech;
}
sub _output_help {
	my $self= shift;
	my $msg = $_[0] ? "$_[0]\n": "";
	my $cmd_line;
	if (my $project= lc($self->project_name)) {
		$cmd_line= "# perl ${project}_tester.pl [URI] [OPTION]";
	} else {
		$cmd_line= "# perl egg_helper.pl Project::Test [URI] [OPTION]";
	}
	print <<END_HELP;

$msg$cmd_line

  OPTION:
    -m [ REQUEST_HETHOD_FLAG ( 0 => GET, 1 => POST ) default is 0 ]
    -p [ PARAMETER_FILE_PATH ]

* GET request is passed URI to script and execute.

* POST request writes and operates the macro.

END_HELP
	exit;
}

=head1 SEE ALSO

L<WWW::Mechanize::CGI>,
L<YAML>,
L<Egg::Helper>,
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
