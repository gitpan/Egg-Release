package Egg::Request::Apache;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Apache.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Request/;
no warnings 'redefine';

our $VERSION= '0.04';

sub setup {
	my($class, $e)= @_;
	my $base= $e->namespace;
	no strict 'refs';  ## no critic
	*{"Egg::handler"}= sub : method { shift; $base->run(@_) };
}
sub prepare_params {
	my($req)= @_; my $r= $req->r;
	$req->{parameters}{$_}= $r->param->{$_} || "" for $r->param;
}
sub output {
	my $req   = shift;
	my $header= shift || return 0;
	my $body  = ref($_[0]) ? $_[0]: \"";
	$req->r->send_cgi_header($$header);
	$body and $req->r->print($$body);
	$req->{e}->debug_out($$header);
}

1;

__END__

=head1 NAME

Egg::Request::Apache - It is a common module for mod_perl.

=head1 SYNOPSIS

The parameter passed to ApacheX::Request can be written in the $e->config->{request}.

 request=> {
   POST_MAX       => 1024,
   DISABLE_UPLOADS=>    1,
   TEMP_DIR       => '/path/to/temp',
   },

When Egg::Plugin::Upload is used, this will become useful.

* If the parameter to which ApacheX::Request cannot be understood is set, it becomes
 an error.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<http://perl.apache.org/>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
