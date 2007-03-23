package Egg::Plugin::Filter;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Filter.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use constant EGG=> 0;
use constant VAL=> 1;
use constant ARG=> 2;

our $VERSION= '0.02';

our %filters= (
 trim=> sub {
   ${$_[VAL]}=~s{(^\s+|\s+$)} []sg if defined(${$_[VAL]});
   },
 hold=> sub {
   ${$_[VAL]}=~s{\s+} []sg if defined(${$_[VAL]});
   },
 strip=> sub {
   ${$_[VAL]}=~s{\s+} [ ]sg if defined(${$_[VAL]});
   },
 hold_tab=> sub {
   ${$_[VAL]}=~tr/\r\t//d if defined(${$_[VAL]});
   },
 strip_tab=> sub {
   ${$_[VAL]}=~tr/\r\t/ / if defined(${$_[VAL]});
   },
 abs_strip_tab=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/\r\t/ /;
   1 while ${$_[VAL]}=~s{  +} [ ]sg;
   },
 hold_crlf=> sub {
   ${$_[VAL]}=~tr/\r\n\t//d  if defined(${$_[VAL]});
   },
 strip_crlf=> sub {
   ${$_[VAL]}=~tr/\r\n\t/ / if defined(${$_[VAL]});
   },
 abs_strip_crlf=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/\r\n\t/ /;
   1 while ${$_[VAL]}=~s{  +} [ ]sg;
   },
 crlf1=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/\t//d; ${$_[VAL]}=~tr/\r/\n/;
   1 while ${$_[VAL]}=~s/\n\n+/\n/sg;
   },
 crlf2=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/\t//d; ${$_[VAL]}=~tr/\r/\n/;
   1 while ${$_[VAL]}=~s/\n\n\n+/\n\n/sg;
   },
 crlf3=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/\t//d; ${$_[VAL]}=~tr/\r/\n/;
   1 while ${$_[VAL]}=~s/\n\n\n\n+/\n\n\n/sg;
   },
 hold_html=> sub {
   ${$_[VAL]}=~s{<.+?>} []sg  if defined(${$_[VAL]});
   },
 strip_html=> sub {
   ${$_[VAL]}=~s{<.+?>} [ ]sg if defined(${$_[VAL]});
   },
 abs_strip_html=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~s{<.+?>} [ ]sg;
   1 while ${$_[VAL]}=~s{  +} [ ]sg;
   },
 escape_html=> sub {
   ${$_[VAL]}= $_[EGG]->escape_html(${$_[VAL]}) if defined(${$_[VAL]});
   },
 digit=> sub {
   ${$_[VAL]}=~s{\D} []g if defined(${$_[VAL]});
   },
 alphanum=> sub {
   ${$_[VAL]}=~s{\W} []g if defined(${$_[VAL]});
   },
 integer=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/0-9+-//dc;
   ${$_[VAL]}= ${$_[VAL]}=~/([\-\+]?\d+)/ ? $1: undef;
   },
 pos_integer=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/0-9+//dc;
   ${$_[VAL]}= ${$_[VAL]}=~/(\+?\d+)/ ? $1: undef;
   },
 neg_integer=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/0-9-//dc;
   ${$_[VAL]}= ${$_[VAL]}=~/(\-?\d+)/ ? $1: undef;
   },
 decimal=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/,/./; ${$_[VAL]}=~tr/0-9.+-//dc;
   ${$_[VAL]}= ${$_[VAL]}=~/([\-\+]?\d+\.?\d*)/ ? $1: undef;
   },
 pos_decimal=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/,/./; ${$_[VAL]}=~tr/0-9.+//dc;
   ${$_[VAL]}= ${$_[VAL]}=~/(\+?\d+\.?\d*)/ ? $1: undef;
   },
 neg_decimal=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/,/./; ${$_[VAL]}=~tr/0-9.-//dc;
   ${$_[VAL]}= ${$_[VAL]}=~/(\-?\d+\.?\d*)/ ? $1: undef;
   },
 dollars=> sub {
   return 0 unless defined(${$_[VAL]});
   ${$_[VAL]}=~tr/,/./; ${$_[VAL]}=~tr/0-9.+-//dc;
   ${$_[VAL]}= ${$_[VAL]}=~/(\d+\.?\d?\d?)/ ? $1: undef;
   },
 lc=> sub {
   ${$_[VAL]}= lc(${$_[VAL]});
   },
 uc=> sub {
   ${$_[VAL]}= uc(${$_[VAL]});
   },
 ucfirst=> sub {
   ${$_[VAL]}= ucfirst(${$_[VAL]});
   },
 phone=> sub {
   ${$_[VAL]}=~s/[^\d,\(\)\.\s,\-#]//g if defined(${$_[VAL]});
   },
 sql_wildcard=> sub {
   ${$_[VAL]}=~tr/*/%/ if defined(${$_[VAL]});
   },
 quotemeta=> sub {
   ${$_[VAL]}= quotemeta(${$_[VAL]}) if defined(${$_[VAL]});
   },
 );

sub setup {
	my($e)= @_;
	my $config= $e->config->{plugin_filter} ||= {};
	if ($config->{plugins} && ref($config->{plugins}) eq 'ARRAY') {
		for my $pkg (@{$config->{plugins}}) {
			$pkg->require or Egg->throw(__PACKAGE__.": Error: $@");
			my $hash= $pkg->filters || next;
			@filters{keys %$hash}= values %$hash;
		}
	}
	$e->next::method;
}
sub filter {
	my $e= shift;
	$_[0] || Egg->throw("I want filter definition.");
	my($args, $param);
	if (ref($_[0])) {
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
			my $value= \$_;
			FILTERPIECE:
			for my $piece (@$config) {
				my($name, @args)= $piece=~/\:/ ? (split /\:/, $piece): ($piece, ());
				my $func= $filters{$name} || next FILTERPIECE;
				eval { $func->($e, $value, \@args) };
				if (my $err= $@) { Egg->throw(__PACKAGE__.": Error: $err") }
			}
		}
	}
	return $param;
}

1;

__END__

=head1 NAME

Egg::Plugin::Filter - Request query is straightened..

=head1 SYNOPSIS

 # Your control file.
 package [MYPROJECT];
 use strict;
 use Egg qw/-Debug Filter/;

* This is code.

 $e->filter( {
   myname => [qw/hold_html abs_strip trim/],
   address=> [qw/hold_html crlf1 abs_strip trim/],
   tel    => [qw/hold phone/],
   } );
 
 my $cookie= $e->filter( {
   nick_name=> [qw/strip_html abs_strip trim/],
   email    => [qw/hold_html hold/],
   }, $e->request->cookies );

=head1 DESCRIPTION

This module makes it easy though the code in which the request query is
 straightened is very annoying.

=head1 METHODS

=head2 $e->filter([.... ]);

The filter processing is executed.

=head1 Filters

=head2 trim

Space is erased before and behind the value.

=head2 hold

All the space characters are erased.

=head2 strip

Space character is replaced with all one space.

=head2 hold_tab

All tabs are erased.

=head2 strip_tab

Tab is substituted for one space.

=head2 abs_strip_tab

Tab is substituted for one space. In addition, the effort
 to settle the space in one completely is done.

=head2 hold_crlf

All crlf are erased.

=head2 strip_crlf

crlf is substituted for one space.

=head2 abs_strip_crlf

crlf is substituted for one space. In addition, the effort
 to settle the space in one completely is done.

=head2 crlf1

Two or more crlf is adjusted to one.

=head2 crlf2

Two or more crlf is adjusted to two.

=head2 crlf3

Two or more crlf is adjusted to three.

=head2 hold_html

All HTML tag are erased.

=head2 strip_html

HTML tag is substituted for one space.

=head2 abs_strip_html

HTML tag is substituted for one space. In addition, the
 effort to settle the space in one completely is done.

=head2 escape_html

It invalidates it escaping in HTML Tag.

=head2 digit

digits characters is left.

=head2 alphanum

alphanumerical character is left.

=head2 integer

integer is left.

=head2 pos_integer

positive integer is left.

=head2 neg_integer

negative integer is left.

=head2 decimal

decimal is left.

=head2 pos_decimal

positive decimal is left.

=head2 neg_decimal

negative decimal is left.

=head2 dollars

express dollars like currency is left.

=head2 lc

Everything lowercases word.

=head2 uc

Everything is replaced with the capital letter.

=head2 ucfirst

Only the first character is replaced with the capital letter.

=head2 phone

Only the character used for the telephone number is left.

=head2 sql_wildcard

The asterisk is replaced with the wild-card for SQL. 

=head2 quotemeta

It escapes in the meta tag for the regular expression.

=head1 Plugin Support

The function to build in the filter of making by oneself as a plugin
 is supported. 

Example:

 #
 # This is an original filter module.
 #
 package [MY_FILTER];
 use strict;
 #
 # 'filters' becomes a method to which 'Egg::Plugin::Filter' refers.
 #
 sub filters {
  {
    # $value = Scalar reference.  $args = Array reference.
    filter1=> sub {
      my($e, $value, $args)= @_;
      .... ban, ban.
      },
    filter2=> sub {
      my($e, $value, $args)= @_;
      .... won, won.
      },
    };
 }

 #
 # Configuration is setup.
 #
   plugin_filter=> {
     plugins=> [qw/[MY_FILTER]/],
     },

Complete.

=head1 THANKS

It referred to the code of 'HTML::FormValidator' partially.

=head1 SEE ALSO

L<Egg::Release>,
L<HTML::FormValidator>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
