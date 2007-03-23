package Egg::Plugin::FillInForm;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FillInForm.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use HTML::FillInForm;

our $VERSION = '0.03';

sub setup {
	my($e)= @_;
	$e->mk_accessors('fillin_ok');
	my $conf= $e->config->{plugin_fillinform} ||= {};
	if ( $e->isa('Egg::Plugin::FormValidator')
	  || $e->isa('Egg::Plugin::FormValidator::Simple')
	  || $e->isa('Catalyst::Plugin::FormValidator')
	  ) {
		$e->flags->{EGG_FILLINFORM_CODE}= sub {
			my($egg)= @_;
			$egg->fillform()
			  if $egg->form->has_missing
			  || $egg->form->has_invalid
			  || $egg->stash->{error};
		  };
	}
	$e->next::method;
}
sub fillform {
	my $e= shift;
	my $body= shift || $e->response->body || return 0;
	my $fdat= @_ ? ($_[1] ? {@_}: $_[0]): $e->request->params;

	$body= \$body unless ref($body);
	$e->response->body(
	  HTML::FillInForm->new->fill(
	    scalarref=> $body,
	    fdat=> $fdat,
	    %{$e->config->{plugin_fillinform}},
	    )
	  );
}
sub finalize {
	my($e)= @_;
	if ($e->fillin_ok) {
		$e->fillform();
	} elsif (my $code= $e->flags->{EGG_FILLINFORM_CODE}) {
		$code->($e);
	}
	$e->next::method;
}

1;

__END__

=head1 NAME

Egg::Plugin::FillInForm - FillInForm for Egg.

=head1 SYNOPSIS

  package MYPROJECT;
  use strict;
  use Egg qw{ FillInForm };

Example of code.

  $e->fillform(\$body, { name=> 'value' });
  
  $e->fillin_ok(1);

=head1 DESCRIPTION

This module buries the value under the form by using L<HTML::FillInForm>.

When this code was made, L<Catalyst::Plugin::FillInForm> was imitated.

* Please see the document of L<HTML::FillInForm> about a detailed explanation.

=head1 CONFIGURATION

If the option of HTML::FillInForm is written in 'plugin_fillinform', it is passed as it is. 

  plugin_fillinform=> {
    fill_password=> 0,
    ignore_fields=> [qw{ param1 param2 }],
    ...
    },

=head1 METHODS

=head2 $e->fillform([BODY], [HASH_REF]);

The burial in the form is processed.

When [BODY] is omitted, $e->response->body is used.
In addition, if $e->response->body is undefined, 0 is returned and it ends.

When [HASH_REF] is omitted, $e->request->params is used. 

=head2 $e->fillin_ok([BOOLEAN]);

When it is called that the processing of Egg ends ,in a word, finalize,
 $e->fillform is executed if this is true.

=head2 finalize

This method is called from Egg. There is no thing that the user calls.

If $e->form->has_missing or $e->form->has_invalid or $e->stash->{error} is true when
 L<Egg::Plugin::FormValidator>, L<Egg::Plugin::FormValidator::Simple>,
 L<Catalyst::Plugin::FormValidator> are read, $e->fillform is executed.

=head1 SEE ALSO

L<HTML::FillInForm>,
L<Catalyst::Plugin::FillInForm>,
L<Catalyst::Plugin::FormValidator>,
L<Catalyst::Plugin::FormValidator::Simple>,
L<Egg::Plugin::FormValidator>,
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

