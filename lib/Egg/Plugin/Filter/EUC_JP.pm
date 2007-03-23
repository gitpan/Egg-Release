package Egg::Plugin::Filter::EUC_JP;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: EUC_JP.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use constant EGG=> 0;
use constant VAL=> 1;
use constant ARG=> 2;
use base qw/Egg::Plugin::Filter/;

our $VERSION= '0.01';

my $Zspace= q{(?:\xA1\xA1)};

sub setup {
	my($e)= @_;
	my %filters= (
	 h2z=> sub {
	   return 0 unless defined(${$_[VAL]});
	   ${$_[VAL]}= ${$_[EGG]}->encode->set($_[VAL])->h2z;
	   },
	 j_trim=> sub {
	   return 0 unless defined(${$_[VAL]});
	   1 while ${$_[VAL]}=~s{^(?:\s|$Zspace)+} []sg;
	   1 while ${$_[VAL]}=~s{(?:\s|$Zspace)$} []sg;
	   },
	 j_hold=> sub {
	   defined(${$_[VAL]}) and ${$_[VAL]}=~s{(?:\s|$Zspace)+} []sg;
	   },
	 j_strip=> sub {
	   return 0 unless defined(${$_[VAL]});
	   ${$_[VAL]}=~s{(?:\s|$Zspace)+} [ ]sg;
	   },
	 j_strip_j=> sub {
	   return 0 unless defined(${$_[VAL]});
	   ${$_[VAL]}=~s{(?:\s|$Zspace)+} [¡¡]sg;
	   },
	 );
	@Egg::Plugin::Filter::filters{keys %filters}= values %filters;
	$e->next::method;
}

1;

__END__

=head1 NAME

Egg::Plugin::Filter::EUC_JP - Filter module for Japanese euc.

=head1 SYNOPSIS

 package [MYPROJECT];
 use strict;
 use Egg qw/-Debug Filter::EUC_JP/;

 $e->filter( {
   myname  => [qw/hold_html h2z j_strip_j j_trim/],
   address => [qw/hold_html h2z j_strip j_trim/],
   } );

=head1 DESCRIPTION

B<$e-E<gt>config-E<gt>{character_in}> Thing that A is made 'B<euc>'.

The character takes the shape when 'sjis' and 'utf8' are set.

=head1 FILTERS

=head2 h2z

The one-byte character is made em-size.
This is processed with B<$e-E<gt>encode-E<gt>set(var)-E<gt>h2z>.

=head2 j_trim

Space in the back and forth is deleted. 
It corresponds to the em-size space.

=head2 j_hold

All the space characters are erased.
It corresponds to the em-size space.

=head2 j_strip

Space character is replaced with all one space.
It corresponds to the em-size space.

=head2 j_strip_j

It processes like j_strip and it replaces it with the em-size space.

=head1 SEE ALSO

L<Egg::Plugin::Filter>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
