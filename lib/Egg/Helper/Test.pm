package Egg::Helper::Test;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Test.pm 129 2007-01-21 05:44:23Z lushe $
#
use strict;
use warnings;
use Cwd;
use File::Temp qw/tempdir/;
use base qw/Class::Accessor::Fast/;

our $VERSION= '0.02';

__PACKAGE__->mk_accessors( qw/current testname/ );

sub new {
	bless {
	  testname=> 'EggTest',
	  current => getcwd(),
	  }, shift;
}
sub temp {
	$_[0]->{temp} ||= tempdir( CLEANUP=> 1 );
	$_[0]->{temp};
}
sub file_open {
	my $self= shift;
	my $file= shift || return 0;
	FileHandle->new($file) || die "Error: $file - $!";
}
sub read_file {
	my $self= shift;
	my $fh= $self->file_open(@_);
	my $result= join '', $fh->getlines;
	$fh->close;
	$result || 0;
}

1;

__END__

=head1 NAME

Egg::Helper::Test - It helps the test program of the module.

=head1 SYNOPSIS

 use Test::More tests=> 7;
 use Egg::Helper::Test;
 
 my $test= Egg::Helper::Test->new;
 
 push @INC, $test->current;
 chdir($test->temp);
 
 .... ban, ban, ban
 
 chdir($test->current);
 pop @INC;

=head1 DESCRIPTION

When the test program is written, only small happiness might be able to be tasted.

=head1 METHODS

=head2 test->current

Current directory of the test execution is returned.

=head2 test->temp

Temp Path obtained from 'File::Temp' is returned.
After it processes it, Temp Path is automatically deleted.

=head2 test->read_file([File Path]);

The content is returned reading the specified file.
It is convenient for the correspondence check etc. of the content of writing.

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
