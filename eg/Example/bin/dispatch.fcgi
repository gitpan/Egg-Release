#!/usr/local/bin/perl
package EggRelease::trigger;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
  $ENV{EXAMPLE_REQUEST_CLASS} ||= 'Egg::Request::FastCGI';
};
use Example;

Example->handler;
