package Egg;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Egg.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg - WEB Application Framework.

=head1 SYNOPSIS

  # The helper script is generated.
  perl -MEgg::Helper -e 'Egg::Helper->out' > egg_helper.pl
  
  # The project is generated.
  perl egg_helper.pl Project MyApp
  
  # Confirming the operation of project.
  ./MyApp/bin/tirigger.cgi
  
  # The project object is acquired.
  use lib './MyApp/lib';
  require MyApp;
  
  my $e= MyApp->new;

=head1 DESCRIPTION

Egg is WEB application framework.

The composition of the module operates at comparatively simply and high speed.

It is MVC framework of model and view and controller composition.

* It was a plug-in etc. and there were Catalyst and some interchangeability
  in the version before.
  Interchangeability was completely lost from the change of the method name
  in this version.
  However, there might not be transplant in the difficulty.

=head1 CONFIGURATION

The setting of the configuration of Egg is a method of passing HASH to the
method of 'egg_startup' directly and the definition. There is a method to
read to a semiautomatic target by it and 'Egg::Plugin::ConfigLoader'.

Please refer to the document of L<Egg::Plugin::ConfigLoader> for details.

=head2 root

Route PATH of project.

  * It is not route PATH of the template.
  * There is no default. Please set it.

=head2 title

Title of project.

Default is a class name of the project. 

=head2 content_type

Contents type used by default.

Default is 'text/html'.

=head2 content_language

Language used by default

There is no default.

=head2 template_extention

Extension of template used by default.

  * There is no '.' needing.

Default is 'tt'.

=head2 template_default_name

Template name used by default.

Default is 'index'.

=head2 static_uri

Route URI for static contents.

  * Please end by '/'.

Default is '/'.

=head2 template_path

Passing for template.

  * The thing set by the ARRAY reference can be done.
  * There is no default. Please set it.

=head2 dir

PATH setting of various folders.

=over 4

=item * lib

Local PATH where library of project is put.

Default is '< $e.root >/lib'.

=item * static

Local PATH where static contents are put.

Default is '< $e.root >/htdocs'.

=item * etc

For preservation of configuration file etc.

Default is '< $e.root >/etc'.

=item * cache

For preservation of cash data.

Default is '< $e.root >/cache'.

=item * template

The main template depository.

Default is '< $e.root >/root'.

=item * comp

Template depository for include.

Default is '< $e.root >/comp'.

=item * tmp

Temporary work directory PATH.

Default is '< $e.root >/tmp'.

=item * lib_project

Project directory PATH in dir->{lib}.

Egg compulsorily sets it based on the value of dir->{lib}.

=item * root

Copy of root.

=back

=head2 accessor_names

The accessor to stash is generated with the set name.

=head2 MODEL

It is a setting of MODEL. As for the content, the setting of each MODEL becomes
ARRAY further by ARRAY, too.
The setting of the first is treated as MODEL of default.

  MODEL => [
    [ DBI => {
      dsn  => '.....',
      user => '...',
      ...
      } ],
    ],

=head2 VIEW

It is a setting of VIEW. As for the content, the setting of each VIEW becomes
ARRAY further by ARRAY, too.
The setting of the first is treated as VIEW of default.

  VIEW => [
    [ Mason => {
      comp_root => [ ... ],
      data_dir  => '...',
      } ],
    ],

=head2 ... others.

Please refer to the module document of each object for other settings.

=cut
use strict;
use warnings;
use Egg::Request;
use Egg::Response;
use base qw/Egg::Base/;
use Carp qw/croak confess/;

our $VERSION= '2.00';

=head1 METHODS

=head2 namespace

The project name under operation is returned.

=head2 config

Configuration is returned by the HASH reference.

=head2 request

The request object is returned.

=over 4

=item * Alias: req

=back

=head2 response

The response object is returned.

=over 4

=item * Alias: res

=back

=cut
__PACKAGE__->mk_accessors(qw/ namespace request response /);

*req= \&request;
*res= \&response;

=head2 dispatch

The dispatch object is returned.

* It is necessary to load the plug-in with the dispatch method.
  Egg::Plugin::Dispatch::Standard and Egg::Plugin::Dispatch::Fast are prepared
  by the standard.

=head2 log

The log object is returned.

* When the plugin with the log method is not loaded, Egg::DummyLog is used.
  - new, notes, debug, error

=cut
sub log { $_[0]->{Log} ||= Egg::DummyLog->new }

sub import {
	my $project= caller(0) || return 0;

	no strict 'refs';  ## no critic
	return if ($project eq 'main' or $project eq __PACKAGE__);

	my %g= ( egg_plugins => [] ); shift;
	for (@_) {
		if (/^\-(.+)/) {
			$g{'-'. lc($1)}= 1;
		} else {
			my $p_class= /^\+([A-Z].+)/ ? $1: "Egg::Plugin::$_";
			push @{$g{egg_plugins}}, $p_class;
			push @{"${project}::ISA"}, $p_class;
		}
	}
	push @{"${project}::ISA"}, __PACKAGE__;

	$_->require or confess($@) for @{$g{egg_plugins}};
	@{$project->global}{keys %g}= values %g;
}

=head2 egg_startup ( [CONFIG_HASH] )

Necessary for operating the project prior is prepared.

CONFIG_HASH is set to 'config' method.
If L<Egg::Plugin::ConfigLoader> is loaded, it is CONFIG_HASH omissible.
However, it is a thing that the configuration file is arranged in an 
appropriate place in this case.

  __PACKAGE__->egg_startup;

=cut
sub egg_startup {
	my $project= shift;
	   $project= ref($project) if ref($project);
	   $project eq __PACKAGE__ and die q/Mistake of call method./;
	   $project->mk_classdata('config');

	my $conf= $project->config( $project->_load_config(@_) );
	my $g   = $project->global;
	my $e   = bless { namespace=> $project }, $project;

	if ($e->debug) {
		print STDERR <<END_INFO;
#----------------------------------------
# >> Egg - $project : startup !!
# + $project - load plugins :
END_INFO
		print STDERR "#   ". join("\n#   ", map{ "- $_ v". $_->VERSION }
		                         @{$g->{egg_plugins}}) || "..... none.";
		print STDERR "\n";
		no strict 'refs';  ## no critic
		no warnings 'redefine';
		*{"${project}::debug_out"}= sub { shift->debugging->notes(@_) };
	}
	for my $method (qw/ dispatch debugging /) {
		$e->can($method) and next;
		warn qq{ '$method' method is not found. };
	}

	# Check on base configuration.
	$conf->{title} ||= $project;
	$conf->{content_type} ||= 'text/html';
	$conf->{template_extention} ||= 'tt';
	$conf->{template_extention}=~s{^\.+} [];
	$conf->{template_default_name} ||= 'index';
	$conf->{static_uri} ||= "/";
	$conf->{static_uri}.= '/' unless $conf->{static_uri}=~m{/$};

	# Check on directory configuration.
	$conf->{root} || die q{ I want 'root' configuration. };
	$conf->{root}=~s{[\\\/]+$} [];
	{
		my $path= $conf->{template_path}
		   || die q{ I want 'template_path' configuration. };
		my @path;
		for (ref($path) eq 'ARRAY' ? @$path: $path) {
			s{[\\\/]+$} [];  push @path, $_;
		}
		$conf->{template_path}= \@path;

		my $dir= $conf->{dir} || die q{ I want 'dir' configuration. };
		for (qw{ lib static etc cache tmp template comp }) {
			$dir->{$_} || die qq{ I want 'dir -> $_' configuration. };
			$dir->{$_}=~s{[\\\/]+$} [];
		}
		$dir->{lib_project}= "$dir->{lib}/$project";
		$dir->{root}= $conf->{root};
		$dir->{temp}= $dir->{tmp};
	  };

	{
		no strict 'refs';  ## no critic
		no warnings 'redefine';

		# Constructor for project.
		*{"${project}::new"}= sub {
			my $pr= shift;
			my $r = shift || undef;
			my $egg= bless {
			  finished  => 0,
			  namespace => $pr,
			  config    => $conf,
			  snip  => [],  stash => {},
			  model => {},  view  => {},
			  }, $pr;
			$egg->request( $g->{REQUEST_PACKAGE}->new($r, $egg) );
			$egg->response( Egg::Response->new($egg) );
			$egg;
		  };

		# Create Stash Accessor.
		my $accessors= $conf->{accessor_names} || [];
		for my $accessor ('template', @$accessors) {
			*{__PACKAGE__."::$accessor"}= sub {
				my $egg= shift;
				return $egg->stash->{$accessor} || "" unless @_;
				$egg->stash->{$accessor}= shift || "";
			  };
		}

		# Model and View setup.
		for my $c_name (qw{ model view }) {
			my($uc_name, $lc_name, $uf_name)=
			  (uc($c_name), lc($c_name), ucfirst($c_name));
			my(@class, %class, %config);
			$conf->{$c_name}= \%config;

=head2 is_model ( [MODEL_NAME] )

If specified MODEL is loaded, the package name is returned.

=head2 is_view ( [VIEW_NAME] )

If specified VIEW is loaded, the package name is returned.

=cut
			*{__PACKAGE__."::is_${c_name}"}= sub {
				my $egg = shift;
				my $name= shift || return 0;
				$class{$name} || 0;
			  };

=head2 models

The loaded MODEL name list is returned by the ARRAY reference.

=head2 views

The loaded VIEW name list is returned by the ARRAY reference.

=cut
			*{__PACKAGE__."::${c_name}s"}= sub { \@class };

=head2 model_class

The loaded MODEL management data is returned by the HASH reference.

=head2 view_class

The loaded VIEW management data is returned by the HASH reference.

=cut
			*{__PACKAGE__."::${c_name}_class"}= sub { \%class };

			## '_prepare_model' and '_prepare_view' Method.
			*{__PACKAGE__."::_prepare_${c_name}"}= sub {
				my($egg)= @_;
				for (@class) {
					my $pkg= $class{$_} || next;
					my $pre= $pkg->can('_prepare') || next;
					$egg->{$c_name}{$_}= $pre->($pkg, $egg) || next;
				} 1;
			  };

=head2 regist_model ( [MODEL_NAME], [PACKAGE_NAME], [INCLUDE_FLAG] )

The use of specified MODEL is enabled.

* MODEL_NAME is not omissible.

* PACKAGE_NAME is an actual package name of object MODEL.
  Egg::Model::[MODEL_NAME] is used when omitting it.

* If INCLUDE_FLAG is true, require is done at the same time.

  $e->regist_model('MyModel', 'MyApp::Model::MyModel', 1);

=head2 regist_view ( [VIEW_NAME], [PACKAGE_NAME], [INCLUDE_FLAG] )

The use of specified VIEW is enabled.

* VIEW_NAME is not omissible.

* PACKAGE_NAME is an actual package name of object VIEW.
  Egg::View::[VIEW_NAME] is used when omitting it.

* If INCLUDE_FLAG is true, require is done at the same time.

  $e->regist_view('MyView', 'MyApp::View::MyView', 1);

=cut
			*{__PACKAGE__."::regist_${lc_name}"}= sub {
				my $egg = shift;
				my $name= shift || croak qq{ I want regist_$c_name 'name'.};
				my $pkg = shift || "Egg::${uf_name}::$name";
				$pkg->require or croak $@ if $_[0];
				($class{$name} || $class{lc($name)})
				   and croak qq{ Tried to redefine $uc_name name. };
				push @class, $name;
				$class{$name}= $pkg;
			  };

=head2 default_model ( [MODEL_NAME] )

The MODEL name of default is returned.
* A high setting of the priority level defaults most and it is treated.

When MODEL_NAME is specified, default is temporarily replaced.

=head2 default_view ( [VIEW_NAME] )

The VIEW name of default is returned.
* A high setting of the priority level defaults most and it is treated.

When VIEW_NAME is specified, default is temporarily replaced.

=cut
			my $default= "default_${c_name}";
			*{__PACKAGE__."::$default"}= sub {
				my $egg= shift;
				return do { $egg->{$default} ||= $class[0] || 0 } unless @_;
				my $name= $class{lc($_[0])}  || return 0;
				$_[0]->{$default}= $name;
			  };

=head2 model ( [MODEL_NAME] )

The object of specified MODEL is returned.

When MODEL_NAME is omitted, the MODEL object of default is returned.

=head2 view ( [VIEW_NAME] )

The object of specified VIEW is returned.

When VIEW_NAME is omitted, the VIEW object of default is returned.

=cut
			*{__PACKAGE__."::${c_name}"}= sub {
				my $egg= shift;
				if (my $key= lc($_[0])) {
					$egg->{$c_name}{$key} || do {
						my $obj= $egg->_create_comps($c_name, @_);
						$egg->{$c_name}{$key}= $obj;
					  };
				} else {
					$egg->{$c_name}{lc($egg->$default)}
					  ||= $egg->_create_comps($c_name, $egg->$default);
				}
			  };

			## MODEL and VIEW setup.
			if (my $list= $conf->{$uc_name}) {
				my $regist= "regist_${lc_name}";
				for (@$list) {
					$e->$regist($_->[0], 0, 1);
					$config{$_->[0]}= $_->[1];
				}
			}

			for my $name (@class) {
				my $pkg= $class{$name} || next;
				my $set= $pkg->can('_setup') || next;
				$set->($pkg, $e, $config{$name});
			}
			if ($e->debug and @class) {
				$e->debug_out( "# + $project - load $c_name : "
				. join(", ", map{"$_ v". ${"$class{$_}::VERSION"}}@class));
			}

		}
	  };

	Egg::Request->_startup($e);
	Egg::Response->_startup($e);

	# They are the plugin other startup and setups.
	$e->_setup;
}
sub _setup {
	my($e)= @_;

	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{"$e->{namespace}::_start_engine"}=
	   $e->debug ? \&_start_engine_debug: \&_start_engine_real;

	$e;
}

=head2 run

The project is completely operated, and the result code is returned at the end. 

* Do not call this method from the code inside of the project.

=cut
sub run {
	my $class= shift;
	my $e= $class->new(@_);
	eval { $e->_start_engine };
	if ($@) {
		$e->error($@);
		$e->_finalize_error;
	}
	$e->_finalize_result;
}

=head2 stash ( [KEY_NAME] )

The value of the common data specified with KEY_NAME is returned.

When KEY_NAME is omitted, the common data is returned by the HASH reference. 

=cut
sub stash {
	my $e= shift;
	return $e->{stash} unless @_;
	my $key= shift;
	@_ ? $e->{stash}{$key}= shift : $e->{stash}{$key};
}

=head2 flag ( [FLAG_NAME] )

The value of the flag specified with FLAG_NAME is returned.

=cut
sub flag {
	my $e  = shift;
	my $key= lc(shift) || return (undef);
	   $key= "-$key" unless $key=~/^-/;
	$e->global->{$key} || (undef);
}

=head2 path ( [CONF_KEY], [PATH] )

The result of combining the value of $e-E<gt>config-E<gt>{dir} specified with
CONF_KEY with PATH is returned.

  $e->path('static', 'images/any.png'); => /path/to/myapp/htdocs/images/any.png

=cut
sub path {
	my $e= shift;
	my $lavel= shift || croak q{ I want the label. };
	my $path = shift || return $e->config->{dir}{$lavel};
	my $base= $e->config->{dir}{$lavel}
	  || croak q{ There is no value corresponding to the label. };
	$path=~s{^/+} [];
	"$base/$path";
}

=head2 uri_to ( [URI], [ARGS_HASH] )

The URI object generated based on [URI] is returned.

The URI object of the query_form setting when ARGS_HASH is passed is returned.

=cut
sub uri_to {
	my $e  = shift;
	my $uri= shift || croak q{ I want base URI };
	my $result= URI->new($uri);
	return $result unless @_;
	my %arg= ref($_[0]) eq 'HASH' ? %{$_[0]}: @_;
	$result->query_form(%arg);
	$result;
}

=head2 page_title ( [TITLE_STRING] )

The value set to $e-E<gt>dispatch-E<gt>page_title is returned.
$e-E<gt>config-E<gt>{title} is returned if there is no setting.

The title can be set by passing TITLE_STRING.

=cut
sub page_title {
	my $e= shift;
	if (my $title= $e->dispatch->page_title(@_)) {
		return $title;
	} else {
		return $e->config->{title} || "";
	}
}

=head2 finished ( [RESPONSE_STATUS], [ERROR_MSG] )

$e-E<gt>reqonse-E<gt>status is set when RESPONSE_STATUS is passed and finished
is made effective.

RESPONSE_STATUS is 500 or $e-E<gt>log-E<gt>error is done any more.
At this time, if ERROR_MSG has been passed, it is included in the argument.

0 It is $e-E<gt>reqonse-E<gt>status(0) when is passed, and finished is
invalidated.

=cut
sub finished {
	my $e= shift;
	return $e->{finished} || undef unless @_;
	if (my $status= shift) {
		$e->response->status($status);
		if (@_) {
			if    ($status>= 500) { $e->log->error($status, @_) }
##			elsif ($status>= 400) { $e->log->debug($status, @_) }
		}
		return $e->{finished}= 1;
	} else {
		$e->response->status(0);
		return $e->{finished}= 0;
	}
}

=head2 snip

$e-E<gt>request-E<gt>snip is returned. 

=cut
sub snip { shift->request->snip(@_) }

=head2 action

$e-E<gt>dispatch-E<gt>action is returned.

=cut
sub action { shift->dispatch->action(@_) }

=head2 debug

The state of the debugging flag is returned.

=cut
sub debug  { $_[0]->global->{'-debug'} || 0 }

=head2 mp_version

$Egg::Request::MP_VERSION is returned.

=cut
sub mp_version { $Egg::Request::MP_VERSION  }

=head2 debug_out ( [MESSAGE] )

If the debugging flag is effective, MESSAGE is output to STDERR.

Nothing is done usually.

=cut
sub debug_out { }

=head1 OPERATION METHODS

When the project module is read, Egg generates the handler method.
And, dynamic contents are output from the handler method via the following
method calls and processing is completed.

=head2 _start_engine

If $e-E<gt>debug is effective, it replaces with _ start_engine_debug.
After the call of each method, '_start_engine_debug' measures the execution time.
This measurement result is reported to STDERR at the end of processing.

=cut
sub _start_engine_real {
	my($e)= @_;
	$e->_prepare_model;
	$e->_prepare_view;
	$e->_prepare;
	$e->_dispatch_start;
	$e->_dispatch_action;
	$e->_dispatch_finish;
	$e->_finalize;
	$e->_finalize_output;
	$e;
}
sub _start_engine_debug {
	my($e)= @_;
	$e->debugging->report;
	my $bench= $e->{bench}= $e->debugging->simple_bench;
	   $bench->_settime;
	$e->_prepare_model;    $bench->stock('prepare_model');
	$e->_prepare_view;     $bench->stock('prepare_view');
	$e->_prepare;          $bench->stock('prepare');
	$e->_dispatch_start;   $bench->stock('dispatch_start');
	if (my $target= $e->dispatch->target_action) {
		$e->debug_out("# + dispatch action  : $target");
	}
	$e->_dispatch_action;  $bench->stock('dispatch_action');
	$e->_dispatch_finish;  $bench->stock('dispatch_finish');
	$e->_finalize;         $bench->stock('finalize');
	$e->_finalize_output;  $bench->stock('finalize_output');
	                       $bench->finish;
	$e;
}

=over 4

=item * _prepare_model

Prior because MODEL is operated is prepared.

=item * _prepare_view

Prior because VIEW is operated is prepared.

=item * _prepare

It is a prior hook for the plugin.

=cut
sub _prepare { $_[0] }

=item * _dispatch_start

It is a prior hook for dispatch.

If it is effective, $e-E<gt>finished has not already done anything.

=cut
sub _dispatch_start {
	$_[0]->{finished} || $_[0]->dispatch->_start;
	$_[0];
}

=item * _dispatch_action

It is a hook for correspondence action of dispatch.

If it is effective, $e-E<gt>finished has not already done anything.

If an appropriate template has been decided, and $e-E<gt>response-E<gt>body
is undefined, $e-E<gt>view-E<gt>output is done.

=cut
sub _dispatch_action {
	return $_[0] if $_[0]->{finished};
	$_[0]->dispatch->_action unless $_[0]->response->body;
	$_[0]->view->output if (! $_[0]->{finished} and ! $_[0]->response->body);
	$_[0];
}

=item * _dispatch_finish

It is a hook after the fact for dispatch.

If it is effective, $e-E<gt>finished has not already done anything.

=cut
sub _dispatch_finish {
	$_[0]->{finished} || $_[0]->dispatch->_finish;
	$_[0];
}

=item * _finalize

It is a hook after the fact for the plugin.

=cut
sub _finalize { $_[0] }

=item * _finalize_output

If it seems to complete the output of contents that are effective $e-E<gt>finished
and have defined $e-E<gt>response-E<gt>{header}, nothing is done.

Contents are output, and $e-E<gt>finished is set.

=back

=cut
sub _finalize_output {
	return $_[0]->debug_out("# + output_content: finished absolute already.")
	    if ($_[0]->{finished} and $_[0]->response->{header});
	my($e)   = @_;
	my $res  = $e->response;
	my $body = $res->body || \"";
	my $head = $res->header($body);
	$res->output($head, $body);
	$e->debug_out("# + Response headers :\n$$head");
	$e->finished( $res->status || 200 );
	$e;
}

=head2 _finalize_error

When some errors occur by '_start_engine', it is called.

The plug-in for which the processing when the error occurs is necessary 
prepares this method.

This method finally writes the log, and outputs contents for debugging.

=cut
sub _finalize_error  {
	my($e)= @_;
	$e->log->error
	   (($e->response->status || 500), ($e->errstr || 'Internal Error.'));
	$e->debugging->output;
	$e;
}

=head2 _finalize_result

They are the last processing most.

$e-E<gt>response-E<gt>result is called and the Result code is returned.

=cut
sub _finalize_result {
	my $result= $_[0]->response->result;
	return $result;
}

sub _create_comps {
	my $e   = shift;
	my $type= shift || return 0;
	my $name= shift || return 0;
	my $cmethod= "${type}_class";
	my $pkg = $e->$cmethod->{$name}
	       || $e->$cmethod->{lc($name)}
	       || confess "'$name' $type is not set up.";
	my $conf= $e->config->{$type}{$name}
	       || $e->config->{$type}{lc($name)}
	       || {};
	$pkg->can('ACCEPT_CONTEXT')
	   ? $pkg->ACCEPT_CONTEXT($e, $conf): $pkg->new($e, $conf);
}
sub _load_config {
	my $class= shift;
	my $conf = $_[0] ? (ref($_[0]) eq 'HASH' ? $_[0]: {@_})
	                 : croak q{ I want config };
	$class->replace_deep($conf, $conf->{dir});
	$class->replace_deep($conf, $conf);
	$conf;
}
sub _example_code { 'unknown.' }

package Egg::DummyLog;
use strict;
sub new { bless {}, shift }
sub notes { }
sub debug { }
sub error { }


=head1 SUPPORT

Distribution site.

  L<http://egg.bomcity.com/>.

sourcefoge project.

  L<http://sourceforge.jp/projects/egg/>.

=head1 SEE ALSO

L<Egg::Base>,
L<Egg::Request>,
L<Egg::Response>,
L<Egg::Model>,
L<Egg::View>,
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
