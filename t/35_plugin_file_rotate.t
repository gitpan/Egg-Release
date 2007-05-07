
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $v= Egg::Helper::VirtualTest->new;
my $g= $v->global;

SKIP: {
skip q{ Environment variable 'EGG_PLUGIN_ROTATE_OK' is not set. }
     if ($v->is_win32 and ! $ENV{EGG_PLUGIN_ROTATE_OK});

my $file= {
  filename => 'tmp/rotate.txt',
  value    => 'test',
  };

$v->prepare(
  controller   => { egg_includes=> [qw/ File::Rotate /] },
  create_files => [$file],
  );

my $fname= $file->{filename};
ok my $e= $v->egg_context;
ok $v->chdir($g->{project_root});
ok $e->rotate($fname);
ok $e->rotate_report;
ok $v->save_file($file);
ok $e->rotate($fname);
ok $v->save_file($file);
ok $e->rotate($fname);
ok $v->save_file($file);
ok $e->rotate($fname);
ok $v->save_file($file);
ok $e->rotate($fname);
ok -e "$fname.5";
is scalar(@{$e->rotate_report}), 5;

# reverse.
ok $e->rotate($fname, reverse => 1 );
ok $e->rotate($fname, reverse => 1 );
ok $e->rotate($fname, reverse => 1 );
ok $e->rotate($fname, reverse => 1 );
ok $e->rotate($fname, reverse => 1 );
ok $e->rotate($fname, reverse => 1 );
ok $e->rotate($fname, reverse => 1 );
ok -e $fname;
ok ! -e "$fname.1";

  };
