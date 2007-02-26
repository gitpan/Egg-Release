package Egg::Dispatch;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Dispatch.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Component/;
use UNIVERSAL::require;

our $VERSION= '0.04';

__PACKAGE__->mk_accessors(qw/page_title/);

sub _before_setup  {}
sub _extension_cut { $_[1] }

sub _setup {
	my($class, $e)= @_;
	my $dispat;
	for (qw/Dispatch D/) {
		my $test= $e->path('lib', "$_.pm");
		if (-e $test && -f _ && -r _) {
			$dispat= $e->global->{EGG_DISPATCH_BASE}= $e->namespace."::$_";
			last;
		}
	}
	$dispat || Egg::Error->throw
	  ('Dispatch is not found or there is no reading permission.');
	$class->_before_setup($e, $dispat);

	{
		no strict 'refs';  ## no critic
		@{"$dispat\::ISA"}= $class;
	  };

	$dispat->require or Egg::Error->throw($@);
	$e->global->{EGG_DISPATCH_DEBUGOUT}= $e->debug ? sub {
		my($egg, $meth, $snip)= @_;
		$egg->debug_out("# + dispatch $meth : ". join('->', @$snip));
	  }: sub { };

	@_;
}
sub _example_code { 'unknown.' }

1;

__END__

=head1 NAME

Egg::Dispatch - A dispatch base module for Egg.

=head1 DESCRIPTION

This module is a base class of dispatch. 

The dispatch of the project side is read by the setup and ISA is adjusted.

Standard dispatch of Egg::Release-1.00 is Egg::Dispatch::Runmode.
This can be replaced with an original dispatch module.

When an original dispatch module is made, it is necessary to fill the following 
requirement.

=over 4

=item * _new

Constructor in name with under bar.

* It is called from Egg::Engine by this name.

=item * Succession of Egg::Dispatch

Processing at least common to the setup can be used. 

=item * _start

To process prior, dispatch is called from Egg::Engine.

=item * _action

To process the favorite of dispatch, it is called from Egg::Engine

=item * _finish

To postprocess dispatch, it is called from Egg::Engine.

=item * Definition of $e->action

The hint to call the template chiefly is expected of the thing defined if 
possible at the stage of '_action'.

=back

It makes it to Houdai now.

Please teach by all means when wonderful Dipatti is completed.

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

