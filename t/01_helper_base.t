
use Test::More qw/no_plan/; 
use Egg::Helper;

eval{ Egg::Helper->run };
ok( $@ );
like $@, qr/I want mode/;
ok( my $t= Egg::Helper->run('O:Test') );
isa_ok $t, 'Egg::Helper::O::Test';
is $t->project_name, 'Other::Dummy';
ok( $t->create_project_root );
ok( my $project_root= $t->project_root );

if ($t->is_win32 && $project_root=~/\s/) {
	die (<<END_OF_ERROR);
I want you to set PATH that space character is not included in
 environment variable 'TMPDIR'.
END_OF_ERROR
}

ok( $t->project_name eq 'EggVirtual' );
is $t->path_to('test'), "$project_root/test";
ok( my $g= $t->global );
is $g->{perl_path}, $t->perl_path;
is $g->{start_dir}, $t->get_cwd;
is $g->{revision}, '$Id$';
ok( $t->data_default );
ok( $t->pod_text );
ok( $t->setup_document_code );
isa_ok $g->{document}, 'CODE';
isa_ok $g->{dist}, 'CODE';
like $g->{document}->($t), qr/.+\=head1 +NAME\s+.+/s;
like $g->{document}->($t), qr/.+\=head1 +SYNOPSIS\s+.+/s;
is $g->{dist}->($t, {}, "$project_root/lib/Test/Test.pm"), 'Test::Test';
ok( $t->chdir( $project_root, 1 ) );
is $project_root, $t->get_cwd;
ok( $t->chdir( $g->{start_dir} ) );
is $g->{start_dir}, $t->get_cwd;
ok( $t->remove_dir( $project_root ) );
ok( ! -e $project_root );
ok( my $file= "$project_root/test/test.txt" );
ok( $t->save_file({}, { filename=> $file, value=> 'test' }) );
ok( -e $file && -f _ );
ok( my $value= $t->read_file($file) );
like $value, qr/^test/;
ok( $t->check_module_name('Test-Test-Test') );
ok( $t->check_module_name('test::test::test') );
eval{ $t->check_module_name('_Test::_Test::_Test') };
ok( $@ );
eval{ $t->check_module_name('1Test::2Test::3Test') };
ok( $@ );
ok( my $testdir= "$g->{start_dir}/t" );
$testdir=~s{(/t)/t$} [$1];
ok( my $number= $t->get_testfile_new_number( $testdir ) );
ok( $t->setup_global_rc );
ok( my $script= $t->catch_stdout( sub { $t->out } ) );
like $$script, qr/^#\!$g->{perl_path}\n/;
like $$script, qr/use +Egg\:\:Helper\;\n/;
ok( my $help= $t->help_message('mode') );
