package Egg::Plugin::Tools;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Tools.pm 184 2007-08-06 19:59:01Z lushe $
#
use strict;
use warnings;
use URI::Escape;
use HTML::Entities;
use Carp qw/croak/;

our $VERSION = '2.06';

=head1 NAME

Egg::Plugin::Tools - Various function collections.

=head1 SYNOPSIS

  use Egg qw/ Tools /;

  $e->escape_html($html);
  
  $e->unescape_html($plain);
  
  $e->sha1_hex('abcdefg');
  
  $e->comma('12345.123');
  
  my @array= (1..100);
  $e->shuffle_array(\@array);

=head1 DESCRIPTION

This plugin offers the method of various functions.

=head1 METHODS

=cut
{
	no warnings 'redefine';

=head2 encode_entities ( [HTML_TEXT], [ARGS] )

The result of L<HTML::Entities>::encode_entities is returned.

=over 4

=item * Alias: escape_html, eHTML

=back

=cut
	sub encode_entities {
		shift; my $args= $_[1] || q{'"&<>@};
		&HTML::Entities::encode_entities($_[0], $args);
	}
	*escape_html = \&encode_entities;
	*eHTML       = \&encode_entities;

=head2 encode_entities_numeric ( [HTML_TEXT], [ARGS] )

The result of L<HTML::Entities>::encode_entities_numeric is returned.

=cut
	sub encode_entities_numeric
	  { shift; &HTML::Entities::encode_entities_numeric(@_) }

=head2 decode_entities ( [PLAIN_TEXT], [ARGS] )

The result of L<HTML::Entities>::decode_entities is returned.

=over 4

=item * Alias: unescape_html, ueHTML

=back

=cut
	sub decode_entities
	  { shift; &HTML::Entities::decode_entities(@_) }
	*unescape_html = \&decode_entities;
	*ueHTML        = \&decode_entities;

=head2 uri_escape ( [URI_PARTS], [ARGS] )

The result of L<URI::Escape>::uri_escape is returned.

=over 4

=item * Alias: escape_uri, eURI

=back

=cut
	sub uri_escape
	  { shift; &URI::Escape::uri_escape(@_) }
	*escape_uri = \&uri_escape;
	*eURI       = \&uri_escape;

=head2 uri_escape_utf8 ( [URI_PARTS], [ARGS] )

The result of L<URI::Escape>::uri_escape_utf8 is returned.

=cut
	sub uri_escape_utf8
	  { shift; &URI::Escape::uri_escape_utf8(@_) }

=head2 uri_unescape ( [URI], [ARGS] )

The result of L<URI::Escape>::uri_unescape is returned.

=over 4

=item * Alias: unescape_uri, ueURI

=back

=cut
	sub uri_unescape
	  { shift; &URI::Escape::uri_unescape(@_) }
	*unescape_uri = \&uri_unescape;
	*ueURI        = \&uri_unescape;

  };

=head2 call ( [PACKAGE_NAME], [METHOD_NAME], [ARGS] )

PACKAGE_NAME is read, and METHOD_NAME is called.

Please give PACKAGE_NAME the module name since the project name.

$e and ARGS are passed to METHOD_NAME.

  # MyApp::AnyPkg->call_method($e, ... args ); is done.
  my $result= $e->call( AnyPkg => 'call_method', .... args );

=cut
sub call {
	my $e= shift;
	my $pkg= shift || croak q{ I want include package name. };
	   $pkg= "$e->{namespace}::$pkg";
	my $method= shift || return $pkg;
	$pkg->require or die $@;
	$pkg->$method($e, @_);
}

=head2 sha1_hex ( [DATA] )

The result of L<Digest::SHA1>::sha1_hex is returned.

=over 4

=item * Alias: md5_hex

=back

=cut
*md5_hex= \&sha1_hex;
sub sha1_hex {
	require Digest::SHA1;
	my $e   = shift;
	my $data= ref($_[0]) eq 'SCALAR' ? $_[0]: \$_[0];
	Digest::SHA1::sha1_hex($$data);
}

=head2 comma ( [NUMBER] )

Is put in given NUMBER in each treble and it returns it.

  $e->comma('123456')       =>    123,456
  $e->comma('-654321.123')  =>   -654,321.123
  $e->comma('+123456789.0') => +1,234,567.0

=cut
sub comma {
	my $num= $_[1] || return 0;
	my($a, $b, $c)= $num=~/^([\+\-])?(\d+)(\.\d+)?/;
	1 while $b=~s{(.*\d)(\d{3})} [$1,$2];
	($a || ""). $b. ($c || "");
}

=head2 shuffle_array ( [ARRAY] )

It returns it mixing given ARRAY at random.

  my @array= (1..10);
  $e->shuffle_array(\@array);

* Quotation from perlfaq.

=cut
sub shuffle_array {
	# Quotation from perlfaq.
	my $surf= shift;
	my $deck= $_[0] ? (ref($_[0]) eq 'ARRAY' ? $_[0]: [@_])
	                : croak q{ I want array. };
	my $i = @$deck;
	while ($i--) {
		my $j = int rand ($i+1);
		@$deck[$i,$j] = @$deck[$j,$i];
	}
	wantarray ? @$deck: $deck;
}

=head2 filefind ( [FIND_REGIX], [SEARCH_DIR_ARRAY] )

L<File::Find> is done and the result is returned by the ARRAY reference.

  my $files= $e->filefind(qr{\.pm$}, qw( /usr/lib/perl5/... ))
          || return 0;

=cut
sub filefind {
	require File::Find;
	my $e= shift;
	my $regix= shift || croak q{ I want File Regixp };
	@_ || croak q{ I want Find PATH. };
	my @files;
	my $wanted= sub {
		push @files, $File::Find::name if $File::Find::name=~m{$regix};
	  };
	File::Find::find($wanted, ref($_[0]) eq 'ARRAY' ? @{$_[0]}: @_ );
	@files ? \@files: 0;
}

=head2 referer_check ([FLAG])

The request is own passing on the site or it checks it.

If the request method is POST and doesn't exist when FLAG is given, false is 
returned.

HTTP_REFERER cannot be acquired by the influence of the security software that
those who inspect it use etc.
When HTTP_REFERER cannot be acquired by there is often a thing, too, true is 
returned.

=cut
sub referer_check {
	my $e= shift;
	if ($_[0]) { $e->req->is_post || return 0 }
	my $refer= $e->req->referer   || return 1;
	my $host = $e->req->host_name || return 0;
	$refer=~m{^https?\://$host} ? 1: 0;
}

=head2 gettimeofday

The result of L<Time::HiRes>::gettimeofday is returned.

  my($second, $micro)= $e->gettimeofday;

=cut
sub gettimeofday {
	require Time::HiRes;
	Time::HiRes::gettimeofday();
}

=head2 mkpath ( [DIR], [VERBOSE], [PERMISSION] )

L<File::Path>::mkpath is done.

* The argument extends to L<File::Path>::mkpath as it is.

  $e->mkpath('/home/hoge', 0, 0755);

=cut
sub mkpath {
	require File::Path;
	shift;
	File::Path::mkpath(@_);
}

=head2 rmtree ( [DIR_LIST] )

L<File::Path>::rmtree is done.

* The argument extends to L<File::Path>::rmtree as it is.

  $e->rmtree('/home/hoge', '/home/boo');

=cut
sub rmtree {
	require File::Path;
	shift;
	File::Path::rmtree(@_);
}

=head2 jfold ( [STRING], [LENGTH] )

L<Jcode>::jfold is done.

Egg::Encode plugin is used.

$e-E<gt>encode-E<gt>set([STRING])-E<gt>jfold([LENGTH]) is executed.

The result is returned by the ARRAY reference.

  my $text= 'ABCDEFG';
  print $e->jfold(\$text, 3)->[0];  ## print is "ABC".

=cut
sub jfold {
	my $e   = shift;
	my $str = shift || croak q{ I want string. };
	[ $e->encode->set($str)->jfold(@_) ];
}

=head2 timelocal ( [YEAR], [MONTH], [DAY], [HOUR], [MINUTE], [SECOND] )

The result of L<Time::Local>::timelocal is returned.

* Please note that order by which the argument is given has reversed completely.

  my $time= $e->timelocal(0, 0, 0, 1, 1, 2007);

The date of a specific format can be passed.

  my $time= $e->timelocal("2007-01-01 00:00:00");

* However, it corresponds only to the following formats.

  - 2007/01/01 00:00:00
  - 2007-01-01 00:00:00

=cut
sub timelocal {
	my $e  = shift;
	my $arg= shift || croak q{ I want argument. };
	require Time::Local;
	my($yer, $mon, $day, $hou, $min, $sec);
	if ($arg=~m{^(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})(.*)}) {
		($arg, $yer, $mon, $day)= ($4, $1, $2, $3);
		if ($arg and $arg=~m{^.+?(\d{1,2})\:(\d{1,2})(.*)}) {
			($arg, $hou, $min)= ($3, $1, $2);
			if ($arg and $arg=~m{^\:(\d{1,2})}) { $sec= $1 }
		}
		$hou ||= 0;  $min ||= 0;  $sec ||= 0;
	} else {
		$yer= $arg; $yer=~m{\D} and croak q{ Bad argument. };
		$mon= shift || croak q{ I want Month. };
		$day= shift || croak q{ I want Day. };
		$hou= shift || 0;  $min= shift || 0;  $sec= shift || 0;
	}
	Time::Local::timelocal($sec, $min, $hou, $day, ($mon- 1), ($yer- 1900));
}

1;

=head1 SEE ALSO

L<HTML::Entities>,
L<URI::Escape>,
L<Digest::SHA1>,
L<Time::HiRes>,
L<File::Path>,
L<Egg::Release>,
L<Egg::Plugin::Encode>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
