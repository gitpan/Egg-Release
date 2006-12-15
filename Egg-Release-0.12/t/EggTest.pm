package EggTest;
use strict;
use Egg qw/--Debug/;

our $VERSION= '0.01';

our %config= (
  root=> 'dummy',
  content_type=> 'text/html',
  MODEL=> [
    [ 'DBI'=> {
        dsn => 'none',
        user=> 'none',
        password=> 'none',
        },
      ],
    ],
  VIEW=> [
    [ 'Template'=> {
        path=> [qw/t/],
        },
      ],
    ],
  );

$ENV{EGGTEST_UNLOAD_DISPATCHER}= 'EggTest::Dispatch';

Egg->__egg_setup( \%config );

package EggTest::Dispatch;
use strict;
sub _setup { }

1;
