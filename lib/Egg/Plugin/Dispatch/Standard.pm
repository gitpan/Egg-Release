package Egg::Plugin::Dispatch::Standard;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Standard.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Dispatch::Standard - Dispatch of Egg standard.

=head1 SYNOPSIS

  use Egg qw/ Dispatch::Standard /;
  
  # If HASH is used for the key, the refhash function is used.
  __PACKAGE__->run_modes( refhash(
  
  # 'ANY' matches to the method of requesting all.
  # The value of label is used with page_title.
  { ANY => '_default', label => 'index page.' }=> sub {
    my($dispatch, $e)= @_;
    $e->template('document/default.tt');
    },
  
  # Empty CODE decides the template from the mode name that becomes a hit.
  # In this case, it is 'Help.tt'.
  help => sub { },
  
  # When the request method is only GET, 'GET' is matched.
  { GET => 'bbs_view', label => 'BBS' } => sub {
    my($dispatch, $e)= @_;
    .... bbs view code.
    },
  
  # When the request method is only POST, 'POST' is matched.
  { POST => 'bbs_post', label => 'BBS Contribution.' } => sub {
    my($dispatch, $e)= @_;
    .... bbs post code.
    },
  
  # 'A' is an alias of 'ANY'.
  { A => 'blog', label => 'My BLOG' }=>
  
    # The refhash function for remembrance' sake when you use HASH for the key.
    refhash(
  
    # Prior processing can be defined.
    _begin => sub {
      my($dispatch, $e)= @_;
      ... blog begin code.
      },
  
    # 'G' is an alias of 'GET'.
    # The regular expression can be used for the action. A rear reference is
    # the third argument that extends to CODE.
    { G => qr{^article_(\d{4}/\d{2}/\d{2})}, label => 'Article' } => sub {
      my($dispatch, $e, $parts)= @_;
      ... data search ( $parts->[0] ).
      },
  
    # 'P' is an alias of 'POST'.
    { 'P' => 'edit', label => 'BLOG Edit Form.' } => sub {
      my($dispatch, $e)= @_;
      ... edit code.
      },
  
    # Processing can be defined after the fact.
    _end => sub {
      my($dispatch, $e)= @_;
      ... blog begin code.
      },
  
    ),
  
    ) );

=head1 DESCRIPTION

It is Dispatch of the Egg standard.

* HASH is set from the controller to run_modes and Dispatch is defined.

* HASH of the layered structure is appreciable.

* The value of the point where the action the final reaches should be CODE.

* E::P::Dispatch::handler and the object of the project are passed to CODE.

* It matches in the retrieval hierarchy of the action and if '_default' key
  is found, it matches it to it.

* It corresponds to the key to the HASH form by using the refhash function.
  see L<Tie::RefHash>.

* Label is set, and the request method can be limited and it match it to the
  request by using the key to the HASH form.

* The regular expression can be used for the key.
  As a result, it is possible to correspond to a flexible request pattern.
  Moreover, it is passed to the third argument of CODE by the ARRAY reference
  if there is a rear reference.
  However, a rear reference can obtain only the one that matched to oneself.
  In a word, what matched by a shallow hierarchy cannot be referred to.

  qr{^baz_(.+)}=> { # <- This cannot be referred to.
     # It is OK if it pulls it out for oneself by using $e-E<gt>request-E<gt>path etc.
  
     qr{^boo_(.+)}=> sub {  # <- Naturally, this can be referred to.
        my($d, $e, $p)= @_;
        },
    },

* When '_begin' key is defined, prior is processed.

* It processes it after the fact when '_end' key is defined.

* It looks for the one of a shallower hierarchy when neither '_begin' nor '_end'
  are found from the hierarchy that becomes a hit.
  Please define empty CODE somewhere of the hierarchy when you want to make the
  search stopped on the way.

  hoge => {
     hoo => {
        baa => {
           match => sub {},
           },
        },
        # It stops here.
        _begin => sub {},
        _end   => sub {},
    },

=cut
use strict;
use warnings;
use Tie::RefHash;
use UNIVERSAL::require;
use base qw/Egg::Plugin::Dispatch/;

our $VERSION = '2.00';

=head1 EXPORT FUNCTION

It is a function compulsorily exported by the controller of the project.

=head2 refhash ( [HASH] )

Whenever the key to the HASH form is set to run_modes, it is made by way of
this function.

This function returns received HASH and after Tie is done by L<Tie::RefHash>,
the HASH is returned by the reference.

* Please it doesn't operate normally even if you pass HASH Rifaren to this
  function.  Please pass usual HASH.

   my $hashref = refhash (
     { A => '_default', label=> 'index page.' } => sub {},
     { A => 'help',     label=> 'help page.'  } => sub {},
     );

=cut
sub _setup {
	my($e)= @_;
	unless ( Tie::RefHash->require ) {
		warn q{ 'Tie::RefHash' is not installed. };
		return $e->next::method;
	}
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{"$e->{namespace}::refhash"}= sub {
		#
		# * Call it as a usual function.
		#   refhash( [ Normal HASH ] )
		#
		my %refhash;
		tie %refhash, 'Tie::RefHash', @_;
		\%refhash;
	  };
	$e->next::method;
}

=head1 METHODS

L<Egg::Plugin::Dispatch> has been succeeded to.
Please refer for that method.

=head2 dispatch

The handler object is returned.

=cut
sub dispatch {
	$_[0]->{Dispatch} ||= Egg::Plugin::Dispatch::Standard::handler->new(@_);
}

=head2 mode_param

see L<Egg::Plugin::Dispatch>.

=cut
{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	sub mode_param {
		my $class= shift;  return 0 if ref($class);
		my $pname= shift || croak(q{ I want param name. });
		my $uc_class= uc($class);
		*{"$class\::_get_mode"}= sub {
			my $snip= $ENV{"$uc_class\_REQUEST_PARTS"}
			       || $_[0]->request->param($pname)
			       || return [];
			$snip=~tr/\t\r\n//d; $snip=~s/ +//g;
			$snip ? [ split /[\/\:\-]+/, $snip ]: [];
		  };
		$class;
	}
  };

sub _run_modes_check {
	my($self, $hash, $myname)= @_;
	while (my($key, $value)= each %$hash) {
		if (! ref($key) and $key=~/^HASH\(0x[0-9a-f]+\)/) {
			warn
			  qq{ Please use the refhash function. '$myname' \n}
			. qq{ The key not recognized as HASH is included. };
		}
		if (ref($value) eq 'HASH') {
			my $name= ref($key) eq 'HASH' ? (
			     $key->{A} || $key->{ANY} || $key->{P} || $key->{POST}
			  || $key->{G} || $key->{GET} || $key->{LABEL} || 'none.'
			  ): $key;
			$self->_run_modes_check($value, $name);
		}
	}
	$hash;
}

package Egg::Plugin::Dispatch::Standard::handler;
use strict;
use base qw/Egg::Plugin::Dispatch::handler/;

__PACKAGE__->mk_accessors(qw/ _snip _backup_action /);

=head1 HANDLER METHODS

L<Egg::Plugin::Dispatch>::handler has been succeeded to.
Please refer for that method of the handler.

=cut

sub _initialize {
	my($self)= @_;
	$self->_snip( $self->e->_get_mode || [@{$self->e->snip}] );
	$self;
}

=head2 mode_now

The value in which the list of the matched action ties by '/' delimitation
is returned.

=cut
sub mode_now {
	my $self = shift;
	my $now  = $self->action;
	my $label= $self->label;
	my $num  = $#{$label}- (shift || 0);
	$num< 0 ? "": (join('/', @{$now}[0..$num]) || "");
}

=head2 label ( [NUMBER] )

The list of the matched action is returned by the ARRAY reference.

When the figure is given, the corresponding value is returned.

=cut
sub label {
	my $self= shift;
	return $self->{label} unless @_;
	$self->{label}->[$_[0]] || "";
}

sub _start {
	my($self)= @_;
	$self->_scan_mode( 0,
	  $self->run_modes,
	  $self->default_mode,
	  ($self->e->request->is_post || 0),
	  );
	my $begin= $self->_scan_mode_more || return 0;
	$begin->($self, $self->e);
	1;
}
sub _action {
	my($self)= @_;
	return 0 if $self->e->finished;
	my $action= $self->{__action_code}
	  || return $self->e->finished(404);  # NOT_FOUND.
	$self->_backup_action( $self->{__backup_action} );
	$action->[0]->($self, $self->e, ($action->[1] || []));
	1;
}
sub _finish {
	my($self)= @_;
	my $end= $self->{__end_code} || return 0;
	$end->($self, $self->e);
	1;
}
sub _scan_mode {
	my($self, $num, $runmode, $default, $is_post)= @_;
	my $snip  = $self->{_snip} || [];
	my $wanted= $snip->[$num]  || "\0";
	   $wanted=~s{\.[^\.]{1,4}$} [];
	unshift @{$self->{__parts}}, $runmode;
	my $d_code;
	for my $key (keys %$runmode) {
		my $value= $runmode->{$key} || next;
		my $page_title;
		if (ref($key) eq 'HASH') {
			my $temp=      ($key->{A} || $key->{ANY}) || do {
				$is_post ? ($key->{P} || $key->{POST} || next)
				         : ($key->{G} || $key->{GET}  || next);
			  };
			$page_title= $key->{label} || $wanted;
			$key= $temp;
		}
		if (my @piece= $wanted=~m{^$key$}) {
			$page_title ||= $wanted;
			push @{$self->{label}}, $page_title;
			if (ref($value) eq 'HASH') {
				$self->_scan_mode(($num+ 1), $value, $default, $is_post)
				   and return 1;
			} else {
				next if $wanted=~/^_/;
				$self->page_title($page_title);
				$self->action([@{$snip}[0..($num- 1)], $wanted]);
				$self->stash->{_action_match}= \@piece;
				$self->{__action_code}= [$value, \@piece];
				return 1;
			}
		} elsif ($key eq $default) {
			$d_code= [$value, $page_title];
		}
	}
	return 0 unless $d_code;
	$self->page_title( $d_code->[1]
	  || $self->label->[$#{$self->{label}}]
	  || $self->config->{title}
	  || $self->default_name
	  );
	$self->action([@{$snip}[0..($num- 1)], $self->default_name]);
	$self->{__action_code}= [$d_code->[0]];
	$self->{__backup_action}= $wanted;
	1;
}
sub _scan_mode_more {
	my($self)= @_;
	my $begin_code;
	for (@{$self->{__parts}}) {
		if (! $begin_code and (my $begin= $_->{_begin})) {
			$begin_code= $begin;
			last if $self->{__end_code};
			$self->{__end_code}= $_->{_end} || next;
		} elsif (! $self->{__end_code} and (my $end= $_->{_end})) {
			$self->{__end_code}= $end;
		}
		last if ($begin_code and $self->{__end_code});
	}
	$begin_code || 0;
}
sub _example_code {
	my($self)= @_;
	my $a= { project_name=> $self->e->namespace };

	<<END_OF_EXAMPLE;
#
# Example of controller and dispatch.
#
package $a->{project_name};
use strict;
use Egg qw/ -Debug
  ConfigLoader
  Dispatch::Standard
  Debugging
  Log /;
use Egg::Const;

__PACKAGE__->egg_startup;

__PACKAGE__->run_modes( refhash (
  
  # 'ANY' matches to the method of requesting all.
  # The value of label is used with page_title.
  { ANY => '_default', label => 'index page.' }=> sub {
    my(\$dispatch, \$e)= \@_;
    \$e->template('document/default.tt');
    },
  
  # Empty CODE decides the template from the mode name that becomes a hit.
  # In this case, it is 'Help.tt'.
  help => sub { },
  
  # When the request method is only GET, 'GET' is matched.
  { GET => 'bbs_view', label => 'BBS' } => sub {
    my(\$dispatch, \$e)= \@_;
    .... bbs view code.
    },
  
  # When the request method is only POST, 'POST' is matched.
  { POST => 'bbs_post', label => 'BBS Contribution.' } => sub {
    my(\$dispatch, \$e)= \@_;
    .... bbs post code.
    },
  
  # 'A' is an alias of 'ANY'.
  { A => 'blog', label => 'My BLOG' }=>
  
    # The refhash function for remembrance' sake when you use HASH for the key.
    refhash (
  
    # Prior processing can be defined.
    _begin => sub {
      my(\$dispatch, \$e)= \@_;
      ... blog begin code.
      },
  
    # 'G' is an alias of 'GET'.
    # The regular expression can be used for the action. A rear reference is
    # the third argument that extends to CODE.
    { G => qr{^article_(&yen;d{4}/&yen;d{2}/&yen;d{2})}, label => 'Article' } => sub {
      my(\$dispatch, \$e, \$parts)= \@_;
      ... data search ( \$parts->[0] ).
      },
  
    # 'P' is an alias of 'POST'.
    { 'P' => 'edit', label => 'BLOG Edit Form.' } => sub {
      my(\$dispatch, \$e)= \@_;
      ... edit code.
      },
  
    # Processing can be defined after the fact.
    _end => sub {
      my(\$dispatch, \$e)= \@_;
      ... blog begin code.
      },
  
    ),
  
  ) );

#
# Only when using it with usual CGI.
# __PACKAGE__->mode_param('mode');
#

1;
END_OF_EXAMPLE
}

=head1 SEE ALSO

L<Egg::Plugin::Dispatch>,
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
