package Egg::Plugin::Filter::Plugin::Japanese;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Japanese.pm 182 2007-08-05 17:25:44Z lushe $
#

=head1 NAME

Egg::Plugin::Filter::Plugin::Japanese - Base class for a Japanese filter.

=head1 DESCRIPTION

It is a base class for L<Egg::Plugin::Filter::Plugin::Japanese::EUC>
and L<Egg::Plugin::Filter::Plugin::Japanese::Shift_JIS> etc.

=cut
use strict;
use warnings;
use Egg::Plugin::Filter;

our $VERSION = '2.01';

our($Zspace, $RZspace);

my $EGG= 0;
my $VAL= 1;
my $ARG= 2;

=head1 FILTERS

=cut
sub _setup_filters {
	my($class, $e)= @_;

	$Zspace  || die q{ I want setup '$Zspace'.  };
	$RZspace || die q{ I want setup '$RZspace'. };

	my $filters= \%Egg::Plugin::Filter::Filters;

=head2 h2z

The normal-width katakana is converted into the em-size katakana.

=cut
	$filters->{h2z}= sub {
		return 0 unless defined(${$_[$VAL]});
		${$_[$EGG]}->encode->set($_[$VAL])->h2z;
	  };

=head2 j_trim

The space character that contains the em-size space before and after is put out.

=cut
	$filters->{j_trim}= sub {
		return 0 unless defined(${$_[$VAL]});
		1 while ${$_[$VAL]}=~s{^(?:\s|$Zspace)+} []sg;
		1 while ${$_[$VAL]}=~s{(?:\s|$Zspace)$} []sg;
	  };

=head2 j_hold

All the space characters including the em-size space are put out.

=cut
	$filters->{j_hold}= sub {
		defined(${$_[$VAL]}) and ${$_[$VAL]}=~s{(?:\s|$Zspace)+} []sg;
	  };

=head2 j_strip

The continuousness of all the space characters including the em-size space is
substituted for one half angle space.

=cut
	$filters->{j_strip}= sub {
		return 0 unless defined(${$_[$VAL]});
		${$_[$VAL]}=~s{(?:\s|$Zspace)+} [ ]sg;
	  };

=head2 j_strip_j

The continuousness of all the space characters including the em-size space is
substituted for one em-size space.

=cut
	$filters->{j_strip_j}= sub {
		return 0 unless defined(${$_[$VAL]});
		${$_[$VAL]}=~s{(?:\s|$Zspace)+} [$RZspace]sge;
	  };

	@_;
}

=head1 SEE ALSO

L<Egg::Plugin::Filter>,
L<Egg::Plugin::Filter::Plugin::Japanese>,
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
