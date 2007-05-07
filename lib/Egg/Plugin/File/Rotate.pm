package Egg::Plugin::File::Rotate;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Rotate.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::File::Rotate - Plugin that does file rotation.

=head1 SYNOPSIS

  use Egg qw/ File::Rotate /;

  # The file made before is reproduced before the file is saved.
  
  if ( -e $file_path ) {
     $e->rotate($file_path, stock => 5 );
  }
  
  my $fh= FileHandle->new("> $file_path") || return do {
  
    # When the problem occurs, it returns it. 
  
    $e->rotate($file_path, reverse => 1 );
  
    die $!;
  
    };

=head1 DESCRIPTION

The number is allocated in an old file, and rotating operation is done.

=cut
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '2.00';

=head1 METHODS

=head2 rotate ( [TARGET_FILE_PATH], [ARGS_HASH] )

To TARGET_FILE_PATH. Rename is done by the file name that puts one.

If TARGET_FILE_PATH.1 already exists, the rotation processes generations of 
the number specified to make it to TARGET_FILE_PATH.2 for 'stock' of ARGS_HASH.

If reverse of ARGS_HASH is effective, opposite operation is done.

=cut
sub rotate {
	my $e    = shift;
	my $base = shift || croak q{ I want base filepath. };
	$e->rotate_report(0);
	my $attr = ref($_[0]) eq 'HASH' ? $_[0]: {@_};
	my $stock= $attr->{stock} || 5;
	   $stock< 3 and $stock= 3;
	my @loop = (1..$stock);
	my $renamecode= $attr->{reverse} ? sub {
		-e "$base$_[0]" || return 0;
		rename("$base$_[0]", "$base$_[1]");
		$e->rotate_report(" + rename : $base$_[0] -> $base$_[1]");
	  }: do {
		return do { $e->rotate_report("'$base' is not found."); 0 }
		      unless -e $base;
		sub {
			-e "$base$_[1]" || return 0;
			rename("$base$_[1]", "$base$_[0]");
			$e->rotate_report(" + rename : $base$_[1] -> $base$_[0]");
		};
	  };
	for my $num ($attr->{reverse} ? @loop: reverse(@loop)) {
		my $old_num= $num- 1;
		$renamecode->(".$num", ( $old_num< 1 ? "": ".$old_num" ));
	}
	return 1;
}

=head2 rotate_report

An easy report for the rotation to have succeeded is returned with ARRAY.

=cut
sub rotate_report {
	my $e= shift;
	if (@_) {
		if ($_[0]) {
			return $e->{rotate_report}
			  ? do { push @{$e->{rotate_report}}, $_[0] }
			  : do { $e->{rotate_report}= [$_[0]] };
		} else {
			return $e->{rotate_report}= 0;
		}
	} else {
		return $e->{rotate_report}
		   ? (wantarray ? @{$e->{rotate_report}}: $e->{rotate_report}): 0;
	}
}

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

1;
