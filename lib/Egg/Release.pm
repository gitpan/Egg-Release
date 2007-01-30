package Egg::Release;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Release.pm 156 2007-01-30 18:05:35Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.37';

=head1 NAME

Egg::Release - WEB application framework release.

=head1 NOTES

As for Egg, debugging is not completed in still a lot of parts.
It is evaluation version release at the present stage.

=head1 SYNOPSIS

First of all, please install Helper script.

The installer is in eg of the source decompression folder. or ../Egg/Helper (Perl Lib) internally.

  # perl ./egg/install-helper.pl [install path]
    or
  # perl /usr/lib/perl5/.../Egg/Helper/install-helper.pl [install path]

Please specify a suitable place such as /usr/bin for [install path].

  # create_project.pl MY_PROJECT [-o /output/path]

!! When -o is omitted, current dir is an output destination.

If B<trigger.cgi> operates by Console, it might be unquestionable. 

  # /output/path/MY_PROJECT/bin/trigger.cgi

B<Warning:> The output code of Default is EUC-JP.

Please make controller, dispatch, and template, etc. now.

=head2 Controller:

F</output/path/MY_PROJECT/lib/MY_PROJECT.pm>

=head2 Configuration:

F</output/path/MY_PROJECT/lib/MY_PROJECT/config.pm>

=head2 Dispatch:

F</output/path/MY_PROJECT/lib/MY_PROJECT/D.pm>

=head2 Sub-dispatch:

F</output/path/MY_PROJECT/lib/MY_PROJECT/D/Root.pm>

=head1 DESCRIPTION

Egg is MVC framework that builds an arbitrary module into Model, View,
 and Controller and makes the WEB application that can be done.

When approaching when the WEB application is constructed, the production
 work efficiency of the trouble eagle code can be improved if Egg is used.

=head2 Default of Model is DBI.

It is possible to use it by loading two or more Model at the same time. 

=head2 Default of View is HTML::Template.

View module can be easily switched by the setting. 

=head2 The code concerning some basic operation is written in Controller.

Plugin, encode another, special code is constructed in the controller.

=head2 Dispatch corresponding to Request URI can be constructed.

Please separate processing based on The fragment of URL is picked up from snip.

Or, according to the value acquired from param.

=head2 About WEB Applicaton that you constructed.

When I can get the report if it is generally accepted, it is glad.

I do so it is necessary to verify and to include it as a standard.

=head2 About the character-code union of the request query.

The treatment of the character-code in multi byte language range is important,
 and sometimes becomes a serious problem.

The default of Egg is processed with EUC though it should be assumed UTF8 for
 this matter usually recent.

Moreover, the union of character-codes has already been completed.

  my $param= $e->request->params;
  
  print $param->{any_param};  # This content is already EUC.

If it wants to do this processing with UTF8, 'character_in' of the configuration
 is merely assumed to be 'utf8'.

Controller's 'create_encode' method is only detached if the processing of the
 character-code union is unnecessary.

Please correct the controller as follows if you want to change this processing 
further.

  package [MYPROJECT];
  use strict;
  use Egg qw/-Debug/;
  use ANY_ENCODE;
  
  __PACKAGE__->__egg_setup;
  
  # Using $e->encode by this becomes possible.
  sub create_encode { ANY_ENCODE->new }
  
  # And, please prepare a suitable method of synchronization with 'character_in'.
  sub unicode_conv {
    my($e, $str)= @_;
    #
    # Here changes depending on the module for the character-code processing.
    #
    $e->encode->convert(\$str)->unicode;
  }
  sub euc_jp_conv {
    my($e, $str)= @_;
    $e->encode->convert(\$str)->euc_jp;
  }
  sub shift_jis_conv {
    my($e, $str)= @_;
    $e->encode->convert(\$str)->shift_jis;
  }
  
  #
  # Some plugins might have the direct call of encode in the character-code processing.
  # I think that they demand the methods such as set, a, and b perhaps.
  # Therefore, when this method is actually adopted, wrappar might be needed. 
  #

=head1 ENVIRONMENT

Egg evaluates several environment variables.

Please replace the part of B<[MYPROJECT]> with own project name and read.

=head2 [MYPROJECT]_DISPATCHER

The module of the name of 'B<Egg::D::$ENV{[MYPROJECT]_DISPATCHER}>' is used as Dispath.

=head2 [MYPROJECT]_CUSTOM_DISPATCHER

The module of B<[MYPROJECT]_CUSTOM_DISPATCHER> is used as Dispath.

=head2 [MYPROJECT]_UNLOAD_DISPATCHER

The module of B<[MYPROJECT]_CUSTOM_DISPATCHER> is used as Dispath.

However, require is not done.

However, C<dispatch-E<gt>_setup> is called.

=head2 [MYPROJECT]_MODEL

The module used as MODEL can be specified.
Please delimit it by B<','> or B<';'> when you specify the plural.

The MODEL setting of configuration is also effective.

=head2 [MYPROJECT]_VIEW

The module used as VIEW can be specified.

The VIEW setting of configuration becomes invalid.

=head2 [MYPROJECT]_REQUEST

An arbitrary module can be used for the Request processing.

However, because the handler is not generated, it is necessary to prepare it by oneself.

=head1 PLUGINS

Egg supports the plugin that can be used like Catalyst.

The specified plugin name is usually supplemented with B<'Egg::Plugin'> and evaluated.
For instance, it is developed with the name of B<'Filter'> when assuming B<'Egg::Plugin::Filter'>.

When the name that starts by + is specified, an untouched name is used.
For instance, B<'+MyProject::Filter'> is evaluated as it is as B<'MyProject::Filter'>.

  use Egg qw/-Debug Filter::EUC_JP +Catalyst::Plugin::FillinForm/;

=head2 Moreover, the following calls are supported to the plugin.

Please refer when you make the plugin by oneself.

=over 4

=item 1 $e-E<gt>setup

When starting, it is called.

=item 2 $e-E<gt>prepare

It is called because of the object generation preparation immediately before dispatch operates.

=item 3 $e-E<gt>action

It is called before VIEW outputs it after dispatch is evaluated.
However, if finished is true, it has already been canceled.

=item 4 $e-E<gt>finalize

It is called before contents are output after VIEW does output. 
In a word, it becomes the end of the plugin call.

=back

Please make the chance to pass processing to the following plug-in by beginning
 ending about the processing of the method of the above-mentioned B<NEXT.pm.>

  package Egg::Plugin::MyPlug;
  use strict;
  use base qw/Class::Data::Inheritable/;
  use NEXT;
  use ANY_MODULE;
  
  __PACKAGE__->mk_classdata( qw/myplug/ );
  
  sub prepare {
    my($e)= @_;
    $e->{myplug}= new ANY_MODULE;
    $e->NEXT::prepare;
  }
  
  #
  # The error occurs if Class::Accessor is used to make the accessor.
  #
  

=head2 Method of plugin

It is possible to call it if it is assumed B<$e-E<gt>method> because the method of the plugin 
is a succession relation to B<Egg>.

=head1 FLAGS

An arbitrary flag is set when Egg is read, and it can be referred to later.

* Control file of this.

  package [MYPROJECT];
  use strict;
  
  use Egg qw/-Debug -foo/;

* This is a code such as dispatch.

  if ($e->flag('foo')) {
    return TRUE;
  } else {
    return FALSE;
  }

=head2 Debug

Egg supports only place 'Debug' flag today.

The Debug flag can be referred to by C<$e-E<gt>debug>.

=head1 CONFIGURATION

=head2 root

B<Default:> [MYPROJECT]/root

It is the one used when Egg chiefly confirms the whereabouts of the template.
Please specify the root directory for the template that becomes a main.
It doesn't relate to the setting of VIEW.

=head2 static_root

B<Default:> [MYPROJECT]/htdocs

Please set the document route for static contents such as the image images and Style Sheets.
Place Egg today doesn't use this setting.

=head2 title

B<Default:> none.

Title of site.
Place Egg today doesn't use this setting.

=head2 accessor_names

B<Default:> none.

Please set the name of the accessor that wants to be made by the ARRAY reference.
It comes to be able to use the made accessor to put C<$e-E<gt>stash> in and out.

=head2 character_in

B<Default:> euc

Character-code used by internal processing.
'utf8', 'euc', and 'sjis' can usually be specified.
When create_encode method is customized, the code that can be specified is changed.

=head2 content_language

B<Default:> none.

When you want to include Content-Language in responce header.

=head2 content_type

B<Default:> text/html

Please set Content-Type output with the response header.
For instance, to include the character set, it is specified 'text/html; charset=euc-jp' etc.

=head2 default_template_extension

B<Default:> .tmpl

Please set the extension when the template name is generated from Dispatch with 
the automatic operation.

=head2 max_snip_deep

B<Default:> 5

It is an upper bound of the depth of the folder in the Path part of Request URL.

=head2 redirect_page

B<Default:> HASH reference.

It is a setting concerning the page displayed with redirect_page method of Egg::Response.

I<Each item of redirect_page>:

 body_style:    Style of body.
 div_style:     Style of the enclosure frame.
 h1_style:      Style of message display part.
 default_url:   Default at url unspecification.
 default_wait:  Default at wait unspecification.
 default_msg:   Default at message unspecification.

=head2 MODEL

It is a setting of the MODEL.

=head2 VIEW

It is a setting of the VIEW.

=head1 METHODS

It introduces only the method that seems to be used well here picking it up.

Please see the document of each module for details.

=head2 $e

is [MY_PROJECT] object.
B<Egg>, B<Engine::Engine>, and the B<plugin> have been succeeded to.

=head2 $e->namespace

The class name of e is returned.
In a word, it is the same as ref($e).

=head2 $e->config

The configuration is returned by the HASH reference. 

=head2 $e->stash

It is a preservation place to share data.
Familiar in Catalyst.

=head2 $e->flag([FLAG_NAME]);

Refer to the flag set to Egg.

=head2 $e->snip

The ARRAY reference into which the request passing is divided by/is returned.

http://dmainname/hoge/foo/ request for instance is developed as follows.

 $e->snip->[0] ... hoge
 $e->snip->[1] ... foo

In addition, http://dmainname/hoge/foo/banban.html is a long ages.

 $e->snip->[0] ... hoge
 $e->snip->[1] ... foo
 $e->snip->[2] ... banban.html

The last value becomes a file name at the request to a clear file.

Moreover, please process each value while doubting undef without fail.
The error occurs in strict environment if it doesn't do so.

 # This makes an error mostly.
 if ($e->snip->[1]=~/^hoge/) { .... }
 
 # it is safe.
 my $dir= $e->snip->[1] || return $e->finished( NOT_FOUND );
 if ($dir=~/^hoge/) { .... }
 
   or
 
 if ($e->snip->[1] && $e->snip->[1]=~/^hoge/) { ... }

=head2 $e->dispatch  or $e->d

Accessor to dispatch object.
However, because sub-dispatch calls class directly, it is not possible to call it 
from this accessor.

=head2 $e->request  or $e->req

Accessor to B<Egg::Request> object.

=over 4

=item * $e->request->param([KEY], [VALUE])

Refer to the value of the request query.
The value can be substituted by giving [VALUE].

=item * $e->request->params  or $e->request->parameters;

The mass of the request query is returned by the HASH reference.

=item * $e->request->cookie([KEY]);

Refer to Cookie of the specified key.
Please use value method when you take out the value that has processed the character-code.
Please use plain_value when you take out the value in which nothing is processed as it is.

 # The value that has processed the character-code is taken out.
 my $foo= $e->request->cookie('Foo');
 my $foo_value= $foo->value;

 # An untouched value is taken out.
 my $foo_value= $foo->plain_value;
   or
 my $foo_value= $foo->{value};

This can refer to cookie.
Please use B<$e-E<gt>response-E<gt>cookie> to set cookie.

=item * $e->request->cookies

The mass of the cookie is returned by the HASH reference.

=item * $e->request->remote_addr or $e->request->address

REMOTE_ADDR of the client is returned.

Egg cannot judge the proxy of the frontend.
This will return information wrong according to the environment.
Please use 'mod_rpaf' etc. when you use the proxy for the frontend.

=item * $e->request->host_name

The host name that the WEB application operates is returned.
Deleted what returns to the port number etc.

=item * $e->request->path

The request path is returned.
Without fail '/' enters for the head.
Please note a little difference from 'Catalyst'.

This is convenient to bury the action value under E<lt>formE<gt> of the template.

=back

=head2 $e->response or $e->res

Accessor to B<Egg::Response> object.

=over 4

=item * $e->response->content_type([CONTENT_TYPE]);

The output contents type is defined.
$e->config->{content_type} is used in default.

=item * $e->response->no_cache([1 or 0])

Charm to prevent a browser of client from caching it.

=item * $e->response->ok_cache([1 or 0])  or $e->set_cache([1 or 0])

Charm to make a browser of client cache it.

=item * $e->response->cookie([KEY], [HASH reference]);

Cookie is set in the client.
Please give the option to pass it to 'CGI::Cookie' by the HASH.
First- must omit the item of 'CGI::Cookie' option.

 $e->response->cookie(
   'foo'=> {
     value  => 'banban',
     expires=> '+1M',
     domain => 'domain-name',
     path   => '/hoge',
     secure => 0,
     }
   );

=item * $e->response->cookies

The mass of data for set-cookie is returned by the HASH reference.

 my $cookie= $e->response->cookies;
 $cookie->{foo}= {
   value=> 'banban',
   ...
   ...
   };

=item * $e->response->redirect([URL], [STATUS]);

Forward is done to specified URL.
The response status can be specified. Default is 302.

=item * $e->response->redirect_page([URL], [MESSAGE], [OPTION]);

When the screen is done in Forward, page contents are displayed once.
The value that is made to the option and done is the same as 'redirect_page' of configuration.

=item * $e->response->body([CONTENT]);  or $e->response->output([CONTENT]);

Contents that want to output are defined directly.
When this is set, the processing of the VIEW side is canceled.
This method maintains the value without fail by the SCALAR reference.

 $e->response->body( "Hello, world!" );
 
 my $body= $e->response->body;
 print $$body;

=back

=head2 $e->encode

The object made from create_encode method is returned.

If $e->encode is effective, the method for some character-code processing can be used.

$e->utf8_conv,  $e->euc_conv,  $e->sjis_conv

=head2 $e->model([MODEL NAME]);

The object of specified MODEL is returned.

=head2 $e->view;

The VIEW object is returned.

=over 4

=item * $e->view->param([KEY], [VALUE]);

When the value is passed to the template engine such as HTML::Template that 
evaluate param, it uses it.

=item * $e->view->params;

The HASH reference that $e->view->param has treated is returned.

=back

=head2 $e->debug;

* Whether it operates by debug mode is checked.

=head2 $e->template  and  $e->error;

It is an accessor to $e->stash.

 $e->template('template.tt');
 
 $e->error('error occurs.');

However, please use $e->dispatch->_template when you set the template from 'despatch_map'.

It is $e->template and there is usually no problem from Sub-dispatch.

 package [MYPROJECT]::D;
 
 sub dispatch_map {
   my($dispat, $e)= @_;
   if (.... ) {
 
     # The error occurs in this.
     return $e->template('index.tt');
 
     # If it is this, it is safe.
     return $dispat->_template('index.tt');
 
     # This is also safe.
     $e->template('index.tt');
     return 0;
 
   # In a word, after setting the template, $dispat->_template returns 0.
   }
 }

=head2 $e->finished([RESPONSE STATUS]);

It reports on the completion of processing.
Some processing is canceled if set in the first half of processing.
Please use the response status code when you set this.
Please set 200 when you complete processing by the success.
If it wants to cause the error, it is 500. And, 'Not Found' is 404. 
If 500 is given, the second argument is evaluated further as an error message,
 and it is written in the log. The default of the message is 'Internal Error'.

=head2 $e->escape_html([HTML_TEXT]);  or $e->encode_entities([HTML_TEXT]);

The HTML tag is invalidated.

=head2 $e->unescape_html([PLAIN_TEXT]);  or $e->decode_entities([PLAIN_TEXT]);

The HTML tag where it is escaped is made effective.

=head1 BUGS

When you find a bug, please email me (E<lt>mizunoE<64>bomcity.comE<gt>) with a light heart.

=head1 SEE ALSO

Egg,
L<Egg::Engine>,
L<Egg::Model>,
L<Egg::View>,
L<Egg::Request>,
L<Egg::Response>,
L<Egg::D::Stand>,
L<Egg::Debug::Base>,

=head1 THANKS

The code of Egg will partially refer to Catalyst.

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
