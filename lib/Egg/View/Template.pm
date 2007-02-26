package Egg::View::Template;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Template.pm 250 2007-02-25 11:40:06Z lushe $
#
use strict;
use warnings;
use base qw/Egg::View/;
use HTML::Template;
use Egg::View::Template::Params;

our $VERSION= '0.04';

sub setup {
	my($class, $e, $conf)= @_;
	$conf->{path} ||= $e->config->{template_path};
}
sub new {
	my $view= shift->SUPER::new(@_);
	$view->{filter}= [];
	$view->{associate}= [];
	Egg::View::Template::Params->in($view, @_);
	$view;
}
sub output {
	my($view, $e)= splice @_, 0, 2;
	my $tmpl= shift || $view->template_file($e)
	   || Egg::Error->throw('I want template.');
	my $body= $view->render($tmpl);
	$e->response->body( $body );
}
sub render {
	my $conf= shift->_create_config(@_);
	my $tmpl= HTML::Template->new(%$conf);
	my $body= $tmpl->output;
	return \$body;
}
sub filter    { shift->_push_var('filter', @_) }
sub associate { shift->_push_var('associate', @_) }

sub _push_var {
	my($view, $type)= splice @_, 0, 2;
	return unless @_;
	push @{$view->{$type}}, shift;
}
sub _create_config {
	my $view= shift;
	my $tmpl= shift || return (undef);
	my $args= $_[0] ? ($_[1] ? {@_}: $_[0]): {};
	my $e= $view->{e};

	while (my($key, $value)= each %{$e->stash})
	  { $view->params->{$key} ||= $value }
	my %conf= %{$view->config};
	@conf{keys %$args}= values %$args;
	if    (ref($tmpl) eq 'SCALAR') { $conf{scalarref}= $tmpl; $conf{cache}= 0 }
	elsif (ref($tmpl) eq 'ARRAY')  { $conf{arrayref} = $tmpl }
	else                           { $conf{filename} = $tmpl };

	push @{$view->{associate}}, $view;
	push @{$view->{associate}}, $e->request;
	$conf{associate}= $view->{associate};

	$conf{filter}= $view->{filter} if @{$view->{filter}};

	\%conf;
}

1;

__END__

=head1 NAME

Egg::View::Template - HTML::Template is used for View of Egg.

=head1 SYNOPSIS

This is a setting example.

 VIEW=> [
   [ Template=> {
     path=> [qw( /path/to/root /path/to/comp )],
     cache=> 1,
     global_vars=> 1,
     die_on_bad_params=> 0,
     ... etc.
     } ],
   ],

 # Associate is set. The object with 'param' method.
 $e->view->push_associate( $e->o );
 
 # Filter is set.
 $e->view->push_filter( ...filter code. );

When you want to use it individually.

 my $mbody= $e->view->render('mail-body.tmpl', { foo=> 'baa' });
 
 sendmail->method('toaddr@domain', 'subject', $mbody);

=head1 DESCRIPTION

The option that can be specified for HTML::Template

 - strict
 - global_vars
 - cache
 - shared_cache
 - double_cache
 - blind_cache
 - die_on_bad_params
 - vanguard_compatibility_mode
 ... etc.

Please see the document of L<HTML::Template> in detail.

The parameter of default is taken from Egg::View::Template::Params.

Please treat %Egg::View::PARAMS when you want to set a fixed parameter arbitrarily.

Please see L<Egg::View> in detail.

=head1 METHODS

=head2 $view->push_associate([OBJECT]);

Object that becomes a hint to bury the value under the template is set.
Set object should have the param method.

=head2 $view->push_filter([filter code]);

Filter that processes the template beforehand is set.
Please see the document of HT about the filter that can be set and the code.

=head2 $view->param([KEY], [VALUE]);

Set and refer to the parameter passed to HTML::Template.

=head2 $view->params

The HASH reference of parameter is returned. 

=head1 SEE ALSO

L<HTML::Template>,
L<Egg::View>,
L<Egg::View::Template::Params>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
