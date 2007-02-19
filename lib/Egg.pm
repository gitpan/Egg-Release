package Egg;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Egg.pm 203 2007-02-19 14:46:38Z lushe $
#
use strict;
use warnings;
use Class::C3;
use UNIVERSAL::require;
use Egg::GlobalHash;
use Egg::Exception;
use base qw{ Class::Accessor::Fast };

our $VERSION= '1.02';

__PACKAGE__->mk_accessors
  (qw{ namespace request response dispatch backup_action });

*req  = \&request;
*res  = \&response;
*d    = \&dispatch;
*flags= \&global;
*is_engine  = \&engine_class;
*is_dispatch= \&dispatch_calss;
*is_request = \&request_class;
*is_response= \&response_class;

our $CRLF= "\015\012";
our $MOD_PERL_VERSION= 0;

local $SIG{__WARN__};

sub import {
	no strict 'refs';  ## no critic
	my $Name= caller(0) || return 0;
	return if ($Name eq 'main' || ++${"$Name\::IMPORT_OK"}> 1);
	my($e, @args)= @_;
	my(@requires, @plugins, %plugin_class, %config, %global);
	${"$Name\::__EGG_CONFIG"} = \%config;
	${"$Name\::__EGG_GLOBAL"} = \%global;
	${"$Name\::__EGG_PLUGINS"}= \@plugins;
	${"$Name\::__EGG_PLUGIN_CLASS"}= \%plugin_class;
	my %flags= ( MOD_PERL_VERSION=> 0 );
	for (@args) {
		if (/^\-(.+)/) {
			$flags{lc($1)}= 1;
		} else {
			my $plugin= /^\+([A-Z].+)/ ? do {
				push @plugins, $1;
				$plugin_class{$1}= $1;
			  }: do {
				push @plugins, $_;
				$plugin_class{$_}= "Egg::Plugin::$_";
			  };
			push @requires, $plugin;
			push @{"$Name\::ISA"}, $plugin;
		}
	}
	push @{"$Name\::ISA"}, __PACKAGE__;
	tie %global, 'Egg::GlobalHash', \%flags;
	$_->require or die $@ for @requires;

	*{"$Name\::debug_out"}= sub { } unless $flags{debug};
}
sub __egg_setup {
	my $class= shift;
	$class= ref($class) if ref($class);
	$class eq __PACKAGE__ and die q/Mistake of call method./;

	local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };

	my $conf;
	{
		no strict 'refs';  ## no critic
		$conf= ${"$class\::__EGG_CONFIG"}= shift
		   || Egg::Error->throw('I want configuration.');
		my $accessors= $conf->{accessor_names} || [];
		for my $accessor (qw{ template }, @$accessors) {
			*{__PACKAGE__."::$accessor"}= sub {
				my $egg= shift;
				$egg->stash->{$accessor}= shift if @_> 0;
				$egg->stash->{$accessor};
			  };
		}
	  };

	$conf->{root} || die "I want you to setup 'root'.";
	(-e $conf->{root} && -d _) || die "Path 'root' is not found.";
	$conf->{root}=~s{/+$} [];

	for ([qw{ content_type }, 'text/html; charset=euc-jp'],
	  [qw{ template_extention .tt }],  [qw{ template_default_name index }],
	  [qw{ max_snip_deep 5 }],  [qw{ content_language ja }],
	  [qw{ static htdocs }],    [qw{ static_uri / }],
	  ) {
		$conf->{$_->[0]} ||= $_->[1];
	}
	for ([qw{ etc etc }], [qw{ temp tmp }],
	  [qw{ cache cache }], ['lib', "lib/$class"]) {
		$conf->{$_->[0]}= "$conf->{root}/$_->[1]";
	}
	$conf->{static_uri}=~s{/+$} [];
	$conf->{static_uri}=
	  "/$conf->{static_uri}" unless $conf->{static_uri}=~m{^/};

	$conf->{template_extention}= ".$conf->{template_extention}"
	   unless $conf->{template_extention}=~/^\./;
	$conf->{template_path}
	  || Egg::Error->throw("I want you to setup 'template_path'");
	$conf->{template_path}= [$conf->{template_path}]
	   unless ref($conf->{template_path}) eq 'ARRAY';
	for (@{$conf->{template_path}}) {
		s{/+$} [];
		$_= "$conf->{root}/$_" unless m{^/};
	}

	my $e= bless { namespace=> $class }, $class;
	my $G= $e->global;
	my $ucName = uc($class);

	my $engine= $G->{ENGINE_CLASS}=
	     $ENV{"$ucName\_ENGINE"}
	  || $ENV{"$ucName\_ENGINE_CLASS"}
	  || $conf->{engine_class}
	  || 'Egg::Engine::V1';
	{
		no strict 'refs';  ## no critic
		push @{"$class\::ISA"}, $engine;
	  };
	$engine->require or Egg::Error->throw($@);
	$e->debug_out("# + Egg-$class Start!!");
	$engine->startup($e);
	$e->debug_out("# + engine-class : $engine-". $engine->VERSION);

	my $unload;
	my $dispath= $G->{DISPATCH_CLASS}=
	    ($ENV{"$ucName\_DISPATCHER"}
	      ? qq{Egg::Dispatch::$ENV{"$ucName\_DISPATCHER"}}: 0)
	 || ($unload= $ENV{"$ucName\_UNLOAD_DISPATCHER"})
	 || $ENV{"$ucName\_CUSTOM_DISPATCHER"}
	 || ($e->config->{dispatch_class}
	      ? qq{Egg::Dispatch::$e->config->{dispatch_class}}: 0)
	 || 'Egg::Dispatch::Runmode';
	$dispath->require or Egg::Error->throw($@) unless $unload;
	$dispath->_setup($e);

	my $request= $G->{REQUEST_CLASS}=
	  $ENV{"$ucName\_REQUEST"} ? do { $ENV{"$ucName\_REQUEST"};
	    }:
	  $ENV{"$ucName\_REQUEST_CLASS"} ? do { $ENV{"$ucName\_REQUEST_CLASS"};
	    }:
	  $conf->{request_class} ? do {
		$conf->{request_class};
	    }:
	  ($ENV{MOD_PERL} && ModPerl::VersionUtil->require) ? do {
	  	$MOD_PERL_VERSION= ModPerl::VersionUtil->mp_version;
		  ModPerl::VersionUtil->is_mp2  ? 'Egg::Request::Apache::MP20'
		: ModPerl::VersionUtil->is_mp19 ? 'Egg::Request::Apache::MP19'
		: ModPerl::VersionUtil->is_mp1  ? 'Egg::Request::Apache::MP13'
		: do {
			$e->debug_out('Unsupported mod_perl version:$MOD_PERL_VERSION');
			$MOD_PERL_VERSION= 0;
			'Egg::Request::CGI';
		  };
	    }: do {
		'Egg::Request::CGI';
	    };
	$request->require or Egg::Error->throw($@);
	$request->setup($e);

	my $response= $G->{RESPONSE_CLASS}=
	    $ENV{"$ucName\_RESPONSE"}
	 || $ENV{"$ucName\_RESPONSE_CLASS"}
	 || $conf->{response_class}
	 || 'Egg::Response';
	$response->require or Egg::Error->throw($@);
	$response->setup($e);

# They are the plugin other setups.
	$e->setup;
}
my $count;
sub __warning_setup {
	my $class= shift;
	$SIG{__WARN__}= shift || sub {
		my $err= shift || 'warning.';
		my @ca = caller(0);
		   @ca = caller(1) if $ca[0]=~/^Egg\::Debug\::Log/;
		   $ca[2] ||= '*';
		print STDERR ++$count. ": $ca[0]: $ca[2] - $err";
	  };
}
sub new {
	my $class= shift;
	my $r    = shift || undef;
	my $e= bless {
	  finished=> 0, namespace=> $class,
	  snip => [], stash=> {}, model=> {}, view => {}, action=> [],
	  }, $class;
	my $request = $e->request_class
	  || Egg::Error->throw('Request Class cannot be acquired.');
	my $response= $e->response_class
	  || Egg::Error->throw('Response Class cannot be acquired.');
	$e->request( $request->new($e, $r) );
	$e->response( $response->new($e) );
	$e;
}
sub engine_class   { $_[0]->global->{ENGINE_CLASS}   }
sub dispatch_calss { $_[0]->global->{DISPATCH_CLASS} }
sub request_class  { $_[0]->global->{REQUEST_CLASS}  }
sub response_class { $_[0]->global->{RESPONSE_CLASS} }
sub debug { $_[0]->flag('debug') }

{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	sub config  { ${"$_[0]->{namespace}::__EGG_CONFIG"}  }
	sub global  { ${"$_[0]->{namespace}::__EGG_GLOBAL"}  }
	sub plugins { ${"$_[0]->{namespace}::__EGG_PLUGINS"} }
	sub plugin_class { ${"$_[0]->{namespace}::__EGG_PLUGIN_CLASS"} }
	sub flag {
		my $e  = shift;
		my $key= shift;
		tied(%{${"$e->{namespace}::__EGG_GLOBAL"}})
		  -> flag_set ($key, @_) if @_;
		${"$e->{namespace}::__EGG_GLOBAL"}->{$key};
	}
  };

sub snip {
	my $e= shift;
	return $e->{snip} unless @_;
	my $array= ref($_[0]) ? $_[0]: do {
		$_[1] ? [@_]: return($e->{snip}->[$_[0]] || "");
	  };
	$e->{snip}= $array;
}
sub path {
	my $e= shift;
	my $lavel= shift || Egg::Error->throw('I want the label.');
	my $path = shift || Egg::Error->throw('I want the path.');
	my $base= $e->config->{$lavel}
	  || Egg::Error->throw('There is no value corresponding to the label.');
	$path=~s{^/+} [];
	"$base/$path";
}
sub action {
	my $e= shift;
	if (@_) { $e->{action}= ref($_[0]) eq 'ARRAY' ? $_[0]: [@_] }
	$e->{action} || undef;
}
sub stash {
	my $e= shift;
	return $e->{stash} unless @_;
	my $key= shift;
	$e->{stash}{$key}= shift if @_;
	$e->{stash}{$key};
}
#sub DESTROY {
#	my($e)= @_;
#	untie(%{$e->global}) if ($e->global && ref($e->global) eq 'HASH');
#}

1;

__END__

=head1 NAME

Egg - WEB application framework.

=head1 SYNOPSIS

First of all, the helper script is generated.

  #> perl -MEgg::Helper::Script -e "Egg::Helper::Script->out" > /path/to/bin/egg_helper.pl

And, the project is generated. 

  #> cd /path/to/work_dir
  #> /path/to/bin/egg_helper.pl project -p MYPROJECT

It moves to the generated directory.

  #> cd MYPROJECT
  #> ls -la
  drwxr-xr-x  ... bin
  -rw-r--r--  ... Build.PL
  drwxr-xr-x  ... cache
  -rw-r--r--  ... Changes
  ..
  ....

Trigger.cgi in bin is moved and it tests.

  #> cd bin
  #> ./trigger.cgi  or  perl trigger.cgi
  
  # << MYPROJECT v0.01 start. --------------
  # + request-path : /
  ..
  ....
  ......

If trigger.cgi doesn't output the error, the installation of the project is a 
success.

=head1 DESCRIPTION

Egg imitated and developed Catalyst.

It is WEB application framework of a simple composition. 

The plugin is compatible with Catalyst.
However, it is complete and not interchangeable.
Some should be likely to be corrected.

In addition, please see the document of L<Egg::Release> about detailed use.

Please see the document of Egg::Dispatch::Runmode about the notation of dispatch.

Egg::Release-1.00 reviewed at the time of beginning and rewrote the code.
Therefore, the content has changed fairly with the version before. 
In the plugin etc. , the up-grade might be needed.

It is the main change point as follows. 

=over 4

=item * Treatment of root by configuration.

The route of the project was shown.
* It was a route of the template before.

And, the treatment and the name changed to some items.

Please look at the chapter of CONFIGURATION in detail.

=item * Exclusion of encode.

All the encode method systems were excluded and it made it to the plugin. 

Please use Egg::Plugin::Encode.

=item * Addition of standard plugin.

  Cache::Memcached
  DBI::*
  Dispatch::AnyCall
  Encode
  FillInForm
  FormValidator::Simple
  Pod::HTML
  Redirect::Page
  Upload

The above was added to a standard plugin. 

=item * Some Hook are excluded. 

$e->action and $e->compress were excluded.

* The function of $e->action has changed.

=item * Making of engine subclass.

It is also easy to build in the engine of original development.
How to treat MODEL and VIEW can be customized.

=item * The treatment of the global variable severely

The superscription of the key that has been defined is observed.
However, it also has the loophole.

=item * Change in dispatch.

It was made to dispatch like CGI::Application. 
And, the function is enhanced by Tie::RefHash. 

Please see L<Egg::Dispatch::Runmode> in detail. 

=item * The helper rewriting.

The helper script moves like the framework. 
As a result, I think that it can easily make the supplementation functions of
 Model, View, and Plugin, etc.

Egg::Helper::PerlModuleMaker is made a standard as Egg::Helper::O::MakeMaker.

=item * VIEW corresponding to HTML::Mason was enclosed.

HTML::Mason is a very high performance template engine.

* Template ToolKit can be used by introducing Egg::View::TT.

=back

=head1 OPTIONS

The start option is given to Egg and the plugin and the flag are set.

  package MYPROJECT;
  use strict;
  use Egg qw{ -Debug Filter Upload };

* The one that - adheres to the head is treated as a flag.
The set value can be referred to with $e->flag('FLAG_NAME').

  use Egg qw{ -hoge };
  
  if ($e->flag('hoge')) { "hoge flag is true." }

* The continuing name is treated when + has adhered to the head and package
 name of the plugin is treated.

  use Egg qw{ +Catalyst::Plugin::FormValidator };

* It treats as a plugin of the package name modified by 'Egg::Plugin::' usually.

  use Egg qw{ Filter::EUC_JP };

  As for this, Egg::Plugin::Filter::EUC_JP is read.

=head1 CONFIGURATION

The setting can be treated by the YAML form in using the YAML plugin. 

  package MYPROJECT;
  use strict;
  use Egg qw{ YAML };
  
  my $config= __PACKAGE__->yaml_load('/path/to/MYPROJECT/etc/MYPROJECT.yaml');
  __PACKAGE__->__egg_setup( $config );

* The setting of the YAML form can be output by using the helper script.

  #> /path/to/MYPROJECT/bin/yaml_generator.pl

=head2 root

Directory that becomes root of project.

* How to treat is different from the version before '1.00'.

Default is none. * Indispensability.

=head2 static

Directory that arranges static contents like image data etc.

Please specify it by the relative path from 'root' or the absolute path.

Default is 'htdocs'.

=head2 static_uri

URL passing when 'static' is seen with WEB. (Absolute path without fail)

Default is '/'.

=head2 title

Title name of project.

Default is '[MYPROJECT_NAME]'.

=head2 template_default_name

Name of template used in index.

* The extension is not included.

Default is 'index'.

=head2 template_extention

Extension of template.

Default is '.tt'.

=head2 accessor_names

To make the accessor to $e->stash, the name is enumerated by the ARRAY reference.

Default is 'template'.

=head2 character_in

Character code used by internal processing. 

* When Egg::Plugin::Encode is used, it is necessary. 

Default is 'euc'.

=head2 content_language

Contents languages.

Default is 'jp'.

=head2 content_type

Default of contents headers

Default is 'text/html'.

=head2 max_snip_deep

Maximum of depth of request URL PATH.
* When this is exceeded, it is 403 FORBIDDEN is returned.

Default is '5'.

  OK  => http://domain/A/B/C/D/E/
  NG  => http://domain/A/B/C/D/E/F/

=head2 engine_class

When you want to use an original engine class.

Default is 'Egg::Engine::V1'.

=head2 request_class

When you want to use an original request class.

Default is 'Egg::Request::( CGI or Apache )'.

=head2 response_class

When you want to use an original response class. 

Default is 'Egg::Response'.

=head2 dispatch_class

When you want to use original Dispatch. 

Default is 'Egg::Dispatch::Runmode'.

=head2 MODEL

It sets it by the ARRAY reference concerning the MODEL.

* The first setting of ARRAY is treated most as a model of default.

Setting example:

  MODEL=> [
    [ 'MODEL1_NAME' => {
        config_param1=> '...',
        config_param2=> '...',
        ...
        },
      ],
    [ 'MODEL2_NAME' => {
        config_param1=> '...',
        config_param2=> '...',
        ...
        },
      ],
    ],

=head2 VIEW

The setting made a VIEW is done by the ARRAY reference.

* The first setting of ARRAY is treated most as a model of default.

* The setting becomes the same form as MODEL. 

=head2 plugin_[PLUGIN_NAME]

Setting read from plugin.

* The naming convention is not compelling it.
According to circumstances, it might be a quite different name. 

* Please see the document of the plugin used in detail.

=head1 METHODS

=head2 new

After the request and the response object are made, the Egg object is returned.

Nothing is done excluding this.
This is convenient to operate with the trigger excluding WEB such as cron.

  my $e= MYPROJECT->new;
  
  # Some components might not function if prepare is not called.
  $e->prepare_component;
  
  ... Freely now ...

=head2 __egg_setup ([CONFIGURATION])

Egg is set, and when starting, it sets it up.

Please call it from the control file of the project.

  use MYPROJECT;
  use MYPROJECT::Config;
  __PACKAGE__->__egg_setup( MYPROJECT::Config->out );

=head2 __warning_setup ([CODE_REFERENCE])

The output format etc. of warn can be customized.

  __PACKAGE__->__warning_setup;

=head2 namespace

The class name of the started project is returned.

=head2 snip ([NUM])

The value in which the request passing is delimited by / is returned
 by the ARRAY reference. 

  Request URL => http://domain/A/B/C/

  print $e->snip->[0];  => A
  print $e->snip->[1];  => B
  print $e->snip->[2];  => C

The dead letter character is returned when a specified value is undefined
 when [NUM] is given.

  $e->snip(1) eq 'B' ? 'OK': 'NG';

* Because it is not necessary to check a specified value whether is 11 
undefinitions and exists, it is convenient.

=head2 stash

The value to share between components of Egg can be put.

  $e->stash->{hoge}= 'foo';

=head2 dispatch  or  d

The dispatch object is returned.

When setting it up, the dispatch of specification is read. 

* The dispatch used by 'Dispatch_class' of environment variable
 '[PROJECT_NAME]_DISPATCHER' or the setting can be specified.
 The class name is modified by 'Egg::Dispatch'. 

* The dispatch used by environment variable '[PROJECT_NAME]_CUSTOM_DISPATCHER'
 can be specified. As for the class name, the specified name is used as it is.

* Dispatch to which require is not done by environment variable 
 '[PROJECT_NAME]_UNLOAD_DISPATCHER' can be specified. 
 As for the class name, the specified name is used as it is.

Default is 'Egg::Dispatch::Runmode'.

=head2 request  or  req

The request object is returned. 

When setting it up, an appropriate request class has been decided.

An original class can be set in 'Request_class' of the setting or environment
 variable '[PROJECT_NAME]_REQUEST'.

  package MYPROJECT;
  ...
  $ENV{MYPROJECT_REQUEST}= 'ORIGN::CUSTOM::Request';

Default is 'Egg::Request::CGI'.

=head2 response  or  res

The response object is returned.

An original class can be set in 'Response_class' of the setting or environment
 variable '[PROJECT_NAME]_RESPONSE'.

Default is 'Egg::Response'.

=head2 dispatch

After the object is generated with Egg::Engine::* it, the Dipatti object is
 returned. 

=head2 debug

The value of the debugging flag is returned.
 It is the same as $e->flag->('debug').

  if ($e->debug) { 'debug mode !!' }

=head2 dispatch_class

The read dispatch class name is returned.

=head2 request_class

The read request class name is returned. 

=head2 response_class

The read response class name is returned. 

=head2 config

The setting is returned.

The content is a global value.
It doesn't return to former value until the server is reactivated when the
 content is changed in mod_perl etc.

  $e->config->{config_name};

=head2 global

The HASH reference where a global value is preserved is returned.

Because the I/O of this HASH is observed by Egg::GlobalHash,
 the overwrited thing cannot be done the key that already exists.
However, it is only a key to one hierarchy that is observed.
It is possible to input and output freely concerning the second key.

Moreover, the key is always a capital letter of the alphabet.

In addition, please see the document of L<Egg::GlobalHash> in detail.

  # It enters without trouble if FUU_VALUE is undefined.
  $e->global->{FUU_VALUE}= 'boo';
  
  # The error has already occurred in this because FUU_VALUE has defined it.
  $e->global->{FUU_VALUE}= 'zuu';

=head2 flag ([FLAG_NAME])

The value of the flag given to the start option of Egg can be referred to.

* The key is sure to become an alphabetic small letter. Moreover, the value
 is not put.

head2 path ([CONFIG_KEY], [PATH])

Passing that combines a set value and the given passing is returned.

  print $e->path(qw{ temp hoo/zuu });  => /path/to/MYPROJECT/tmp/hoo/zuu

=head2 action

Passing information on the place in the request place actually processed
 returns by the ARRAY reference.

* The value of this method expects the thing set by dispatch.
  When dispatch doesn't set the value, undef is returned.

For instance, each request starts in Egg::Dispatch::Runmode as follows.

* If it is .. run_modes( home=> { _default=> sub { ... } } )

  http://domain/home/  => [ 'home', 'index' ]

The part of 'Index' is supplemented with the value of 'Template_default_name' 
of the setting. 

* run_modes( home=> { qr/ABC\d+/=> sub { ... } } )

  http://domain/home/ABC123/ => [ 'home', 'ABC123' ]

* Perhaps, this cannot specify the template. 

=head2 plugins

The list of the name of the read plugin is returned.

=head2 plugin_class

The name of the read plug-in is returned and the key and the package name
 return HASH of the value.

=head1 BUGS

The error occurs when Class::Accessor::Fast is succeeded to by the plugin module.
Measures against this are not made yet. 

This can be evaded by the thing assumed the $e->mk_accessors(...) with setup.

However, it is not a complete solution because there might be a demand from another plug-in 
that was previously called. 
There is a hand that substitutes Class::Data::Inheritable to deal with this.

  package MY_PLUGIN;
  sub setup {
    my($e)= @_;
    $e->mk_accessors(...);
  }

or

  package MY_PLUGIN;
  use base qw{ Class::Data::Inheritable };
  __PACKAGE__->mk_classdata($_) for qw{ .... };

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Engine>,
L<Egg::Engine::V1>,
L<Egg::Model>,
L<Egg::View>,
L<Egg::Request>,
L<Egg::Response>,
L<Egg::Dispatch::Runmode>,
L<Egg::Exception>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
