package Egg::Helper::O::Test;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Test.pm 187 2007-02-17 07:29:15Z lushe $
#
use strict;
use warnings;
use IO::Scalar;
use File::Temp qw/tempdir/;
use base qw/Egg::Helper::O::Test::Prepare Egg::Component/;
use UNIVERSAL::require;
use Egg::Exception;

our $VERSION= '0.01';

local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };

__PACKAGE__->mk_accessors(qw/cleanup/);

*temp_path= \&out_path;
*env      = \&setup_env;
*catch    = \&response_catch;
*attach   = \&attach_request;
*egg      = \&egg_virtual;
*exec_cgi = \&exec_trigger;

sub new {
	my $self= shift->SUPER::new;
	$self->global->{out_path}= "";
	$self->cleanup(1);
	$self;
}
sub egg_virtual {
	my($self)= @_;
	my $pname= $self->project_name;
	$pname->require || die $@;
	$pname->new;
}
sub response_catch {
	my $self= shift;
	my $egg = shift || 0;
	if ($egg && ! ref($egg)) {
		if (@_) {
			my $data= ref($_[0]) ? $_[0]: {@_};
			$egg= $self->attach_request('POST', $egg, $data);
		} else {
			$self->setup_env($egg);
			undef($egg);
		}
	}
	$egg ||= $self->egg_virtual;
	$self->catch_stdout( sub { $egg->start_engine } );
}
sub response_catch2 {
	my $self= shift;
	my $egg = shift || die 'I want egg object.';
	$egg->dispatch  || die 'Please call it after $e->prepare_componet.';
	$self->catch_stdout( sub {
		$egg->dispatch->_start;
		$egg->response->body || $egg->dispatch->_action;
		$egg->finished || do {
			$egg->response->body || do {
				$egg->view->output($egg);
				$egg->response->status || $egg->response->status(200);
			  };
			$egg->dispatch->_finish;
		  };
		$egg->response->content_type
		  || $egg->response->content_type($egg->config->{content_type});
		$egg->finalize;
		$egg->output_content;
	  } );
}
sub catch_stdout {
	my $self= shift;
	my $code= shift || die 'I want code.';
	my $catch;
	eval {
		tie *STDOUT, 'IO::Scalar', \$catch;
		$code->(@_);
		untie *STDOUT;
	  };
	my $err= $@ || return \$catch;
	$self->error_win32_lowdown($err);
}
sub attach_request {
	my $self= shift;
	$ENV{REQUEST_METHOD}= uc(shift) || 'GET';
	my $url = shift || die 'I want URL';
	my $data= $_[0] ? (ref($_[0]) ? $_[0]: {@_}): {};
	$self->setup_env($url, $data->{ENV});
	if ($ENV{REQUEST_METHOD}=~/POST/) {
		delete($data->{ENV}) if $data->{ENV};
		HTTP::Request::Common->require;
		my $request= HTTP::Request::Common::POST($url, %$data);
		my $query  = $request->as_string;
		$query=~s{^POST[^\r\n]+\r?\n} [];
		$query=~s{Content\-Length\:\s+(\d+)\r?\n}
		          [ $ENV{CONTENT_LENGTH}= $1; "" ]e;
		$query=~s{Content\-Type\:\s+([^\n]+)\r?\n}
		          [ $ENV{CONTENT_TYPE}  = $1; "" ]e;
		my $egg;
		eval{
			tie *STDIN, 'IO::Scalar', \$query;
			my $egg= $self->egg_virtual;
			$egg->prepare_component;
			untie *STDIN;
		  };
		my $err= $@ || return $egg;
		$self->error_win32_lowdown($err);
	} else {
		my $egg= $self->egg_virtual;
		$egg->prepare_component;
		return $egg;
	}
}
sub error_win32_lowdown {
	my($self, $err)= @_;
	if ($self->is_win32) {
		print STDERR " Warning: $err \n";
		return 0;
	} else {
		die $err;
	}
}
sub setup_env {
	my $self= shift;
	my $url = shift || die 'I want request URL';
	my $data= $_[0] ? (ref($_[0]) ? $_[0]: {@_}): {};
	while (my($name, $value)= each %$data) {
		$ENV{uc($name)}= $value || "";
	}
	if ($url=~m{\?(.*?)$}) {
		$ENV{REQUEST_METHOD} ||= 'GET';
		$ENV{QUERY_STRING}= $1;
		$url=~s{\?.*?$} [];
	}
	if ($url=~m{^https\://}) {
		$ENV{HTTPS}= 'on' ;
		$ENV{SERVER_PORT}= 443;
	} else {
		$ENV{SERVER_PORT}= $url=~m{^http\://[^/\:]+\:(\d+)} ? $1: 80;
	}
	if ($url=~m{^https?\://([^/]+)}) {
		$ENV{SERVER_NAME}= $1;
		$url=~s{^https?\://[^/]+} [];
	}
	$ENV{SCRIPT_NAME}= $url;
	$ENV{REQUEST_METHOD}  ||= 'GET';
	$ENV{HTTP_USER_AGENT} ||= $self->project_name;
	$self;
}
sub exec_trigger {
	my($self)= @_;
	my $g= $self->global;
	$self->chdir($self->path_to('bin'));
	eval{
		if ($self->is_unix) {
			`./trigger.cgi`;
		} else {
			`$g->{perl_path} trigger.cgi`;
		}
	  };
	$self->chdir($g->{start_dir});
	$@ and die $@;
	return 1;
}
sub path_to {
	my $self= shift;
	my $path= shift || die 'I want path.';
	$path=~s{(^/+|/+$)} []go;
	$self->project_root."/$path";
}
sub project_name {
	my $self= shift;
	return $self->SUPER::project_name unless @_;
	return $self->SUPER::project_name(@_)
	    if $self->SUPER::project_name=~/\:/;
	Egg::Error->throw('The project_name cannot recurrently be called.');
}
sub project_root {
	my $self= shift;
	my $g= $self->global;
	return ($g->{project_root} || undef) unless @_;
	$g->{project_root} and die "'project_root' already exists.";
	$g->{project_root}= $self->path_regular(shift);
}
sub create_project_root {
	my $self = shift;
	my $pname= $self->project_name=~/\:/
	   ? $self->project_name( shift || 'EggVirtual')
	   : $self->project_name;
	my $g= $self->global;
	$g->{out_path} ||= $self->temp_dir;
	my $proot= "$g->{out_path}/$pname";
	$self->project_root($proot);
	-e $proot and Egg::Error->throw("'$proot' already exists.");
	$proot;
}
sub temp_dir {
	my($self)= @_;
	$self->global->{out_path}
	  || $ENV{EGG_TEST_TEMP} || tempdir( CLEANUP=> $self->cleanup );
}
sub file_view {
	my $self= shift;
	my $path= shift || die 'I want path.';
	$self->read_file($self->path_to($path));
}

1;

__END__

=head1 NAME

Egg::Helper::O::Test - It assists in the construction of the test environment for Egg.

=head1 SYNOPSIS

  use Test::More tests=> 3;
  use Egg::Helper;
  
  my $test= Egg::Helper->run('O::Test');
  
  # The test project environment is constructed.
  $test->prepare;
  
  # The object of the test project is acquired. 
  my $egg= $test->egg_virtual;
  
  # The environment variable for a virtual request is setup.
  $egg->setup_env('http://domain.name/hoge?param1=a1&param2=a2');
  
  # The use of the component of a virtual project is enabled.
  $egg->prepare_component;
  
  ok( $egg->request->params->{param1} eq 'a1' );
  
  # The output contents of a virtual project are acquired.
  ok( my $catch= $t->response_catch2($egg) );
  
  ok( $$catch );

=head1 DESCRIPTION

The construction of a virtual project and other assistances are done so that
this module may conveniently test the module related to Egg.

=head1 METHODS

The object of this module is received via Egg::Helper.

  my $test= Egg::Helper->run('O::Test');

=head2 preapre

The environment of a virtual project is temporarily constructed in the 
directory.

It is necessary to be called always first.

Please see the document of L<Egg::Helper::O::Test::Prepar> in detail.

=head2 egg_virtual

The object of a virtual project is returned.

=head2 cleanup (BOOLEAN)

The CLEANUP flag of File::Temp::tempdir is specified.

=head2 response_catch ([EGG_OBJECT] or [VR_URL], [DATA])

The output contents of a virtual project are returned by the SCALAR reference.

When URL is passed, setup_env is done.
Moreover, when [DATA] is passed, it is treated as POST request.

$e->start_engine is done and the output contents are acquired.
Therefore, please note uselessness even if [EGG_OBJECT] that did
$e->prepare_componet is passed.

Please use 'response_catch2' if you want the result the same as the expectation.

=head2 response_catch2 ([EGG_OBJECT])

The output contents of a virtual project are returned by the SCALAR reference.

Processing that omits $e->prepare_component because of $e->start_engine is done.
It is necessary to do [EGG_OBJECT]->prepare_component beforehand.

Moreover, if it wants the result of a specific request, it is necessary to do
setup_env beforehand.

=head2 catch_stdout ([CODE_REFERENCE])

The result of the output of [CODE_REFERENCE] to STDOUT is returned by the SCALAR
reference.

=head2 attach_request ([REQUEST_METHOD], [VR_URL], [DATA])

The object of a virtual project of the request processing ending is returned.
It is ,in a word, an object of the $e->prepare_component processing.

When [REQUEST_METHOD] is POST, the value of [DATA] becomes an option to pass
to L<HTTP::Request::Common>.

  my $egg= $test->attach_request( POST=> 'http://domain.name/test', {
    Content_Type=> 'form-data',
    Content=> [
      param1 => 'test',
      upload1=> ["/path/to/file1"],
      upload2=> ["/path/to/file2"],
      ],
    });

The option to pass to setup_env with the key named ENV can be defined in [DATA].

=head2 setup_env ([VR_URL], [DATA]);

The environment variable based on passed URL is setup.

HASH passed with [DATA] is developed with the environment variable. All keys are 
converted into the capital letter.

=head2 exec_trigger

'Trigger.cgi' that exists in bin of a virtual project is moved.

=head2 path_to ([PATH])

Passing that builds in the project route of a virtual project is returned.

  my $path= $test->path_to('test/test.txt');
  
  ok( $path eq $test->project_root ."/test/test.txt" );

=head2 project_name ([PROJECT_NAME])

The virtual project name is returned.

The project name can be specified by specifying [PROJECT_NAME].

However, a correct project name cannot be acquired in case of not being 
after 'prepare' or 'create_project_root' is called.

=head2 project_root

Passing the route of a virtual project is returned.

However, it is not possible to acquire it in case of not being after 'prepare'
or 'create_project_root' is called.

=head2 create_project_root ([PROJECT_NAME])

If the project name is undefined, 'project_root' is decided after 'project_name'
is defined, and temp_dir is acquired, and the passing is returned. 

If [PROJECT_NAME] unspecifies it, 'EggVirtual' becomes default.

The directory of 'project_root' has not been made in this processing yet.
Moreover, if 'project_root' already exists, the exception is generated.

=head2 temp_dir

The work passing is temporarily returned.

Passing specification can be set beforehand by environment variable 'EGG_TEST_TEMP'.
Default becomes passing generated with File::Temp::tempdir.

=head2 file_view ([PATH])

The content is returned reading the file of [PATH].

Please note the evaluation with path_to about [PATH].

  print $test->file_view('lib/MYPROJECT.pm');

=head1 SEE ALSO

L<File::Temp>,
L<Egg::Helper::O::Test::Prepare>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
