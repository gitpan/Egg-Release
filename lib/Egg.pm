package Egg;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Egg.pm 99 2007-01-15 06:33:14Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use Error;
use NEXT;
use Egg::Response;
use base qw/Egg::Engine Class::Accessor::Fast/;

our $VERSION= '0.18';

__PACKAGE__->mk_accessors( qw/view snip request response/ );

BEGIN {
	my $count;
	$SIG{__WARN__} = sub {
		my $err= shift || 'warning.';
		my @ca= caller(0);
#		$err=~s/\,\s+<DATA>\s+line\s+\d+//;
#		$err=~s/\s+at\s+[^\s]+\s+line\s+(\d+)//;
		my $line= $1 || $ca[2] || '*';
		my $pkg = $ca[0];
		$pkg= 'EGG-LOG' if $pkg=~/^Egg\:+Debug\:+Log/;
		my $countdisp= ++$count== 1 ? "\n$count": $count;
		print STDERR "$countdisp: $pkg: $line - $err";
	  };
  };

*req= \&request;
*res= \&response;
*d  = \&dispatch;

our $CRLF= "\015\012";

sub import {
	my($e, @args) = @_;
	no strict 'refs';  ## no critic
	my $Name= caller(0);
	${"$Name\::IMPORT_OK"} ||= 0;
	return if ++${"$Name\::IMPORT_OK"}> 1;
	my $firstName= uc($Name);
	my %flags= ( MOD_PERL_VERSION=> 0 );
	for (@args) {
		if (/^\-(.+)/) {
			$flags{lc($1)}= 1;
		} else {
			my $plugin= /^\+([A-Z].+)/ ? $1: "Egg::Plugin::$_";
			$plugin->require or throw Error::Simple $@;
			push @{"$Name\::ISA"}, $plugin;
		}
	}
	push @{"$Name\::ISA"}, __PACKAGE__;
	${"$Name\::__EGG_FLAGS"}= \%flags;
	*{"$Name\::debug_out"}= sub { } unless $flags{debug};
}

{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	sub namespace { $_[0]->{namespace} }
	sub encode { ${"$_[0]->{namespace}::__EGG_ENCODE"} }
	sub flags  { ${"$_[0]->{namespace}::__EGG_FLAGS"}  }
	sub flag   { ${"$_[0]->{namespace}::__EGG_FLAGS"}->{$_[1]} }
	sub plugins {
		[ map{(/^Egg\:\:Plugin\:\:(.+)/)[0]}
		 (grep /^Egg\:\:Plugin\:/, @{"$_[0]->{namespace}::ISA"}) ];
	}
	sub config {
		$_[0]->{namespace} ? ${"$_[0]->{namespace}::__EGG_CONFIG"}: 0;
	}
	sub __egg_setup {
		my $Name  = caller(0);
		my $class = shift;
		my $config= ${"$Name\::__EGG_CONFIG"}= shift
		  || throw Error::Simple q/I want configuration./;
		my $flags = ${"$Name\::__EGG_FLAGS"};
		my $self  = bless { namespace=> $Name }, $Name;
		$config->{character_in}= 'euc' unless exists($config->{character_in});
		my $firstName= uc($Name);

	# Include does the request class.
		my $r_class;
		if ($ENV{"$firstName\_REQUEST"}) {
			$r_class= $ENV{"$firstName\_REQUEST"};
		} elsif ($ENV{MOD_PERL} && ModPerl::VersionUtil->require) {
			$r_class=
			   ModPerl::VersionUtil->is_mp2  ? 'Egg::Request::Apache::MP20'
			 : ModPerl::VersionUtil->is_mp19 ? 'Egg::Request::Apache::MP19'
			 : ModPerl::VersionUtil->is_mp1  ? 'Egg::Request::Apache::MP13'
			 : throw Error::Simple qq/Unsupported mod_perl ver: $ENV{MOD_PERL}/;
			my $version= ModPerl::VersionUtil->mp_version;
			$version >= 1.9901
			  ? do { *handler= sub : method { shift; $Name->new(@_)->run } }
			  : do { *handler= sub ($$) { shift; $Name->new(@_)->run } };
			$flags->{MOD_PERL_VERSION}= $version;
		} else {
			$r_class= 'Egg::Request::CGI';
		}
		$r_class->require or throw Error::Simple $@;
		$flags->{R_CLASS}= $r_class;
		Egg::Response->setup($self);

	# dispatch is loaded.
		my $d_class;
		if ($d_class= $ENV{"$firstName\_DISPATCHER"}) {
			$d_class= $flags->{D_CLASS}= "Egg::D::$d_class";
			$d_class->require or throw Error::Simple $@;
		} elsif ($d_class= $ENV{"$firstName\_CUSTOM_DISPATCHER"}) {
			$flags->{D_CLASS}= $d_class;
			$d_class->require or throw Error::Simple $@;
		} elsif ($d_class= $ENV{"$firstName\_UNLOAD_DISPATCHER"}) {
			$flags->{D_CLASS}= $d_class;
		} else {
			$d_class= $flags->{D_CLASS}= 'Egg::D::Stand';
			$d_class->require or throw Error::Simple $@;
		}
		$d_class->_setup( $self );

	# method for character-code conversion.
		eval { ${"$Name\::__EGG_ENCODE"}= $Name->create_encode };
		if (my $err= $@) {
			throw Error::Simple
			 qq/Please arrange create_encode in the $Name package./;
		}
		for my $code (qw/euc sjis utf8/) {
			*{"$Name\::$code\_conv"}=
			  sub { ${"$Name\::__EGG_ENCODE"}->set($_[1])->$code };
		}

	# the accessor for stash is generated.
		my $accessors= $config->{accessor_names} || [];
		for my $accessor (qw/template error/, @$accessors) {
			*{__PACKAGE__."::$accessor"}= sub {
				my $e= shift;
				$e->stash->{$accessor}= shift if @_> 0;
				$e->stash->{$accessor};
			  };
		}

	# Include does the model module.
		{
			my(@models, %model_class);
			for (@{$config->{MODEL}}) {
				my($name, $model)= $_->[0]=~/^\+(.+)/
				  ? ($_->[0], $_->[0]): ($_->[0], "Egg::Model::$_->[0]");
				$name= $_->[1]->{conf_name} if $_->[1]->{conf_name};
				$model->require or throw Error::Simple $@;
				$model->setup($self, $_->[1], "model_$name");
				push @models, $name;
				$model_class{$name}= $model;
			}
			if (my $model= $ENV{"$firstName\_MODEL"}) {
				for (split /\s*[\,\;]\s*/, $model) {
					$_->require or throw Error::Simple $@;
					$_->setup($self);
					push @models, $_;
					$model_class{$_}= $_;
				}
			}
			$flags->{MODEL}= \@models;
			$flags->{MODEL_CLASS}= \%model_class;

	# Include does the view module.
			if (my $view= $ENV{"$firstName\_VIEW"}) {
				$view->require or throw Error::Simple $@;
				$view->setup($self);
				$flags->{VIEW_CLASS}= $flags->{VIEW}= $view;
			} else {
				my $v= $config->{VIEW}->[0] || [ 'Dummy'=> {} ];
				my($name, $view)= $v->[0]=~/^\+(.+)/
				  ? ($v->[0], $v->[0]): ($v->[0], "Egg::View::$v->[0]");
				$name= $_->[1]->{conf_name} if $_->[1]->{conf_name};
				$view->require or throw Error::Simple $@;
				$view->setup($self, $v->[1], "view_$name");
				$flags->{VIEW}= $v->[0];
				$flags->{VIEW_CLASS}= $view;
			}
		  };

	# They are the plugin other setups.
		$self->setup;
	}
  };

sub new {
	my $class= shift;
	my $r    = shift || undef;
	my $e= bless {
	  finished=> 0, namespace=> $class,
	  snip => [], stash=> {}, model=> {},
	  }, $class;
	my $r_class= $e->flag('R_CLASS') || throw Error::Simple
	   "Error - 'request_class' is not set."
	 . " $class\->setup seems to have failed.";
	$e->request ( $r_class->new($e, $r) );
	$e->response( Egg::Response->new($e) );
	for (@{$e->flag('MODEL')}) {
		my $pkg= $e->flags->{MODEL_CLASS}{$_} || next;
		$e->{model}{$_}= $pkg->new($e);
	}
	my $view_class= $e->flag('VIEW_CLASS');
	$e->view ( $view_class->new($e) );
	$e;
}
sub stash {
	my $e= shift;
	return $e->{stash} if @_< 1;
	my $key= shift;
	$e->{stash}{$key}= shift if @_> 0;
	$e->{stash}{$key};
}
sub dispatch {
	my $e= shift;
	return "$e->{namespace}::D::$_[0]" if @_;
	$e->{dispatch};
}
sub finished {
	my $e= shift;
	if (my $status= shift) {
		if ($status) {
			$status== 500 and $e->log->notes(@_);
			$e->response->status($status);
			$e->{finished}= 1;
		} else {
			$e->response->status(200);
			$e->{finished}= 0;
		}
		return 0;
	}
	$e->{finished};
}
sub debug { $_[0]->flag('debug') }

1;

__END__

=head1 NAME

Egg - WEB application framework.

=head1 SYNOPSIS

First of all, please make the project.

And, please setup as you answer the WEB request.

Please see L<Egg::Release> for details.

A local script and the operation such as cron can be united as follows.

 #!/usr/loca/bin/perl -w
 use strict;
 use [MYPROJECT];
 
 my $e= [MYPROJECT]->new;

 $e->method ...
 
 ... ban, bo, bo, bo, bon.

However, I think that the error occurs only because some methods are
 for WEB requests. 

=head1 ENVIRONMENT

It explains the environment variable more in detail in L<Egg::Release>.

=head2 [MYPROJECT]_DISPATCHER

=head2 [MYPROJECT]_CUSTOM_DISPATCHER

=head2 [MYPROJECT]_UNLOAD_DISPATCHER

=head2 [MYPROJECT]_MODEL

=head2 [MYPROJECT]_VIEW

=head2 [MYPROJECT]_REQUEST

=head1 METHODS

=head2 new

It is called from the controller of the project directly.
Only the Request object is accepted to the argument.
It is undefined and good usually.

 my $e= [MYPROJECT]->new;

=head2 $e->namespace

The project name under operation is returned.
It is the same as ref($e).

=head2 $e->config

The HASH reference of the configuration is returned.

=head2 $e->plugins

The list of the loaded plugin is returned by the ARRAY reference.

=head2 $e->flags

The set flag is settled by the HASH reference and it returns it.

=head2 $e->flag([FLAG NAME]);

The value of the specified flag is returned.

=head2 $e->encode;

The object for the character-code processing is returned.

$e->euc_conv, $e->sjis_conv, $e->utf8_conv

=head2 $e->dispatch  or $e->d

When the argument is not given, the dispath object made from 'create_dispatch' is returned.
When the argument is given, the class name modified with '[MYPROJECT]::D' is returned. 

 # [MYPROJECT]::D::Hoge->foo is called.
 
 $e->d('Hoge')->foo($e);

=head2 $e->request  or $e->req

The Egg::Request object is returned.

=head2 $e->response  or $e->res

The Egg::Response object is returned.

=head2 $e->model([MODEL_NAME]);

The object of specified MODEL is returned.

=head2 $e->view

The VIEW object to output contents is returned.

=head2 $e->debug;

It is a flag whether operate by debug mode.

=head2 $e->template;  $e->error;

It is an accessor to $e->stash.

=head2 $e->snip->[[Number]];

The ARRAY reference into which the request passing is divided by/is returned.

=head2 $e->stash->{[KEY NAME]};

It is a preservation place to share data.

=head2 $e->stash([KEY], [VALUE]);

When [KEY] is given, the value of $e->stash->{[KEY]} is returned.

When [VALUE] is given, the value is set in $e->stash->{[KEY]}.

=head2 $e->finished([RESPONSE STATUS CODE]);

It reports on the completion of processing.
Please give an appropriate response code.

=head1 BUGS

When you find a bug, please email me (E<lt>mizunoE<64>bomcity.comE<gt>) with a light heart.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Engine>,
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
