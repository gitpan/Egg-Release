package Egg::Plugin::FillInForm;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FillInForm.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::FillInForm - HTML::FillInForm for Egg.

=head1 SYNOPSIS

  use Egg qw/ FillInForm /;
  
  __PACKAGE__->egg_startup(
  
    plugin_fillinform => {
      fill_password => 0,
      ignore_fields => [qw{ param1 param2 }],
      ...
      },
  
  );

  # When outputting it, HTML::FillInForm is processed.
  $e->fillin_ok(1);

=head1 DESCRIPTION

It is a plugin to use L<HTML::FillInForm>.

The setting is defined in 'Plugin_fillinform' with HASH.

All set values extend to L<HTML::FillInForm>.

Please refer to the document of L<HTML::FillInForm> for details.

=cut
use strict;
use warnings;
use HTML::FillInForm;
use base qw/Class::Accessor::Fast/;

our $VERSION = '2.00';

=head1 METHODS

=head2 fillin_ok ( [BOOL] )

$e-E<gt>fillform is called immediately before the output of contents when an 
effective value is set.

* The call of $e-E<gt>fillform becomes effective at the Validate error if
  L<Egg::Plugin::FormValidator::Simple > is read at the same time.

  $e->fillin_ok(1);

=cut
__PACKAGE__->mk_accessors(qw/ fillin_ok /);

sub _setup {
	my($e)= @_;
	if ($e->isa('Egg::Plugin::FormValidator::Simple')) {
		no warnings 'redefine';
		*_valid_error= sub {
			my($egg)= @_;
			return ( $egg->stash->{error}
			      || $egg->form->has_missing
			      || $egg->form->has_invalid ) ? 1: 0;
		  };
	}
	$e->next::method;
}

=head2 fillform ( [CONTENT_REF], [PARAM_HASH] )

L<HTML::FillInForm > is processed for CONTENT_REF.

CONTENT_REF is SCALAR always reference. 

When PARAM_HASH is omitted, $e-E<gt>request-E<gt>params is used.

  $e->fillform( \$content, \%param );

=cut
sub fillform {
	my $e   = shift;
	my $body= shift || $e->response->body || return 0;
	my $fdat= @_ ? ($_[1] ? {@_}: $_[0]): $e->request->params;
	return 0 unless %$fdat;
	$e->response->body( HTML::FillInForm->new->fill(
	  scalarref => $body, fdat => $fdat,
	  %{$e->config->{plugin_fillinform}},
	  ) );
}
sub _finalize {
	my($e)= @_;
	$e->fillform if ( $e->fillin_ok or $e->_valid_error );
	$e->next::method;
}
sub _valid_error { 0 }

=head1 SEE ALSO

L<HTML::FillInForm>,
L<Catalyst::Plugin::FillInForm>,
L<Egg::Plugin::FormValidator::Simple>,
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
