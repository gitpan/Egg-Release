package Egg::Helper;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Helper.pm 111 2007-05-09 21:31:43Z lushe $
#

=head1 NAME

Egg::Helper - Helper module for Egg WEB Aplication Framework.

=head1 SYNOPSIS

  # Obtaining of helper script.
  perl -MEgg::Helper -e 'Egg::Helper->out' > egg_helper.pl
  
  # Generation of project.
  perl egg_helper.pl Project MyApp -o /home
  
  # The helper of the project is used.
  perl MyApp/bin/myapp_helper.pl Plugin::Maker NewPlugin

=head1 DESCRIPTION

This offers the helper function to use Egg WEB Aplication Framework.

* This document is the one to make the helper script chiefly.
  It is not personally related to the composition of WEB Aplication.

=head1 DEVELOPER

It becomes help of the helper script development, and it explains the behavior
etc. of this module.

This module starts the helper module specified from the command line according
to the following procedures.

=over 4

=item * perl myapp_helper.pl Plugin::Maker NewPlugin

Myapp_helper.pl is a helper script only for the project generated to the bin
folder of the project.

=item * run

The command line is evaluated by this method.

The part of continuing myapp_helper.pl Plugin::Maker is recognized as a helper
module of the object that puts the start.

And, it tries to evaluate a suitable name or the option.

The part of NewPlugin is concretely identified to 'any_name' in this example. 
It comes to be able to refer from the helper module with $helper-E<gt>global->{any_name}.
If the character string that starts by '_' continues, it is treated as an option.
It comes to be able to access it globally by the name defined by the method of
'_setup_get_options'.

=item * execute

The object helper module is read after the command line is suitably evaluated,
and the method of '_execute' is called.

At this time, it adds in @ISA of the object helper module beforehand and it
adds it to Egg::Helper.
As a result, it comes to be able to call all methods of Egg::Helper from the
object helper module like the method completely.
Egg::Helper operates in a word consequentially like the framework for the helper
module.

=back

A convenient code is only freely written now if a target helper module starts.

=cut
use strict;
use warnings;
use UNIVERSAL::require;
use Cwd;
use Getopt::Easy;
use File::Which;
use File::Path;
use YAML;
use Egg::Release;
use Egg::Exception;
use base qw/Egg::Base/;
use Carp qw/croak/;

our $VERSION = '2.02';

my $Alias= {
  M => 'Model',  V => 'View',  D => 'Dispatch', R => 'Request',
  P => 'Plugin', A => 'App',   H => 'Helper',
  };

=head1 METHODS

=head2 new

Constructor.

It uses it when processing it after the object is made by the method of
'_execute'.

The object of the HASH reference base is restored.

=cut
sub new { bless {}, shift }

=head2 global

It is an accessor to global HASH.

When the method of '_execute' was called, some values had already been defined.

=cut
our %G;
sub global { \%G }

=head2 _setup_get_options ( [OPTION_STRING], [HELP_CODE] )

It prepares it. receive the option from the command line.

OPTION_STRING is an option to pass to Getopt::Easy.
* ' o-out= g-debug h-help ' is added without fail.

The default of HELP_CODE is $helper-E<gt>can('_output_help').

  $helper->SUPER::_setup_get_options( ' u-user_name= p-password= ' );

Please refer to the document of L<Getopt::Easy>.

=cut
sub _setup_get_options {
	my $class    = shift;
	my $options  = shift || "";
	   $options .= " o-out= g-debug h-help";
	my $help_code= shift || $class->can('_output_help');
	Getopt::Easy::get_options( $options, $help_code );
}

=head2 run ( [MODE], [ARGS_HASH] )

After the global variable is set up, the helper module is started.

MODE is a name of the helper who puts the start.

  * This name is progressed , saying that 'Egg::Helper::[MODE]'.
  * MODE that doesn't contain ':' is not accepted.

It is ,in a word, a part of 'Plugin::Maker' of the place said by the DEVELOPER
explanation example.

=cut
sub run {
	my $class= shift;
	my $mode = shift || croak q{ I want 'MODE'. };
	if ($mode eq 'Project') {
		my $project= shift(@ARGV)
		   || $ENV{EGG_PROJECT_NAME}
		   || return $class->_output_help(q{ I want project name. });
		$project=~/^[A-Z][A-Za-z0-9_]+$/
		   || return $class->_output_help(q{ Bat project name. });
		$class->_run("${mode}::Build", $project, @_);
	} else {
		$mode= ($Alias->{$1} || $1). "::$2"
		   if $mode=~m{^([A-Z][A-Za-z0-9]+)\:+(.+)}o;
		$mode=~s{\:+} [::]g;
		$class->_run($mode, 0, @_);
	}
	1;
}
sub _run {
	my $class= shift;
	my $helper_class= $class->_setup_global(@_) || return 0;
	my $self= $helper_class->new;
	$self->_execute || $class->_output_help;
}
sub _setup_global {
	my($class, $h_class, $pname)= splice @_, 0, 3;
	my $args = ref($_[0]) eq 'HASH' ? $_[0]: {@_};

	$h_class= "Egg::Helper::$h_class";
	{
		no strict 'refs';  ## no critic
		push @{"${h_class}::ISA"}, __PACKAGE__;
		$h_class->require || return $class->_output_help($@);
	  };
	my $g= $h_class->global;
	$class->project_name($pname) if $pname;
	$args->{any_name}= shift(@ARGV) if ($ARGV[0] && $ARGV[0]!~m{^\-});
	$args->{any_name} ||= $ENV{EGG_ANY_NAME} || "";
	$h_class->_setup_get_options;
	$args->{debug}= $O{debug} || $ENV{EGG_DEBUG} || 0;

	$SIG{__DIE__}= sub { Egg::Error->throw(@_) } if $args->{debug};

	$h_class->_setup_output_path(\%O);
	$args->{start_dir} ||= $h_class->get_cwd;
	$g->{$_} ||= $args->{$_} for keys %$args;
	@{$g}{ keys %O }= values %O;
	$h_class;
}
sub _setup_output_path {
	my $class= shift;
	my $opt= shift || {};
	my $dir= $class->dir_check
	   ( $ENV{EGG_OUT_PATH} || $opt->{out} || $class->get_cwd );
	delete($opt->{out}) if exists($opt->{out});
	$class->global->{output_path}= $dir;
}

=head2 start_dir

The current directory in the place where the helper script was started is 
returned.

=head2 project_root

Route PATH of the project of the object is returned.

* Anything doesn't return when project_root of ARGS_HASH passed with run is
  erased.

=cut
{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	for my $accessor (qw/ start_dir project_root /) {
		*{__PACKAGE__."::$accessor"}= sub { $_[0]->global->{$accessor} || "" };
	}
  };

=head2 chdir ( [TARGET_DIR], [CREATE_FLAG] )

The current directory is changed and it reports to STDOUT.

After TARGET_DIR is made, chdir is done when CREATE_FLAG is given.

=cut
sub chdir {
	my $self= shift;
	my $path= shift || croak q{ I want path. };
	$self->create_dir($path) if ($_[0] && ! -e $path);
	CORE::chdir($path) || croak qq{ $! : $path };
	print "= change dir : $path\n";
	1;
}

=head2 create_dir ( [CREATE_PATH] )

After CREATE_PATH is made, it reports to STDOUT.

It moves even if a deep hierarchy is suddenly specified because mkpath of
L<File::Path> is used.

=cut
sub create_dir {
	my $self= shift;
	my $path= shift || croak q{ I want path. };
	File::Path::mkpath($path, 1, 0755) || return 0;  ## no critic
#	print "+ create dir : $path\n";
	1;
}

=head2 remove_dir ( [DELETE_PATH] )

After DELETE_PATH is deleted, it reports to STDOUT.

Because rmtree of L<File::Path > is used, the subdirectory is recurrently
deleted.

=cut
sub remove_dir {
	my $self= shift;
	my $path= shift || croak q{ I want dir. };
	File::Path::rmtree($path) || return 0;
	print "- remove dir : $path\n";
	1;
}

=head2 remove_file ( [DELETE_FILE] )

It reports to STDOUT if the deletion of DELETE_FILE is tested, and it succeeds.

DELETE_FILE can be passed with ARRAY.

=cut
sub remove_file {
	my $self= shift;
	@_ || croak q{ I want file path. };
	for my $file (ref($_[0]) eq 'ARRAY' ? @{$_[0]}: @_)
	    { print "+ remove file: $file\n" if unlink($file) }
}

=head2 read_file ( [FILE_PATH] )

The content is returned reading FILE_PATH.

=over 4

=item * Alias: fread

=back

=cut
sub read_file {
	require FileHandle;
	my $self= shift;
	my $file= shift || croak q{ I want file path. };
	my $fh  = FileHandle->new($file) || croak qq{ '$file' : $! };
	binmode $fh;
	my $value= join '', <$fh>;
	$fh->close;
	$value || "";
}
*fread= \&read_file;

=head2 save_file ( [SAVE_DATA_HASH], [REPLACE_PARAM_HASH] )

It saves a file based on structural the following SAVE_DATA_HASH, and it
reports to STDOUT.

  filename ... PATH and name of made file.
               If the directory doesn't exist making ahead, it makes it.
  
  value    ... Content of made file.
  
  filetype ... File type.
  
    - If it is a name that starts by bin, it starts doing decode_base64 of
      L<MIME::Base64>, and it developing with the binary.
  
    - If it is a name that starts by script or bin_exec, chmod 0700 is done.

Filename is put on $helper-E<gt>replace.

Value is put on $helper-E<gt>replace in case of not being in the name that
the file type starts by bin.

  $helper->save_file({
  
    filename => 'etc/example.txt',
    value    => $example_value,
  
    }, \%param_data );

  $helper->save_file({
  
    filename => 'htdocs/images/example.png',
    filetype => 'bin',
    value    => $base64_encode_text,
  
    });

=cut
sub save_file {
	my $self = shift;
	my $data = shift || croak q{ I want data.  };
	my $param= shift || 0;
	my $path = $self->replace(($param || {}), $data->{filename})
	        || croak q{ I want data->{filename} };
	my $ftype= $data->{filetype} || "";
	my $value= $ftype=~/^bin/i ? do {
		MIME::Base64->require;
		MIME::Base64::decode_base64($data->{value});
	  }: do {
		$param ? do {
			$self->replace($param, \$data->{value}, $path) || return "";
		  }: do {
			$data->{value} || return "";
		  };
	  };
	my $basedir= File::Basename::dirname($path);
	if (! -e $basedir || ! -d _) {
		$self->create_dir($basedir) || die qq{ $! : $basedir };
	}
	my @path= split /[\\\/\:]+/, $path;
	my $file= File::Spec->catfile(@path);
	open FH, "> $file" || return die qq{ File Open Error: $path - $! };  ## no critic
	binmode(FH);
	print FH $value;
	close FH;
	if (-e $file) {
		print "+ create file: $path\n";
		if ($ftype=~m{^script}i or $ftype=~m{^bin_exec}i) {
			if ( chmod 0700, $file ) { print "+ chmod 0700: $file\n" }  ## no critic
		}
	} else {
		print "- create Failure : $path\n";
	}
	return 1;
}

=head2 yaml_load ( [YAML_TEXT] or [YAML_FILE_PATH] )

YAML_TEXT or YAML_FILE_PATH is done in Perth and the result is returned.

=cut
sub yaml_load {
	my $self= shift;
	my $data= shift || croak q{ I want yaml data. };
	$data=~m{[\r\n]} ? YAML::Load($data): YAML::LoadFile($data);
}

=head2 load_project_config ( [PM_ONLY_FLAG] )

The setting of the project is read and returned.

When PM_ONLY_FLAG is given, it reads for only config.pm.

=cut
sub load_project_config {
	my $self = shift;
	my $pm   = shift || 0;
	my $pname= $self->project_name || die q{ I want project_name. };
	my $proot= $self->project_root || die q{ I want project_root. };
	$pname->require or die $@;
	my $conf= $pname->config || do {
		my $load_conf_module= sub {
			"${pname}::config"->require or die $@;
			"${pname}::config"->out || die q{ configuration is not found. };
		  };
		$pm ? $load_conf_module->(): do {
			my $lcpname= lc($pname);
			my $yaml= -e "$proot/$lcpname.yaml"     ? "$proot/$lcpname.yaml"
			        : -e "$proot/etc/$lcpname.yaml" ? "$proot/etc/$lcpname.yaml"
			        :  0;
			$yaml ? $self->yaml_load($yaml): $load_conf_module->();
		  };
	  };
	$conf->{root}     || die q{ 'root' is not setup. };
	$conf->{dir}      || die q{ 'dir' is not setup.  };
	$conf->{dir}{lib} || die q{ 'dir' -> 'lib' is not setup. };
	$conf->{dir}{tmp} || die q{ 'dir' -> 'tmp' is not setup. };
	$self->replace_deep($conf, $conf->{dir});
	$self->replace_deep($conf, $conf);
	$conf->{dir}{root}        =  $conf->{root};
	$conf->{dir}{temp}        =  $conf->{dir}{tmp};
	$conf->{dir}{lib_project} = "$conf->{dir}{lib}/$pname";
	$self->config($conf);
}

=head2 generate ( [OPERATION_ATTR_HASH] )

The file complete set is generated based on structural the following
OPERATION_ATTR_HASH.

=over 4

=item * chdir => [ [PATH], [FLAG] ]

If chdir is done, it defines it.
This is an argument passed to $helper-E<gt>chdir and an always ARRAY reference.

=item * create_files => [ [SAVE_DATA_HASH] ]

The made file data is defined by the ARRAY reference.

Each value of ARRAY is an argument passed to $helper-E<gt>save_file.

=item * create_dirs => [ [CREATE_PATH_ARRAY] ]

An empty directory is made.

=item * create_code => [CODE_REF],

The code can be added. 

The helper object is passed to the code.

=item * makemaker_ok => [ 1 or 0 ]

After the file complete set is generated, a series of perl Makefile.PL and
others make test is done.

=item * complete_msg => [COMPLETE_MESSAGE],

COMPLETE_MESSAGE set when the generation processing is completed is output
to STDOUT.

=item * errors => [OPTION_HASH],

It is a setting concerning the settlement when the error occurs.

  rmdir => [DELETE_DIR_ARRAY]
     List of deleted directory.
     This list extends to $helper-E<gt>remove_dir.
  
  unlink => [DELETE_FILE_ARRAY]
     List of deleted file.
     This list extends to $helper-E<gt>remove_file.
  
  message => [ERROR_MESSAGE]
     It is an error message.

=back

  $helper->generate(
    chdir        => [qw{ /path/to/home 1 }],
    create_files => \@files,
    create_dirs  => \@dirs,
    makemaker_ok => 0,
    complete_msg => ' ... Coumpete. ',
    create_code  => sub { ... },
    errors => {
      rmdir   => \@dirs,
      unlink  => \@files,
      message => ' ... Internal Error !! ',
      },
    );

=cut
sub generate {
	my $self= shift;
	my $attr= ref($_[0]) eq 'HASH' ? $_[0]: {@_};
	my $g   = $self->global;
	if (my $chdir= $attr->{chdir}) { $self->chdir(@$chdir) }
	eval{
		if (my $files= $attr->{create_files})
		   { $self->save_file($_, $g) for @$files }
		if (my $dirs = $attr->{create_dirs})
		   { $self->create_dir($_) for @$dirs }
		if (my $code = $attr->{create_code})
		   { $code->($self, $attr) }
		$self->_execute_makemaker if $attr->{makemaker_ok};
		if (my $message= $attr->{complete_msg}) { print $message }
	  };
	$self->chdir($g->{start_dir});

	my $error= $@ || return 1;
	if (my $err= $attr->{errors}) {
		my $msg= $err->{message} || "";
		if (my $dirs = $err->{rmdir})  { $self->remove_dir(@$dirs) }
		if (my $files= $err->{unlink}) { $self->remove_file(@$files) }
		die "$msg : $error";
	} else {
		die $error;
	}
	$self;
}

=head2 testfile_number_now

The number of the test file newly made is returned.

'00' is returned when project_root cannot be acquired or project_root/t has
been deleted or it fails in acquisition.

  my $test_number= $helper->testfile_number_now;

=cut
sub testfile_number_now {
	my($self)= @_;
	my $testdir = $self->project_root || return '00';
	   $testdir.= '/t';
	-e $testdir || return '00';
	my $number= 0;
	for (grep /\.t$/, <$testdir/*>) {
		my($num)= m{/(\d+)[^/]+$};
		$number= $num if ($num && $num< 70 && $num> $number);
	}
	sprintf "%02d", ++$number;
}

=head2 mod_name_resolv ( [MODULE_PATH] )

It checks whether file PATH composition is resolved and the name of each
hierarchy is suitable as the module name of Perl.

And, the result of the check is returned with ARRAY.

If it is not suitable among hierarchies even by one place as the module name
of Perl, 0 is returned.

  $helper->mod_name_resolv('./MyApp/Orign/tools');

=cut
sub mod_name_resolv {
	my $self= shift;
	my $name= join(':', @_) || croak q{ I want module strings. };
	   $name=~s{\.pm} []; $name=~s{\s+} []sg;
	my @parts;
	for ( split /\s*[\\\/\-\:]+\s*/, $name ) {
		/^([A-Za-z][A-Za-z0-9_]*)$/
		   || croak qq{ A part of the module name is bad. };
		push @parts, $_;
	}
	@parts || die q{ There are no parts of the module. };
	wantarray ? @parts: \@parts;
}

=head2 is_platform

OS while operating it is returned.

'Unix' returns if there is neither 'Win32' nor 'MacOS'.

=cut
sub is_platform {
	{ MSWin32=> 'Win32', MacOS=> 'MacOS' }->{$^O} || 'Unix';
}

=head2 is_unix

One returns if judged that $helper-E<gt>is_platform is 'Unix'.

=cut
sub is_unix {
	$_[0]->is_platform eq 'Unix' ?  1: 0;
}

=head2 is_win32

One returns if judged that $helper-E<gt>is_platform is 'Win32'.

=cut
sub is_win32 {
	$_[0]->is_platform eq 'Win32' ? 1: 0;
}

=head2 is_mac

One returns if judged that $helper-E<gt>is_platform is 'MacOS'.

=cut
sub is_mac {
	$_[0]->is_platform eq 'MacOS' ? 1: 0;
}

=head2 project_name ( [PROJECT_NAME] )

When PROJECT_NAME is given, the project name is set again.

However, if it is not suitable as ':' is contained as the project name, the
exception is generated.

When PROJECT_NAME is omitted, the project name under the setting is returned.

* Because the helper module is loaded with the project name has been set,
  it is not necessary to set it again usually.

=cut
sub project_name {
	my $self= shift;
	return $self->global->{project_name} || undef unless @_;
	my $pname= shift || croak q{ I want 'project name'. };
	$self->global->{project_name}= $pname=~m{^[A-Z][A-Za-z0-9_]+$}
	   ? $pname: croak qq{ Bad format of project name: '$pname'. };
}

=head2 get_cwd

The current directory is returned.

=cut
sub get_cwd {
	Cwd::getcwd();
}

=head2 year

A present Christian era is returned.

=cut
sub year {
	(localtime time)[5]+ 1900;
}

=head2 dir_check ( [DIR_PATH] )

DIR_PATH exists, and it is recordable is checked.

When the check cannot be passed, the exception is generated.

=cut
sub dir_check {
	my $class= shift;
	my $dir  = shift || return (undef);
	$dir=~s{[\\\/\:]+$} [];
	(-e $dir && -d _ && -w _)
	   || croak qq{ '$dir' is thing that is recordable directory. };
	$dir || undef;
}

=head2 perl_path

Passing the main body of perl is returned.

The value is returned if environment variable 'PERL_PATH' is set, and 
PATH is specified by L<File::Which> in case of not being.
When everything fails, the exception is generated.

=cut
sub perl_path {
	my($self)= @_;
	$self->global->{perl_path}= $ENV{PERL_PATH}
	  || which('perl')
	  || croak q/Please set environment variable 'PERL_PATH'./;
}

=head2 _setup_rc

Reading the rc file is tried by L<Egg::Plugin::rc>.
And, 'copywright' etc. are set up to $helper-E<gt>global.

Please refer to RESOURCE CODE VARIABLE for details.

=cut
sub _setup_rc {
	my($self)= @_;
	require Egg::Plugin::rc;
	my $rc= Egg::Plugin::rc::load_rc
	  ($self, current_dir=> ($self->global->{start_dir} || $self->get_cwd) )
	  || {};
	$rc->{author}     ||= $rc->{copywright} || "";
	$rc->{copywright} ||= $rc->{author}     || "";
	$rc->{headcopy}   ||= $rc->{copywright} || "";
	$rc->{license}    ||= 'perl';

	my %esc= ( "'"=> 'E<39>', '@'=> 'E<64>', "<"=> 'E<lt>', ">"=> 'E<gt>' );
	for (qw{ author copyright headcopy }) {
		$rc->{$_} ||= $ENV{LOGNAME} || $ENV{USER} || 'none.';
		$rc->{$_}=~s{([\'\@<>])} [$esc{$1}]gso;
	}
	@G{ keys %$rc }= values %$rc;
}

=head2 _output_help

-h It moves when help is demanded by the option etc.

Override may do this method on the helper module side.

=cut
sub _output_help {
	my $self= shift;
	my $message= shift || ""; $message &&= "$message \n\n";
	print <<END_HELP;

$message # usage: perl egg_helper.pl [MODE] [OPTION]

END_HELP
	exit(0);
}

=head2 out

The helper script code is output.

Please preserve the output code in a suitable place and use it.

  perl -MEgg::Helper -e "Egg::Helper->out" > /path/to/bin/egg_helper.pl

=cut
sub out {
	my($class)= @_;
	my $perlpath= $class->perl_path;
	print <<SCRIPT;
#!$perlpath
use Egg::Helper;
Egg::Helper->run( shift(\@ARGV) );
SCRIPT
}

=head1 GLOBAL VARIABLE

It is a key to global HASH that will be set up by the time the helper module
is called list.

=head2 project_name

Project name.

=head2 project_root

Route PATH of project.

=head2 any_name

When the name has been passed to the helper script, it is set.

=head2 debug

-d When $ENV{EGG_DEBUG} is set, whether the option is effective it is set.

* If this value is effective, it sets it up like displaying the stack trace
  when the error occurs.

=head2 start_dir

The current directory is set.

=head2 output_path

-o If the option is effective, it is set.
Or, if $ENV{EGG_OUT_PATH} is set, this value is set.
If it is undefined, all current directories are set above.

=head2 help

-h If the option is effective, it is set.

=head2 ... etc

Additionally, the global value set beforehand changes by the option to pass
to the setting and the run method of the method of '_setup_get_options'.

=cut
sub _setup_module_maker {
	my $self = shift;
	my $pkg  = shift || ref($self) || croak q{ I want package name. };
	my $g    = $self->global;
	my $pname= $self->project_name || "";
	$self->perl_path;
	$self->_setup_rc;

	if (my $egg_inc= $ENV{EGG_INC}) {
		$g->{egg_inc}= qq{\nuse lib qw(}
		 . join(' ', split /\s*[\, ]\s*/, $egg_inc). qq{);\n};
	} else {
		$g->{egg_inc}= "";
	}
	$g->{created}  = "$pkg v". $pkg->VERSION;
	$g->{revision} = '$'. 'Id'. '$';
	$g->{lib_dir}  = "lib/$pname";
	$g->{lc_project_name}= lc($pname);
	$g->{uc_project_name}= uc($pname);
	$g->{ucfirst_project_name}= ucfirst($pname);
	$g->{module_version} ||= 0.01;
	$g->{perl_version}= $] > 5.006 ? sprintf "%vd", $^V : sprintf "%s", $];
	$g->{egg_release_version}= Egg::Release->VERSION;
	$g->{gmtime_string}= gmtime time;
	$g->{year}= sub { $self->year };
	my $hash= $self->_load_data;
	$hash->{document}= sub {
		my($h, $param, $fname)= @_;
		my $pod_text= $hash->{pod_text};
		$h->replace($param, \$pod_text, ($fname || ""));
	  };
	$hash->{dist}= sub {
		my($proto, $param)= splice @_, 0, 2;
		my $proot_regix= $g->{project_root};
		   $proot_regix=~s{\\} [\\\\]g;
		my $fname= $proto->_conv_unix_path(@_) || return "";
		$fname=~s{^[A-Za-z]\:+} []o;
		$fname=~s{^$proot_regix} []o;
		$fname=~s{^/?lib} []o;
		$fname=~s{^/+} []o;
		$fname=~s{\.pm$} []o;
		join '::', (split /\/+/, $fname);
	  };
	$self->{_setup_module_maker}= 1;
	@{$g}{ keys %$hash }= values %$hash;
}
sub _load_data {
	my($self)= @_;
	$self->global->{_load_data} ||= $self->yaml_load( join '', <DATA> );
}
sub _setup_module_name {
	my $self= shift;
	my $name= ref($_[0]) eq 'ARRAY' ? $_[0]: \@_;
	my $g= $self->global;
	$g->{module_name}     = join('-', @$name);
	$g->{module_filename} = join('/', @$name). '.pm';
	$g->{module_distname} = join('::', @$name);
	$g->{target_path}     = "$g->{output_path}/$g->{module_name}";
	$g->{target_dir}      = "$g->{output_path}/"
	                      . join('/', @{$name}[0..($#{$name}- 1)]);
	$self;
}
sub _execute_makemaker {
	my($self)= @_;
	return if (exists($ENV{EGG_MAKEMAKER}) and ! $ENV{EGG_MAKEMAKER});
	if ($self->is_unix) {
		eval{
			system('perl Makefile.PL') and die $!;
			system('make manifest')    and die $!;
			system('make')             and die $!;
			system('make test')        and die $!;
			`make distclean`;
		  };
		if (my $err= $@) {
			warn $err;
			print <<END_WARN;
$err

----------------------------------------------------------------
  !! Warning !! The error occurred.
                Please execute 'make distclean'.
END_WARN
			$self->_output_manifest;
		}
	} else {
		$self->_output_manifest;
	}
}
sub _output_manifest {
	my($self)= @_;
	print <<END_OF_INFO;

----------------------------------------------------------------
  !! MANIFEST was not able to be adjusted. !!
  !! Sorry to trouble you, but please edit MANIFEST later !!
----------------------------------------------------------------

END_OF_INFO
}
sub _common_check {
	my($self)= @_;
	my $g= $self->global;
	$g->{project_root} || croak q{ I want setup 'project_root'. };
	$g->{project_root}=~s{/+$} [];
}
sub _conv_unix_path {
	my $self= shift;
	my $path= shift || return "";
	return $path if $self->is_unix;
	my $regixp= $self->is_mac ? qr{\:}: qr{\\};
	$path=~s{$regixp+} [/]g;
	$path;
}

1;

=head1 RESOURCE CODE VARIABLE

When the method of '_setup_rc' is called, loading the rc file is tried by way
of Egg::Plugin::rc.
And, HASH that succeeds in loading is set in a global value.

It is a key as follows set up without fail when the method of '_setup_rc'
is called.

=over 4

=item * author, copyright, headcopy

=back

  * The above-mentioned default is a value obtained with $ENV{LOGNAME} or
    $ENV{USER}.
  * It is escaped in the mail address and <> for pod.

=head1 MODULE GENERATION VARIABLE

When the module file is generated, a special global value is set up when
'_setup_module_maker' is called beforehand.

This is a list of the key set up.

=head2 created

Name and version mark of helper script under operation.

=head2 revision

Character for CVS and SVN to substitute it as Ribijon.

* It is measures against the situation that the character for the Ribijon
  mark replaces by committing of the helper script.

=head2 lib_dir

lib/$e-E<gt>project_name

=head2 lc_project_name

Entire project name of small letter.

=head2 uc_project_name

Entire project name of capital letter.

=head2 ucfirst_project_name

The first character is a project name of the capital letter.

=head2 module_version

0.01

=head2 perl_version

Version of Perl under operation.

=head2 egg_release_version

Version of Egg::Release.

=head2 gmtime_string

Value of gmtime.

=head2 year

Christian era when starting.  (CODE reference)

=head2 document

Pod document of default.  (CODE reference)

=head2 dist

The module name is decided from the file name of the generation module.
  (CODE reference)

=head1 SEE ALSO

L<File::Path>,
L<File::Which>,
L<Getopt::Easy>,
L<MIME::Base64>,
L<YAML>,
L<Egg::Base>,
L<Egg::Exception>,
L<Egg::Plugin::rc>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
pod_text: |
  # Below is stub documentation for your module. You'd better edit it!
  
  =head1 NAME
  
  < $e.dist > - Perl extension for ...
  
  =head1 SYNOPSIS
  
    use < $e.dist >;
    
    ... tansu, ni, gon, gon.
  
  =head1 DESCRIPTION
  
  Stub documentation for < $e.dist >, created by < $e.created >
  
  Blah blah blah.
  
  =head1 SEE ALSO
  
  L<Egg::Release>,
  
  =head1 AUTHOR
  
  < $e.author >
  
  =head1 COPYRIGHT
  
  Copyright (C) < $e.year > by < $e.copyright >, All Rights Reserved.
  
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version < $e.perl_version > or,
  at your option, any later version of Perl 5 you may have available.
  
  =cut
