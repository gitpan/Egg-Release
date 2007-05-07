#!/usr/local/bin/perl
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
use lib qw( ../lib );
use Egg::Helper;
Egg::Helper->run( shift(@ARGV) );
