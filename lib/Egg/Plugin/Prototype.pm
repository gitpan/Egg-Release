package Egg::Plugin::Prototype;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Prototype.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Prototype - Plugin for Prototype

=head1 SYNOPSIS

  # use it
  use Egg qw/ Prototype /;

  # ...add this to your mason template...
  <% $e->prototype->define_javascript_functions %>

  # ...and use the helper methods...
  <div id="view"></div>
  <textarea id="editor" cols="80" rows="24"></textarea>
  % my $uri = $e->config->{static_uri}. 'edit/'. $e->page_title;
  <% $e->prototype->observe_field( 'editor', $uri, { 'update' => 'view' } ) %>

=head1 DESCRIPTION

Some stuff to make Prototype fun.

This plugin replaces L<Egg::Helper::Plugin::Prototype>.

=cut
use strict;
use warnings;
use base 'Class::Data::Inheritable';
use HTML::Prototype;

our $VERSION = '2.00';

__PACKAGE__->mk_classdata('prototype');
eval { require HTML::Prototype::Useful; };

=head2 METHODS

=head3 prototype

Returns a ready to use L<HTML::Prototype> object.

=cut

if ( $@ ) {
    __PACKAGE__->prototype( HTML::Prototype->new );
} else {
    __PACKAGE__->prototype( HTML::Prototype::Useful->new );
}

=head1 SEE ALSO

L<Catalyst::Plugin::Prototype>,
L<Egg::Helper::Plugin::Prototype>,
L<Egg::Release>,

=head1 AUTHOR

This code is a transplant of 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>'
 of the code of 'L<Catalyst::Plugin::Prototype>'.

Therefore, the copyright of this code is assumed to be the one that belongs
 to 'Sebastian Riedel, C<sri@oook.de>'.

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
