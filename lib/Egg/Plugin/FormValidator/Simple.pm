package Egg::Plugin::FormValidator::Simple;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Simple.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;
use FormValidator::Simple;

our $VERSION = '0.04';

sub setup {
	my($e)= @_;
	my $conf= $e->config->{plugin_validator} ||= {};
	if (my $plugins= $conf->{plugins}) {
		FormValidator::Simple->import(@$plugins);
	}
	if (my $messages= $conf->{messages}) {
		FormValidator::Simple->set_messages($messages);
	}
	if (my $options= $conf->{options}) {
		FormValidator::Simple->set_option(%$options);
	}
	if (my $format= $conf->{message_format}) {
		FormValidator::Simple->set_message_format($format);
	}
	$e->next::method;
}
sub form {
	my $e= shift;
	$e->{form} ||= FormValidator::Simple->new;
	if (@_) {
		my($form, $param)= ref($_[0]) eq 'ARRAY'
		  ? ($_[0], ($_[1] || $e->request)): ([@_], $e->request);
		return $e->{form}->check($param, $form);
	}
	$e->{form}->results;
}
sub set_invalid_form {
	my $e= shift;
	$e->{form} ||= FormValidator::Simple->new;
	$e->{form}->set_invalid(@_);
	$e->{form}->results;
}

1;

__END__

=head1 NAME

Egg::Plugin::FormValidator::Simple - FormValidator::Simple for Egg.

=head1 SYNOPSIS

  package MYPROJECT;
  use strict;
  use Egg qw/FormValidator::Simple/;

Example of configuration.

  plugin_validator=> {
    plugins=> [qw/Japanise/],
    messages=> {
      origin_lavel=> {
        nickname=> {
          DEFAULT=> 'Please input nickname.',
          LENGTH => 'nickname input is long.',
          ...
          },
        email=> {
          DEFAULT=> 'Please input email.',
          EMAIL  => 'Format of email is mistaken.',
          ...
          },
        ...
        },
      },
    message_format=> .... message format hear.
    },

Example of code.

  $e->form(
    nickname=> [qw/NOT_BLANK .../, [qw/LENGTH 3 30/]],
    email   => [qw/NOT_BLANK EMAIL/],
    );
  
  if ($e->has_error) {
    for my $message (@{$e->form->messages('origin_lavel')}) {
      print $message;
    }
  } else {
    ... success code.
  }

* Please see L<FormValidator::Simple> of use about more detailed information.

=head1 DESCRIPTION

This is a module to do the input check on the form by using L<FormValidator::Simple>.

Please install FormValidator::Simple before using.

  perl -MCPAN -e 'install FormValidator::Simple'

* The installation was effective well for B<Windows> by doing nmake after it had
  obtained it why. ?

  # The package is obtained.
  http://search.cpan.org/dist/FormValidator-Simple/
  
  # It defrosts and 'nmake' is done when downloading it.


When this code was made, L<Catalyst::Plugin::FormValidator::Simple> was imitated.

=head1 CONFIGURATION

=head2 plugins

The plugin for FormValidator::Simple is enumerated by the ARRAY reference.

=head2 options

The option of FormValidator::Simple is defined. 

=head2 messages

The alias of the error message can be defined.

=head2 message_format

The output format of the error message can be defined.

=head1 METHODS

=head2 $e->form([PARAMETER])

The check on form data is executed.

=head1 SEE ALSO

L<FormValidator::Simple>,
L<Catalyst::Plugin::FormValidator::Simple>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
