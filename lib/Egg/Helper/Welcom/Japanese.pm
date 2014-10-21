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
����ǤȤ��������ޤ���<br />
���β��̤�ɽ������Ƥ���Ȥ������ϡ����˵����Υ����С��� Egg - WEB application framework. �������ư���Ƥ��ޤ���
</div>
</div>
<h1>$title</h1>
<div id="project">$project</div>
<div id="content">
<p>�Ǥϡ����Υץ������Ȥ� dispatch ���ĥ���ޤ��礦��</p>
<p>��Ϥ�� controller ���ܤ��̤��Ʋ��������ե�����ξ��� [MYPROJECT]/lib/$project_name.pm �Ǥ���</p>
<pre>
 use Egg qw/-Debag Filter::EUC_JP/;
</pre>
<p>�ǥե���ȤǤ� Egg ���ɤ߹����Ϥ����ʤäƤ��ޤ���</p>
<p>-Debug �ϥǥХå��⡼�ɤ�ư���������̣���ޤ�����Ƭ�� '-' �ǻϤޤ��Τ����ƥե饰�Ȥ��ư����ޤ���</p>
<p>������ Filter::EUC_JP �ϥץ饰����� require ¾�ν����� Egg ����ư�ǹԤ��ޤ���
 �ץ饰����̾�� 'Egg::Plugin' �򽤾��������饹̾��ɾ������ޤ���
 �Ĥޤꤳ�ξ��� Egg::Plugin::Filter::EUC_JP ���ɤ߹��ޤ�ޤ���<br />
 �����ʤߤˤ��Υץ饰����ϥꥯ�����ȥ����꡼���ͤ������ʥǡ����ˤ������������Ԥ��٤Τ�ΤǤ���<br >
 \&nbsp; �ܤ����� Egg::Plugin::Filter::EUC_JP �Υɥ�����Ȥ�����������
</p>
<p>���� dispatch ���ܤ��̤��Ʋ��������ե�����ξ��� [MYPROJECT]/lib/$project_name/D.pm �Ǥ���</p>
<p>���� dispatch �� despacth_map �᥽�åɤ� URI�١����Υ�����������ȥ���δΤˤʤ�ޤ���</p>
<p>������ despacth_map �ǲ���Ԥ����ɤ�����ޤ�� [MYPROJECT]/lib/$project_name/D/Root.pm �����˽����ϰܤ�ޤ���
���줬 sub-despacth �ˤʤ�ޤ���������������Ϥ����ޤǥǥե���Ȥ�ư��Ǥ��ä� Root.pm �ʳ��� sub-despacth ��Ƥֻ������ޤ���
<pre>
 package $project_name\::D;
 use strict;
 
 sub despacth_map {
   my(\$dispat, \$e)= \@_;

   return qw{ Root };
   # ����� D::Root->_default ��ƤӽФ��ޤ���
   # ��˥����ȤΥ롼�ȥ���ƥ�Ĥ���Ϥ���٤˻Ȥ����ˤʤ�Ȼפ��ޤ���
   # ��������D::Root->_default ���ƤФ������ D::Root->_begin ����˸ƤФ졢������
   # D::Root->_default �ν�����λ��� D::Root->_end ���ƤФ�ޤ���

   return qw{ Root help };
   # ����� D::Root->help ��ƤӽФ��ޤ���

   return qw{ Hoge content };
   # ����� D::Hoge->content
   # ���ξ��� D::Hoge �������ȤʤꡢD::Hoge->_begin �θƤӽФ����ߤޤ������줬��
   # �줿���� D::Root->_begin ��ƤӽФ��ޤ����ǽ���ã���� D �Ǥ��������� D::_begin 
   # �ϲ���Ԥ��ޤ��󡣤��Τ褦�˵��������� _begin ��õ���褦��ư��򤷤ޤ���
   # ������ D::Hoge->_end ��Ʊ�ͤ��������Ԥ��ޤ���

   return qw{ Hoge::Foo admin }
   # �����ơ�����˿���
   # ���ε����� D::Hoge::Foo �Ǥ���
   # D::Hoge::Foo->_begin �� D::Hoge::->_begin �� D::Root->_bebin �ν���������ޤ���
   # ����D::Hoge::Foo->_begin �ƤӽФ������������� D::Hoge::->_begin �Ȥ���ʹߤϸƤФ�
   # �ޤ���

   return \$dispat->_template( 'boo.tmpl' );
   # ����ϥƥ�ץ졼�Ȥ������������Ǥ���
   # ���ξ��� D::Root �������ˤʤ�ޤ��������� D::Root->_default �ϸƤФ�ޤ���

   return qw{ Hoge::Foo 0 }, \$dispat->_template( 'boo.tmpl' );
   # ��������� D::Hoge::Foo �������ˤʤ�ޤ���
   # �裲�������̾�᥽�å�̾�Ǥ��������ξ��ϻ��ꤷ�Ƥ�̵��̣�ʤΤ� 0 �ˤ��Ƥ��ޤ���

   return \$e->finished( 404 );  # NOT_FOUND
   # ��λ�ȥ��ơ����������ɤ���𤷤ƽ�λ���ޤ���
   # _begin , _end �ʤɤθƤӽФ������ƥ���󥻥�ˤʤ�ޤ���

   return \$e->redirect( 'http://domainname/hooo.html' );
   # ����Σգң̤ز��̤�ž�����ޤ���
   # _begin �� _end �θƤӽФ���ͭ���Ǥ���

   return \$e->response->body( 'Hello world!' );
   # ����ƥ�Ĥ�ľ�ܽ��Ϥ��ޤ���

   \$e->response->body( 'Hello world!' );
   return qw{ Hoge::Foo };
   # ����ƥ�Ĥ�ľ�ܽ��Ϥ�����������ꤷ�ޤ���

 }
</pre>

<p>�����ޤȤ�Ƥ����ޤ���</p>
<p>�����ͤ�����Ѥߤξ��� dispatch �ο��񤤤��Ѥ�ޤ���</p>
<ul>
 <li><b>\$e->finished( response_code )</b><br />
  ���Ƥ� sub-dispatch ������ϥ���󥻥�ˤʤ�ޤ���
 </li>
 <li><b>\$e->response->body, \$e->template, \$e->response->redirect ...</b><br />
  _default ¾��sub-dispatch �᥽�åɤθƤӽФ��ϥ���󥻥뤷�ޤ��������� _begin �� _end �ϸƤФ�ޤ���
 </li>
 <li><b>\$e->response->body</b><br />
  �Ĥ��ǤǤ���... VIEW �ν����⥭��󥻥�ˤʤ�ޤ���
 </li>
</ul>

<p>������ sub-dispatch �Ǥ���</p>
<pre>
 package $project_name\::D::Root;
 use strict;
 use Egg::Const;   # �쥹�ݥ󥹥����ɤ�ͤ˸��䤹���񤯰٤�...
 
 # sub-dispatch �γƥ᥽�åɤ��Ϥ�����裱������ dispatch �Ȱ�äơ����֥�
 # �����ȤǤϤ���ޤ��󡣸ƤӽФ��줿���Τ��Υ��饹̾���Ϥ�ޤ���
 # dispatch ���֥������Ȥ�ɬ�פʤ� \$e->dispatch ���� \$e->d ��ȤäƲ�������
 
 sub _begin {
   my(\$class, \$e)= \@_;
   ....
   # �����ϻ����˹ԤäƤ������������Ǥ���
 }
 sub _default {
   my(\$class, \$e)= \@_;
   # sub-dispatch �ν������ؤɤξ��ƥ�ץ졼�Ȥ������������Ǵ�λ�����
   # �פ��ޤ��� VIEW �� HTML::Template �ʤɤΥѥ�᡼�����������ʤ�������
   # �Τ�Τ���Ѥ�����ϥѥ�᡼����������������Ԥ����ˤʤ�ޤ���
 
   my \$param= \$e->request->params;
   \$e->view->param( 'param1'=> \$param->{param1} );
     ����
   \$e->stash->{param1}= \$param->{param1};
 
   ........... �����ɬ�פʽ����������...
 
   return \$e->template( 'hoge.tmpl' );
   # dispatch �����Ǥϥƥ�ץ졼������� dispatch->_template ��Ȥ��ޤ���
   # �� sub-dispatch �Ǥ�ľ�ܥƥ�ץ졼�����������ɤ��Ǥ���
   # dispatch �����Ǥ�������ȥ��顼�ˤʤ�ޤ��Τ���դ��Ʋ�������
 
   return \$e->response->body( 'Hello world!' );
   # ľ�ܽ������Ƥ�������Ƥ⹽���ޤ���
 
   return \$e->response->redirect( 'http://domainname/hoge.html' );
   # ����Σգң̤ز��̤�ž�����ޤ���
 
   return \$e->finished( FORBIDDEN );
   # VIEW �˽������Ϥ��������ꤷ���쥹�ݥ󥹥����ɤǽ�����λ���ޤ���
 }
 sub banban {
   my(\$class, \$e)= \@_;
 
   # ����ϥ桼��������Υ᥽�åɡ�
   # dispatch ����� '_' ����Ϥޤ�̾���Υ᥽�åɤ���ꤷ�ƸƤֻ��ϤǤ���
   # ���褦�ˤʤäƤ��ޤ���
 
   return \$e->template( 'banban.tmpl' );
 }
 sub _end {
   my(\$class, \$e)= \@_;
   ....
   # �����ˤϻ��������...
 }
</pre>

<a href="$eggurl" target="_blank">
<img style="float:right;" src="/images/egg125x125.gif" width="125" height="125" alt="Egg - WEB application framework." /></a>

<p>�⤦���դ���Ƥ���Ȼפ��ޤ������ƥ�ץ졼�Ȥ������������ʤ� sub-dispatch �˽������Ϥ�ɬ�פϤ���ޤ���</p>
<p>³���� <a href="$eggurl">Egg-Rlease - WEB application framework �ۡ���ڡ���</a> ����������������</p>

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
