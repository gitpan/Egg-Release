package Egg::Appli;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id$
#
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

our $VERSION= '0.02';

__PACKAGE__->mk_accessors( qw/name params/ );

sub setup    { 0 }
sub prepare  { 0 }
sub action   { $_[0] }
sub finalize { $_[0] }

sub new {
	my($class, $e)= @_;
	bless { e=> $e, name=> $class, params=> {} }, $class;
}
sub param {
	my $self= shift;
	return keys %{$self->{params}} if @_< 1;
	my $key = shift;
	$self->{params}{$key}= shift if @_> 0;
	$self->{params}{$key};
}

1;

__END__

=head1 NAME

Egg::Appli - General base class.

=head1 SYNOPSIS

This is a base class that the module used should chiefly use from Egg::Plugin::Appli.

 package Egg::Appli::Booo;
 use strict;
 use base qw/Egg::Appli/;
 
 __PACKAGE__->mk_accesors( qw/parameter/ );
 
 sub setup {
   my($class, $e)= @_;
   ...
   .....
 }
 sub new {
   my($class, $e)= @_;
   my $app= $class->SUPER::new($e);
   $app->{parameter}= 'parameter';
   $app;
 }
 sub hogehoge {
   my($app)= @_;
   ...
   .....
 }
 sub finalize {
   my($app)= @_;
   ...
   .....
 }

=head1 DESCRIPTION

To tell the truth, it is used from Egg::Config.

The user thinks that he or she will use it through Egg::Plugin::Appli.

 package [PROJECT];
 use strict;
 use Egg qw/-Debug Appli/;

And, to the configuration.

 plugin_appli=> {
   applications=> [qw/bbs wiki blog/],
   },

=head1 METHODS

These methods are basically called through Egg::Plugin::Appli.

 my $app= $e->app->get('BBS');

=head2 new

Egg::Plugin::Appli calls implicitly.

=head2 $app->setup, $app->prepare, $e->action, $e->finalize

It is called from Egg::Plugin::Appli according to the same timing for
 the plugin of Egg as the call.

=head2 $app->param([KEY], [VALUE]);

The parameter is referred to and it defines it.
It is a in a word general param method.

=head2 $app->params

All parameter is returned by the HASH reference.

=head1 SEE ALSO

L<Egg::Plugin::Appli>,
L<Egg::Config>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
