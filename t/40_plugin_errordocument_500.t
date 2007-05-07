
use Test::More  qw/no_plan/;
use Egg::Helper::VirtualTest;

my $test = Egg::Helper::VirtualTest->new;

$test->disable_stderr;

my @files    = $test->yaml_load(join '', <DATA>);
my $dispatch = shift @files;
$test->prepare({
  controller => {
    egg_includes => [qw/ ErrorDocument /],
    dispatch     => $dispatch->{value},
    },
  config=> {
    plugin_error_document=> {
      view_name => 'Template',
      template  => 'error_document.tt',
      },
    },
  create_files => \@files,
  });

SKIP: {
skip q{ WWW::Mechanize::CGI is not installed. } unless $test->mech_ok;

my $n;
eval{ $n= $test->mech_get('/') };
skip q{ VirtualTest->mech_get method is invalid. } if $@;

ok $body= $n->content;
like $body, qr{<html.*>.+?</html>}s;
like $body, qr{<title>500 +\- +Internal +Server +Error</title>}s;
like $body, qr{<h1>500 +\- +Internal +Server +Error</h1>}s;
like $body, qr{<div>SERVER_ERROR</div>}s;

  };

__DATA__
---
value: |
  _default=> sub { $_[1]->finished(500) },
---
filename: comp/error_document.tt
value: |
  <html>
  <head><title><TMPL_VAR NAME="page_title"></title></head>
  <body>
  <h1><TMPL_VAR NAME="page_title"></h1>
  <TMPL_IF NAME="status_404">
    <div>NOT_FOUND</div>
  <TMPL_ELSE><TMPL_IF NAME="status_403">
    <div>FORBIDDEN</div>
  <TMPL_ELSE>
    <div>SERVER_ERROR</div>
  </TMPL_IF></TMPL_IF>
  </body>
  </html>
