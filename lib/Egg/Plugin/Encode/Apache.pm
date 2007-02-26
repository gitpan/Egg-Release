package Egg::Plugin::Encode::Apache;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Apache.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.01';

{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{'Egg::Request::Apache::prepare_params'}= sub {
		my($req)= @_;
		my $r= $req->r;
		my $e= $req->e;
		my $icode= $e->config->{character_in}. '_conv';
		for my $key ($r->param) {
			my $value= $r->param->{$key} || next;
			$req->{parameters}{$key}= ref($value) eq 'ARRAY'
			 ? [ map{$e->$icode(\$_)}@$value ]: $e->$icode(\$value);
		}
	  };
  };

1;

__END__

=head1 NAME

Egg::Plugin::Encode::Apache - The encode of the character is supported for Egg.

=head1 DESCRIPTION

This module is called from Egg::Plugin::Encode, and enhances prepare_params
 of Egg::Request::Apache.

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
