package Egg::Plugin::Dispatch::AnyCall;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: AnyCall.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use UNIVERSAL::require;

our $VERSION= '0.01';

sub call_to {
	my $e= shift;
	my $target= $_[0] ? do {
		my $pkg= shift;
		$pkg= $pkg=~/^\++(.+)/ ? $1: $e->namespace."::D::$pkg";
		$pkg->require or Egg::Error->throw($@);
		$pkg;
	  }: do {
		shift || 0; $e->namespace.'::D';
	  };
	my($method, $code);
	if ($method= $e->backup_action) {
		if ($code= $target->can($method)) {
			$e->debug_out("# + dispatch anycall: $target -> $method");
			return $code->($e->dispatch, $e);
		}
	}
	$method= shift
	  || $e->action->[$#{$e->action}]
	  || $e->config->{template_default_name};
	$code= $target->can($method) || return $e->finished(404);  # NOT_FOUND.
	$e->debug_out("# + dispatch anycall: $target -> $method");
	$code->($e->dispatch, $e);
}

1;

__END__

=head1 NAME

Egg::Plugin::Dispatch::AnyCall - The Dispatch function for Egg is supplemented.

=head1 SYNOPSIS

  package MYPROJECT;
  use strict;
  use Egg qw/Dispatch::AnyCall/;

Dispatch example.

  __PACKAGE__->run_modes(
    _default=> sub {
      my($dispat, $e)= @_;
      $e->call_to('Home');
      },
    );

Dispatch sub class example.

  package MYPROJECT::D::Home;
  use strict;
  
  sub index {
    my($dispat, $e)= @_;
    $e->response->body('is index.');
  }
  sub hoge {
    my($dispat, $e)= @_;
    .....
    $e->response->body('is hoge hoge.');
  }

Request example.

  htto://domain.name/
               => Display : is index.
  
  htto://domain.name/
               => Display : is hoge hoge.

=head1 DESCRIPTION

This module supplements handling '_default' key to run_modes that
Egg::Dispatch::Runmode treats.

Egg::Dispatch::Runmode starts making it match to '_default' compared with
the request of the type not defined in run_modes.
This module guesses the dispatch method that calls from the request to '_default'.

  package MYPROJECT::D::Booo;
  use strict;
  sub foo {
    my($dispat, $e)= @_;
    $e->response->body('is foo.');
  }
  sub hoo {
    my($dispat, $e)= @_;
    $e->response->body('is hoo.');
  }

To the subdispatch like the above-mentioned when run_modes is as follows.

  __PACKAGE__->run_modes(
    _default=> sub {},
    home=> {
      _default=> sub {
        my($dispat, $e)= @_;
        $e->call_to('Booo');
        },
      },
    );

This is answered to each request as follows. 

  http://domain/
              => index.tt (content of template)
  
  http://domain/home
              => NOT FOUND.

  http://domain/home/foo
              => 'is foo.'
  
  http://domain/home/hoo
              => 'is hoo.'

To return http://domain/home the content of the template as usual, it only has
to define neither the template nor response->body by the subdispatch.

  sub index {}

It comes to evaluate home/index.tt to http://domain/home by this.

=head1 METHODS

=head2 call_to ([DISPATCH_NAME], [DEFAULT_METHOD])

The method corresponding to request URI is called reading the specified dispatch.

[DISPATCH_NAME] is modified by [project_name]::D.
For instance, if it is 'BanBan', MYPROJECT::D::BanBan is read.
Moreover, when [DISPATCH_NAME] is omitted, MYPROJECT::D is an object.

When [DISPATCH_NAME] starts by +, the continuing name is treated as a module name.
For instance '+ORIGN::Dispatch' reads ORIGN::Dispatch.

[DEFAULT_METHOD] is a method name used when the call corresponding to the request fails.
As for this, 'template_default_name' is used usually.

=head1 SEE ALSO

L<Egg::Dispatch::Runmode>
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
