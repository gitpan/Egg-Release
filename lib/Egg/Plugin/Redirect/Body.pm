package Egg::Plugin::Redirect::Body;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Body.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Redirect::Body - Output of redirect screen etc.

=head1 SYNOPSIS

  use Egg qw/ Redirect::Body /;
  
  __PACKAGE__->egg_startup(
  
    plugin_redirect => {
      default_url  => '/',
      default_wait => 0,
      default_msg  => 'Processing was completed.',
      style => {
        body => ' ..... ',
        h1   => ' ..... ',
        div  => ' ..... ',
        },
      },
  
    );

  # redirect screen is output and processing is ended.
  $e->redirect_body('/hoge_page', 'complete ok.', alert => 1 );
  
  # The HTML source of redirect screen is acquired.
  my $html= $e->redirect_body_source('/hoge_page', 'complete ok.', alert => 1 );

=head1 DESCRIPTION

It is a plugin concerning an easy screen display at redirect.

=head1 CONFIGURATION

This plugin is setup by the item name 'plugin_redirect'.

=head2 default_url => [DEFAULT_URL]

URL when 'url' is unspecified.

Default is '/'.

=head2 default_wait => [WAIT_TIME]

redirect waiting time when 'wait' is unspecified.

Default is 0,

=head2 default_mag => [REDIRECT_MESSAGE]

Default when redirect message is unspecified.

Default is 'Processing was completed.'.

=head2 style => [HASH]

The screen style is set with HASH.

=over 4

=item * body => [BODY_STYLE]

The entire basic setting of screen.

 Default:
   background  : #FFEDBB;
   text-align  : center;

=item * h1 => [H1_STYLE]

Style of E<lt>h1E<gt>.

 Default:
   font        : bold 20px sans-serif;
   margin      : 0px;
   margin-left : 0px;'.

=item * div => [DIV_STYLE]

Style of E<lt>divE<gt>.

 Default:
   background  : #FFF7ED;
   padding     : 10px;
   margin      : 50px;
   font        : normal 12px sans-serif;
   border      : #D15C24 solid 3px;
   text-align  : left;

=back

=cut
use strict;
use warnings;

our $VERSION= '2.00';

{
	no warnings 'redefine';
	*Egg::Response::redirect_body= sub {
		my $res= shift;
		$res->e->redirect_body(@_);
	  };
  };

sub _setup {
	my($e)= @_;
	my $conf = $e->config->{plugin_redirect} ||= {};
	my $style= $conf->{style} ||= {};

	$conf->{default_url}  ||= '/';
	$conf->{default_wait} ||= 0;
	$conf->{default_msg}  ||= 'Processing was completed.';

	$style->{body}
	  ||= q{ background:#FFEDBB; text-align:center; };
	$style->{h1}
	  ||= q{ font:bold 20px sans-serif; margin:0px; margin-left:0px; };
	$style->{div}
	  ||= q{ background:#FFF7ED; padding:10px; margin:50px;}
	    . q{ font:normal 12px sans-serif; border:#D15C24 solid 3px;}
	    . q{ text-align:left; };

	$e->next::method;
}

=head1 METHODS

=head2 redirect_body_source ( [URL], [MESSAGE], [ARGS_HASH] )

The HTML source of redirect screen is returned.

When URL is omitted, a set value of 'default_url' is used.

When MESSAGE is omitted, a set value of 'default_msg' is used.

The following items can be passed to ARGS_HASH.

=over 4

=item * wait => [WAIT_TIME]

redirect waiting time. The value of default_wait is used when omitted.

  $e->redirect_body_source(0, 0, wait => 1 );

=item * alert => [BOOL]

The script concerning alert of the JAVA script is built in.

  $e->redirect_body_source(0, 0, alert => 1 );

=item * onload_func => [ONLOAD_FUNCTION]

onload is added to E<lt>bodyE<gt> when given.

  $e->redirect_body_source(0, 0, onload_func => 'onload_script()' );

=item * body_style => [STYLE]

The setting of plugin_redirect->{style}{body} is overwrited when given.

=item * h1_style => [STYLE]

The setting of plugin_redirect->{style}{h1} is overwrited when given.

=item * div_style => [STYLE]

The setting of plugin_redirect->{style}{div} is overwrited when given.

=back

=cut
sub redirect_body_source {
	my $e= shift;
	my($res, $mconf)= ($e->response, $e->config);
	my $conf  = $mconf->{plugin_redirect};
	my $style = $conf->{style};

	my $url   = shift || $conf->{default_url};
	my $msg   = shift || $conf->{default_msg};
	my $attr  = $_[0] ? (ref($_[0]) ? $_[0]: {@_}): {};
	my $wait  = defined($attr->{wait}) ? $attr->{wait}: $conf->{default_wait};
	my $popup = $attr->{alert} ? " window.onload= alert('$msg');": "";
	my $onload= $attr->{onload_func} ? qq{ onload="$attr->{onload_func}"}: "";

	my $body_style= $attr->{body_style} || $style->{body};
	my $div_style = $attr->{div_style}  || $style->{div};
	my $h1_style  = $attr->{h1_style}   || $style->{h1};

	my $clang = $res->content_language($mconf->{content_language} || 'en');
	my $ctype = $res->content_type($mconf->{content_type} || 'text/html');

	<<END_OF_HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="$clang">
<head>
<meta http-equiv="content-language" content="$clang" />
<meta http-equiv="Content-Type" content="$ctype" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta http-equiv="refresh" content="$wait;url=$url" />
<script type="text/javascript"><!-- //
$popup
// --></script>
<style type="text/css">
body { $body_style }
div  { $div_style }
h1   { $h1_style }
</style>
</head>
<body$onload>
<div>
<h1>$msg</h1>
<a href="$url">- Please click here when forwarding fails...</a>
</div>
</body>
</html>
END_OF_HTML

}

=head2 redirect_body ( [URL], [MESSAGE], [ARGS_HASH] )

$e-E<gt>response-E<gt>redirect is setup.
And, 'redirect_body_source' is set in $e-E<gt>response-E<gt>body.

The argument is passed to redirect_body_source as it is.

=cut
sub redirect_body {
	my $e  = shift;
	my $url= shift || $e->config->{plugin_redirect}{default_url};
	$e->response->redirect($url);
	$e->response->body( $e->redirect_body_source($url, @_) );
}

=head1 SEE ALSO

L<Egg::Response>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
