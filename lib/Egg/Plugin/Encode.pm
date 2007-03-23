package Egg::Plugin::Encode;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Encode.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;

our $VERSION= '0.03';
{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	sub setup {
		my($e)= @_;
		$e->config->{character_in} ||= 'euc';
		my $name= $e->namespace;
		${"$name\::__EGG_ENCODE"}= $e->create_encode;
		unless ($e->config->{disable_encode_query}) {
			if (my $pkg=
			    $e->request_class=~m{^Egg\:\:Request\:\:Apache\:\:.+}
			      ? __PACKAGE__.'::Apache'
			  : $e->request_class=~m{^Egg\:\:Request\:\:(?:Fast)?CGI}
			      ? __PACKAGE__.'::CGI'
			  : 0 ) {
				$pkg->require or Egg::Error->throw($@);
				$pkg->setup;
				$e->debug_out("# + plugin_encode : $name - $pkg");
			}
		}
		$e->next::method;
	}
	sub encode { ${$_[0]->namespace.'::__EGG_ENCODE'} }
  };

sub create_encode {
	Jcode->require or Egg::Error->throw($@);
	Jcode->new('jcode object.');
}
sub euc_conv  { shift->encode->set(@_)->euc  }
sub sjis_conv { shift->encode->set(@_)->sjis }
sub utf8_conv { shift->encode->set(@_)->utf8 }

sub is_utf8 { utf8::is_utf8($_[1]) }
sub utf8enc { utf8::encode($_[1])  }
sub utf8dec { utf8::decode($_[1])  }

1;

__END__

=head1 NAME

Egg::Plugin::Encode - The encode of the character is supported for Egg.

=head1 SYNOPSIS

  package MYPROJECT;
  use stirct;
  use Egg qw/Encode/;

Example of code.

  $e->encode->set(\$string)->utf8;
  
  my $euc_str = $e->euc_conv(\$any_code_string);
  my $utf8_str= $e->utf8_conv(\$any_code_string);
  my $sjis_str= $e->sjis_conv(\$any_code_string);

=head1 DESCRIPTION

This module adds the method for the treatment of the character-code.
And, the operation united by the character-code set to 'character_in' when
 acquisition and the cookie of Ricestoceri are set is done.

The default of 'character_in' is euc.

Jcode is used for the conversion of the character-code.
It is possible to change by adding the following codes to the controller.

  package MYPROJECT;
  use Unicode::Japanese;
  ....
  
  sub create_encode {
  	Unicode::Japanese->new('character');
  }

Euc_conv, sjis_conv, and utf8_conv can be used in default.

Please give to the operation of the module that Orbaraids these methods and
 uses it additionally if there is a problem.

Moreover, please add the method newly to treat the code that this module 
doesn't assume.

  sub ucs2_conv {
  	my($e, $str)= @_;
  	$e->encode->set($str)->ucs2;
  }
  sub anycode_conv {
  	my($e, $str)= @_;
  	$e->encode->set($str)->anycode;
  }

And, please set the code to 'character_in' if you want to do to the code for
 internal processing of default.

  character_in=> 'ucs2',
  
  or
  
  character_in=> 'anycode',

* It seems to fail in the encode of the request query in utf8 'character_in'.
  The encode of the request query is turned off in setting 'B<disable_encode_query>'
  as an emergency measure.

=head1 METHODS

=head2 encode

The object received with create_encode is returned.

Default is 'Jcode'.

=head2 euc_conv , utf8_conv , sjis_conv

It is an accessor for the character-code conversion.

=head2 is_utf8

utf8::is_utf8 is done.

=head2 utf8enc

utf8::encode is done.

=head2 utf8dec

utf8::decode is done.

=head1 SEE ALSO

L<Jcode>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
