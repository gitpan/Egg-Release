package Egg::Helper::Script;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Script.pm 72 2006-12-22 11:48:58Z lushe $
#
use strict;
use warnings;
use FileHandle;
use File::Path;
use File::Spec;
use File::Which;
use File::Basename;
use UNIVERSAL::require;
use Getopt::Std;
use Egg::Release;

our $VERSION= '0.03';

sub run {
	my $class = shift;
	my $cmd   = shift || shift(@ARGV) || "none.";
	my $option= shift || {};
	my %opts;
	getopt('hpvobd?', \%opts);
	@opts{keys %$option}= values %$option;
	$opts{mode}= $cmd;
	  $cmd=~/^project/i
	  ? $class->comp(\%opts, 'Egg::Helper::Script::Project')->generate

	: $cmd=~/^dispatch/i
	  ? $class->comp(\%opts, 'Egg::Helper::Script::Dispatcher')->generate

	: $cmd=~/^yaml/i
	  ? $class->comp(\%opts, 'Egg::Helper::Script::YAML')->generate

	: $cmd=~/^prototype/i
	  ? $class->comp(\%opts, 'Egg::Helper::Script::Prototype')->generate

	: $cmd=~/^install/i
	  ? $class->comp(\%opts, 'Egg::Helper::Script::Install')->generate

	: $class->comp(\%opts)->help;
	1;
}
sub out {
	my $perl_path= $ENV{PERL_PATH} || which('perl')
	  || die q/Please set environment variable 'PERL_PATH'./;
	print <<SCRIPT;
#!$perl_path
use Egg::Helper::Script;
Egg::Helper::Script->run('install');
SCRIPT
}
sub comp {
	my($class, $option, $base)= @_;
	my $pkg;
	if ($base) {
		$base->require or die $@;
		$pkg= $base;
		no strict 'refs';  ## no critic
		@{"$base\::ISA"}= __PACKAGE__;
	} else {
		$pkg= __PACKAGE__;
	}
	my $self= bless $option, $pkg;
	(exists($self->{h}) || exists($self->{'?'})) and return $self->help;
	# ---
	if ($option->{b} || $ENV{PERL_PATH}) {
		$self->{perl_path}= $option->{b} || $ENV{PERL_PATH};
	}
	$self->{perl_path}= which('perl')
	  if (! $self->{perl_path} || -f $self->{perl_path});
	$self->{perl_path}
	  || die q/Please set environment variable 'PERL_PATH'./;
	# ---
	$self->{output} ||= "";
	$self->{output}= $self->{o} if $self->{o};
	# ---
	$self->{project} ||= $option->{p} || "";
	$self->{project}= ucfirst($self->{project});
	unless ($self->{project}=~/^[A-Z][A-Za-z0-9_]+$/) {
		die qq/Project name of invalid format. : $self->{project}/
		  if $self->{project};
	}
	# ---
	$self->{egg_version}= Egg::Release->VERSION;
	$self->{egg_label}= 'Egg::Release v'. Egg::Release->VERSION;
	$self->{gmt} = scalar(gmtime time). ' GMT';
	$self->{year}= (localtime time)[5]+ 1900;
	$self;
}
sub setup_uname {
	my($self)= @_;
	$self->{uname}= $ENV{LOGNAME} || $ENV{USER} || $self->{project};
}
sub create_dir {
	my $self= shift;
	my $path= shift || die q/I want dir./;
	my $result= File::Path::mkpath($path, 1, 0755);  ## no critic
#	print "+ create dir : $path\n";
	$result || 0;
}
sub remove_dir {
	my $self= shift;
	my $path= shift || die q/I want dir./;
	my $result= File::Path::rmtree($path);
	print "- remove dir : $path\n";
	$result || 0;
}
sub output_file {
	my $self = shift;
	my $param= shift || die q/I want param./;
	my $data = shift || return "";
	my $value= ($data->{filetype} && $data->{filetype}=~/^bin/i) ? do {
		MIME::Base64->require;
		MIME::Base64::decode_base64($data->{value});
	  }: do {
		$self->conv($param, \$data->{value}) || return "";
	  };
	my $path= $self->conv($param, \$data->{filename})
	  || die q/I want data->{filename}/;
	my $basedir= File::Basename::dirname($path);
	$self->create_dir($basedir) unless -d $basedir;
	my @path= split /[\\\/]+/, $self->conv($param, \$path);
	my $fh= FileHandle->new(">". File::Spec->catfile(@path) )
	  || die "File Open Error: $path - $!";
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
sub conv {
	my $self = shift;
	my $param= shift || return "";
	my $text = shift || return "";
	return "" unless $$text;
	$$text=~s{<\#\s+(.+?)\s+\#>} [
	  $param->{$1} ? do {
	    ref($param->{$1}) ? $param->{$1}->($self, $param): $param->{$1};
	    }: "";
	 ]sge;
	$$text;
}
sub document_default {
	my $self = shift;
	my $param= shift || return "";
	my $value= $self->{document_template} ||= do {
		YAML->require;
		my $hash= YAML::Load( join '', <DATA> );
		$hash->{document};
	  };
	$value=~s{<\#\s+(.+?)\s+\#>} [$param->{$1} || ""]sge;
	return $value;
}
sub help {
	my($self)= @_;
	print "* Egg::Helper v$VERSION\n";
	print "* Target-project: $self->{project}\n" if $self->{project};
	print "\n";
	if ($self->{mode}=~/^install/i) {
		print <<HELP;
Usage: perl install_helper.pl [option]

* Please set environment variable 'PERL_PATH'.
  -o = Install prefix.
  -b = When you do not set 'PERL_PATH'.

Example:
 * When shell is bash.
 # export PERL_PATH=/usr/bin/perl

 # perl install_helper.pl -o /usr/bin
HELP

	} elsif ($self->{mode}=~/^project/i) {
		my $options= $self->common_options_disp;
		print <<HELP;
# Usage: egg_helper.pl project [options]
$options
HELP

	} elsif ($self->{mode}=~/^yaml/i) {

		my $options= $self->common_options_disp;
		print <<HELP;
# Usage: yaml_generator.pl [options]
$options
HELP

	} elsif ($self->{mode}=~/^prototype/i) {

		my $options= $self->common_options_disp;
		print <<HELP;
# Usage: prototype_generator.pl [options]
$options
HELP

	} elsif ($self->{mode}=~/^dispatch/) {

		my $options= $self->common_options_disp;
		print <<HELP;
# Usage: create_dispatch.pl -d [dispatch_name] [options]
$options
HELP

	} else {
		my $options= $self->common_options_disp;
		print <<HELP;
# Usage: egg_helper.pl [command] [options]

 command:
   project   = Project is generated.
   yaml      = Configuration is output with YAML.
   prototype = prototype.js is output.
   install   = Helper script is installed in an arbitrary place.
$options
HELP

	}
	exit;
}
sub common_options_disp {
	<<HELP;

 options:
   -h or -? = This screen.
   -p = Project Name.
   -v = Generated version is specified.
   -o = Output destination. default is current directory.
   -b = Perl bin path or set environment 'PERL_PATH'.
HELP
}

1;

=head1 NAME

Egg::Helper::Script - It is a base module of the helper script.

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
document: |
  __END__
  # Below is stub documentation for your module. You'd better edit it!
  
  =head1 NAME
  
  <# dist #> - Perl extension for ...
  
  =head1 SYNOPSIS
  
    use <# dist #>;
    
    ... tansu, ni, gon, gon.
  
  =head1 DESCRIPTION
  
  Stub documentation for <# dist #>, created by <# egg_label #>
  
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
