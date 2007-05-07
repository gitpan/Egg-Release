package Egg::Model;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Model.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Model - Base class for MODEL.

=head1 DESCRIPTION

This is a base class only for MODEL.

* And, VIEW has been succeeded to to tell the truth.

* MODEL and VIEW only for the project must use 'Egg::Base'.

=cut
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

our $VERSION = '2.00';

__PACKAGE__->mk_accessors(qw/ e config params /);

=head1 METHODS

=head2 new

Constructor.

Egg object, a setup value, and the parameter are received.

=cut
sub new {
	my($class, $e, $config, $params)= @_;
	bless { e => $e,
	  config => ($config || {}),
	  params => ($params || {}),
	  }, $class;
}

=head2 param ( [KEY], [VALUE] )

It is a very usual param method.

=cut
sub param {
	my $self= shift;
	return keys %{$self->{params}} unless @_;
	my $key = shift;
	@_ ? $self->{params}{$key}= shift : $self->{params}{$key};
}

sub _setup    { @_ }
sub _prepare  { @_ }
sub _action   { @_ }
sub _finalize { @_ }

=head1 SEE ALSO

L<Class::Accessor::Fast>,
L<Egg::Model::DBI>,
L<Egg::View>,
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
