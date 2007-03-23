package Egg::Base;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use UNIVERSAL::require;
use base qw/Egg::Component/;

our $VERSION= '0.01';

{
	no strict 'refs';  ## no critic

	sub config {
		my $class= shift;
		my $basename= ref($class) || $class;
		return ${"$basename\::__CONFIGURATION"} unless @_;
		${"$basename\::__CONFIGURATION"}= ref($_[0]) eq 'HASH' ? $_[0]: {@_};
	}
	sub init_name {
		my $class= shift;
		my $basename= ref($class) || $class;
		return ${"$basename\::__INIT_NAME"} unless @_;
		${"$basename\::__INIT_NAME"}= shift || "";
	}
	sub include {
		my $class= shift;
		my $pkg= shift || return 0;
		$pkg->require or Egg::Error->throw($@);
		my $basename= ref($class) || $class;
		my $inc= ${"$basename\::__INCLUDES"} ||= [];
		push @$inc, $pkg;
		1;
	}
	sub include_packages {
		my $class= shift;
		my $basename= ref($class) || $class;
		${"$basename\::__INCLUDES"} || [];
	}

  };

1;

__END__

=head1 NAME

Egg::Base - Common base class for project component for Egg.

=head1 SYNOPSIS

  package MYPROJECT::AnyClass;
  use strict;
  use base qw/ Egg::Base /;

=head1 METHODS

=head2 config

The HASH reference of the configuration is returned.

When HASH is passed, it sets it as a global value of the class that calls it.

  __PACKAGE__->config(
    hoge=> 'param',
    ...
    );

=head2 init_name

The defined value is returned.

When the value is given, it maintains it as a global value.
The usage is not especially decided.

  __PACKAGE__->init_name( 'fooo' );

=head2 include

When the module name is given, the module is include.
And, the name is added to ARRAY.

  __PACKAGE__->include('Foo::Module');

=head2 include_packages

The list of the module that include is done by 'Include' is returned.

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
