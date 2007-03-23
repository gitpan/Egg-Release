package Egg::Plugin::Encode::CGI;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: CGI.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.02';

sub setup {
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{'Egg::Request::CGI::prepare_params'}= sub {
		my($req)= @_;
		my $e= $req->e;
		my $icode= $e->config->{character_in}. '_conv';
		my $params= $req->r->Vars;
		while (my($key, $value)= each %$params) {
			next unless $value;
			$req->{parameters}{$key}= ref($value) eq 'ARRAY'
			 ? [ map{$e->$icode(\$_)}@$value ]: $e->$icode(\$value);
		}
	  };
}

1;

__END__

=head1 NAME

Egg::Plugin::Encode::CGI - The encode of the character is supported for Egg.

=head1 DESCRIPTION

This module is called from Egg::Plugin::Encode, and enhances prepare_params
 of Egg::Request::CGI.

=head1 SEE ALSO

L<Egg::Plugin::Encode>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
