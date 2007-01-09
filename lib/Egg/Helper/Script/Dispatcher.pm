package Egg::Helper::Script::Dispatcher;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Dispatcher.pm 93 2007-01-08 19:18:28Z lushe $
#
use strict;
use warnings;
use Cwd;
use Egg::Helper::Script;
use File::Basename;

our $VERSION= '1.00';

sub generate {
	my($self)= @_;
	$self->{project} || die q/I want Project Name./;
	$self->{version}= $self->{v} || '0.01';
	$self->{output} ||= Cwd::getcwd || die q/I want output destination./;
	($self->{output}!~m{/$self->{project}$}
	  || $self->{output}=~m{/lib/$self->{project}$})
	  and die qq{Please specify root dir of project at the output destination.};
	-d $self->{output}
	  || die qq{There is no directory : $self->{output}};
	-d "$self->{output}/t"
	  || die qq{There is no test directory : $self->{output}/t};
	$self->setup_uname;
	$self->{d} || die q/I want the name of generated dispatch./;
	$self->{d}=~s{\.[^\.]+$} [];
	$self->{base}= $self->{output};
	$self->{dispath}= "$self->{base}/lib";
	my @part= ($self->{project}, 'D');
	for (split /[\-\:\/]+/, $self->{d}) {
		if (/^[A-Za-z][A-Za-z0-9_]+$/) {
			push @part, $_;
		} else {
			die q/It is a package name of an illegal format./;
		}
	}
	$self->{name}= join '-' , @part;
	$self->{packname}= join '::', @part;
	my $help= Egg::Helper::Script->comp
	  ( { project => 'Orign' }, 'Egg::Helper::Script::Project' );
	$self->{dispath}.= "/". (join '/', @part). ".pm";
	-e $self->{dispath} and die qq/It already exists : $self->{dispath}/;
	my $rc= $help->rcparam;
	my $current= Cwd::getcwd();
	chdir($self->{base});
	my $report= "";
	eval {
		while (my($key, $value)= each %$self) {
			$rc->{$key}= $value unless ref($value);
		}
		$rc->{document}= \&Egg::Helper::Script::document_default;
		$rc->{number}= 0;
		my $testdir= "$rc->{base}/t";
		for (grep /\.t$/, <$testdir/*>) {
			my($num)= m{/(\d+)[^/]+$};
			$rc->{number}= $num
			  if ($num && $num<= 80 && $num> $rc->{number});
		}
		$rc->{number}= sprintf "%02d", ++$rc->{number};
		$help->output_files($rc, join '', <DATA>);
		if (File::Spec->isa('File::Spec::Unix')) {
			`make distclean`;
			system('perl Makefile.PL') and die $!;
			system('make manifest') and die $!;
			`make distclean`;
		} else {
			$report= <<REPORT;

!! Oneself must edit the MANIFEST !!
REPORT
		}
	  };
	chdir($current);
	if (my $err= $@) {
		print <<ERROR;
-- create error:
$err
-- 
ERROR
	} else {
		print <<SUCCESS;

... The generation of dispatch was completed.
$report

SUCCESS
	}
	return 1;
}

1;

=head1 NAME

Egg::Helper::Script::Dispatcher - The skeleton of Dispatch is made.

=head1 SYNOPSIS

 # cd /path/to/project_root
 # bin/create_dispath.pl -d [NEW_DISPATCH_NAME]
 ....
 ....
 
 ... The generation of dispatch was completed.
 
 # ls -la lib/project_name/D
 ...
 -rw-r--r--  1 user user ..... [NEW_DISPATCH_NAME].pm
 
 # ls -la t/
 ...
 -rw-r--r--  1 user user ..... NN_[NEW_DISPATCH_NAME].t

=head1 DESCRIPTION

MANIFEST is not renewed in OS other than UNIX system.
Please edit it sorry to trouble you, but by yourself.

=head1 SEE ALSO

L<Egg::Helper::Script>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
---
filename: <# dispath #>
filetype: module
value: |
  package <# packname #>;
  #
  # Copyright (C) <# headcopy #>, All Rights Reserved.
  # <# author #>
  #
  # $Id: Dispatcher.pm 93 2007-01-08 19:18:28Z lushe $
  #
  use strict;
  use warnings;
  use Egg::Const;
  
  sub dispath_name {
  	my($class, $e, $d)= @_;
  
  	# ... Let's write the code here.
  
  	return $e->finished( FORBIDDEN );
  }
  
  1;
  
  <# document #>
---
filename: t/<# number #>_<# name #>.t
value: |
  
  use Test::More tests => 1;
  BEGIN { use_ok('<# packname #>') };
  
