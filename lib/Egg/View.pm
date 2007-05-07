package Egg::View;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: View.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::View - Base class only for VIEW.

=head1 SYNOPSIS

  use Egg::View;
  
  # The parameter that wants to be used by default is set.
  %Egg::View::PARAMS= (
    hoge => '......',
    ....
    ..
    );

=head1 DESCRIPTION

This is a base class only for VIEW.

* VIEW only for the project must use 'Egg::Base'.

The parameter that wants to be used by default in setting the value in global
HASH can be setup.

=cut
use strict;
use warnings;
use base qw/Egg::Model/;

our $VERSION = '2.00';
our %PARAMS;

=head1 METHODS

=head2 new

Constructor.

=cut
sub new {
	my($class, $e, $conf)= @_;
	$class->SUPER::new($e, $conf, \%PARAMS);
}

=head2 template

It returns it guessing the template from the template set to $e-E<gt>template
or $e-E<gt>action.

=cut
sub template {
	my($view)= @_;  my $e= $view->e;
	my $template= $e->template || do {
		my $path= join('/', @{$e->action}) || do {
			$e->log->debug( q/I want you to define $e->template./ );
			return do { $e->finished(404); 0 };
		  };
		"$path.". $e->config->{template_extention};
	  };
	$e->debug_out("# + template file : $template");
	$template;
}

=head1 SEE ALSO

L<Egg::Model>,
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
