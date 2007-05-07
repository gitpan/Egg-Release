
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $test = Egg::Helper::VirtualTest->new;

$test->disable_stderr;

my $proot= $test->project_root;
my @files= $test->yaml_load( join '', <DATA> );
$test->prepare(
  controller  => { egg_includes=> [qw/Upload/] },
  create_files=> \@files,
  );

SKIP: {
skip q{ WWW::Mechanize::CGI is not installed. } unless $test->mech_ok;

my($metch, $e);
eval{
	($metch, $e)= $test->mech_post('/', {
	  Content_Type => 'form-data',
	  Content => [
	    param1  => 'test',
	    upload1 => ["$proot/data/upload.txt" ],
	    upload2 => ["$proot/data/upload.html"],
	    ],
	  } );
};
skip q{ VirtualTest->mech_post method is invalid. } if $@;

ok $req= $e->request;
ok $req->is_post;
ok ! $req->is_get;
ok ! $req->is_head;
ok my $param1= $req->param('param1');
is $param1, 'test';

ok $upload= $req->upload('upload1');
isa_ok $upload, 'Egg::Plugin::Upload::CGI';
ok $upload->filename;
is $upload->filename,    'upload.txt';
is $upload->catfilename, 'upload.txt';
is $upload->type,        'text/plain';
isa_ok $upload->handle,  'Fh';
ok my $value= $test->fread($upload->tempname);
like $value, qr/^test123\n/s;

ok $upload= $req->upload('upload2');
isa_ok $upload, 'Egg::Plugin::Upload::CGI';
ok $upload->filename;
is $upload->filename,    'upload.html';
is $upload->catfilename, 'upload.html';
is $upload->type,        'text/html';
isa_ok $upload->handle,  'Fh';
ok $value= $test->fread($upload->tempname);
like $value, qr{^<html>.+</html>\n$}s;
like $value, qr{<body>test123</body>}s;

  };

__DATA__
---
filename: data/upload.txt
value: |
  test123
---
filename: data/upload.html
value: |
  <html>
  <body>test123</body>
  </html>
