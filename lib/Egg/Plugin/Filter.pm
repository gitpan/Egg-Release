package Egg::Plugin::Filter;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Filter.pm 200 2007-10-31 04:30:14Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use HTML::Entities;

our $VERSION= '2.03';

=head1 NAME

Egg::Plugin::Filter - Filter of request query for Egg plugin.

=head1 SYNOPSIS

  use Egg qw/ Filter /;

  # The received form data is filtered.
  $e->filter(
   myname => [qw/hold_html abs_strip trim/],
   address=> [qw/hold_html crlf:2 abs_strip trim/],
   tel    => [qw/hold phone/],
   );

  # Cookie is filtered.
  my $cookie= $e->filter( {
    nick_name=> [qw/strip_html abs_strip trim/],
    email    => [qw/hold_html hold/],
    }, $e->request->cookies );

=head1 DESCRIPTION

It is filter plugin to pass it as for data.

=head1 FILTERS

=head2 trim

The space character in the back and forth is deleted.

=head2 hold

The space character is deleted.

=head2 strip

The continuousness of the space character is substituted for one half angle 
space.

=head2 hold_tab

The tab is deleted.

=head2 space

Consecutive half angle space is settled in one.

=head2 crlf:[NUM]

A consecutive changing line is settled in [NUM] piece. * The tab is deleted.

Default when [NUM] is omitted is 1.

=head2 strip_tab

Continuousness in the tab is substituted for one half angle space.

=head2 hold_crlf

It is 'hold' for changing line and the tab.

=head2 strip_crlf

It is 'strip' for changing line and the tab.

=head2 hold_html

The character string seen the HTML tag is deleted.

=head2 strip_html

The character string seen the HTML tag is substituted for one half angle space.

=head2 escape_html

L<HTML::Entities>::encode_entities is done.

=head2 digit

It deletes it excluding the normal-width figure.

=head2 alphanum

It deletes it excluding the alphanumeric character.

=head2 integer

It deletes it excluding the integer.

=head2 pos_integer

It deletes it excluding the positive integer.

=head2 neg_integer

It deletes it excluding the negative integer.

=head2 decimal

It deletes it excluding the integer including small number of people.

=head2 pos_decimal

It deletes it excluding a positive integer including small number of people.

=head2 neg_decimal

It deletes it excluding a negative integer including small number of people.

=head2 dollars

It deletes it excluding the figure that can be used with dollar currency.

=head2 lc

lc is done.

=head2 uc

uc is done.

=head2 ucfirst

ucfirst is done.

=head2 phone

The character that cannot be used by the telephone number is deleted.

=head2 sql_wildcard

'*' is substituted for '%'.

=head2 quotemeta

quotemeta is done.

=head2 email

The domain name part in the mail address is converted into the small letter.

  MyName@DOMAIN.COM => MyName@domain.com

=head2 url

The domain name part in the URL is converted into the small letter.

  http://MYDOMAIN.COM/Hoge/Boo.html => http://mydomain.com/Hoge/Boo.html

=cut

my $EGG= 0;
my $VAL= 1;
my $ARG= 2;

our %Filters= (

 trim=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~s{^\s+} []s;
   ${$_[$VAL]}=~s{\s+$} []s;
   },
 hold=> sub {
   ${$_[$VAL]}=~s{\s+} []sg if defined(${$_[$VAL]});
   },
 strip=> sub {
   ${$_[$VAL]}=~s{\s+} [ ]sg if defined(${$_[$VAL]});
   },
 space=> sub {
   ${$_[$VAL]}=~s{  +} [ ]sg if defined(${$_[$VAL]});
   },
 crlf=> sub {
   return 0 unless defined(${$_[$VAL]});
   my $re= "\n" x ( $_[$ARG]->[0] ? (($_[$ARG]->[0]=~/(\d+)/)[0] || 1 ): 1 );
   ${$_[$VAL]}=~s{\n\n+} [$re]sge;
   },
 hold_tab=> sub {
   ${$_[$VAL]}=~tr/\t//d if defined(${$_[$VAL]});
   },
 strip_tab=> sub {
   ${$_[$VAL]}=~tr/\t/ / if defined(${$_[$VAL]});
   },
 hold_crlf=> sub {
   ${$_[$VAL]}=~tr/\n//d  if defined(${$_[$VAL]});
   },
 strip_crlf=> sub {
   ${$_[$VAL]}=~tr/\n/ / if defined(${$_[$VAL]});
   },
 hold_html=> sub {
   ${$_[$VAL]}=~s{<.+?>} []sg  if defined(${$_[$VAL]});
   },
 strip_html=> sub {
   ${$_[$VAL]}=~s{<.+?>} [ ]sg if defined(${$_[$VAL]});
   },
 escape_html=> sub {
   ${$_[$VAL]}= &__escape_html(${$_[$VAL]}) if defined(${$_[$VAL]});
   },
 digit=> sub {
   ${$_[$VAL]}=~s{\D} []g if defined(${$_[$VAL]});
   },
 alphanum=> sub {
   ${$_[$VAL]}=~s{\W} []g if defined(${$_[$VAL]});
   },
 integer=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/0-9+-//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/([\-\+]?\d+)/ ? $1: undef;
   },
 pos_integer=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/0-9+//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/(\+?\d+)/ ? $1: undef;
   },
 neg_integer=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/0-9-//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/(\-?\d+)/ ? $1: undef;
   },
 decimal=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/,/./; ${$_[$VAL]}=~tr/0-9.+-//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/([\-\+]?\d+\.?\d*)/ ? $1: undef;
   },
 pos_decimal=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/,/./; ${$_[$VAL]}=~tr/0-9.+//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/(\+?\d+\.?\d*)/ ? $1: undef;
   },
 neg_decimal=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/,/./; ${$_[$VAL]}=~tr/0-9.-//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/(\-?\d+\.?\d*)/ ? $1: undef;
   },
 dollars=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/,/./; ${$_[$VAL]}=~tr/0-9.+-//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/(\d+\.?\d?\d?)/ ? $1: undef;
   },
 lc=> sub {
   ${$_[$VAL]}= lc(${$_[$VAL]});
   },
 uc=> sub {
   ${$_[$VAL]}= uc(${$_[$VAL]});
   },
 ucfirst=> sub {
   ${$_[$VAL]}= ucfirst(${$_[$VAL]});
   },
 phone=> sub {
   ${$_[$VAL]}=~s/[^\d,\(\)\.\s,\-#]//g if defined(${$_[$VAL]});
   },
 sql_wildcard=> sub {
   ${$_[$VAL]}=~tr/*/%/ if defined(${$_[$VAL]});
   },
 quotemeta=> sub {
   ${$_[$VAL]}= quotemeta(${$_[$VAL]}) if defined(${$_[$VAL]});
   },
 email=> sub {
   return 0 unless ${$_[$VAL]};
   ${$_[$VAL]}=~s{\s+} []sg;
   ${$_[$VAL]}=~s{(.+?\@)([^\@]+)$} [$1. lc($2)]e;
   },
 url=> sub {
   return 0 unless ${$_[$VAL]};
   require URI;
   ${$_[$VAL]}=~s{\s+} []sg;
   my $uri= URI->new(${$_[$VAL]});
   ${$_[$VAL]}= $uri->canonical;
   },
 );

sub _filters { \%Filters }

=head1 CONFIGURATION

It is possible to set it by 'plugin_filter' as follows.

=head2 plugins => [PLUGIN_ARRAY]

List of plugin module to enhance filter.

The specified name is progressed and treated
 with 'Egg::Plugin::Filter::[PLUGIN_NAME]' usually.
When + is applied to the head, the name is treated as it is as a module name.

  plugins => [qw/ Japanese::EUC /],

=cut
sub _setup {
	my($e)= @_;
	my $config= $e->config->{plugin_filter} ||= {};
	if ($config->{plugins}) {
		for my $name (ref($config->{plugins}) eq 'ARRAY'
		                ? @{$config->{plugins}}: $config->{plugins}) {
			my $pkg= $name=~m{^\++(.+)} ? $1
			       : __PACKAGE__. "::Plugin::$name";
			$pkg->require or die __PACKAGE__.": Error: $@";
			if (my $code= $pkg->can('_filters')) {
				my $hash= $code->($pkg, $e) || next;
				@Filters{keys %$hash}= values %$hash;
			} elsif (my $setup= $pkg->can('_setup_filters')) {
				$setup->($pkg, $e);
			}
		}
	}
	$e->next::method;
}

=head1 METHODS

=head2 filter ( [ATTR_HASH], [TARGET_PARAM] )

The filter is processed according to ATTR_HASH, and the result is returned.

When TARGET_PARAM is omitted, $e-E<gt>request-E<gt>params is used.

Please set the list of the filter name to the parameter name of the object about
ATTR_HASH.

  $e->filter(
    param_name1 => [qw/ strip space trim /],
    param_name2 => [qw/ strip_html space trim /],
    param_name3 => [qw/ strip_html crlf:3 trim /],
    );

=cut
sub filter {
	my $e= shift;
	$_[0] || die q{ I want filter definition. };
	my($args, $param);
	if (ref($_[0]) eq 'HASH') {
		$args = shift;
		$param= shift || $e->request->params;
	} else {
		$args = {@_};
		$param= $e->request->params;
	}

	MAINFILTER:
	while (my($key, $config)= each %$args) {
		next unless $param->{$key};
		QUERYPARAM:
		for (ref($param->{$key}) eq 'ARRAY' ? @{$param->{$key}}: $param->{$key}) {
			s/(?:\r\n|\r)/\n/sg;
			my $value= \$_;
			FILTERPIECE:
			for my $piece (@$config) {
				my($name, @args)= split /\:/, $piece;
				my $func= $Filters{$name}
				       || die qq{ '$name' filter is not defined. };
				eval { $func->($e, $value, \@args) };
				$@ and die __PACKAGE__. ": $@";
			}
		}
	}

	$param;
}
sub __escape_html { &HTML::Entities::encode_entities(shift, q{'"&<>}) }

=head1 SEE ALSO

L<HTML::Entities>,
L<Egg::Request>,
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
