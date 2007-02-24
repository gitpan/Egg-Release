
use Test::More qw/no_plan/;
use Egg::Helper;

my $t= Egg::Helper->run('O:Test');

my @files= $t->yaml_load(join '', <DATA>);

$t->prepare(
  controller=> { egg=> [qw/Upload/] },
  create_files=> \@files,
  );

ok ( my $proot= $t->project_root );

my $e= $t->attach_request(
  qw( POST /upload ), {
  Content_Type=> 'form-data',
  Content=> [
    param1 => 'test',
    upload1=> ["$proot/data/upload.txt" ],
    upload2=> ["$proot/data/upload.html"],
    ],
  } );

if ($e) {
	ok( $value= $e->request->param('param1') );
	is $value, 'test';
	ok( $upload= $e->request->upload('upload1') );
	like $upload->filename, qr/upload\.txt$/;
	is $upload->catfilename, 'upload.txt';
	is $upload->type, 'text/plain';
	isa_ok $upload->handle, 'Fh';
	ok( $value= $t->fread($upload->tempname) );
	like $value, qr/^test123\n/s;
	ok( $upload= $e->request->upload('upload2') );
	like $upload->filename, qr/upload\.html$/;
	ok( $upload->catfilename eq 'upload.html' );
	is $upload->type, 'text/html';
	isa_ok $upload->handle, 'Fh';
	ok( $value= $t->fread($upload->tempname) );
	like $value, qr{^<html>.+</html>\n$}s;
	like $value, qr{<body>test123</body>}s;
}

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
