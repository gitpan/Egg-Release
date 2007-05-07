package Egg::View::Mason;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Mason.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::View::Mason - HTML::Mason for Egg View.

=head1 SYNOPSIS

  __PACKAGE__->egg_startup(
    ...
    .....
  
  VIEW=> [
    [ 'Mason' => {
      comp_root=> [
        [ main   => '/path/to/root' ],
        [ private=> '/path/to/comp' ],
        ],
      data_dir=> '/path/to/temp',
      ... other HTML::Mason option.
      } ],
    ],
  
   );

  # The VIEW object is acquired.
  my $view= $e->view('Mason');
  
  # It outputs it specifying the template.
  my $content= $view->render('hoge.tt', \%option);

=head1 DESCRIPTION

It is VIEW to use HTML::Mason.

Please add the setting of VIEW to the project to use it.

  VIEW => [
    [ Mason => { ... HTML::Mason option. (HASH) } ],
    ],

* Please refer to the document of L<HTML::Mason> for the option to set.

It accesses the object and data by using following variable from the template.

  $e ... Object of project.
  $s ... $e->stash.
  $p ... $e->view('Mason')->params.

=cut
use strict;
use warnings;
use HTML::Mason;
use base qw/Egg::View/;
use Carp qw/croak/;

our $VERSION= '2.00';

=head1 METHODS

=head2 new

When $e-E<gt>view('Mason') is called, this constructor is called.

Please set %Egg::View::PARAMS directly from the controller to the parameter
that wants to be set globally.

  %Egg::View::PARAMS= %NewPARAM;

=head2 params, param

The parameter that wants to be passed to HTML::Mason must use these methods.

=head2 render ( [TEMPLATE], [OPTION] )

TEMPLATE is evaluated and the output result (SCALAR reference) is returned.

It is given priority more than set of default when OPTION is passed.

  my $body= $view->render( 'foo.tt', [OPTION_HASH] );

=cut

sub _setup {
	my($class, $e, $conf)= @_;
	$conf->{comp_root} ||= [ 'main' => $e->config->{template_path}[0] ];
	$conf->{data_dir}  ||= $e->config->{temp};
	$class;
}

=head2 render ( [TEMPLATE], [OPTION] )

TEMPLATE is evaluated and the output result (SCALAR reference) is returned.

It is given priority more than set of default when OPTION is passed.

  my $body= $view->render( 'foo.tt', [OPTION_HASH] );

=cut
sub render {
	my $view= shift;
	my $tmpl= shift || return(undef);
	   $tmpl=~m{^[^/]} and $tmpl= "/$tmpl";
	my $args= $_[0] ? ($_[1] ? {@_}: $_[0]): {};
	my $body;
	my $mason= HTML::Mason::Interp->new(
	  %{$view->config}, %$args,
	  out_method    => \$body,
	  allow_globals => [qw/$e $s $p/],
	  );
	$mason->set_global(@$_) for (
	  [ '$e' => $view->{e} ],
	  [ '$s' => $view->{e}->stash ],
	  [ '$p' => $view->params ],
	  );
	$mason->exec($tmpl);
	\$body;
}

=head2 output ( [TEMPLATE], [OPTION] )

The output result of the receipt from 'render' method is set in
$e-E<gt>response-E<gt> body.

When TEMPLATE is omitted, acquisition is tried from $view->template.
 see L<Egg::View>.

If this VIEW operates as default_view, this method is called from
'_dispatch_action' etc. by Egg.

  $view->output;

=cut
sub output {
	my $view= shift;
	my $tmpl= shift || $view->template || croak q{ I want template. };
	$view->e->response->body( $view->render($tmpl, @_) );
}

=head1 SEE ALSO

L<HTML::Mason>,
L<Egg::View>,
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
