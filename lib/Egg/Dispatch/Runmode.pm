package Egg::Dispatch::Runmode;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Runmode.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use Tie::RefHash;
use base qw/Egg::Dispatch/;

our $VERSION = '0.08';

*start_mode= \&default_mode;
{
	no strict 'refs';  ## no critic
	sub run_modes {
		my $self = shift;
		my $class= ref($self) || $self;
		if (@_) {
			$class eq __PACKAGE__
			 and Egg::Error->throw('Mistake of call method.');
			${"$class\::RUN_MODES"}= ref($_[0]) ? $_[0]: {@_};
		}
		${"$class\::RUN_MODES"} || 0;
	}
	sub default_mode {
		my $self = shift;
		my $class= ref($self) || $self;
		if (my $default= shift) {
			$class eq __PACKAGE__
			  and Egg::Error->throw('Mistake of call method.');
			$default= "_$default" if $default!~/^_/;
			${"$class\::RUN_MODE_DEFAULT"}= $default;
		}
		${"$class\::RUN_MODE_DEFAULT"} ||= '_default';
	}
	sub mode_param {
		my $prot= shift;
		if (my $class= ref($prot)) {
			return ${"$class\::PARAM_CODE"} ||= sub {};
		} else {
			my $param_name= shift || Egg::Error->throw('I want param name.');
			${"$prot\::PARAM_CODE"}= sub {
				my($self, $e)= @_;
				if (my $snip= $e->request->params->{$param_name}) {
					$snip=~tr/\t\r\n//d; $snip=~s/ +//g;
					return $snip
					  ? [map{lc($_)}(split /[\/\:\-]+/, $snip)]: [];
				}
				return [];
			  };
		}
	}
	sub _before_setup {
		my($class, $e, $dispat)= @_;
		no warnings 'redefine';
		*{"$dispat\::refhash"}= sub {
			my %refhash;
			tie %refhash, 'Tie::RefHash', @_;
			\%refhash;
		  };
		$class->next::method($e, $dispat);
	}
  };

sub _new {
	my($class, $e)= @_;
	my $dispat= $e->global->{EGG_DISPATCH_BASE};
	my $self= bless { e=> $e,
	  default_name=> $e->config->{template_default_name} }, $dispat;
	$self->{snip}= $self->mode_param->($self, $e)
	            || [map{lc($_)}@{$e->snip}];
	$self->{debug_out}= $e->global->{EGG_DISPATCH_DEBUGOUT};
	$self->{label}= [];
	$self;
}
sub mode_now {
	my $self = shift;
	my $now  = $self->e->action  || return "";
	my $label= $self->{label};
	my $num  = $#{$label}- (shift || 0);
	$num< 0 ? "": (join('-', @{$now}[0..$num]) || "");
}
sub label {
	my $self= shift;
	return $self->{label} unless @_;
	$self->{label}->[$_[0]] || "";
}
sub _scan_mode_exted { @_ }

sub _scan_mode {
	my($self, $num, $runmode, $default, $is_post)= @_;
	my $snip  = $self->{snip} || [];
	my $wanted= $snip->[$num] || "\0";
	   $wanted=~s{\.[^\.]{1,4}$} [];
	unshift @{$self->{__parts}}, $runmode;
	my $d_code;
	for my $key (keys %$runmode) {
		my $value= $runmode->{$key} || next;
		my $page_title;
		if (ref($key) eq 'HASH') {
			my $temp= $key->{ANY} || do {
				$is_post ? ($key->{POST} || next): ($key->{GET} || next);
			  };
			$page_title= $key->{label} || $wanted;
			$key= $temp;
		}
		if (my @piece= $wanted=~m{^$key$}) {
			$page_title ||= $wanted;
			push @{$self->{label}}, $page_title;
			if (ref($value) eq 'HASH') {
				return 1 if $self->
				  _scan_mode(($num+ 1), $value, $default, $is_post);
			} else {
				next if $wanted=~/^_/;
				$self->page_title($page_title);
				$self->e->action(@{$snip}[0..($num- 1)], $wanted);
				$self->_scan_mode_more;
				$self->e->stash->{_action_match}= \@piece;
				$self->{__action_code}= [$value, \@piece];
				return 1;
			}
		} elsif ($key eq $default) {
			$d_code= [$value, $page_title];
		} else {
			$self->_scan_mode_exted($snip, $num, $wanted, $key,
			  $value, $default, $is_post, ($page_title || $wanted));
		}
	}
	return 0 unless $d_code;
	$self->page_title(
	     $d_code->[1]
	  || $self->{label}->[$#{$self->{label}}]
	  || $self->e->config->{title}
	  || $self->{default_name}
	  );
	$self->e->action(@{$snip}[0..($num- 1)], $self->{default_name});
	$self->_scan_mode_more;
	$self->{__action_code}= [$d_code->[0]];
	$self->{__backup_action}= $wanted;
	1;
}
sub _scan_mode_more {
	my($self)= @_;
	for (@{$self->{__parts}}) {
		if (my $begin= $_->{_begin}) {
			$self->{__begin_code}= $begin;
			last if $self->{__end_code};
		}
		if (my $end= $_->{_end}) {
			$self->{__end_code}= $end;
			last if $self->{__begin_code};
		}
	}
	$self;
}
sub _start {
	my($self)= @_;
	$self->_reset;
	$self->_scan_mode(
	  0, $self->run_modes,
	  $self->default_mode,
	  ($self->e->request->is_post || 0),
	  ) || return 0;
	my $begin= $self->{__begin_code} || return 0;
	$begin->($self, $self->e);
	1;
}
sub _action {
	my($self)= @_;
	return 0 if $self->e->finished;
	my $action= $self->{__action_code}
	  || return $self->e->finished(404);  # NOT_FOUND.
	$self->e->backup_action($self->{__backup_action});
	$action->[0]->($self, $self->e, ($action->[1] || []));
	1;
}
sub _finish {
	my($self)= @_;
	my $end= $self->{__end_code} || return 0;
	$end->($self, $self->e);
	1;
}
sub _reset {
	my($self)= @_;
	$self->{label}= [];
	$self->{__parts}= [];
	$self->e->{action}= [];
	$self->{__begin_code}= $self->{__action_code}= $self->{__end_code}= 0;
}
sub _example_code {
	my($self)= @_;
	my $a= { project_name=> $self->e->namespace };

	<<END_OF_EXAMPLE;
package $a->{project_name}\::D;
use strict;
use Egg::Const;

use $a->{project_name}::D::Members;
use $a->{project_name}::D::BBS;

__PACKAGE__->run_modes( refhash(

  _default=> sub {},

  help=> sub {},

  { ANY=> 'members', label=> 'Members' }=> refhash(
    { ANY=> 'login', label=> 'Login'  }=> &yen;&$a->{project_name}::D::Members::login,
    { ANY=> 'logout' label=> 'Logout' }=> &yen;&$a->{project_name}::D::Members::logout,
    { POST=> 'login_check' }=> &yen;&$a->{project_name}::D::Members::login_check,
    qr/([a-z][a-z0-9_]+)/ => &yen;&$a->{project_name}::D::Members::orign_disp,
    _default => sub { \$_[0]->finished( FORBIDDEN ) },
    _begin => &yen;&$a->{project_name}::D::Members::begin,
    _end   => &yen;&$a->{project_name}::D::Members::end,
    ),

  { ANY=> 'bbs', label=> 'bulletin board' }=> refhash(
    { GET  => '_default' }=> &yen;&$a->{project_name}::D::BBS::article_view,
    { POST => 'edit' }=> &yen;&$a->{project_name}::D::BBS::article_edit,
    { POST => 'post' }=> &yen;&$a->{project_name}::D::BBS::article_post,
    _begin => &yen;&$a->{project_name}::D::Members::begin,
    _end   => &yen;&$a->{project_name}::D::Members::end,
    ),

  ));

#
# Only when using it with usual CGI.
# __PACKAGE__->mode_param('mode');
#

1;
END_OF_EXAMPLE
}

1;

__END__

=head1 NAME

Egg::Dispatch::Runmode - Standard subdispatch class for Egg.

=head1 SYNOPSIS

Dispatch file example.

  package MYPROJECT::D;
  use strict;
  use MYPROJECT::D::Help;
  use MYPROJECT::D::Root;
  
  __PACKAGE__->run_modes(
    _begin  => \&_begin,
    _default=> \&_default,
    _end    => \&_end,
    help    => {
      _begin => sub {},  # The operation of '_begin' of top-level is stopped.
      _end   => sub {},  # The operation of '_end' of top-level is stopped.
      faq    => \&MYPROJECT::D::Help::faq,
      },
    members => {
      _begin  => \&MYPROJECT::D::Root::_begin,
      _default=> \&MYPROJECT::D::Root::_default,
      _end    => \&MYPROJECT::D::Root::_end,
      profile => sub {
        my($self, $e)= @_;
        $e->template('profile.tt');
        },
      },
    );
  
  __PACKAGE__->default_mode('default');
  
  # Only when operating by CGI.
  __PACKAGE__->mod_param('mode');
  
  sub _default {
    ....
  }
  
  ... Additionally, necessary code.

=head1 DESCRIPTION

This dispatch distributes processing based on HASH set to run_modes.

* HASH of a multiple structure is supported.

* The final attainment point must become CODE reference.

* Dispatch is concretely defined by the following styles.

  package MYPROJECT::D;
  use strict;
  
  __PACKAGE__->run_modes(
    front_page => sub { ... },
    second_page=> {
      _default => sub { ... },
      sub_page => sub { ... },
      },
    ...
    );

This operates as follows.

  http://domain/front_page/
      =>  run_modes->{front_page} is called.
  
  http://domain/second_page/
      =>  run_modes->{second_page}{_default} is called.
  
  http://domain/second_page/sub_page/
      =>  run_modes->{second_page}{sub_page} is called.


If '_default' is put when the key done to agree to the hierarchy under the
 scanning is not found, it matches it to it.

* Please make the value of '_default' CODE reference.

  __PACKAGE__->run_modes(
    _default=> sub { ... default code },
    ...
    );

* The name of '_default' is revokable in the method of 'default_mode' beforehand.

  __PACKAGE__->default_mode('_index');


The processing after a prior thing like Catalyst is reproduced with
 '_begin' and '_end' key.

* Please make the value of '_begin' and '_end' CODE reference. 

  __PACKAGE__->run_modes(
    _begin=> sub { ... begin code },
    _end  => sub { ... end code   },
    ...
    );

* Please put '_begin' and '_end' that doesn't do anything when you want to
  stop this on the way.

HASH and the regular expression can be used for the key by using L<Tie::RefHash>
 as follows.
Because Tie::RefHash is conveniently used, the 'refhash' function is available.

  __PACKAGE__->run_modes( refhash(
      qr/member_([a-z0-9]{8})/=> refhash(
        qr/([A-Z])([0-9]{7})/ => \&MYPROJECT::D::Member::id,
        _default=> \&MYPROJECT::D::Member::default,
        ),
      login=> refhash(
        { POST=> 'check' }=> sub { check code ... },
        ),
      { GET=> 'help' }=> sub { help code ... },
      ),
    ),

* It is sure to match it before and behind the regular expression.
  '^' and '$' need not be put.
  The thing that should be assumed to be '.+abc.+' to make it match on the
  way is noted.

This operates as follows.

 http://domain/member_hoge/
     => &MYPROJECT::D::Member::default($dispath, $e, ['hoge']);
  
  http://domain/member_hoge/A1234567/
     => &MYPROJECT::D::Member::id($dispath, $e, ['A', '1234567']);

* As for a rear reference for the regular expression, only the thing matched
  at the end can be acquired.

* A rear reference is passed to the third argument by the ARRAY reference.
  This value can be acquired from $e->stash->{_action_match}.

When HASH is used for the key, REQUEST_METHOD is definable POST and GET

* Even if REQUEST_METHOD is specified over two or more hierarchies, it is not
  significant because it scans from a top hierarchy.

This is NG.

  { GET=> 'foo' }=> {
    { POST=> 'boo'  }=> sub { ... },
    { GET => 'hoge' }=> sub { ... },
    },

This doesn't match to all POST requests by a hierarchical scanning of foo.
Therefore, there is no thing that matches to foo->boo.
Moreover, it is not necessary to specify GET with hoge. This only becomes
 only inefficient.

When you want to make the POST request matched to boo.

  foo=> {
    { POST=> 'boo'  }=> sub { ... },
    { GET => 'hoge' }=> sub { ... },
    },

It is the above-mentioned and the mistake is not found in the syntax.
However, this doesn't operate normally.
I think that being passed to Tie::RefHash after the key to the second
 hierarchy progresses the character string is a problem.
Therefore, the key is not recognized as HASH.

Please use 'refhash' though it is troublesome for a moment.

  __PACKAGE__->run_modes=> (
    foo=> refhash(
      { POST=> 'boo' }=> sub { ... },
      { GET => 'hoge'  }=> sub { ... },
      hoge=> refhash(
        qr/regixp(...)/ => sub { ... },
        qr/id(...)/ => sub { ... },
        ),
      ),
    );


$e->snip can be usually used in mod_perl.
Please define the parameter name to reproduce snip beforehand by the use of
 'mode_param' method in usual CGI.

  __PACKAGE__->mode_param('m');
  __PACKAGE__->run_modes(
    hoge=> {
      foo=> {
        baa=> sub { ... },
        },
      },
    );

This operates as follows.

  http://domain/cgi-bin/trigger.cgi?m=hoge-foo-baa
      => run_modes->{hoge}{foo}{baa} is called.

=head1 METHODS

=head2 run_modes ( HASH )

It is a method for the prior definition of the operation mode.

The reference can be used for the key by using L<Tie::RefHash>.

  package MYPROJECT::D;
  use strict;
  
  __PACKAGE__->run_modes(
    .... HASH
    );

=head2 default_mode ([DEFAULT_NAME])  or  start_mode ([DEFAULT_NAME])

The name of the default key can be set.

  __PACKAGE__->default_mode('_index');

=head2 param_name ([REQUEST_NAME]);

The parameter name to acquire the mode when moving it with usual CGI is set.

  __PACKAGE__->param_name('mode');

=head2 mode_now ([NUMBER])

The character that converts an action now at the time of matched it when 
executing it for the modal parameter is returned.

* This is a method of utility for usual CGI.

When [NUMBER] is specified, the action to the upstairs layer of one is targeted. 

  action value : [qw{ foo hoge now }]
  
  dispath->mode_now()  =>  foo-hoge-now
  
  dispath->mode_now(1) =>  foo-hoge
  
  dispath->mode_now(2) =>  foo
  
  dispath->mode_now(3) =>  '' # Dead letter character.

=head2 label ([NUMBER])

The label of each action hierarchy is returned by the ARRAY reference.

If the label is defined in run_modes, the label is preserved.

  run_modes( refhash(
    { ANY=> 'members',  label=> 'For member' }=> refhash(
      { ANY=> 'edit',   label=> 'Member information edit' }=> sub { ... },
      { ANY=> 'service' label=> 'Service' }=> sub { ... },
      ),
  ) );

* Please set the action key by using 'ANY' to make it match POST and GET any.

This is useful for making Topic PATH.

  my $topic= qq{ <a href="/">HOME</a> };
  for (0..$#{$e->action}) {
  	my $path = join('/', @{$e->action}[0..$_]) || "";
  	my $label= $e->dispatch->label($_) || next;
  	$topic.= qq{ &gt; <a href="/$path">$label</a> };
  }

* When label is not defined, URI parts under the scanning are put as they are.
  The $e->escape_html passing might be safe.

=head2 page_title

Matched label or action key is returned.

Using it with the template is convenient.

  <title><% $e->escape_html($e->dispatch->page_title) %></title>

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

