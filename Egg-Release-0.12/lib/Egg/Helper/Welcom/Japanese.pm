package Egg::Helper::Welcom::Japanese;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id$
#
use strict;
use base qw/Egg::Helper::Welcom/;

our $VERSION= '0.01';

sub content {
	my($class, $e)= @_;
	my $title= $class->title($e);
	my $project= $class->project($e);
	my $egg_label= $class->label($e);
	my $eggurl= $class->egg_url($e);
	my $footer= $class->footer($e);
	my $project_name= $e->namespace;
	my $style= $class->style($e);
	<<END_OF_CONTENT;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="ja">
<title>$title</title>
<head>
<meta http-equiv="Content-Language" content="ja" />
<meta http-equiv="Content-Type" content="text/html; charset=euc-jp" />
<style type="text/css">
$style
</style>
</head>
<body>
<div id="container">
<div id="banner">
<img src="/images/egg_logo.png" width="236" height="73" alt="Egg - WEB application framework." />
<div>
おめでとうございます。<br />
この画面が表示されているという事は、既に貴方のサーバーで Egg - WEB application framework. が正常に動いています。
</div>
</div>
<h1>$title</h1>
<div id="project">$project</div>
<div id="content">
<p>では、このプロジェクトの dispatch を拡張しましょう。</p>
<p>手始めに controller に目を通して下さい。ファイルの場所は [MYPROJECT]/lib/$project_name.pm です。</p>
<pre>
 use Egg qw/-Debag Filter::EUC_JP/;
</pre>
<p>デフォルトでは Egg を読み込む所はこうなっています。</p>
<p>-Debug はデバックモードで動作させる事を意味します。先頭が '-' で始まるものは全てフラグとして扱われます。</p>
<p>そして Filter::EUC_JP はプラグインで require 他の処理は Egg が自動で行います。
 プラグイン名は 'Egg::Plugin' を修飾したクラス名で評価されます。
 つまりこの場合は Egg::Plugin::Filter::EUC_JP が読み込まれます。<br />
 ※ちなみにこのプラグインはリクエストクエリーの値を正規なデータにする事前処理を行う為のものです。<br >
 \&nbsp; 詳しくは Egg::Plugin::Filter::EUC_JP のドキュメントをご覧下さい。
</p>
<p>次に dispatch に目を通して下さい。ファイルの場所は [MYPROJECT]/lib/$project_name/D.pm です。</p>
<p>この dispatch の despacth_map メソッドが URIベースのアクセスコントロールの肝になります。</p>
<p>そして despacth_map で何を行えば良いか決まれば [MYPROJECT]/lib/$project_name/D/Root.pm の方に処理は移ります。
これが sub-despacth になります。しかし、これはあくまでデフォルトの動作であって Root.pm 以外の sub-despacth を呼ぶ事も出来ます。
<pre>
 package $project_name\::D;
 use strict;
 
 sub despacth_map {
   my(\$dispat, \$e)= \@_;

   return qw{ Root };
   # これは D::Root->_default を呼び出します。
   # 主にサイトのルートコンテンツを出力する為に使う事になると思います。
   # ただし、D::Root->_default が呼ばれる前に D::Root->_begin が先に呼ばれ、そして
   # D::Root->_default の処理終了後に D::Root->_end が呼ばれます。

   return qw{ Root help };
   # これは D::Root->help を呼び出します。

   return qw{ Hoge content };
   # これは D::Hoge->content
   # この場合は D::Hoge が起点となり、D::Hoge->_begin の呼び出しを試みます。これが外
   # れた場合は D::Root->_begin を呼び出します。最終到達点は D ですが、この D::_begin 
   # は何も行いません。このように起点から順に _begin を探すような動作をします。
   # もちろん D::Hoge->_end も同様に走査が行われます。

   return qw{ Hoge::Foo admin }
   # そして、さらに深く
   # この起点は D::Hoge::Foo です。
   # D::Hoge::Foo->_begin → D::Hoge::->_begin → D::Root->_bebin の順で走査します。
   # 尚、D::Hoge::Foo->_begin 呼び出しが成功したら D::Hoge::->_begin とそれ以降は呼ばれ
   # ません。

   return \$dispat->_template( 'boo.tmpl' );
   # これはテンプレートを定義するだけです。
   # この場合は D::Root が起点になります。ただし D::Root->_default は呼ばれません。

   return qw{ Hoge::Foo 0 }, \$dispat->_template( 'boo.tmpl' );
   # こうすると D::Hoge::Foo が起点になります。
   # 第２引数は通常メソッド名ですが、この場合は指定しても無意味なので 0 にしています。

   return \$e->finished( 404 );  # NOT_FOUND
   # 終了とステータスコードを報告して終了します。
   # _begin , _end などの呼び出しは全てキャンセルになります。

   return \$e->redirect( 'http://domainname/hooo.html' );
   # 特定のＵＲＬへ画面を転送します。
   # _begin と _end の呼び出しは有効です。

   return \$e->response->body( 'Hello world!' );
   # コンテンツを直接出力します。

   \$e->response->body( 'Hello world!' );
   return qw{ Hoge::Foo };
   # コンテンツを直接出力し、起点も指定します。

 }
</pre>

<p>少しまとめておきます。</p>
<p>次の値が定義済みの場合は dispatch の振舞いが変ります。</p>
<ul>
 <li><b>\$e->finished( response_code )</b><br />
  全ての sub-dispatch コールはキャンセルになります。
 </li>
 <li><b>\$e->response->body, \$e->template, \$e->response->redirect ...</b><br />
  _default 他、sub-dispatch メソッドの呼び出しはキャンセルします。ただし _begin と _end は呼ばれます。
 </li>
 <li><b>\$e->response->body</b><br />
  ついでですが... VIEW の処理もキャンセルになります。
 </li>
</ul>

<p>そして sub-dispatch です。</p>
<pre>
 package $project_name\::D::Root;
 use strict;
 use Egg::Const;   # レスポンスコードを人に見やすく書く為に...
 
 # sub-dispatch の各メソッドに渡される第１引数は dispatch と違って、オブジ
 # ェクトではありません。呼び出された時のそのクラス名が渡ります。
 # dispatch オブジェクトが必要なら \$e->dispatch 又は \$e->d を使って下さい。
 
 sub _begin {
   my(\$class, \$e)= \@_;
   ....
   # ここは事前に行っておきたい処理です。
 }
 sub _default {
   my(\$class, \$e)= \@_;
   # sub-dispatch の処理は殆どの場合テンプレートを定義するだけで完了すると
   # 思いますが VIEW に HTML::Template などのパラメータしか扱えないタイプ
   # のものを使用する場合はパラメータを定義する処理を行う事になります。
 
   my \$param= \$e->request->params;
   \$e->view->param( 'param1'=> \$param->{param1} );
     又は
   \$e->stash->{param1}= \$param->{param1};
 
   ........... さらに必要な処理があれば...
 
   return \$e->template( 'hoge.tmpl' );
   # dispatch の方ではテンプレート定義に dispatch->_template を使いました
   # が sub-dispatch では直接テンプレート定義すれば良いです。
   # dispatch の方でこうするとエラーになりますので注意して下さい。
 
   return \$e->response->body( 'Hello world!' );
   # 直接出力内容を定義しても構いません。
 
   return \$e->response->redirect( 'http://domainname/hoge.html' );
   # 特定のＵＲＬへ画面を転送します。
 
   return \$e->finished( FORBIDDEN );
   # VIEW に処理を渡さず、指定したレスポンスコードで処理を終了します。
 }
 sub banban {
   my(\$class, \$e)= \@_;
 
   # これはユーザー定義のメソッド。
   # dispatch からは '_' から始まる名前のメソッドを指定して呼ぶ事はできな
   # いようになっています。
 
   return \$e->template( 'banban.tmpl' );
 }
 sub _end {
   my(\$class, \$e)= \@_;
   ....
   # ここには事後処理を...
 }
</pre>

<a href="$eggurl" target="_blank">
<img style="float:right;" src="/images/egg125x125.gif" width="125" height="125" alt="Egg - WEB application framework." /></a>

<p>もう気付かれていると思いますが、テンプレートを定義するだけなら sub-dispatch に処理を渡す必要はありません。</p>
<p>続きは <a href="$eggurl">Egg-Rlease - WEB application framework ホームページ</a> の方をご覧下さい。</p>

<div class="footbanner">
<a href="$eggurl" target="_blank">
<img src="/images/egg80x15.gif" width="80" height="15" alt="Egg - WEB application framework." /></a>
<a href="$eggurl" target="_blank">
<img src="/images/egg224x33.gif" width="224" height="33" alt="Egg - WEB application framework." /></a>
</div>

</div>
$footer
</div>
<br />
</body>
</html>
END_OF_CONTENT
}

1;

__END__

=head1 NAME

Egg::Helper::Welcom::Japanese - Japanese default page.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Helper::Script>,
L<Egg::Helper::Welcom>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
