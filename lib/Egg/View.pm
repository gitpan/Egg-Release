package Egg::View;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: View.pm 230 2007-02-23 06:50:37Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Component/;

our $VERSION= '0.08';

our %PARAMS= (
  no_cache_header=>
      qq{<meta http-equiv="Pragma" content="no-cache">\n}
    . qq{<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">\n}
    . qq{<meta http-equiv="expires" content="0">},
  );

sub new {
	my $view = shift->SUPER::new(@_);
	my %param= %PARAMS;
	$view->params( \%param );
	$view;
}
sub template_file {
	my($view, $e)= @_;
	my $template= $e->template || do {
		my $path= join('/', @{$e->action}) || do {
			$e->log->debug( q/I want you to define $e->template./ );
			$e->finished(404);
			return(undef);
		  };
		$path. $e->config->{template_extention};
	  };
	$e->debug_out("# + template file: $template");
	$template;
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

The parameter can be set up beforehand.

 package [MYPROJECT];
 use strict;
 use Egg::View;
 
 $Egg::View::PARAMS{param1}= 'value1';

 # The set value is acquired.
 $e->view->param( 'param1' );

=head1 METHODS

This module has succeeded to L<Egg::Component>.

=head2 $view->template_file([Egg Object]);

The set template is received.
If Egg is debug mode, the report is sent to STDERR.
When the template is not set, $e->finished(404) is returned.

=head1 SEE ALSO

L<Egg::Component>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
