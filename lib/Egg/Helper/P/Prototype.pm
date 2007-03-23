package Egg::Helper::P::Prototype;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Prototype.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use HTML::Prototype;
use base qw/Egg::Component/;

our $VERSION= '0.01';

sub new {
	my $self= shift->SUPER::new();
	my $pt= HTML::Prototype->new;
	my $g= $self->global;

	my $version= HTML::Prototype->VERSION;
	$version=~s/\\\.//go;

	my $script= $pt->define_javascript_functions;
	$script=~s{^.+?<\!--\s*}    []so;
	$script=~s{\s*//\s*-->.+?$} []so;

	my $C= $self->load_config;
	$C->{static} ||= 'htdocs';
	my $out_path= "$g->{project_root}/$C->{static}";

	$self->save_file({}, {
	  filename=> "$out_path/prototype-$version.js",
	  value   => $script,
	  });

	print <<END_OF_INFO;
 ... completed.

* HTML header example.

<html>
<head>
<script type="text/javascript" src="/prototype-$version.js"></script>
  ...

END_OF_INFO
}

1;

__END__

=head1 NAME

Egg::Helper::P::Prototype - Prototype.js is output for Egg.

=head1 SYNOPSIS

  # cd /path/to/MYPROJECT/bin
  
  # ./myproject_helper.pl P:Prototype
  
  ... completed.

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
L<Egg::Helper>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
