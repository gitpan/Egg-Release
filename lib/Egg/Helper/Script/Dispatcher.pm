package Egg::Helper::Script::Dispatcher;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Dispatcher.pm 62 2006-12-19 11:51:17Z lushe $
#
use strict;
use warnings;
use Cwd;
use FileHandle;
use File::Path;

our $VERSION= '0.02';

sub generate {
	my($self)= @_;

	$self->{project} || die q/I want Project Name./;
	$self->{version}= $self->{v} || '0.01';
	$self->{output} ||= getcwd || die q/I want output destination./;
	-d $self->{output}
	  || die qq{The configuration directory is not found.: $self->{output}};

	$self->setup_uname;
	my $basedir = "$self->{output}/lib/$self->{project}/D";
	my $packname= "$self->{project}::D";
	my(@dirs, $filename);
	$self->{d} || die q/I want the name of generated dispatch./;
	$self->{d}=~s{\.[^\.]+$} [];
	for (split /\:\:+/, $self->{d}) {
		if (/^[A-Za-z][A-Za-z0-9_]+$/) {
			$packname.= "::$_";
			push @dirs, $_;
		} else {
			die q/It is a package name of an illegal format./;
		}
	}
	$filename= pop(@dirs); $filename.= ".pm";
	$basedir.= '/'. (join '/', @dirs) if @dirs> 0;
	-f "$basedir/$filename" and die qq{$packname already exists.};
	-d $basedir || File::Path::mkpath($basedir, 0, 0755);

	# create dispatch.
	{
		my $doc_default= $self->document_default;
		my $value= <<END_OF_SCRIPT;
package $packname;
use strict;
use warnings;
use Egg::Const;

sub dispath_name {
	my(\$class, \$e, \$d)= \@_;

	# ... Let's write the code here.

	return \$e->finished( FORBIDDEN );
}

1;

__END__
$doc_default
END_OF_SCRIPT
		$self->output_file("$basedir/$filename", $value);
	  };

	my $test_ok= my $manifest_ok= 0;
	# create test.
	if (-d "$self->{output}/t") {
		my $test_name= 0;
		my $test_dir = "$self->{output}/t";
		for (grep /\.t$/, <$test_dir/*>) {
			my($num)= m{/(\d+)[^/]+$};
			$test_name= $num if ($num && $num> $test_name);
		}
		$test_name = sprintf "%02d", ++$test_name;
		$test_name.= "$packname.t";
		$test_name =~s{\:\:+} [-]g;
		my $value= <<END_OF_TEST;

use Test::More tests => 1;
BEGIN { use_ok('$packname') };

END_OF_TEST
		$self->output_file("$test_dir/$test_name", $value);
		$test_ok= 1;

		if (-f "$self->{output}/Makefile.PL") {
			my $current= getcwd();
			chdir($self->{output});
			eval {
				`perl Makefile.PL`;
				`make manifest`;
			  };
			$manifest_ok= 1 unless $@;
			chdir($current);
		}
	}

	print "Complete.\n";
	print "*warn: Test script was not generable.\n"
	  unless $test_ok;
	print "*warn: MANIFEST was not able to be checked.\n"
	  unless $manifest_ok;
}

1;

__END__

=head1 NAME

Egg::Helper::Script::Dispatcher - The skeleton of Dispatch is made.

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
