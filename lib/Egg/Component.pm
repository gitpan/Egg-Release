package Egg::Component;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Component.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use base qw/Class::Accessor::Fast/;
use Egg::Exception;

our $VERSION= '0.01';

__PACKAGE__->mk_accessors(qw/name e config parameters/);

*params= \&parameters;

sub setup   { @_ }
sub prepare { 0 }

sub new {
	my $proto = shift;
	my $e     = shift;
	my $config= shift || {};
	my $params= shift || {};
	if (my $class= ref($proto)) {
		$proto->{e} ||= $e;
		$proto->{name} ||= $class;
		$proto->{config} ||= $config;
		$proto->{parameters} ||= $params;
		return $proto;
	} else {
		return bless {
		  e=> $e,
		  name=> $proto,
		  config=> $config,
		  parameters=> $params,
		  }, $proto;
	}
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

Egg::Component - Common base class for Egg component.

=head1 SYNOPSIS

  use base qw/Egg::Component/;

=head1 DESCRIPTION

Using some methods such as parameters by succeeding to this module becomes possible.

* It is not possible to use it from the plugin module.

=head1 METHODS

=head2 name

Own class name is returned. It is the same as ref($self). 

=head2 e

The Egg object is returned.
It is necessary to have passed the Egg object to constructor's the first argument.

=head2 config

HASH set as a configuration is returned.
If HASH is passed to constructor's the second argument, it becomes an initial 
value.

=head2 parameters  or params

HASH set as a parameter is returned. 
If HASH is passed to constructor's the third argument, it becomes an initial 
value.

=head2 param ([KEY], [VALUE])

The same exercising like CGI module etc. as the param method general is done. 

=head2 setup

Nothing is done. The passed argument is returned as it is.

=head2 prepare

Nothing is done. 0 is always returned.

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
