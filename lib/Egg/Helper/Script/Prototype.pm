package Egg::Helper::Script::Prototype;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id$
#
use strict;
use warnings;
use Cwd;
use HTML::Prototype;
use FileHandle;

our $VERSION= '0.01';

sub generate {
	my($self)= @_;
	$self->{output} ||= getcwd || die q/I want output destination./;
	-d $self->{output}
	  || die qq/The configuration directory is not found. : $self->{output}/;

	my $pt= HTML::Prototype->new;

	my $version= HTML::Prototype->VERSION;
	$version=~s/\\\.//go;

	my $script= $pt->define_javascript_functions;
	$script=~s{^.+?<\!--\s*}    []so;
	$script=~s{\s*//\s*-->.+?$} []so;

	my $fh= FileHandle->new(">$self->{output}/prototype-$version.js")
	  || die qq{$! - $self->{output}/prototype-$version.js};
	print $fh $script;
	$fh->close;

	print STDERR <<END_OF_INFO;
 ... completed.

* HTML header example.

<html>
<head>
<script type="text/javascript" src="/prototype-$version.js"></script>
  ...

END_OF_INFO

	return 1;
}

1;

__END__

=head1 NAME

Egg::Helper::Script::Prototype - Prototype.js is output to an arbitrary directory.

=head1 SYNOPSIS

Refer to help.

 prototype_generator.pl -?

Even if nothing is specified, it outputs it to '[MYPROJECT]/htdocs' usually.

 [MYPROJECT]/bin/prototype_generator.pl

=head1 DESCRIPTION

Please use output prototype.js reading from the HTML header.

 <html>
 <head>
 <script type="text/javascript" src="/prototype-1.XX.js"></script>
 ...
 </head>
 <body>
 ....
 ......

prototype.js can be used by this.
When ajax script is written, it is very convenient.

Please see the site of prototype.js here in detail.
http://prototype.conio.net/

=head1 SEE ALSO

L<http://prototype.conio.net/>
L<HTML::Prototype>
L<Egg::Helper::Script>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
