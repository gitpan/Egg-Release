
use Test::More tests => 60;
use Egg::Helper::VirtualTest;
use Egg::Plugin::Filter;

my $test= Egg::Helper::VirtualTest->new( prepare=> {
  controller => { egg_includes  => [qw/Filter/] },
  config     => { plugin_filter => { plugins=> 'Japanese::EUC' } },
  });

my $e= $test->egg_context;
ok my $filters= Egg::Plugin::Filter->_filters;

## warn q{ filter of Egg::Plugin::Filter::Japanese };
ok $filters->{h2z};
ok $filters->{j_trim};
ok $filters->{j_hold};
ok $filters->{j_strip};
ok $filters->{j_strip_j};

## warn q{ filter of Egg::Plugin::Filter };
ok $filters->{trim};
ok $filters->{hold};
ok $filters->{strip};
ok $filters->{hold_tab};
ok $filters->{strip_tab};
ok $filters->{hold_crlf};
ok $filters->{strip_crlf};
ok $filters->{crlf};
ok $filters->{hold_html};
ok $filters->{strip_html};
ok $filters->{escape_html};
ok $filters->{digit};
ok $filters->{alphanum};
ok $filters->{integer};
ok $filters->{pos_integer};
ok $filters->{neg_integer};
ok $filters->{decimal};
ok $filters->{pos_decimal};
ok $filters->{neg_decimal};
ok $filters->{dollars};
ok $filters->{lc};
ok $filters->{uc};
ok $filters->{ucfirst};
ok $filters->{phone};
ok $filters->{sql_wildcard};
ok $filters->{quotemeta};

my $data= {
  t_trim          => "   test  ",
  t_hold          => " t e s t ",
  t_strip         => "t\ne\ns\nt",
  t_hold_tab      => "t\te\ts\tt",
  t_strip_tab     => "t\te\ts\tt",
  t_hold_crlf     => "t\r\ne\r\ns\r\nt",
  t_strip_crlf    => "t\r\ne\r\ns\r\nt",
  t_crlf1         => "t\n\ne\n\ns\n\nt",
  t_crlf2         => "t\n\n\ne\n\n\ns\n\n\nt",
  t_crlf3         => "t\n\n\n\ne\n\n\n\ns\n\n\n\nt",
  t_hold_html     => "<font>t</font><font>e</font><font>s</font><font>t</font>",
  t_strip_html    => "<font>t</font><font>e</font><font>s</font><font>t</font>",
  t_escape_html   => "<font>test</font>",
  t_digit         => "1t2e3s4t5",
  t_alphanum      => "(test)[1234]",
  t_integer       => "12345",
  t_pos_integer   => "+12345",
  t_neg_integer   => "-12345",
  t_decimal       => "1.2345",
  t_pos_decimal   => "+1.2345",
  t_neg_decimal   => "-1.2345",
  t_dollars       => "123.45",
  t_lc            => "TEST",
  t_uc            => "test",
  t_ucfirst       => "test",
  t_phone         => "ABC123(DEF456)GHI789#01",
  t_sql_wildcard  => "*test*",
  t_quotemeta     => '@test@',
  };

my $param= $e->filter({
  t_trim          => [qw/trim/],
  t_hold          => [qw/hold/],
  t_strip         => [qw/strip/],
  t_hold_tab      => [qw/hold_tab/],
  t_strip_tab     => [qw/strip_tab/],
  t_hold_crlf     => [qw/hold_crlf/],
  t_strip_crlf    => [qw/strip_crlf/],
  t_crlf1         => [qw/crlf:1/],
  t_crlf2         => [qw/crlf:2/],
  t_crlf3         => [qw/crlf:3/],
  t_hold_html     => [qw/hold_html/],
  t_strip_html    => [qw/strip_html/],
  t_escape_html   => [qw/escape_html/],
  t_digit         => [qw/digit/],
  t_alphanum      => [qw/alphanum/],
  t_integer       => [qw/integer/],
  t_pos_integer   => [qw/pos_integer/],
  t_neg_integer   => [qw/neg_integer/],
  t_decimal       => [qw/decimal/],
  t_pos_decimal   => [qw/pos_decimal/],
  t_neg_decimal   => [qw/neg_decimal/],
  t_dollars       => [qw/dollars/],
  t_lc            => [qw/lc/],
  t_uc            => [qw/uc/],
  t_ucfirst       => [qw/ucfirst/],
  t_phone         => [qw/phone/],
  t_sql_wildcard  => [qw/sql_wildcard/],
  t_quotemeta     => [qw/quotemeta/],
  }, $data );

like $param->{t_trim},          qr/^test$/;
like $param->{t_hold},          qr/^test$/;
like $param->{t_strip},         qr/^t e s t$/;
like $param->{t_hold_tab},      qr/^test$/;
like $param->{t_strip_tab},     qr/^t e s t$/;
like $param->{t_hold_crlf},     qr/^test$/;
like $param->{t_strip_crlf},    qr/^t e s t$/;
like $param->{t_crlf1},         qr/^t\ne\ns\nt$/;
like $param->{t_crlf2},         qr/^t\n\ne\n\ns\n\nt$/;
like $param->{t_crlf3},         qr/^t\n\n\ne\n\n\ns\n\n\nt$/;
like $param->{t_hold_html},     qr/^test$/;
like $param->{t_strip_html},    qr/^ t  e  s  t $/;
like $param->{t_escape_html},   qr/^\&lt\;font\&gt\;test\&lt\;\/font\&gt\;$/;
like $param->{t_digit},         qr/^12345$/;
like $param->{t_alphanum},      qr/^test1234$/;
like $param->{t_integer},       qr/^12345$/;
like $param->{t_pos_integer},   qr/^\+12345$/;
like $param->{t_neg_integer},   qr/^\-12345$/;
like $param->{t_decimal},       qr/^1\.2345$/;
like $param->{t_pos_decimal},   qr/^\+1\.2345$/;
like $param->{t_neg_decimal},   qr/^\-1\.2345$/;
like $param->{t_dollars},       qr/^123\.45$/;
like $param->{t_lc},            qr/^test$/;
like $param->{t_uc},            qr/^TEST$/;
like $param->{t_ucfirst},       qr/^Test$/;
like $param->{t_phone},         qr/^123\(456\)789\#01$/;
like $param->{t_sql_wildcard},  qr/^\%test\%$/;
like $param->{t_quotemeta},     qr/^\\\@test\\\@$/;
