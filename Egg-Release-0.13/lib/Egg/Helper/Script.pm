package Egg::Helper::Script;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Script.pm 34 2006-12-14 08:17:52Z lushe $
#
use strict;
use warnings;
use FileHandle;
use File::Which;
use UNIVERSAL::require;
use Getopt::Std;
use Egg::Release;

our $VERSION= '0.01';

sub run {
	my $class = shift;
	my $cmd   = shift || shift(@ARGV);
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
sub comp {
	my($class, $option, $base)= @_;
	my $pkg;
	if ($base) {
		$base->require or die $@;
		$pkg= $base;
		no strict 'refs';
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
	$self->{output}=~s{[\\\/]+$} [];
	# ---
	$self->{project} ||= $option->{p} || "";
	$self->{project}= ucfirst($self->{project});
	unless ($self->{project}=~/^[A-Z][A-Za-z0-9_]+$/) {
		die qq/Project name of invalid format. : $self->{project}/
		  if $self->{project};
	}
	# ---
	$self->{egg_version}= Egg::Release->VERSION;
	$self;
}
sub setup_uname {
	my($self)= @_;
	$self->{uname}= $ENV{LOGNAME} || $ENV{USER} || $self->{project};
}
sub output_file {
	my $self = shift;
	my $path = shift || die q/I want Path./;
	my $value= shift || "";
	my $fh= FileHandle->new(">$path") || die "File Open Error: $path - $!";
	binmode($fh);
	print $fh $value;
	$fh->close;
	print STDERR "+ create: $path\n";
	1;
}
sub document_default {
	MIME::Base64->require;
	my($self)= @_;
	$self->{create_year} ||= (localtime time)[5];
	my $value= <<END_OF_TEXT;
IyBCZWxvdyBpcyBzdHViIGRvY3VtZW50YXRpb24gZm9yIHlvdXIgbW9kdWxlLiBZb3UnZCBiZXR0
ZXIgZWRpdCBpdCENCg0KPWhlYWQxIE5BTUUNCg0KPCUgcHJvamVjdCAlPiAtIFBlcmwgZXh0ZW5z
aW9uIGZvciBibGFoIGJsYWggYmxhaA0KDQo9aGVhZDEgU1lOT1BTSVMNCg0KICB1c2UgPCUgcHJv
amVjdCAlPjsNCiAgYmFuIGJvIGJvIGJvbi4NCg0KPWhlYWQxIERFU0NSSVBUSU9ODQoNClN0dWIg
ZG9jdW1lbnRhdGlvbiBmb3IgPCUgcHJvamVjdCAlPiwgY3JlYXRlZCBieSA8JSBlZ2dfdmVyc2lv
biAlPi4NCg0KQmxhaCBibGFoIGJsYWguDQoNCj1oZWFkMSBTRUUgQUxTTw0KDQpMPEVnZzo6UmVs
ZWFzZT4sDQoNCj1oZWFkMSBBVVRIT1INCg0KPCUgdW5hbWUgJT4sIEU8bHQ+PCUgdW5hbWUgJT5F
PDY0PmxvY2FsZG9tYWluRTxndD4NCg0KPWhlYWQxIENPUFlSSUdIVA0KDQpDb3B5cmlnaHQgKEMp
IDwlIGNyZWF0ZV95ZWFyICU+IGJ5IDwlIHVuYW1lICU+DQoNClRoaXMgbGlicmFyeSBpcyBmcmVl
IHNvZnR3YXJlOyB5b3UgY2FuIHJlZGlzdHJpYnV0ZSBpdCBhbmQvb3IgbW9kaWZ5DQppdCB1bmRl
ciB0aGUgc2FtZSB0ZXJtcyBhcyBQZXJsIGl0c2VsZiwgZWl0aGVyIFBlcmwgdmVyc2lvbiA1Ljgu
NiBvciwNCmF0IHlvdXIgb3B0aW9uLCBhbnkgbGF0ZXIgdmVyc2lvbiBvZiBQZXJsIDUgeW91IG1h
eSBoYXZlIGF2YWlsYWJsZS4NCg0KPWN1dA0K
END_OF_TEXT
	$value= MIME::Base64::decode_base64($value);
	$value=~s/<\%\s+(.+?)\s+\%>/$self->{$1}/sg;
	return $value;
}
sub help {
	my($self)= @_;
	print STDERR "* Egg::Helper v$VERSION\n";
	print STDERR "* Target-project: $self->{project}\n" if $self->{project};
	print STDERR "\n";
	if ($self->{mode}=~/^install/i) {
		print STDERR <<HELP;
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
		print STDERR <<HELP;
# Usage: egg_helper.pl project [options]
$options
HELP

	} elsif ($self->{mode}=~/^yaml/i) {

		my $options= $self->common_options_disp;
		print STDERR <<HELP;
# Usage: yaml_generator.pl [options]
$options
HELP

	} elsif ($self->{mode}=~/^prototype/i) {

		my $options= $self->common_options_disp;
		print STDERR <<HELP;
# Usage: prototype_generator.pl [options]
$options
HELP

	} elsif ($self->{mode}=~/^dispatch/) {

		my $options= $self->common_options_disp;
		print STDERR <<HELP;
# Usage: create_dispatch.pl -d [dispatch_name] [options]
$options
HELP

	} else {
		my $options= $self->common_options_disp;
		print STDERR <<HELP;
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

__END__

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
