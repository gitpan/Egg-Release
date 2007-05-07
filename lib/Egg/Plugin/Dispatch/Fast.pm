package Egg::Plugin::Dispatch::Fast;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Fast.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Dispatch::Fast - High-speed Dispatch for Egg Plugin.

=head1 SYNOPSIS

  use Egg qw/ Dispatch::Fast /;
  
  __PACKAGE__->run_modes(
  
    _default => {
      label=> 'index page.',
      action => sub { ... },
      },
  
    # When only the label is set, an empty CODE reference is set to action.
    # And, hooo.tt was set in the template.
    hooo => { label => 'hooo page.' },
  
    hoge => {
      label => 'hoge page',
      action => sub { ... },
      },
  
    );

=head1 DESCRIPTION

It is a plugin to do Dispatch that is more high-speed
than L<Egg::Plugin::Dispatch::Standard> of the Egg standard.

HASH of run_modes can recognize only a single hierarchy.

Moreover, the regular expression etc. cannot be used for the key.

The content of the key should be CODE reference.

The argument passed for the CODE reference is similar
to L<Egg::Plugin::Dispatch::Standard>.

=cut
use strict;
use warnings;
use base qw/Egg::Plugin::Dispatch/;

our $VERSION = '2.00';

=head1 METHODS

L<Egg::Plugin::Dispatch> has been succeeded to.
Please refer for that method of the handler.

=head2 dispatch

The handler object of E::P::Dispatch::Fast is returned.

=cut
sub dispatch {
	$_[0]->{Dispatch} ||= Egg::Plugin::Dispatch::Fast::handler->new(@_);
}

package Egg::Plugin::Dispatch::Fast::handler;
use strict;
use base qw/Egg::Plugin::Dispatch::handler/;

=head1 HANDLER METHODS

L<Egg::Plugin::Dispatch>::handler has been succeeded to.
Please refer for that method of the handler.

=cut
__PACKAGE__->mk_accessors(qw/ mode_now _action_code /);

=head2 new

Constructor who returns E::P::Dispatch::Fast::handler object.

=cut
sub new {
	my($class, $e)= @_;
	my $self= $class->SUPER::new($e);
	$self->mode( $e->_get_mode || $e->snip->[0] || "" );
	$self;
}

=head2 mode_now

The mode that matches to run_modes is actually returned.

* The value of 'default_mode' method is returned when failing in the match.

=cut

sub _start {
	my($self)= @_;
	my($code, $mode, $label);
	if ($code= $self->run_modes->{$self->mode}) {
		$mode= $self->mode_now($self->mode);
		$self->action([$mode]);
	} elsif ($code= $self->run_modes->{$self->default_mode}) {
		$mode= $self->mode_now($self->default_mode);
		$self->action([$self->default_name]);
	} else {
		$code= sub {};
		$mode= $self->mode_now($self->default_mode);
		$self->action([$self->default_name]);
	}
	if (ref($code) eq 'HASH') {
		$self->label([ $code->{label} || $self->action->[0] ]);
		$self->page_title( $self->label->[0] );
		$self->_action_code( $code->{action} || sub {} );
	} else {
		$self->label([ $self->action->[0] ]);
		$self->page_title( $self->label->[0] );
		$self->_action_code( $code );
	}
}
sub _action {
	my($self)= @_;
	my $action= $self->_action_code
	   || return $self->e->finished(404);  # NOT_FOUND.
	$action->($self, $self->e);
	1;
}
sub _finish { 1 }

sub _example_code {
	my($self)= @_;
	my $a= { project_name=> $self->e->namespace };

	<<END_OF_EXAMPLE;
#
# Example of controller and dispatch.
#
package $a->{project_name};
use strict;
use Egg qw/ -Debug Dispatch::Fast Log Debugging /;
use Egg::Const;

use $a->{project_name}::Members;
use $a->{project_name}::BBS;

__PACKAGE__->_egg_setup;

__PACKAGE__->run_modes(

  # HASH can be used for the value.
  # Please define not HASH but CODE if you do not use the label.
  _default => {
    label  => 'index page.',
    action => sub {},
    },

  # If it is a setting only of the label, 'action' is omissible.
  # Empty CODE tries to be set in action when omitting it, and to use
  # 'help.tt' for the template.
  help => { label => 'help page.' },

  members        => &yen;&$a->{project_name}::Members::default,
  members_login  => &yen;&$a->{project_name}::Members::login,
  members_logout => &yen;&$a->{project_name}::Members::logout,

  bbs      => &yen;&$a->{project_name}::BBS::article_view,
  bbs_post => &yen;&$a->{project_name}::BBS::article_post,
  bbs_edit => &yen;&$a->{project_name}::BBS::article_edit,

  );

#
# Only when using it with usual CGI.
# __PACKAGE__->mode_param('mode');
#

1;
END_OF_EXAMPLE
}

=head1 SEE ALSO

L<Egg::Plugin::Dispatch>,
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
