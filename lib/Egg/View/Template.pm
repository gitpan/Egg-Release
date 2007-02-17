package Egg::View::Template;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Template.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use warnings;
use base qw/Egg::View/;
use HTML::Template;
use Egg::View::Template::Params;

our $VERSION= '0.02';

 {
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	for my $name ( qw/associate filter/ ) {
		*{__PACKAGE__."::push_$name"}= sub {
			return unless @_> 1;
			my($view, $code)= @_;
			push @{$view->{$name}}, $code;
		 };
	}
  };

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
	my $view= shift;
	my $e   = shift;
	my $tmpl= $view->template_file($e) || return;
	my $body= $view->render($tmpl);
	$e->response->body( $body );
	1;
}
sub render {
	my $view= shift;
	my $tmpl= shift || return (undef);
	my $args= shift || {};
	my $e= $view->{e};

	@{$view->params}{keys %$args}= values %$args;
	my %conf= %{$view->config};
	if    (ref($tmpl) eq 'SCALAR') { $conf{scalarref}= $tmpl; $conf{cache}= 0 }
	elsif (ref($tmpl) eq 'ARRAY')  { $conf{arrayref} = $tmpl }
	else                           { $conf{filename} = $tmpl };

	push @{$view->{associate}}, $view;
	push @{$view->{associate}}, $e->request;
	$conf{associate}= $view->{associate};

	$conf{filter}= $view->{filter} if (@{$view->{filter}});

	my $template= $view->create_template(\%conf, $e);
	my $body= $template->output;
	return \$body;
}
sub create_template {
	my($view, $conf)= @_;
	HTML::Template->new(%$conf);
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

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
