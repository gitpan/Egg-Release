package Egg::Helper::Script::YAML;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id$
#
use strict;
use warnings;
use Cwd;
use YAML;
use UNIVERSAL::require;
use FileHandle;

our $VERSION= '0.01';

sub generate {
	my($self)= @_;
	$self->{project} || die q/I want Project Name./;
	$self->{output}  ||= getcwd || die q/I want output destination./;
	-d $self->{output}
	  || die qq/The configuration directory is not found. : $self->{output}/;
	my $pkg= "$self->{project}::config";
	$pkg->require or die $@;
	my $yaml= "$self->{output}/$self->{project}.yaml";
	my $is_yaml= -f $yaml ? 0: 1;

	my $fh= FileHandle->new(">$yaml") || die \$!;
	print $fh "---\n";
	print $fh "--- $self->{project} Configuration. - $self->{project}.yaml\n";
	print $fh "---\n";
	print $fh "--- output date : ". (gmtime time). " (GMT)\n";
	print $fh "---\n";
	print $fh YAML::Dump( $pkg->out );
	$fh->close;

	print STDERR "... completed.\n\n";

	if ($is_yaml) {
		print STDERR <<END_OF_INFO;
* Edit '$self->{base}/lib/$self->{project}.pm' as follows.

- is old.
use $self->{project}::config;
__PACKAGE__->__config( $self->{project}::config->out );

+ is new.
use Egg qw/YAML/

my \$config= __PACKAGE__->yaml_load( '$yaml' );
__PACKAGE__->__config( \$config );

END_OF_INFO
	}
	return 1;
}

1;

__END__

=head1 NAME

Egg::Helper::Script::YAML - The configuration is converted into the YAML form.

=head1 SYNOPSIS

Refer to help.

 yaml_generator.pl -?

Only it usually executes even if nothing is done
 and '[MYPROJECT]/etc/[MYPROJECT].yaml' is output.

 [MYPROJECT]/bin/yaml_generator.pl

=head1 DESCRIPTION

When writing in YAML is not understood, it is convenient.

=head1 SEE ALSO

L<Egg::Helper::Script>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
