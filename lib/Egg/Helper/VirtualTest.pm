package Egg::Helper::VirtualTest;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: VirtualTest.pm 156 2007-05-21 03:39:31Z lushe $
#
use strict;
use warnings;
use File::Temp qw/tempdir/;
use Data::Dumper;
use Carp qw/croak/;
use base qw/Egg::Helper/;

our $VERSION = '2.03';

=head1 NAME

Egg::Helper::VirtualTest - The virtual test environment for Egg project.

=head1 SYNOPSIS

  use Egg::Helper::VirtualTest;
  
  my $vr= Egg::Helper::VirtualTest->new;
  
  $vr->prepare(
    controller   => { egg_includes => [qw/ AnyPlugin /] },
    create_files => \@files,
    config => {
      hoo  => '.....',
      hoge => '...',
      },
    );
  
  my $e= $vr->egg_context;
  
  my $mech= $vr->mech_get('/request_uri');
  print $mech->content;

=head1 DESCRIPTION

An executable virtual environment is constructed for the test of the Egg 
project.

A virtual environment can control the composition by HASH passed to the
prepare method.

Moreover, the result to a virtual request and the operation of the script 
are verifiable it according to WWW::Mechanize::CGI.

=cut

__PACKAGE__->mk_accessors(qw/ option /);

=head1 METHODS

=head2 new ( [OPTION_HASH] )

Constructor.

It comes to be able to access given OPTION_HASH by the option method. 

Suitable following initialize is done, and the object is returned.

=over 4

=item * project_name

If project_name of OPTION_HASH is undefined, 'VirtualTest' is set.

=item * start_dir

Current directory of execution.

=item * project_root

If temp_dir of OPTION_HASH is undefined, the work directory is acquired 
temporarily and set from L<File::Temp>.

=item * project_already

When project_root already exists when 'already_ok' of OPTION_HASH is 
undefined, the exception is generated.

=item * prepare

It passes it to the prepare method if there is prepare in OPTION_HASH.

=back

=cut
sub new {
	my $class = shift;
	my $option= ref($_[0]) eq 'HASH' ? $_[0]: {@_};
	my $self= bless { option => $option }, $class;
	$self->_initialize($option);
}
sub _initialize {
	my($self, $option)= @_;
	$SIG{__DIE__}= sub { Egg::Error->throw(@_) };
	my $pname= $self->project_name($option->{project_name} || 'VirtualTest');
	my $g= $self->global;

	$g->{start_dir}= $self->get_cwd;
	$g->{project_root} = $option->{temp_dir} || tempdir( CLEANUP=> 1 );
	$g->{project_root} =~s{[\\\/]+$} [];
	$g->{project_root}.= "/$pname";
	$g->{include_path} = " $g->{start_dir}/lib $g->{start_dir}/../lib";

	if (-e $g->{project_root}) {
		$option->{already_ok} || die q{ Project already exists. };
	} else {
		$self->create_dir($g->{project_root});
	}
	if (my $prepare= $option->{prepare}) {
		my $attr= ref($prepare) eq 'HASH' ? $prepare: {};
		$self->prepare($attr);
	}
	$self;
}

=head2 prepare ( [PREPAR_HASH] )

A virtual project is constructed according to PREPAR_HASH.

When PREPAR_HASH is omitted, all virtual projects are constructed with Defolt.

The item evaluated with PREPAR_HASH is as follows.

=over 4

=item * controller => [CONTROLLER_HASH]

Setting concerning controller.

The content evaluates the following items with HASH without fail.

=over 4

=item * egg => [PLUGIN_OR_FLAG_ARRAY]

The plugin and the flag that makes it load are specified with ARRAY.

Default is [qw/Dispatch::Standard Debugging Log/]

  controller => { egg => [qw/ Dispatch::Fast Debugging Log /] },

=item * egg_includes => [PLUGIN_OR_FLAG_ARRAY]

List of plugin and flag added to value of egg.

  controller => { egg_includes => [qw/ AnyPlugin /] },

=item * egg_debug => [BOOL]

'-Debug' is added to the list of the plugin and the flag.

  controller => { egg_debug => 1 },

=item * default_mode => [DEFAULT_MODEL]

Name of default_mode defined in default_mode.

  controller => { default_mode => 'default' },

=item * egg_dispatch_map => [DISPATCH_MAP_TEXT]

The setting of dispatch_map is set as it is in the text.

  my $dispatch_map= <<'END_MODE';
  
    _default => sub {},
    hoo => sub {
      my($self, $e)= @_;
      $e->template('document/hoo.tt');
      },
    hoge => sub {},
  
  END_MODE
  
  controller => { dispatch_map => $dispatch_map },

=item * egg_mode_param => [PARAM_NAME]

Name of mode_param defined in mode_param.

  controller => { mode_param => 'mode' },

=item * first_code = [CODE_TEXT]

Script code that wants to be included in controller's first half.

  my $first_code= <<'END_CODE';
  
  use MyApp::Tools;
  
  END_CODE
  
  controller => { first_code => $first_code },

=item * last_code => [CODE_TEXT]

Script code that wants to be included in controller's latter half.

  my $last_code = <<'END_CODE';
  
  sub last_code {
    my($self, $e)= @_;
    .........
    .....
    ..
  }
  
  END_CODE
  
  controller => { last_code => $last_code },

=item * version => [VERSION_NUMBER]

Version of controller who generates it. 

  controller => { version => '1.00' },

=back

=item * config => [CONFIG_HASH]

=over 4

=item * title => [TITLE_TEXT]

Default is $vr-E<gt>project_name.

=item * root => [PROJECT_ROOT_PATH]

Default is $vr-E<gt>project_root.

=item * template_path => [PATH_ARRAY]

Default is ["$vr-E<gt>project_root/root", "$vr-E<gt>project_root/comp"]

=item * VIEW => [VIEW_CONFIG_ARRAY]

Default is a setting of Template  (HTML::Template).

=item * default_view_mason => [BOOL]

Mason is set to VIEW if this value is effective when the setting of VIEW
is undefined.

=item * ... etc.

Additionally, please refer to the document of L<Egg> for details for the 
configuration.

=back

=item * create_files => [FILE_DATA_ARRAY]

A new file is generated according to FILE_DATA_ARRAY.

Each item of ARRAY is HASH passed to L<Egg::Helper>-E<gt>save_file.

 * Because generation does project_root to the starting point, filename
   can be specified by relativity PATH.

  create_files => [
    {
      filename => "etc/hoge.txt",
      value    => "<\$e.project_name> \n OK \n",
      },
    {
      filename => "bin/hoge.pl",
      filetype => "script",
      value    => "print 'OK';",
      },
    ],

=item * create_dirs => [DIR_LIST_ARRAY]

An empty directory is made according to DIR_LIST_ARRAY.

  create_dirs => [qw{ tmp/myapp cache/content/myapp }],

=back

=cut
sub prepare {
	my $self = shift;
	my $attr = ref($_[0]) eq 'HASH' ? $_[0]: {@_};
	my $pname= $self->project_name || croak q{ 'project name' is not setup. };
	my $proot= $self->project_root || croak q{ 'project root' is not setup. };
	my $g= $self->global;
	$self->{yaml_config}= $attr->{yaml_config} || 0;
	$self->_setup_module_maker( __PACKAGE__ );
	$self->_setup_controller($attr->{controller});
	$self->_setup_config($attr->{config});

	$self->{data_backup}= join('', <DATA>) unless $self->{data_backup};
	my @files= YAML::Load($self->{data_backup});
	seek DATA, 0, 0;
	if (my $create= $attr->{create_files}) {
		$create= [$create] unless ref($create) eq 'ARRAY';
		splice @files, 0, 0, @$create;
	}
	my @dirs = [ map{"$proot/$_"}(qw{ root cache etc comp tmp/uploads }) ];
	if (my $create= $attr->{create_dirs}) {
		$create= [$create] unless ref($create) eq 'ARRAY';
		splice @dirs, 0, 0, @$create;
	}
	$self->generate(
	  chdir        => [$proot, 1],
	  create_files => \@files,
	  create_dirs  => \@dirs,
	  errors       => { rmdir=> [$self->project_root, @dirs] },
	  ) || return 0;
	1;
}

=head2 disable_warn

$SIG{__WARN__}= sub {}.

=cut
sub disable_warn {
	$SIG{__WARN__}= sub {};
}

=head2 disable_stdout

STDOUT is output temporary.

=cut
sub disable_stdout {
	my($self)= @_;
	open STDOUT, ">". $self->project_root. "/stdout.tmp";  ## no critic
}

=head2 disable_stderr

STDERR is output temporary.

=cut
sub disable_stderr {
	my($self)= @_;
	open STDERR, ">". $self->project_root. "/stderr.tmp";  ## no critic
}

=head2 disable_allstd

All 'disable_warn' and 'disable_stdout' and 'disable_stderr' is done at a time.

=cut
sub disable_allstd {
	my($self)= @_;
	$self->disable_warn;
	$self->disable_stdout;
	$self->disable_stderr;
}

=head2 egg_context

The object of a virtual project is returned.

  my $e= $vr->egg_context;

=cut
sub egg_context {
	my $self= shift;
	$self->_setup_inc;
	$self->project_name->require || croak $@;
	$self->project_name->new;
}

=head2 egg_pcomp_context

The object of a virtual project of the '_prepare_model' and '_prepare_view'
 and '_prepare' execution is returned.

  my $e= $vr->egg_pcomp_context;

=cut
sub egg_pcomp_context {
	my $self= shift;
	my $e= $self->egg_context;
	$e->prepare_engine;
	$e;
}

=head2 egg_handler

仮想プロジェクトの handler メソッドをコールします。

  $vr->egg_handler;

=cut
sub egg_handler {
	my $self= shift;
	$self->_setup_inc;
	$self->project_name->require || croak $@;
	$self->project_name->handler;
}

=head2 helper_run ( [MODE], [ANY_NAME], [OPTION] )

The helper script is operated on a virtual project.

MODE is not omissible.

  $vr->helper_run('Plugin:Helper', 'NewName', { ... options });

=cut
sub helper_run {
	my $self= shift;
	my $mode= shift || croak q{ I want mode. };
	$ENV{EGG_ANY_NAME}= shift || "";
	my $pname = $self->project_name || croak q{ I want setup 'project_name'. };
	my $proot = $self->project_root || croak q{ I want setup 'project_root'. };
	$self->_setup_inc;
	Egg::Helper->run($mode, $pname,
	   { %{ $_[1] ? {@_}: ($_[0] || {}) }, project_root=> $proot } );
	1;
}

=head2 mech_ok

If the include of WWW::Mechanize::CGI succeeds, true is returned.

=cut
sub mech_ok {
	WWW::Mechanize::CGI->require ? 1: 0;
}

=head2 mechanize ( [OPTION_HASH] )

The object of WWW::Mechanize::CGI is returned.

OPTION_HASH is an option to pass to L<WWW::Mechanize::CGI>.

=cut
sub mechanize {
	WWW::Mechanize::CGI->require || croak <<END_INFO;
$@
===========================================================
 * 'WWW::Mechanize::CGI' is not installed.
 >> perl -MCPAN -e 'install WWW::Mechanize::CGI'
===========================================================
END_INFO

	my $self  = shift;
	my $option= ref($_[0]) eq 'HASH' ? $_[0]: {@_};
	$option->{agent} ||= __PACKAGE__."/$VERSION";
	my $proot = $self->project_root
	    || die q{ 'project root' is not setup. };
	my $script= "$proot/bin/trigger.cgi";
	(-e $script and -f _)
	    || die q{ I want you to complete prepare previously. };
	chmod 0755, $script unless -x $script;  ## no critic
	my $mech= WWW::Mechanize::CGI->new( %$option );
	$mech->cgi_application("$proot/bin/trigger.cgi");
	$mech->agent($option->{agent});
	$mech;
}

=head2 mech_get ( [VR_REQUEST_URI], [OPTION] )

Virtual GET is requested to VR_REQUEST_URI.

OPTION is an option to pass to 'mechanize' method.

When the return value is received with ARRAY, the object of the project
after CGI is executed can be received.

  my($mech, $e)= $vr->mech_get('/get_request');
  
  print $mech->content;
  
  if ($e->param('check_param')) { print "OK" }

=cut
sub mech_get {
	my $self= shift;
	my $uri = shift || croak q{ I want URI. };
	my $e; my $mech= $self->_prepare_mech(\$e, @_);
	$mech->get($uri);
	$self->_stock_env_restore;
	wantarray ? ($mech, $e): $mech;
}

=head2 mech_post ( [VR_REQUEST_URI], [QUERY_DATA_HASH], [OPTION] )

Virtual POST is requested to VR_REQUEST_URI.

QUERY_DATA_HASH is a parameter passed to CGI.

OPTION is an option to pass to 'mechanize' method.

  my $mech= $vr->mech_post('/post_request', { foo => 'test', hoge=> 'OK' });
  
  print $mech->content;

* When upload is tested, it is L as for QUERY_DATA_HASH. <HTTP::Request::Common>
  Please give it by the form that passes.

  my $proot= $vr->project_root;
  my($mech, $e)= $vr->mech_post('/post_request', {
    Content_Type => 'form-data',
    Content => [
      upload1 => ["$proot/data/upload.txt" ],
      upload2 => ["$proot/data/upload.html"],
      param1  => 'test',
      ],
    });
  
  my $upload= $e->request->upload('upload1');
  
  if ($upload->filename) { print "OK" }

* It is necessary to load the 'Upload' plugin into the test of upload.

=cut
sub mech_post {
	my $self = shift;
	my $uri  = shift || croak q{ I want URI. };
	my $query= shift || croak q{ I want query data. };
	my $e; my $mech= $self->_prepare_mech(\$e, @_);
	if ($query->{Content_Type}) {
		require HTTP::Request::Common;
		$mech->request( HTTP::Request::Common::POST($uri, %$query) );
	} else {
		$mech->post( $uri, $query );
	}
	$self->_stock_env_restore;
	wantarray ? ($mech, $e): $mech;
}
sub _prepare_mech {
	my $self= shift;
	my $e   = shift || die q{ I want egg context container. };
	my $mech= $self->mechanize(@_);
	$mech->cgi( sub {
		$self->_stock_env;
		eval{
			$$e= $self->egg_pcomp_context;
			$$e->_dispatch_start;
			$$e->_dispatch_action;
			$$e->_dispatch_finish;
			$$e->_finalize;
			$$e->_finalize_output;
		  };
		$@ and warn $@;
	  } );
	$mech;
}
sub _stock_env {
	my($self)= @_;
	$self->{stock_env}= {};
	@{$self->{stock_env}}{ keys %ENV }= values %ENV;
}
sub _stock_env_restore {
	my($self)= @_;
	my $env= $self->{stock_env} || return 0;
	@ENV{ keys %$env }= values %$env;
}
sub _setup_inc {
	my $self = shift;
	my $proot= $self->project_root || die q{ 'project root' is not setup. };
	my $inc  = "$proot/lib";
	unshift @INC, $inc unless (grep { $inc eq $_ } @INC);
}
sub _setup_controller {
	my $self= shift;
	my $attr= shift || {};
	my $g= $self->global;
	{
		my $egg= $attr->{egg} || [qw/Dispatch::Standard Debugging Log/];
		$egg= [$egg] if ref($egg) ne 'ARRAY';

		if (my $inc= $attr->{egg_includes}) {
			$inc= [$inc] if ref($inc) ne 'ARRAY';
			splice @$egg, 0, 0, @$inc;
		}

		push(@$egg, '-Debug') if $attr->{egg_debug};
		$g->{egg_args}= join(' ', @$egg);
	  };

	my $default_name;
	if ($default_name= $attr->{default_mode}) {
		$g->{egg_default_mode}= <<END_CODE;
__PACKAGE__->default_mode('$default_name');
END_CODE
		$default_name=~s{^_+} [_];
	} else {
		$default_name= '_default';
	}
	$g->{egg_dispatch_map} ||= $g->{egg_run_modes}
	    || $attr->{dispatch_map} || $attr->{run_modes}
	    || $attr->{dispatch}     || <<END_CODE;
 $default_name => sub {
  my(\$e, \$dispatch)= \@_;
  require Egg::Helper::BlankPage;
  \$e->response->body( Egg::Helper::BlankPage->out(\$e) );
  },
END_CODE

	$g->{egg_mode_param}= $attr->{mode_param}
	   ? qq{__PACKAGE__->mode_param('$attr->{mode_param}');\n}: "";

	$g->{egg_first_code}= $attr->{first_code} || "";
	$g->{egg_last_code} = $attr->{last_code}  || "";
	$g->{egg_project_version}= $attr->{version} || '0.01';
}
sub _setup_config {
	my $self = shift;
	my $attr = shift || {};
	my $proot= $self->project_root;
	my $pname= $self->project_name;
	my $g= $self->global;

	## default setup.
	$attr->{title} ||= $pname;
	$attr->{root}  ||= $proot;
	$attr->{template_path} ||= ["$proot/root", "$proot/comp"];

	{
		my $request= $attr->{request} ||= {};
		$request->{POST_MAX} ||= 10240;
		$request->{DISABLE_UPLOADS}= 0
		      unless defined($request->{DISABLE_UPLOADS});
		$request->{TEMP_DIR} ||= "$proot/tmp/uploads";
	  };

	{
		my $dir= $attr->{dir} ||= {};
		$dir->{lib}      ||= "$proot/lib";
		$dir->{static}   ||= "$proot/htdocs";
		$dir->{etc}      ||= "$proot/etc";
		$dir->{cache}    ||= "$proot/cache";
		$dir->{tmp}      ||= "$proot/tmp";
		$dir->{comp}     ||= "$proot/comp";
		$dir->{template} ||= ref($attr->{template_path}) eq 'ARRAY'
		       ? $attr->{template_path}->[0]: $attr->{template_path};
	  };

	$attr->{VIEW} ||= $attr->{default_view_mason} ? [
	  [ Mason => {
	    comp_root=> [[ main => "$proot/root" ],[ private => "$proot/comp" ]],
	    data_dir => "$proot/tmp",
	    } ],
	  ]: [
	  [ Template => {
	    path=> ["$proot/root", "$proot/comp"],
	    global_vars=> 1,
	    die_on_bad_params=> 1,
	    } ],
	  ];

	my $config= Data::Dumper::Dumper($attr);
	   $config=~s{^[^\{]+\{\s+} []s;
	   $config=~s{\s+\}\;\s+$} [\n]s;
	   $config=~s{(^|\n) +} [$1  ]sg;
	$g->{egg_project_config}= $config;
	$g->{egg_startup}= sub { "(\n$config\n)" };
}

=head1 SEE ALSO

L<File::Temp>,
L<WWW::Mechanize::CGI>,
L<HTTP::Request::Common>,
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

__DATA__
---
filename: lib/< $e.project_name >.pm
filetype: module
value: |
  package < $e.project_name >;
  use strict;
  use warnings;< $e.egg_inc >
  use Egg qw/< $e.egg_args >/;
  < $e.egg_first_code >
  
  our $VERSION= '< $e.egg_project_version >';
  
  __PACKAGE__->egg_startup< $e.egg_startup >;
  < $e.egg_default_mode >
  < $e.egg_mode_param >
  # Dispatch. ------------------------------------------------
  __PACKAGE__->dispatch_map( < $e.egg_dispatch_map > );
  # ----------------------------------------------------------
  
  < $e.egg_last_code >
  
  1;
---
filename: lib/< $e.project_name >/config.pm
filetype: module
value: |
  package < $e.project_name >::config;
  use strict;
  use warnings;
  my $C= {
  < $e.egg_project_config >
    };
  
  sub out { $C }
  
  1;
---
filename: bin/trigger.cgi
filetype: script
value: |
  #!< $e.perl_path >
  package < $e.project_name >::trigger;
  use lib qw{ < $e.project_root >/lib< $e.include_path > };
  use < $e.project_name >;
  
  < $e.project_name >->handler;
  
---
filename: bin/< $e.lc_project_name >_helper.pl
filetype: script
value: |
  #!< $e.perl_path >
  use lib qw(< $e.project_root >/lib);
  use Egg::Helper;
  
  Egg::Helper->run( shift(@ARGV), {
    project_name => '< $e.project_name >',
    project_root => '< $e.project_root >',
    } );
  
