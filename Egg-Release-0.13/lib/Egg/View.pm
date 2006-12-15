package Egg::View;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: View.pm 34 2006-12-14 08:17:52Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Config/;

our $VERSION= '0.02';

sub template_file {
	my($view, $e)= @_;
	if (my $template= $e->template) {
		$e->debug_out("# + template file: $template");
		return $template;
	} else {
		$e->debug and $e->log->debug( q/I want you to define $e->template./ );
		$e->finished(404);
		undef;
	}
}

1;

__END__

=head1 NAME

Egg::View - Common package for VIEW module.

=head1 SYNOPSIS

 package Egg::View::[FOO_TEMPLATE];
 use strict;
 use base qw/Egg::View/;
 use [FOO_TEMPLATE_MODULE];
 
 sub new {
   my $view= shift->SUPER::new(@_);
   ...
   ... ban, ban.
 }
 sub output {
   my($view, $e)= @_;
   my $config  = $e->flag('VIEW_CONFIG_[FOO_TEMPLATE]') || {};
   my $template= $view->template_file($e) || return;
 
   my $body= [FOO_TEMPLATE_MODULE]->output(
     template=> $template,
     option  => $config,
     );
 
   $e->response->body( \$body );
 
   return 1;
 }

=head1 DESCRIPTION

When the View module uses this, happiness can be tasted only just a little.

=head1 METHODS

=head2 $view->name;

Class name when calling it is returned.

=head2 $view->params;

The HASH reference of the parameter is returned.

=head2 $view->param([KEY NAME], [VALUE]);

This does operation similar to the param method of the appearance often.

=head2 $view->template_file([Egg Object]);

The set template is received.
If Egg is debug mode, the report is sent to STDERR.
When the template is not set, $e->finished(404) is returned.

=head1 SEE ALSO

L<Egg::Release>, L<Egg::Config>

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
