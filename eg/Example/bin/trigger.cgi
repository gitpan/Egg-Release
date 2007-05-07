#!/usr/local/bin/perl
package Example::trigger;
# use FindBin;
# use lib "$FindBin::Bin/../lib";
use lib qw{ ./Example/lib };
use Example;

Example->handler;
