package Egg::Engine;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Engine.pm 34 2006-12-14 08:17:52Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use Error;
use NEXT;
use HTML::Entities;

our $VERSION= '0.01';

sub setup    { $_[0] }
sub prepare  { $_[0] }
sub action   { $_[0] }
sub finalize { $_[0] }
sub compress { }
sub create_encode { Egg::DummyEncode->new }

{
	no warnings 'redefine';
	*escape_html  = \&encode_entities;
	*unescape_html= \&decode_entities;
	sub encode_entities {
		shift;
		my $args= $_[1] || q/\\\<>&\"\'/;
		&HTML::Entities::encode_entities($_[0], $args);
	}
	sub decode_entities {
		shift;
		&HTML::Entities::decode_entities(@_);
	}
	sub encode_entities_numeric {
		shift;
		&HTML::Entities::encode_entities_numeric(@_);
	}
  };

sub run {
	my($e)= @_;
	eval {
	$e->debug ? do {
		Egg::Debug::SimpleBench->require or throw Error::Simple $@;
		my $bench= Egg::Debug::SimpleBench->new;
		my $Name = $e->namespace. ' v'. $e->VERSION;
		my $model_class= join ', ', map{
			my $pkg= "Egg::Model::$_";
			"$_ v". $pkg->VERSION;
		 } @{$e->flag('MODEL')};
		my $view_class= $e->flag('VIEW');
		my $view_pkg= "Egg::View::$view_class";
		$view_class.= ' v'. $view_pkg->VERSION;
		$bench->settime;
		$e->request->prepare($e);
		$e->debug_out(
		  "\n# << $Name start. --------------\n"
		  . "# + request-path : ". $e->request->path. "\n"
		  . "# + load plugins : ". (join ', ', @{$e->plugins}). "\n"
		  . "# + request-class: ". $e->flag('R_CLASS'). "\n"
		  . "# + dispatch-clas: ". $e->flag('D_CLASS'). "\n"
		  . "# + model-class  : $model_class\n"
		  . "# + view-class   : $view_class"
		  );
		$e->request->param and do {
			my $params= $e->request->params;
			$e->debug_out(
			    "# + in request querys:\n"
			  . (join "\n", map{"# +   - $_ = $params->{$_}"}keys %$params)
			  . "\n# + --------------------\n"
			  );
		 };
		$e->step1; $bench->stock('step1:');
		$e->step2; $bench->stock('step2:');
		$e->step3; $bench->stock('step3:');
		$bench->out;
	 }: do {
		$e->request->prepare($e);
		$e->step1;
		$e->step2;
		$e->step3;
	 };
	};
	if (my $err= $@) {
		my $comp= $e->template || '*';
		$e->log->notes("$comp: $err");
		$e->disp_error("$comp: $err");
	}
	$e->response->result;
}
sub step1 {
	my($e)= @_;
	$e->prepare;
	$e->create_dispatch;
	$e->finished || do {
		$e->dispatch->_start;
		$e->dispatch->_run;
	  };
	$e;
}
sub step2 {
	my($e)= @_;
	$e->finished || do {
		$e->action;
		$e->response->body || $e->view->output($e);
		$e->dispatch->_finish;
	  };
	$e;
}
sub step3 {
	my($e)= @_;
	$e->response->content_type || $e->response
	  -> content_type($e->config->{content_type} || 'text/html');
	$e->finalize;
	$e->output_content;
	$e;
}
sub output_content {
	my $e= shift;
	my $res= $e->response;
	return if $e->finished;
	if ($res->status=~/^(30[1237])/) {
		my $location= $res->location || return $e->finished(500);
		my $header= $res->create_cookies;
		$header.= "Status: $1 Found$Egg::CRLF"
		       .  "Location: $location$Egg::CRLF$Egg::CRLF";
		$e->request->output(\$header);
	} else {
		$e->compress($res->body);
		my $body= $res->body;
		$e->request->output($res->create_header($body), $body);
	}
	$res->body(undef);
	return $e->finished(200) unless my $err= $@;
	return $e->finished(500, $err);
}
sub create_dispatch {
	my($e)= @_;
	my $dispatch= $e->flag('D_CLASS')
	  || throw Error::Simple q/Class of dispatch is not understood./;
	$e->{dispatch}= $dispatch->_new($e);
}
sub plugin {
	my $e= shift;
	my $accessor= shift || 0;
	my $plugin= "Egg::Plugin::$_[0]";
	$plugin->require or throw Error::Simple $@;
	$plugin->prepare;
}
sub is_view {
	my $e= shift;
	$e->flag('VIEW') eq $_[0] ? 1: 0;
}
sub is_model {
	my $e= shift;
	return (grep /^$_[0]$/, @{$e->flag('MODEL')})[0] ? 1: 0;
}
sub model { $_[1] ? $_[0]->{model}{$_[1]}: 0 }

sub log {
	$_[0]->{__egg_log} || do {
		Egg::Debug::Log->require or die $@;
		$_[0]->{__egg_log}= Egg::Debug::Log->new($_[0]);
		$_[0]->{__egg_log};
	 };
}
sub disp_error {
	Egg::Debug::Base->require or throw Error::Simple $@;
	Egg::Debug::Base->disp_error(@_);
}
sub debug_out {
	Egg::Debug::Base->require or throw Error::Simple $@;
	Egg::Debug::Base->debug_out(@_);
}

package Egg::DummyEncode;
sub new {
	my $class= shift;
	my $self = bless {}, $class;
	@_> 0 ? $self->set(@_): $self;
}
sub set {
	my $self= shift;
	$self->{str}= @_> 0 ? (ref($_[0]) ? $_[0]: \$_[0]): \"";
	$self;
}
sub euc  { $_[0]->{str} ? ${$_[0]->{str}}: "" }
sub sjis { $_[0]->{str} ? ${$_[0]->{str}}: "" }
sub utf8 { $_[0]->{str} ? ${$_[0]->{str}}: "" }

1;

__END__

=head1 NAME

Egg::Engine - It assists in basic operation of Egg.

=head1 METHODS

=head2 $e->run

A series of processing is done until the WEB request is received and
 contents are output.

=head2 $e->step1

It is processing of the first stage that is called from $e->run.

=head3 $e->prepare

'prepare' method of each B<plugin> is sequentially called.

=head3 $e->create_dispatch

It is initial processing of dispatch.

=head3 $e->dispatch->_start  and $e->dispatch->_run

'_start' method and '_run' method of dispatch are continuously called.
However, if $e->finished is ture, these processing is canceled.

=head2 $e->step2

It is processing of the second stage that is called from $e->run.
However, if $e->finished is true, all processing here is canceled.

=head3 $e->action

'action' method of the plugin is called.

=head3 $e->view->output

The template is evaluated and contents for the output are generated.
However, if $e->response->body has defined it, processing here has already
 been canceled. 

=head3 $e->dispatch->_finish

If $e->response->body is undefined, '_finish' method of dispatch is called.
The processing of dispatch are the completion of all by this.

=head2 $e->step3

They are the last processing most that is called from $e->run.

If $e->response->content_type is first of all undefined in the processing
 to here, $e->config->{content_type} is set.

=head3 $e->finalize

'_finalize' method of each plugin is sequentially called.

=head3 $e->output_content

If $e->finished is true, all processing here is canceled.

$e->compress( $e->response->body ) is called before contents are output.

And, contents are output to the client.

=head2 $e->create_dispatch

The dispatch object is generated.
An overwrite of the controller of this method and customizing for me are
 also good.

=head2 $e->plugin

The plugin is require.
However, it is not added to @ISA, and 'setup' method is not called.
This merely does require.

=head2 $e->is_model([MODEL_NAME]);

Whether Model of [MODEL_NAME] is called in is checked.

=head2 $e->is_view([VIEW_NAME]);

Whether VIEW of [VIEW_NAME] is called in is checked.

=head2 $e->log

The Egg::Debug::Log object is returned.

=head2 $e->disp_error([MESSAGE]);

When the error occurs by processing $e->run, it reports on the error on
 the screen where Egg is yellow.

=head2 $e->debug_out([MESSAGE]);

The message of argument is output to STDERR while operating by debug mode.
This any method is replaced with the code not done usually.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model>,
L<Egg::View>,
L<Egg::Request>,
L<Egg::Response>,
L<Egg::D::Stand>,
L<Egg::Debug::Base>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
