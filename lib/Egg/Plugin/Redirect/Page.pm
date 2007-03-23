package Egg::Plugin::Redirect::Page;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Page.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.01';

sub setup {
	my($e)= @_;
	my $mconf= $e->config->{plugin_redirect} ||= {};
	my $conf = $mconf->{page} ||= {};
	$conf->{body_style}   ||= q/background:#FFEDBB; text-align:center;/;
	$conf->{div_style}    ||= q/background:#FFF7ED; padding:10px; margin:50px; font:normal 12px sans-serif; border:#D15C24 solid 3px; text-align:left;/;
	$conf->{h1_style}     ||= q/font:bold 20px sans-serif; margin:0px; margin-left:0px;/;
	$conf->{default_url}  ||= '/';
	$conf->{default_wait} ||= 0;
	$conf->{default_msg}  ||= 'Processing was completed.';
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{Egg::Response::redirect_page}= sub {
		my $res= shift;
		$res->e->redirect_page(@_);
	  };
	$e->next::method;
}
sub redirect_page_html {
	my $e= shift;
	my($res, $mconf)= ($e->response, $e->config);
	my $conf = $mconf->{plugin_redirect}{page};
	my $url  = shift || $conf->{default_url};
	my $msg  = shift || $conf->{default_msg};
	my $attr = $_[0] ? (ref($_[0]) ? $_[0]: {@_}): {};
	my $wait = defined($attr->{wait}) ? $attr->{wait}: $conf->{default_wait};
	my $popup= $attr->{alert} ? " window.onload= alert('$msg');": "";
	my $onload= $attr->{onload_func} ? qq{ onload="$attr->{onload_func}"}: "";
	my $body_style= $attr->{body_style} || $conf->{body_style};
	my $div_style = $attr->{div_style}  || $conf->{div_style};
	my $h1_style  = $attr->{h1_style}   || $conf->{h1_style};
	my $clang= $res->headers->{'content-language'} || 'en';
	my $ctype= $res->content_type($mconf->{content_type} || 'text/html');

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
sub redirect_page {
	my $e= shift;
	$e->response->status(200);
	$e->response->body( $e->redirect_page_html(@_) );
}

1;

__END__

=head1 NAME

Egg::Plugin::Redirect::Page - The page for for Egg ..redirecting.. is displayed.

=head1 SYNOPSIS

  package MYPROJECT;
  use strict;
  use Egg qw/Redirect::Page/;

Example of code.

  # It puts out and it informs of alert of the Java script before
  # the page is switched.
  $e->redirect_page('/complete/ok', 'Processing was completed.', alert=> 1 );

=head1 DESCRIPTION

This module sets the page and HTML for the switch is set in $e->response->body.

Set HTML can customize the design by the setting in the simple one 
including <meta http-equiv="refresh" ...>.

=head1 CONFIGURATION

This module is set by the page item of 'plugin_redirect'.

  __egg_setup(
    ...
    plugin_redirect=> {
      page=> {
        ..
        ...
        },
      },
    );

* 'Content-Language' and 'Content-Type' succeed the setting of the main.

=head2 body_style

Style setting of body.

Default is 'background:#FFEDBB; text-align:center;'.

=head2 div_style

Style setting of enclosure of the entire page.

Default is 'background:#FFF7ED; padding:10px; margin:50px; font:normal 12px sans-serif; border:#D15C24 solid 3px; text-align:left;'.

=head2 h1_style

Style setting in message part displayed on screen.

Default is 'font:bold 20px sans-serif; margin:0px; margin-left:0px;'.

=head2 default_url

Default when page switch previous URL is not specified. 

Default is '/'.

=head2 default_wait

Waiting time until page is switched.

Default is 0.

=head2 default_msg

Default when message displayed on screen is not passed.

Default is 'Processing was completed.'.

=head1 METHODS

=head2 redirect_page_html ([REDIRECT_URL], [MESSAGE], [OPTION]);

The HTML source for page switch is returned.

When [REDIRECT_URL] is omitted, a set value of default_url is used.

When [MESSAGE] is omitted, a set value of default_msg is used.

Some settings can be overwrited by [OPTION].

List of option.

  wait        ... Waiting time until page switching.
  alert       ... Alert of the Java script is displayed before the page is switched.
  onload_func ... Script to want to execute when page is displayed.
  body_style  ... Style of body. 
  div_style   ... Enclosure style on the entire page.
  h1_style    ... Style of message display part.

=head2 redirect_page  or  response->redirect_page ([REDIRECT_URL], [MESSAGE], [OPTION]);

The HTML source obtained from A is set in $e->response->body.
And, 200 is set in $e->response->status.

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
