package Egg::Helper;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Helper.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use Cwd;
use Getopt::Easy;
use FileHandle;
use File::Spec;
use File::Which;
use File::Basename;
use Egg::Plugin::YAML;
use Egg::Exception;
use Egg::Engine;
use base qw/Class::Accessor::Fast/;

our $VERSION= '0.08';

my %Global;
sub global { \%Global }

*yaml_load    = \&parse_yaml;
*escape_html  = \&Egg::Engine::escape_html;
*unescape_html= \&Egg::Engine::unescape_html;
*escape_uri   = \&Egg::Engine::escape_uri;
*unescape_uri = \&Egg::Engine::unescape_uri;
*error        = \&Egg::Engine::error;
*fread        = \&read_file;
*fwrite       = \&save_file;

{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	for my $accessor (qw/copy move/) {
		*{__PACKAGE__."::$accessor"}= sub {
			my $self = shift;
			my $file1= shift || Egg::Error->throw('I want file1');
			my $file2= shift || Egg::Error->throw('I want file2');
			File::Copy->require;
			&{"File::Copy::$accessor"}($file1, $file2) || return 0;
			print "- $accessor file : $file1 => $file2\n";
			1;
		  };
	}
	sub get_options {
		my $class   = shift;
		my $options = shift || "i-in= D-debug o-out= h-help";
		Getopt::Easy::get_options
		  ( $options, $class->help_message($Global{mode}) );
	}
  };

sub run {
	my $class= shift;
	my $mode = $Global{mode}= shift || die 'I want mode.';
	my $pname= shift || "";
	my $args = shift || {};

	local $SIG{__DIE__}= sub { Egg::Error->throw(@_) }  ## no critic
	  if $ENV{EGG_HELPER_DEBUG};

	# Project.
	if ($mode=~m{^Project\:+([A-Z][A-Za-z0-9_]+)}) {
		$class->project_name($1);
		$class->setup_global();
		$class->isa_self('Project::Build')->new($1);

	# Other.
	} elsif ($mode=~m{^(O\:\:?[A-Z][A-Za-z0-9_\:]+)}) {
		my $pkg= $1;
		$Global{project_name}= $Global{project}= 'Other::Dummy';
		$class->setup_global();
		$class->isa_self($pkg)->new();

	# Model, View, Engine, Dispatch, Plugin, etc.
	} elsif ($mode=~m{^([A-Z]\:\:?[A-Z][A-Za-z0-9_\:]+)}) {
		my $pkg= $1;
		$class->project_name($pname)
		  || Egg::Error->throw('I want project name.');
		my $helper= $class->isa_self($pkg);
		$helper->setup_global($args);
		$Global{project_root}=
		  $class->path_regular($Global{project_root})
		  || Egg::Error->throw('I want project_root.');
		$helper->new();

	# Help.
	} else {
		print $class->help_message($mode);

	}
}
sub isa_self {
	my $class= shift;
	my $pkg  = shift || Egg::Error->throw('I want package name.');
	$pkg=~s{([A-Za-z0-9_]\:)([A-Za-z0-9_])} [$1:$2]go;
	$pkg= "Egg::Helper::$pkg";
	no strict 'refs';  ## no critic
	push @{"$pkg\::ISA"}, __PACKAGE__;
	$pkg->require or Egg::Error->throw($@);
	$pkg;
}
sub is_platform {
	{ MSWin32=> 'Win32', MacOS=> 'MacOS' }->{$^O} || 'Unix';
}
sub is_unix {
	$_[0]->is_platform eq 'Unix' ?  1: 0;
}
sub is_win32 {
	$_[0]->is_platform eq 'Win32' ? 1: 0;
}
sub is_mac {
	$_[0]->is_platform eq 'MacOS' ? 1: 0;
}
sub perl_path {
	my($self)= @_;
	my $perl_path= $ENV{PERL_PATH} || which('perl')
	 || die q/Please set environment variable 'PERL_PATH'./;
	$self->path_regular($perl_path);
}
sub project_name {
	my $class= shift;
	if (@_) {
		my $pname= shift || return(undef);
		if ($pname=~/^[A-Z][A-Za-z0-9_]+$/) {
			$Global{project_name}= $Global{project}= $pname;
		} else {
			Egg::Error->throw("Bad format of project name: $pname");
		}
	}
	$Global{project_name} || undef;
}
sub setup_global {
	my $class= shift;
	my $args = shift || {};
	$args->{any_name}= shift(@ARGV)
	 if ($ARGV[0] && $ARGV[0]=~m{^[A-Za-z].*?$});

	$class->get_options;

	$SIG{__DIE__}= sub { Egg::Error->throw(@_) } if $O{debug};

	$args->{start_dir}= $class->get_cwd();
	$args->{perl_path}= $class->perl_path;
	$args->{out_path} = $class->get_out_path(\%O);
	$args->{out_path} = $class->path_regular($args->{out_path});
	$args->{year}= (localtime time)[5]+ 1900;
	$args->{revision}= '$'. 'Id'. '$';
	$args->{gmtime_string}= gmtime time;
	$args->{license}= $args->{version}= "";
	@Global{keys %$args}= values %$args;
	@Global{keys %O}= values %O;
	$Global{examples}= $Global{example}= 'examples';
}
sub get_out_path {
	my $class  = shift;
	my $option = shift || {};
	my $outpath= $option->{out} || $ENV{EGG_OUT_PATH} || $class->get_cwd();
	my $regixp = $class->is_win32 ? qr{^(?:[C..Z]\:)?[/\\].+}: qr{^/.+};
	if (! $outpath=~m{$regixp}) {
		print "Warning: Output path is not Absolute PATH. : $outpath\n";
	}
	$outpath=~s{/+$} []o;
	$outpath;
}
sub get_cwd {
	Cwd::getcwd();
}
sub setup_document_code {
	my $self= shift;
	$Global{document} ||= sub {
		my($proto, $param, $fname)= @_; $fname ||= "";
		my $document= $self->pod_text;
		$proto->conv($param, \$document, $fname);
	  };
	$Global{dist} ||= sub {
		my($proto, $param, $fname)= @_;
		$fname= $self->path_regular($fname);
		if (my $proot= $Global{project_root}) {
			$fname=~s{^$proot} []o;
		}
		$fname=~s{^/?lib} []o;
		$fname=~s{^/} []o;
		$fname=~s{\.pm$} []o;
		join '::', (split /\/+/, $fname);
	  };
	$self;
}
sub path_regular {
	my $self= shift;
	my $path= shift || return "";
	return $path if $self->is_unix;
	my $regixp= $self->is_mac ? qr{\:}: qr{\\};
	$path=~s{$regixp+} [/]g;
	$path;
}
sub chdir {
	my $self= shift;
	my $path= shift || Egg::Error->throw('I want path.');
	$self->create_dir($path) if ($_[0] && ! -e $path);
	CORE::chdir($path) || Egg::Error->throw("$! : $path");
	print "= change dir : $path\n";
	1;
}
sub create_dir {
	my $self= shift;
	my $path= shift || Egg::Error->throw('I want path.');
	File::Path->require;
	File::Path::mkpath($path, 1, 0755) || return 0;  ## no critic
#	print "+ create dir : $path\n";
	1;
}
sub remove_dir {
	my $self= shift;
	my $path= shift || Egg::Error->throw(q/I want dir./);
	File::Path->require;
	File::Path::rmtree($path) || return 0;
	print "- remove dir : $path\n";
	1;
}
sub remove_file {
	my $self = shift;
	Egg::Error->throw('I want file path.') unless @_;
	for my $file (@_) {
		print "+ remove file: $file\n" if unlink($file);
	}
}
sub read_file {
	my $self = shift;
	my $file = shift || Egg::Error->throw('I want file path.');
	my $param= $_[0] ? (ref($_[0]) ? $_[0]: {@_}): \%Global;
	my $fh= FileHandle->new($file) || Egg::Error->throw("$! - $file");
	binmode($fh);
	my $value= join '', $fh->getlines;
	$fh->close;
	-T $file ? $self->conv($param, \$value, $file): \$value;
}
sub save_file {
	my $self = shift;
	my $param= shift || Egg::Error->throw('I want param.');
	my $data = shift || Egg::Error->throw('I want data');
	my $path= $self->conv($param, \$data->{filename})
	  || Egg::Error->throw(q/I want data->{filename}/);
	my $value= ($data->{filetype} && $data->{filetype}=~/^bin/i) ? do {
		MIME::Base64->require;
		MIME::Base64::decode_base64($data->{value});
	  }: do {
		$self->conv($param, \$data->{value}, $path) || return "";
	  };
	my $basedir= File::Basename::dirname($path);
	if (! -e $basedir || ! -d _) {
		$self->create_dir($basedir) || Egg::Error->throw($!);
	}
	my @path= split /[\\\/]+/, $path;
	my $fh= FileHandle->new(">". File::Spec->catfile(@path))
	  || Egg::Error->throw("File Open Error: $path - $!");
	binmode($fh);
	print $fh $value;
	$fh->close;
	print "+ create file: $path\n";
	if ($data->{permission}) {
		chmod $data->{permission}, $path;  ## no critic
		print "+ chmod : $path\n";
	}
	return 1;
}
sub execute_make {
	my($self)= @_;
	if ($self->is_unix) {
		eval{ $self->exec_perl_Makefile };
		if (my $err= $@) {
			warn $err;
			eval{ $self->output_manifest };
		}
	} else {
		$self->output_manifest;
	}
}
sub distclean_execute_make {
	my($self)= @_;
	if ($self->is_unix) {
#		unlink("$Global{project_root}/MANIFEST");
		`make distclean`;
		eval{ $self->exec_perl_Makefile };
		if (my $err= $@) {
			warn $err;
			eval{ $self->output_manifest };
		}
	} else {
		$self->output_manifest;
	}
}
sub exec_perl_Makefile {
	my($self)= @_;
	system('perl Makefile.PL') and Egg::Error->throw($!);
	system('make manifest') and Egg::Error->throw($!);
	system('make') and Egg::Error->throw($!);
	system('make test') and Egg::Error->throw($!);
	`make distclean`;
}
sub conv {
	my $self = shift;
	my $param= shift || {};
	my $text = shift || return "";
	my $fname= shift || "";
	return "" unless $$text;
	$$text=~s{<\#\s+(.+?)\s+\#>} [
	  $param->{$1} ? do {
	    ref($param->{$1}) eq 'CODE'
	      ? $param->{$1}->($self, $param, $fname): $param->{$1};
	    }: "";
	 ]sgeo;
	$$text;
}
sub egg_context {
	my $self= shift;
	my $project= $self->project_name || return 0;
	$project->require or Egg::Error->throw($@);
	$project->new;
}
sub load_config {
	my $self = shift;
	my $pname= $self->project_name || return 0;
	my $yaml = "$Global{project_root}/etc/$pname.yaml";
	if (-e $yaml && -f _) {
		return $self->yaml_load($yaml);
	} else {
		$pname.= '::config';
		$pname->require or Egg::Error->throw($@);
		return $pname->out;
	}
}
sub check_module_name {
	my $self= shift;
	my $name= shift || Egg::Error->throw('I want module name');
	my @part= $_[0] ? ($_[1] ? @_: @{$_[0]}): ();
	for (split /[\-\:\/]+/, $name) {
		if (/^[A-Za-z][A-Za-z0-9_]+$/) {
			push @part, $_;
		} else {
			Egg::Error->throw(q/It is a package name of an illegal format./);
		}
	}
	\@part;
}
sub get_testfile_new_number {
	my $self   = shift;
	my $testdir= shift || Egg::Error->throw('I want test dir.');
	-e $testdir  || Egg::Error->throw('test dir is not found.');
	my $number= 0;
	for (grep /\.t$/, <$testdir/*>) {
		my($num)= m{/(\d+)[^/]+$};
		$number= $num if ($num && $num< 80 && $num> $number);
	}
	sprintf "%02d", ++$number;
}
sub setup_global_rc {
	my $self= shift;
	my $rc= Egg::Plugin::YAML->loadrc || {};
	$rc->{author}     ||= $rc->{copywright} || "";
	$rc->{copywright} ||= $rc->{author}     || "";
	$rc->{headcopy}   ||= $rc->{copywright} || "";
	$rc->{$_} ||= $ENV{LOGNAME} || $ENV{USER} || 'none.'
	  for (qw/author copyright headcopy/);
	$rc->{author}=~s{\'} [E<39>]go;
	$rc->{license} ||= 'perl';
	$rc->{version} ||= '0.01';
	$rc->{uname} ||= $ENV{LOGNAME} || $ENV{USER} || $self->project_name
	  || 'none.';
	@Global{keys %$rc}= values %$rc;
}
sub parse_yaml {
	my $self= shift;
	my $yaml= $_[0] ? (ref($_[0]) ? $_[0]: \$_[0])
	                : Egg::Error->throw('I want YAML text.');
	YAML::Load($$yaml);
}
sub data_default {
	my($self)= @_;
	$self->{data_default} ||= $self->parse_yaml(join '', <DATA>);
}
sub pod_text {
	my($self)= @_;
	my $hash= $self->data_default;
	$hash->{pod_text};
}
sub encode_bin_out {
	my $self= shift;
	my $path= shift || $self->global->{in} || die 'I want bin data.';
	my $fh= FileHandle->new($path) || die "$! - $path";
	binmode $fh;
	my $data= join '', (<$fh>);
	MIME::Base64->require;
	MIME::Base64::encode_base64($data);
}
sub out {
#
# > perl -MEgg::Helper -e "Egg::Helper->out" > /path/to/bin/egg_helper.pl
#
	my($class)= @_;
	my $perl_path= $class->perl_path;
	print <<SCRIPT;
#!$perl_path
use Egg::Helper;
Egg::Helper->run( shift(\@ARGV) );
SCRIPT
}
sub help_message {
	my $class= shift;
	my $mode = shift || Egg::Error->throw('I want mode.');
	my $script_name= $mode=~m{^(?:A|Project)\:} ? 'egg_helper.pl': do {
		my $pname= lc($class->project_name)
		   || Egg::Error->throw('I want project name.');
		lc($pname).'_helper.pl';
	  };
	<<END_OF_HELP;

# usage: perl $script_name [MODE] [-o=OUTPUT_PATH] [-h] [-D]

END_OF_HELP
}

1;

=head1 NAME

Egg::Helper - Framework of helper script for Egg.

=head1 SYNOPSIS

  # The helper script is obtained.
  perl -MEgg::Helper -e "Egg::Helper->out" > /path/to/bin/egg_helper.pl
  
  # Project is generated.
  perl /path/to/bin/egg_helper.pl Project:[PROJECT_NAME]

=head1 DESCRIPTION

It is a module that offers the helper function for Egg.

Please make the helper script first of all to use it as follows.

  perl -MEgg::Helper -e "Egg::Helper->out" > /path/to/bin/egg_helper.pl
  chmod 755 /path/to/bin/egg_helper.pl

* Putting on the place that PATH passed is convenient for egg_helper.pl.

Afterwards, please make the project as follows.

  egg_helper.pl Project:MYPROJECT

The directory named MYPROJECT is made from this in the current directory.
And, the skeleton for the project is generated in that.

Passing at the output destination can be specified by '-o' option.

  egg_helper.pl Project:MYPROJECT -o /path/to

MYPROJECT is made for the subordinate of /path/to from this.

Passing Perl cannot be acquired according to circumstances and there 
might be doing the error end. For that case, please set PELR_PATH to 
the environment variable.

  export PELR_PATH=/usr/bin/perl

A is generated to bin of the made project.
The helper only for the project can be used by using this script.

  cd /path/to/MYPROJECT/bin
  ./myproject_helper.pl D:Make NewDispatch

Please see special each helper's document about special helper's use.

=head1 METHODS

These are for the developer of the helper script.
It is not information necessary for the application making.

=head2 global

A global HASH reference is returned.

=head2 yaml_load   or parse_yaml  ([YAML_FILE])

After given YAML is regularized, it returns it.

=head2 escape_html ([HTML_TEST])

It escapes in the HTML tag in the text.

=head2 escape_html ([PLAIN_TEXT])

It returns it based on escape ending HTML tag in the text.

=head2 escape_uri ([URI])

It escapes in the character for which the escape in URI is necessary.

=head2 unescape_uri

It returns it based on the escape character in URI. 

=head2 conv ([PARAM_HASH], [TEXT], [FILE_NAME])

The part of <# param_name #> in [TEXT] is replaced with the value of
corresponding [PARAM_HASH].

* The CODE reference can be defined in the value of [PARAM_HASH].

=head2 fread  or  read_file ([FILE_PATH], [PARAM])

The content of the given file is returned.

When the read content is a text, the result of passing conv is returned.
The content is returned by the SCALAR reference, except when the content is
a text.

When [PARAM] is omitted, global is used.

=head2 fwrite  or save_file ([PARAM], [FILE_DATA])

The file is made based on information given by [FILE_DATA].

[FILE_DATA] becomes HASH reference with the following keys and the values.

  filename : Generated file PATH.
  value    : Content of generated file.
  filetype : Only bin can be specified.
             When making it to bin, the content given with value is a value of
             the MIME::Base64 encode.
  permission: After the file is generated, a specified permission is set.
  
  * The value of filename and value passes conv.

[PARAM] is HASH reference passed to conv.

=head2 is_unix

When operating by system OS UNIX, true is restored.

=head2 is_win32

When operating by system OS Windows, true is restored.

=head2 is_mac

When operating by system OS MacOS, true is restored.

=head2 perl_path

Passing Perl is returned.
When it is not possible to acquire it from environment variable PERL_PATH or
File::Which, the exception is generated.

=head2 project_name

The object project name under execution is returned.

=head2 setup_global

A global value of default is set.
Because this is called beforehand, it is not necessary to usually call it from
the helper module.

=head2 get_out_path

Passing at the output destination is returned.

The thing specified by environment variable EGG_OUT_PATH besides specifying it
by '-o' option is possible. Anything returns a current passing when there is
no specification.

=head2 get_cwd

A current now passing is returned.

=head2 setup_document_code

It sets it concerning the document of the default put on the module.

=head2 chdir ([PATH])

After chdir is done, it reports to a standard output.

=head2 copy ([PATH1], [PATH2])

After File::Copy::copy is done, it reports to a standard output.

=head2 move ([PATH1], [PATH2])

After File::Copy::move is done, it reports to a standard output.

=head2 remove_dir ([PATH])

After File::Path::rmtree is done, it reports to a standard output.

=head2 execute_make

If 'is_unix' is true, 'exec_perl_Makefile' is called and if it is false,
'output_manifest' is called.

* Please prepare 'output_manifest'.

=head2 distclean_execute_make

If 'is_unix' is true, 'exec_perl_Makefile' is called after make distclean 
is done and if it is false, 'output_manifest' is called.

* Please prepare 'output_manifest'.

=head2 exec_perl_Makefile

Perl Makefile.PL and a series of operation are done.

It is necessary to have moved to the root directory etc. of the project before
it calls it.

=head2 egg_context

The object of the object project is returned.

* Prepare_component etc. have not gone.
  Please call it if necessary after it receives it.

=head2 load_config

The setting of the object project is returned reading.

It gives priority to that if there is YAML file at the output destination of
Egg::Helper::P::YAML.

=head2 check_module_name

Whether it is accepted as a module name is checked.

=head2 get_testfile_new_number

The last number of the test file of the object project is returned most.

=head2 setup_global_rc

The value obtained from Egg::Plugin::YAML->loadrc is set in global.

=head2 encode_bin_out ([FILE_PATH])

The result of MIME::Base64::encode_base64 is returned reading the file of
[FILE_PATH].

It is convenient so that filetype passed to 'save_file' may make value of bin.

=head2 help_message

Help of default is output.

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


__DATA__
pod_text: |
  # Below is stub documentation for your module. You'd better edit it!
  
  =head1 NAME
  
  <# dist #> - Perl extension for ...
  
  =head1 SYNOPSIS
  
    use <# dist #>;
    
    ... tansu, ni, gon, gon.
  
  =head1 DESCRIPTION
  
  Stub documentation for <# dist #>, created by <# created #>
  
  Blah blah blah.
  
  =head1 SEE ALSO
  
  L<Egg::Release>,
  
  =head1 AUTHOR
  
  <# author #>
  
  =head1 COPYRIGHT
  
  Copyright (C) <# year #> by <# copyright #>, All Rights Reserved.
  
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.8.6 or,
  at your option, any later version of Perl 5 you may have available.
  
  =cut
