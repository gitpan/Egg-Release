package Example;
use strict;
use warnings;
use Egg qw/ -Debug
  ConfigLoader
  Dispatch::Standard
  Debugging
  Log
  /;

our $VERSION= '0.01';

__PACKAGE__->egg_startup;

# Dispatch. ------------------------------------------------
__PACKAGE__->run_modes(

  _default => sub {
    my($dispatch, $e)= @_;
    require Egg::Helper::BlankPage;
    $e->response->body( Egg::Helper::BlankPage->out($e) );
    },

  );
# ----------------------------------------------------------

1;

__END__

# * Example
#
# use Example::Dispatch::Members;
#
# __PACKAGE__->run_modes( refhash( # <= Importance.
#
#   { ANY=> '_default', label=> 'HOME' }=> sub {},  ## template => index.tt
#
#   { ANY=> 'members',  label=> 'Members page.' }=> refhash( # <= Importance.
#
#      _begin=> \&Example::Dispatch::Members::session_start,
#
#      _default=> sub {
#        my($d, $e)= @_;
#        $e->finished( FORBIDDEN );  ## see Egg::Plugin::ErrorDocument.
#        },
#
#     { ANY=> 'profile', label=> 'Profile View.' }=> sub {},  ## template => members/profile.tt
#
#     _end=> \&Example::Dispatch::Members::session_end,
#
#     ),
#
#   ));
#

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Example - Perl extension for ...

=head1 SYNOPSIS

  use Example;
  
  ... tansu, ni, gon, gon.

=head1 DESCRIPTION

Stub documentation for Example, created by Egg::Helper::Project::Build v2.00

Blah blah blah.

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

