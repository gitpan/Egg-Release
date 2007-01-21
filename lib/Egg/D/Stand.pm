package Egg::D::Stand;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Stand.pm 129 2007-01-21 05:44:23Z lushe $
#
use strict;
use warnings;
use Error;
use UNIVERSAL::require;

our $VERSION= '0.04';

sub _setup {
	my($class, $e)= @_;
	my $dispat= $e->namespace.'::D';
	my $diroot= "$dispat\::Root";
	$dispat->require or throw Error::Simple $@;
	$diroot->require or throw Error::Simple $@;
	no strict 'refs';  ## no critic
	@{"$dispat\::ISA"}= __PACKAGE__;
	$e->flags->{EGG_D_TARGET}= $e->debug
	  ? sub { throw Error::Simple $_[1] }
	  : sub { $_[0]->_super_call('_default') };
	$class;
}
sub _new {
	my($class, $e)= @_;
	my $dispatch= $e->namespace. "::D";
	my $root= $e->config->{root} || throw Error::Simple q/I want config 'root'./;
	my $ext = $e->config->{default_template_extension} || '.tmpl';
	my $dis = bless {
	  basename=> $dispatch,
	  isa=> [],
	  ext=> $ext,
	  e  => $e,
	  }, $dispatch;
	my($pkg, $method, $template, $check)= $dis->dispatch_map($e);
	$e->finished || do {
		$pkg=~/^\d/ and $pkg= undef;
		$pkg ||= 'Root';
		my($root_ok, $load);
		no strict 'refs';  ## no critic
		for ( split /\:\:+/, $pkg ) {
			$load.= "::$_";
			my $pkgname= $dispatch. $load;
			$pkgname->require || do {
				if (my $err= $@) {
					$e->debug_out("# - require error: $pkgname - $err");
				}
				next;
			  };
			push @{$dis->{isa}}, $pkgname;
			$root_ok= 1 if $pkgname=~/^$dispatch\:\:Root$/;
		}
		push @{$dis->{isa}}, "$dispatch\::Root" unless $root_ok;
		push @{$dis->{isa}}, __PACKAGE__;

		$e->debug and $e->debug_out
		 ("# + Dispatcher   : ". (join ', ', @{$dis->{isa}}));

		if (! $e->template && ! $e->response->body) {
			if ($template) {
				$dis->_template($template, $check);
			} else {
				(! $method || $method=~/^_/) and $method= '_default';
				$pkg= $dis->{isa}->[0];
				$dis->_target( sub {
					eval { $pkg->$method($e) };
					if (my $err= $@) {
						$e->flags->{EGG_D_TARGET}->($dis, "[$pkg] $err");
					}
				  } );
			}
		}
	 };
	return $dis;
}
sub _target {
	my $dis= shift;
	return $dis->{_target} if @_< 1;
	($dis->{_target})= @_;
}
sub _template {
	my $dis  = shift;
	my $tmpl = shift || return 0;
	my $check= shift || 0;
	my($e, $root)= ($dis->{e}, $dis->{e}->config->{root});
	return do { $e->template($tmpl); 1 } unless $check;
	return do { $e->template($tmpl); 1 } if -e "$root$tmpl";
	$tmpl=~s{\.[^/\.]+$} [];
	if ($tmpl=~m{/$}) {
		$tmpl.= "index$dis->{ext}";
		return do { $e->template($tmpl); 1 } if -e "$root$tmpl";
	} elsif ($tmpl=~m{/index$}) {
		$tmpl.= $dis->{ext};
	} else {
		$tmpl.= "/index$dis->{ext}";
		return do { $e->template($tmpl); 1 } if -e "$root$tmpl";
	}
	$e->debug_out("# + template file: NoFound!! - $tmpl");
	$e->finished(404);
	return 0;
}
sub _template_make {
	my($dis, $base, $check)= @_;
	my $tmpl= $dis->_make_template_path($base) || return 0;
	$dis->_template($tmpl, $check);
}
sub _make_template_path {
	my $dis = shift;
	my $base= shift || "";
	my $path= lc($dis->{e}->request->path) || return $dis->{e}->finished(404);
	my($name)= $path=~m{([^/]+)$};
	return $dis->{e}->finished(403) if ($name && $name=~/^\./);
	return
	   $path=~m{^$base/([a-z0-9_\-\:/]+)/$}i ? "$base/$1/index$dis->{ext}"
	 : $path=~m{^$base/([a-z0-9_\-\:/]+)}i   ? "$base/$1$dis->{ext}"
	 :                                         "$base/index$dis->{ext}";
}
sub _start {
	$_[0]->_super_call('_begin');
}
sub _run {
	my($dis)= @_; my $e= $dis->{e};
	return if ($e->template || $e->response->body);
	my $target= $dis->_target || return;
	$target->();
}
sub _finish {
	$_[0]->_super_call('_end');
}
sub _call {
	my $dis= shift;
	my $pkg= shift || return 0;
	$pkg= "$dis->{basename}::$pkg";
	$pkg->require || do {
		my $err= $@;
		$dis->{e}->debug_out("# - _call error  : $err");
		return 0;
	  };
	return $pkg;
}
sub _super_call {
	my($dis, $method)= @_;
	for my $pkg (@{$dis->{isa}}) {
		next unless $pkg->can($method);
		eval { $pkg->$method($dis->{e}, $dis) };
		if (my $err= $@) {
			$dis->{e}->debug_out("# - _call error  : $pkg\->$method - $err");
			throw Error::Simple $err;
		}
		last;
	}
}
sub _default { warn "There is no 'Root::_default'." }
sub _begin   { }
sub _end     { }

1;

__END__

=head1 NAME

Egg::D::Stand - Standard dispatch for Egg.

=head1 SYNOPSIS

Example of code in which dispatch is made from control.

 sub create_dispatch {
 	my($e)= @_;
 	$e->{dispatch}= Egg::D::Stand->_new($e);
 }

=head1 DESCRIPTION

When the constructor is called, dispatch_map of dispatch on the project
 side is called.

How the behavior at each request is done on the dispatch_map side has been 
decided. How to call sub-dispatch can be decided with dispatch_map.

If finished of the call of the constructor is effective, nothing is done.

It is an example of dispatch_map as follows.

 package MYPROJECT::D;
 use strict;
 use Egg::Const;
 
 sub dispatch_map {
 	my($dis, $e)= @_;
 	#
 	# The directory name of Request Path of the first hierarchy is received.
 	# If it is empty, ARGS is returned to call _default
 	#  of MYPROJECT::D::Root.
 	#
 	my $dir1= $e->snip->[0] || return qw{ Root };
 	if ($dir1=~/^hoge/) {
 		#
 		# The directory name of the second hierarchy is received.
 		# If it is empty, the template definition is returned. (It is 0 to
 		#  actually extend.)
 		# And, it tries always to call _begin and _end though _default of
 		# Root is not called.
 		#
 		my $dir2= $e->snip->[1]
 		  || return $dis->_template('/hoge/index.tt');
 		if ($dir2=~/^foo/) {
 			#
 			# Processing is entrusted to index (method)
 			#  of MYPROJECT::D::Foo. 
 			# The thing that $e->response->body is defined or template by
 			# index is expected.
 			#
 			return qw{ Foo index };
 		} else {
 			#
 			# The method of the leading part of MYPROJECT::D::Foo is undefined.
 			# It defines it directly guessing the template.
 			# _begin and _end are called.
 			# When 1 is given to the second argument of make, existence under
 			# of $e->config->{root} is checked.
 			# 404 is returned in case of not being.
 			#
 			return ('Foo', 0, $dis->_template_make("/$dir1/$dir2", 1));
 		}
 	} elsif ($dir1=~/^boo/) {
 		#
 		# _default of MYPROJECT::D::Boo operates if it is empty.
 		#
 		my $dir2= $e->snip->[1] || return qw{ Boo };
 		if ($dir=~/.+\.txt$/) {
 			#
 			# If the second hierarchy is a file name, contents of a suitable
 			# file are returned. And, $e->responce->body is defined.
 			#
 			$e->responce->content_type('text/plain');
 			open FH, "/path/to/boo.txt" || return $e->finished( NOT_FOUND );
 			$e->responce->body( join '', <FH> );
 			close FH;
 			return 0;
 		} else {
 			return $e->finished( FORBIDDEN ); # Forbidden is returned.
 		}
 	}
 	#
 	# All requests not matched above are returned by _default
 	# of MYPROJECT::D::Root.
 	#
 	return return qw{ Root };
 	#
 	#
 	# Or, when you return Not Found.
 	return $e->finished( NOT_FOUND );
 	#
 }

=head1 METHODS

=head2 $e->_template([TEMPLATE PATH], [1]);

The template is decided.
When 1 is given to the second argument of make, existence under of
$e->config->{root} is checked. 404 is returned in case of not being.

=head2 $e->_template_make([REQUEST PATH], [1]);

Template is guessed by given Path.
After a suitable template is decided, processing is passed to $e->_template.

=head2 $e->_call([PACKAGE NAME]);

After the name supplemented with MYPROJECT::D is packaged in require,
 the name is returned.

=head1 SEE ALSO

L<Egg::Release>

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
