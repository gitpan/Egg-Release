package Egg::Plugin::Encode;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Encode.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Encode - Plugin to treat character code.

=head1 SYNOPSIS

  use Egg qw/ Encode /;

  $e->encode->set(\$text)->utf8;
  
  $e->utf8_conv(\$text);
  $e->euc_conv (\$text);
  $e->sjis_conv(\$text);

=head1 DESCRIPTION

This plug-in adds some methods to treat the character code conveniently.

If $e-E<gt>config-E<gt>{character_in} is set, it sets it up so that
Egg::Request::parameters may unite character-codes of the request query.

It is "[in_code]_conv" as for the character-code set in $e-E<gt>config-E<gt>{character_in}. 
Specifying it becomes either of 'utf8' and 'euc' and 'sjis' because it develops
with the method name.

If it wants to make the code excluding this treated, the method is made for the 
controller from the name of "[in_code]_conv", and the code name is set to
$e-E<gt>config-E<gt>{character_in}.

=cut
use strict;
use warnings;

our $VERSION = '2.00';

sub _setup {
	my($e)= @_;

	if (my $icode= $e->config->{character_in}) {
		my $enc_method= "${icode}_conv";
		my $r_class= $e->global->{REQUEST_PACKAGE};
		my $get_param;
		if (my $code= $r_class->can('_prepare_params')) {
			$get_param= sub {
				my $egg  = $_[0]->e;
				my $param= $code->($_[0]);
				while (my($key, $value)= each %$param) {
					if (ref($value) eq 'ARRAY') {
						for (@$value) { $egg->$enc_method(\$_) }
						$param->{$key}= $value;
					} else {
						$param->{$key}= $egg->$enc_method(\$value);
					}
				}
				$param;
			  };
		} else {
			$get_param= sub {
				my($req)= @_; my $egg= $req->e;
				my %param;
				for ($req->r->param) {
					my $value= $req->r->param($_);
					if (ref($value) eq 'ARRAY') {
						for (@$value) { $egg->$enc_method(\$_) }
						$param{$_}= $value;
					} else {
						$param{$_}= $egg->$enc_method(\$value);
					}
				}
				\%param;
			  };
		}
		no warnings 'redefine';
		*Egg::Request::parameters=
		   sub { $_[0]->{parameters} ||= $get_param->($_[0]) };

	}

=head1 METHODS

=head2 encode

The object for the character-code conversion acquired with $e->create_encode
is returned.

* Does the problem occur according to the module used because it is Closure
  No be known.

=cut
	{
		no warnings 'redefine';
		my $encode= $e->create_encode;
		*encode= sub { $encode };
	  };

	$e->next::method;
}

=head2 create_encode

The object for the character-code conversion is returned.

It is possible to make the object of the favor Orbaraid this method as a 
controller, and returned.

Default is Jcode.

=cut
sub create_encode {
	require Jcode;
	Jcode->new('jcode object.');
}

=head2 utf8_conv ( [TEXT], [ARGS] )

Shift-E<gt>encode-E<gt>set(@_)-E<gt>utf8 is done.

* When create_encode is Orbaraided, necessary to Orbaraid this method.
  It might be.

=cut
sub utf8_conv { shift->encode->set(@_)->utf8 }

=head2 euc_conv ( [TEXT], [ARGS] )

Shift-E<gt>encode-E<gt>set(@_)-E<gt>euc is done.

* When create_encode is Orbaraided, necessary to Orbaraid this method.
  It might be.

=cut
sub euc_conv  { shift->encode->set(@_)->euc }

=head2 sjis_conv ( [TEXT], [ARGS] )

Shift-E<gt>encode-E<gt>set(@_)-E<gt>sjis is done.

* When create_encode is Orbaraided, necessary to Orbaraid this method.
  It might be.

=cut
sub sjis_conv { shift->encode->set(@_)->sjis }


=head1 SEE ALSO

L<Jcode>,
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
