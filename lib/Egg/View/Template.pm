package Egg::View::Template;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Template.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::View::Template - HTML::Template for Egg view.

=head1 SYNOPSIS

  __PACKAGE__->_egg_config(
  
    VIEW => [
      [ Template => {
        path  => [qw{ <$e.template> <$e.comp> }],
        cache             => 1,
        global_vars       => 1,
        die_on_bad_params => 0,
        ... etc.
        } ],
      ],
  
    );

  # The VIEW object is acquired.
  my $view= $e->view('Template');
  
  # Associate is set.
  $view->push_associate( $object );
  
  # Filter is set.
  $view->push_filter( $filter );
  
  # It outputs it specifying the template.
  my $content= $view->render('hoge.tmpl', \%option);

=head1 DESCRIPTION

It is VIEW to use HTML::Template.

Please add the setting of VIEW to the project to use it.

  VIEW => [
    [ Template => { ... HTML::Template option. (HASH) } ],
    ],

* Please refer to the document of L<HTML::Template> for the option to set.

=cut
use strict;
use warnings;
use HTML::Template;
use Egg::View::Template::Params;
use base qw/Egg::View/;
use Carp qw/croak/;

our $VERSION= '2.00';

sub _setup {
	my($class, $e, $conf)= @_;
	$conf->{path} ||= $e->config->{template_path};
	@_;
}

=head1 METHODS

=head2 new

When $e-E<gt>view('Template') is called, this constructor is called.

Please set %Egg::View::PARAMS directly from the controller to the parameter
that wants to be set globally.

  %Egg::View::PARAMS= ( %Egg::View::PARAMS, %NewPARAM );

Some default parameters are set by L<Egg::View::Template::Params>.

=cut
sub new {
	Egg::View::Template::Params->prepare($_[1]);
	my $view= shift->SUPER::new(@_);
	$view->{filter}   = [];
	$view->{associate}= [];
	$view;
}

=head2 params, param

The parameter that wants to be passed to HTML::Template must use these methods.

=head2 push_filter ( [FILTER] )

The filter is set.

=over 4

=item * Alias: filter

=back

=cut
sub push_filter { shift->_push_var('filter', @_) }
*filter = \&push_filter;

=head2 push_associate ( [OBJECT] )

associate に渡す OBJECT をセットします。

=over 4

=item * Alias: associate

=back

=cut
sub push_associate { shift->_push_var('associate', @_) }
*associate = \&push_associate;

=head2 render ( [TEMPLATE], [OPTION] )

TEMPLATE is evaluated and the output result (SCALAR reference) is returned.

It is given priority more than VIEW set of default when OPTION is passed.

  my $body= $view->render( 'foo.tmpl', [OPTON_HASH] );

=cut
sub render {
	my $option= shift->_create_option(@_);
	my $tmpl= HTML::Template->new(%$option);
	my $body= $tmpl->output;
	return \$body;
}

=head2 output ( [TEMPLATE], [OPTION] )

The output result of the receipt from 'render' method is set in
$e-E<gt>response-E<gt>body.

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

sub _push_var {
	my($view, $type)= splice @_, 0, 2;
	return unless @_;
	push @{$view->{$type}}, shift;
}
sub _create_option {
	my $view= shift;
	my $tmpl= shift || return (undef);
	my $args= $_[0] ? ($_[1] ? {@_}: $_[0]): {};
	my $e= $view->{e};

	while (my($key, $value)= each %{$e->stash})
	  { $view->params->{$key} ||= $value }

	my %option= %{$view->config};
	@option{keys %$args}= values %$args;
	if (ref($tmpl) eq 'SCALAR') {
		$option{scalarref}= $tmpl; $option{cache}= 0;
	} elsif (ref($tmpl) eq 'ARRAY') {
		$option{arrayref}= $tmpl;
	} else {
		$option{filename}= $tmpl;
	}
	push @{$view->{associate}}, $view;
	push @{$view->{associate}}, $e->request;
	$option{associate}= $view->{associate};

	$option{filter}= $view->{filter} if @{$view->{filter}};

	\%option;
}

=head1 SEE ALSO

L<HTML::Template>,
L<Egg::View>,
L<Egg::Template::Param>,
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
