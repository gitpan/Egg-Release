package Egg::AnyBase;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Config.pm 94 2007-01-11 05:22:07Z lushe $
#
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

our $VERSION= '0.01';

__PACKAGE__->mk_accessors( qw/name e parameters/ );

*params= \&parameters;

sub config   { @_ }
sub prepare  { @_ }
sub action   { @_ }
sub finalize { @_ }

sub setup {
	my($class, $e, $config, $name)= @_;
	if ($config && $name) {
		$name=~s/\:\:/_/g;
		$e->config->{lc($name)} ||= $config || {};
	}
	@_;
}
sub new {
	my $class= shift;
	my $e    = shift;
	my $hash = shift || {};
	bless { name=> $class, e=> $e, parameters=> $hash }, $class;
}
sub param {
	my $self= shift;
	return keys %{$self->{parameters}} if @_< 1;
	my $key = shift;
	$self->{parameters}{$key}= shift if @_> 0;
	$self->{parameters}{$key};
}

1;

__END__

=head1 NAME

Egg::AnyBase - General-purpose base class.

=head1 DESCRIPTION

It equips it with necessary Sod with Egg.

Using it reading from the plugin module etc. is convenient.

=head1 SEE ALSO

L<Egg::Release>, L<Egg::View>, L<Egg::Model>

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
