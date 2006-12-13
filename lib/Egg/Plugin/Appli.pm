package Egg::Plugin::Appli;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id$
#
use strict;
use UNIVERSAL::require;
use Error;
use NEXT;
use base qw/Class::Data::Inheritable/;

__PACKAGE__->mk_classdata('app');

{
	no strict 'refs';
	sub setup {
		my($e)= @_;
		my $config= $e->config->{plugin_appli} ||= {};
		my $apps= $config->{applications} || return $e->NEXT::setup;
		my $Name= $e->namespace;
		my $names = ${"$Name\::__EGG_APPLI_NAMES"} = [];
		my $object= ${"$Name\::__EGG_APPLI_OBJECT"}= {};
		for (@$apps) {
			my($pkg, $name)= /^\+([A-Z][A-Za-z0-9_\:]+)/
			  ? ($1, uc($1)): ("Egg::Appli::$_", uc($_));
			$pkg->require or throw Error::Simple qq/Egg::Appli : $@/;
			push @$names, $name;
			$object->{$name}= $pkg;
		}
		$e->NEXT::setup;
	}
  };

sub prepare  {
	my($e)= @_;
	$e->{app}= Egg::Plugin::Appli::Base->new($e);
	$e->{app}->process($e, 'prepare');
	$e->NEXT::prepare
}
sub action {
	my($e)= @_;
	$e->{app}->process($e, 'action');
	$e->NEXT::action;
}
sub finalize {
	my($e)= @_;
	$e->{app}->process($e, 'finalize');
	$e->NEXT::finalize;
}

package Egg::Plugin::Appli::Base;
use strict;
use base qw/Class::Data::Inheritable/;

__PACKAGE__->mk_classdata( qw/names objects/ );

{
	no strict 'refs';
	sub new {
		my($class, $e)= @_;
		my $Name= $e->namespace;
		bless {
		  names=> ${"$Name\::__EGG_APPLI_NAMES"},
		  objects=> ${"$Name\::__EGG_APPLI_OBJECT"},
		  }, $class;
	}
  };

sub get {
	my $app= shift;
	my $key= shift || return 0;
	$app->{objects}{uc($key)} || 0;
}
sub process {
	my($app, $e, $method)= @_;
	for (@{$app->{names}}) {
		if (my $app= $app->{objects}{$_}) { $app->$method($e) }
	}
}

1;

__END__

=head1 NAME

Egg::Plugin::Appli - Base plugin for Egg application.

=head1 SYNOPSIS

 package [MYPROJECT];
 use strict;
 use Egg qw/-Debug Appli/;

Configuration is such feeling.

 plugin_appli=> {
   applications=> [qw/BBS::Mini Wiki Blog/],
   },

And, the application object is received.

 my $app= $e->app->get('BBS::MINI');
 
 $e->response->body( $app->foo_disp('foo_disp.tt') );

=head1 DESCRIPTION

The WEB application made for Egg is mediated.
Making after Egg::Applie is succeeded to and crowding might be good
 for the application. 

 package Egg::Appli::Booo;
 use strict;
 use base qw/Egg::Appli/;
 
 # The following please as liked.

=head1 METHODS

=head2 $e->app

The Egg::Plugin::Appli::Base object is returned.

=head2 $e->app->get([APPLICATION_NAME]);

The object of [APPLICATION_NAME] is returned.

Please specify all [APPLICATION_NAME] by the capital letter.

=head2 $e->prepare, $e->action, $e->finalize,

The method of this name of the application side is called according to
 the same timing as the plugin call.

=head1 SEE ALSO

L<Egg::Appli>,
L<Egg::Engine>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
