package Egg::Release;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Release.pm 288 2007-03-16 08:30:59Z lushe $
#
use strict;
use warnings;

our $VERSION= '1.19';

1;

__END__

=head1 NAME

Egg::Release - WEB application framework release version.

=head1 DESCRIPTION

Egg imitated and developed Catalyst.

It is WEB application framework of a simple composition. 

It is possible to use it by replacing Model, View, Plugin, Engine, and
 Dispatch with the module of original development. 
It is a feature that the customizing degree of freedom is high. 

The treatment of Plugin looks like Catalyst well.

Version View to use HTML::Mason from Egg::Release-1.00 was enclosed.
I think that it can use a flexible, strong template environment.

It came to be able to set the label of each action by dispatch.
The label is convenient to make page title and Topic Path.

It corresponds to 'FastCGI' more than v1.04.
Please see the document of L<Egg::Request::FastCGI> about use.

=head1 TUTORIAL

It introduces the method of making an easy bulletin board here and it explains
 the use of Egg.

=head2 Obtaining of helper script.

First of all, the script to generate the project is obtained.

  perl -MEgg::Helper -e "Egg::Helper->out" > /path/to/egg_helper.pl
  
  chmod 755 /path/to/egg_helper.pl

The helper script was made by this.

* Putting on the directory that PATH passes is convenient for this helper script. 

=head2 Generation of project.

The file complete set that composes the project of Egg like the control and
 dispatch, etc. is generated.

  cd /home
  
  egg_helper.pl Project:TinyBBS

It is completion if displayed as completed.

TinyBBS can be done by this under the control of /home, and the configuration
 file complete set is made in that.

* The part of TinyBBS is a project name.
 The project name that wants to be made is specified in this part.
 The form of the project name is a thing according to the naming convention
  of the Perl module. However, ':' cannot be included.

* After it moves to the output destination in the example, it executes it.
 The output destination can be specified for '-o' option.

=head2 Confirmation of initial operation.

Whether a first of all existing project operates normally before editing the 
configuration file is confirmed.

  cd /home/TinyBBS/bin
  
  ./trigger.cgi

If it is this and the error is not output, it operates normally.

* If 'x-egg-project-error: true' is contained in the header, it is an error.
  Please straighten out that problem previously.

=head2 Setting of WEB server (Apache)

To demonstrate the highest performance when started from 'mod_perl', Egg is made.
If possible, please set 'mod_perl'.

* The setting example is for 'mod_perl2'.

  # If it is DSO support.
  LoadModule perl_module modules/mod_perl.so
  
  <VirtualHost domain.name:80>
    ServerName   domain.name
    DocumentRoot /home/TinyBBS/htdocs
  
    PerlOptions  +Parent
    PerlSwitches -I/home/TinyBBS/lib
    PerlModule   mod_perl2
    PerlModule   TinyBBS
    <LocationMatch "^/([A-Za-z0-9_\-\+\:\%/]+)?(\.html)?$">
    SetHandler          perl-script
    PerlResponseHandler TinyBBS
    </LocationMatch>
  
  </VirtualHost>

This setting has treated the one that matches to LocationMatch as dynamic
 contents. All things not matched are treated as static contents.

  Dynamic contents URL pattern:
    http://domain.name/
    http://domain.name/read
    http://domain.name/read.html
    etc.

  Static contents URL pattern:
    http://domain.name/index.htm
    http://domain.name/style.css
    http://domain.name/images/hoge.gif
    It is all URL in LocationMatch not matched ...

Please make it fit and change the use type to the pattern of LocationMatch at
the right time.

* Please move bin/trigger.cgi to the directory for CGI for usual CGI.

Please see the document of L<Egg::Dispatch::Runmode> in detail.

=head2 Preparation for data base.

The made table is such feeling.

 create table tinybbs (
   id          serial       primary key,
   post_date   timestamp    default now(),
   nickname    verchar(30)  not null,
   article     text         not null
   );
 grant all on tinybbs to dbuser;
 create index tinybbs_post_date on tinybbs(post_date);
 create index tinybbs_nickname  on tinybbs(nickname);

* It is for PostgreSQL in this tutorial.

* We will recommend L<Apache::DBI> to be used if possible. 

=head2 Edit of control.

lib/TinyBBS.pm is edited and the composition of Egg is decided. 

It is as follows in default. 

  package TinyBBS;
  use strict;
  use warnings;
  use Egg qw/-Debug/;
  use TinyBBS::config;
  
  our $VERSION= '0.01';
  
  __PACKAGE__->__egg_setup( TinyBBS::config->out );
  
  1;

'-Debug' of the module option is used to operate Egg by debug mode. 
Please delete this when this operating or invalidate it as '--Debug'.

'__egg_setup' is a trigger to execute the setup when Egg is started.

Then, a necessary plugin for the bulletin board is added.

  Filter
    ... The extra one is removed from the value of the request query.
  
  FormValidator::Simple
    ... The value of the request query is a normal value or it checks it.
      * Please download 'Egg::Plugin::FormValidator::Simple'
        from http://egg.bomcity.com/.
  
  FillInForm
    ... The value is buried under CGI form.

  DBI::Accessors::Extra
    ... The handling of DBI is made convenient a little.
  
  Redirect::Page
    ... The page with the message is displayed before it redirects it. 

And, the controller becomes the following.

  package TinyBBS;
  use strict;
  use warnings;
  use Egg qw/ -Debug
    Filter
    FormValidator::Simple
    FillInForm
    DBI::Accessors::Extra
    Redirect::Page
    /;
  use TinyBBS::config;
  
  our $VERSION= '0.01';
  
  __PACKAGE__->__egg_setup( TinyBBS::config->out );
  
  1;

=head2 Setting of configuration.

lib/TinyBBS/config.pm is edited.

The setting of the plugin etc. is included.

Setting of title first of all.

  title => 'Super-easy BBS',

MODEL is set.

  MODEL=> [
    [ 'DBI'=> {
          dsn=> 'dbi:Pg:dbname=dbname;host=localhost',
          user    => 'dbuser',
          password=> 'dbpassword',
          options => { AutoCommit=> 1, RaiseError=> 1 },
        },
      ],
    ],

HTML::Mason is used for the template.
The setting of HTML::Template is invalidated or it gives priority to
 HTML::Mason.

  VIEW=> [
    [ Mason=> {
        ...
        },
      ],

  #  [ Template=> {
  #      ...
  #      },
  #    ],

    ],

It is a setting of Egg::Plug-in::FormValidator::Simple.

  plugin_validator=> {
    messages=> {
      tinybbs=> {
        nickname=> {
          DEFAULT=> 'Please input the contributor name.',
          LENGTH => 'The contributor name is too long.',
          },
        article=> {
          DEFAULT=> 'Please input the content of the contribution.',
          LENGTH => 'The content of the contribution is too long.',
          },
        },
      },
    },

* The installation of FormValidator::Simple seems not to go well in Windows.
  This is caused by the installation's of 'DateTime::Format::Strptime' failing. 
  Perhaps, you may install it as it is because it is unquestionable in many cases.

* You may use FormValidator if anxious.
  In this case, Catalyst::Plugin::FormValidator can be used.
  Please edit the control as follows after it installs it.

  package MYPROJECT;
  use strict;
  use Egg qw{ +Catalyst::Plugin::FormValidator };

The plug-in of Catalyst can be misappropriated because of such feeling.

* Please note the place where + is described at the head. 

=head2 Edit of dispatch.

lib/TinyBBS/D.pm is edited and behavior to each request is decided. 

The setting concerning behavior gives and defines HASH in run_modes.

It is as follows in default.

  package MYPROJECT::D;
  use strict;
  use warnings;
  use Egg::Const;
  
  __PACKAGE__->run_modes(
  
    _default=> sub {
      my($dispatch, $e)= @_;
      require Egg::Helper::Project::BlankPage;
      $e->response->body( Egg::Helper::Project::BlankPage->out($e) );
      },
  
    );
  1;

When not agreeing to any key to run_modes, the '_default' key is matched.

BlankPage is set to '_default' key in initial.

The value of '_default' is CODE reference and should exist.
Moreover, the value of the key that the action finally reaches at last is CODE
 reference.

And, the object and the Egg object of Dispatch are passed for this CODE
 reference.

It makes it here to doing the content of '_default' as follows.

  _default=> sub {},

The code reference that did not do anything was defined.
The template is specified from the content of $e->action by processing View
 when doing so.

Therefore, this is the same as the setting of index.tt to the template.

If you want to return NOT_FOUND excluding top page.

  _default=> sub {
    my($dispat, $e)= @_;
    my $page= $e->action->[0] || return;
    return if $page eq $e->config->{template_default_name};
    $e->finished( NOT_FOUND );
    },

Or, '_begin' key is added.

  _begin=> sub {
    my($dispat, $e)= @_;
    my $page= $e->action->[0] || return;
    return if $page eq $e->config->{template_default_name};
    $e->finished( NOT_FOUND );
    },
  _default=> sub {},

* It is possible to process it to prior processing ( _begin ) after the
  fact ( _end ).

* The script that has a look at the content of the contribution will be
  buried under index.tt.

Next, it is a part where the contribution form and the content of the 
contribution are accepted.

  { POST=> 'posting', label=> 'Contribution form' }=> sub {},

The key is HASH.

When REQUEST_METHOD is only POST, this is matched.

And, the label key is a name related to the key.
This makes Topic PATH and is convenient.

Please see the document of L<Egg::Dispatch::Runmode> in detail.

It was possible to dispatch it by this in general. 
However, all the contribution articles will be displayed the way things are 
going by the request to '_default'.

Then, following Dipatti is added.

  page=> {
    { ANY=> '_default', label=> 'Super-easy BBS' }=> sub {
      $_[1]->template('index.tt');
      },
    { ANY=> qr/(\d+)/, label=> 'Super-easy BBS (NEXT)'}=> sub {
      my($dispat, $e, $parts)= @_;
      $e->stash->{page_no}= $parts->[0];
      $e->template('index.tt');
      },
    },

* To tell the truth, the hierarchy need not be especially deepened.
  It digs up the hierarchy here to exemplify it.

And, the key is set to ANY.
In this, GET and POST are to mean it is made to match.
To define label in the key, such writing is done without fail.

Moreover, the regular expression is used for the key.
It is given to the third argument to the CODE reference by the ARRAY reference
 if a rear reference is here.

This regular expression matches to the figure. 
And, the figure is put in $e->stash.
Index.tt obtains the page number referring to this $e->stash.

Dispatch that settles the above is as follows.
However, it doesn't go the way things are going well usually because the
 reference is used for the key to HASH.

Then, it is necessary to use Tie::RefHash.
It is possible to describe it easily by using this it is be able to use the
 refhash function.

  package MYPROJECT::D;
  use strict;
  use warnings;
  use Egg::Const;
  
  __PACKAGE__->run_modes( refhash(
  
    _default=> sub {},
    { POST=> 'posting', label=> 'Contribution form'  }=> sub {},
    page=> refhash(
      { ANY=> '_default', label=> 'Super-easy BBS' }=> sub {
        $_[1]->template('index.tt');
        },
      { ANY=> qr/(\d+)/, label=> 'Super-easy BBS (NEXT)'}=> sub {
        my($dispat, $e, $parts)= @_;
        $e->stash->{page_no}= $parts->[0];
        $e->template('index.tt');
        },
      ),
  
  ) );
  #
  # It is necessary only to use 'trigger.cgi'.
  # __PACKAGE__->mode_param('mode');
  #
  1;

* It is necessary to recurrently use Tie::RefHash when there is a hierarchy
  of HASH.

=head2 Making of template.

The following templates are made.

  ## comp/html-header
  <%init>
  my $page_title= $e->escape_html($e->dispatch->page_title);
  </%init>
  <html>
  <head>
  <title><% $page_title %></title>
  </head>
  <body>
  <h1><% $page_title %></h1>

  ## comp/html-footer
  </body>
  </html>

  ## root/index.tt
  <%init>
  my $date_field= 'post_date',
  my $name_field= 'nickname';
  my $post_field= 'article';
  my $page_no= $e->stash->{page_no} || 1;
  my $limit  = 20;
  my $offset = $limit* ($page_no- 1);
  my $msg_conv= sub {
    my $msg= shift || return "";
    $msg= $e->escape_html($msg);
    $msg=~s{\r?\n} [<br />]sg;
    $msg;
    };
  </%init>
  %
  <& /html-header &>
  <form method="POST" action="/posting">
  <input type="submit" value="The article is contributed." />
  </form>
  <hr size="1">
  %
  % if (my $array= $e->db->tinybbs->arrayref(
  %    [$date_field, $name_field, $post_field], 0,
  %    " order by post_date desc offset $offset limit $limit ")) {
  %
  %   for (@$array) {
    Contribution date : <% $_->{$date_field} %><br />
    Contributor : <% $e->escape_html($_->{$name_field}) %><br />
    Content of contribution:<br /><% $msg_conv->($_->{$post_field}) %>
    <hr size="1">
  %   }
  % } else {
    <h2>There is no contribution.</h2>
    <hr size="1">
  % }
  <& /html-footer &>

* If trigger.cgi is used, a value form action is always passing to trigger.cgi.
Moreover, the specification of the mode is needed.
The following hidden fields are added to the form to the contribution screen.

  <input type="hidden" name="mode" value="posting" />

  ## root/posting.tt
  % if ($a->{complete}) {
  %
  <% $e->redirect_page_html('/', 'The contribution was accepted.', alert=> 1 ) %>
  
  % } else {
  <& /html-header &>
  <h1>Contribution form</h1>
  <a href="/">It returns to the home.</a>
  % if ($e->form->has_error) {
    <div style="color:#F00; font-weight:bold; border-bottom:#000 solid 1px;">
    <% join '', map{"<li>$_</li>"}@{$e->form->messages('tinybbs')} %>
    </div>
  % }
  <hr size="1">
  <form method="POST" action="<% $e->response->path %>">
  Contributor name :
  <input type="text" name="<% $name_field %>" maxlength="30" size="30" />
  <ht size="1">
  Content of contribution: <textarea name="<% $post_field %>"></text>
  <ht size="1">
  <input type="submit">
  </form>
  <& /html-footer &>
  % }
  
  <%init>
  my $a= {};
  my $name_field= 'nickname';
  my $post_field= 'article';
  my $param= $e->request->params;
  my $display= sub {
  	$e->fillin_ok(1);
  	$param->{$name_field} ||= $e->request->cookie_value($post_field) || "";
    };
  my $posting= sub {
  	return 0 unless ($param->{$name_field} && $param->{$post_field});
  	$e->filter(
  	  $name_field=> [qw{j_trim strip_html j_strip}],
  	  $post_field=> [qw{j_trim escape_html crlf2}],
  	  );
  	my $form= $e->form(
  	  $name_field=> [qw{NOT_BLANK}, [qw{LENGTH 2 30}]],
  	  $post_field=> [qw{NOT_BLANK}, [qw{LENGTH 10 1000}]],
  	  );
  	$form->has_error and return 0;
  	$e->db->tinybbs->insert
  	  ([$name_field, $post_field], @{$param}{($name_field, $post_field)});
  	$e->response->cookie( $name_field=> { value=> $param->{$name_field} } );
  	$a->{complete}= 1;
    };
  $posting->() || $display->();
  </%init>

* If trigger.cgi is used, the following hidden field is necessary. 

  <input type="hidden" name="mode" value="<% $e->dispatch->mode_now %>" />

And, ignore_fields is set so that FillInForm should not touch this field. 

  plugin_fillinform=> {
    ignore_fields=> [qw{ mode }],
    },

=head2 Confirmation of the final operation.

It was possible to file it above in general. 
It actually requests from a browser and operation is confirmed. 

 http://domain.name/
 
If it bites and usual trigger.cgi is used
 
 Is it http://domain.name/trigger.cgi or http://domain.name/cgi-bin/trigger.cgi

* The reboot of the WEB server is needed for mod_perl.
  Perhaps, even if Apache::Reload is effective, it is necessary.

* The helper of Egg has not had the test server yet though this is very
  inconvenient. (^_^;

=head2 Summary.

I think that it was able to make an easy bulletin board by this. 
However, this is not a final product.
Please complete it by your hand adding the improvement a little more.

The use of Egg is such feeling.
The WEB application is constructed repeating the following work. 

  1.. The controller's edit.
  2.. Review of configuration.
  3.. Edit of dispatch.
  4.. Making or edit of template. 

And, if it wants to add the method newly, it is recommended to make the plugin.
Or, you may add the function to the controller, and it might be also good to
 make the succession module.
Anyway, please construct the application in remaining the freedom nature now it. 

Building in my making it is also good if it feels dissatisfied in the function
 of the engine and dispatch. Please try a powerful person by all means. 
Egg is offering the function and the helper to answer such needs. 

* The constructor of Egg only returns the object of the project.
  Therefore, it can be operated with triggers other than WEB such as cron.
  Therefore, because the configuration and the function can be shared, it
  is convenient.

=head2 Helper

Let's use the helper script and use Egg a little conveniently.

=over 4

=item * The model of the plugin module is generated.

The script that generates the skeleton of the plug-in module assumes the thing
 operated regardless to be a project. Please generate the script as follows.

  perl -MEgg::Helper::O::MakeMaker -e "Egg::Helper::O::MakeMaker->out" > /path/to/egg_makemaker.pl
  
  chmod 755 /path/to/egg_makemaker.pl

Putting on the place where PATH passed egg_makemaker.pl is convenient.

  egg_makemaker.pl Egg::Plugin::NewPlugin

When this is executed, the skeleton of the plug-in module is generated to the 
current directory.

* It is not already the one to generate only the plugin for Egg though it
  might be awareness. It can accomplish the substitute of h2xs -AX.

The made module is installed in a usual Perl similar module as follows. 

  perl Makefile.PL
  make
  make test
  make install

=item * The skeleton of the subdispatch is generated.

  bin/myproject_helper.pl D:Make [NEW_DISPATCH_NAME]

When this is executed, the skeleton of the subdispatch is generated to the 
subordinate of lib/MYPROJECT/D.

An easy test script generates it to it and t.

The generated dispatch is not read by the automatic operation.
It is necessary to edit the main dispatch.

  package MYPROJECT::D;
  use strict;
  use MYPROJECT::D::NewDispatch;
  
  __PACKAGE__->run_modes(
    ...
    new_action=> \&MYPROJECT::D::NewDispatch::default,
    );

=item * The configuration is made YAML.

  bin/myproject_helper.pl P:YAML

When this is executed, the configuration obtained with MYPROJECT::config->out
 is output to etc/MYPROJECT.yaml by the YAML form.

Output YAML changes as follows and uses the controller.

  package MYPROJECT;
  use strict;
  use warnings;
  use Egg qw/-Debug YAML/;
  
  our $VERSION= '0.01';
  
  my $config= __PACKAGE__->yaml_load('/path/to/MYPROJECT/etc/MYPROJECT.yaml');
  __PACKAGE__->__egg_setup( $config );

* MYPROJECT::config is not read.

* Embarrassing it because YAML is edited directly and it encounters the format 
  error are convenient.

=item * To use Ajax of the fashion on the street.

  bin/myproject_helper.pl P:Prototype

When this is executed, prototype.js is output to the subordinate of htdocs.

Please use output prototype.js reading from the HTML header.

Details are Prototype Javascript Library L<http://www.prototypejs.org/>.

=item * An original Egg engine is developed.

  bin/myproject_helper.pl E:Create [NEW_ENGIN_NAME]

When this is executed, [NEW_ENGIN_NAME].pm is generated by the subordinate
 of lib/MYPROJECT/E.

An original engine can be used by setting it to MYPROJECT_ENGINE_CLASS 
of engine_class of the configuration or the environment variable.

Necessary minimum method is described though the movement of the engine of 
the skeleton cannot be secured. The content of these methods is changed,
 and please newly add the method and develop a new engine.

Please try by all means though the hurdle might be a little high.

=back

=head1 REFERENCE

This reference is a list of the main method that seems often to be used.

Please refer to the document of each module for more detailed information.

=head2 my $e= PROJECT_NAME->new

The object for the project is received. 

package: L<Egg>.

=head2 $e->prepare_component

It is not necessary to call it from the WEB application.

Please call it when you use it from cron etc.

Prepare of the plugin and each component is settled and this is done.

package: L<Egg::Engine>.

=head2 Egg::Error->throw ([MESSAGE])

The error message with the debugging trace is output.

package: L<Egg::Exception>.

=head2 $e->debug

True is restored when operating by debug mode.

package: L<Egg>.

=head2 $e->flag

The state of the flag set by the module option of Egg is returned.

package: L<Egg>.

=head2 $e->stash

It is a preservation place of the data that wants to share by each component. 

package: L<Egg>.

=head2 $g->global

A global HASH reference is returned.

It is not initialized until the server is reactivated when the value is put.
The thing not anticipated that the content is changed in a word carelessly 
might happen.

* All keys to the defined value are handled as a capital letter.

* The defined value cannot already been redefined in a usual substitution type.

package: L<Egg::GlobalHash>.

=head2 $e->config

The HASH reference of the configuration is returned. 

package: L<Egg>.

=head2 $e->debug_out ([MESSAGE])

[MESSAGE] is output to STDERR when debug mode is effective.
If debug mode is invalid, nothing is done.

package: L<Egg>.

=head2 $e->log

The object for the log output is returned.

package: L<Egg::Debug::Log>.

=head2 $e->path ([CONFIG_NAME], [PATH])

PATH that ties to $e->config->{[CONFIG_NAME]} [PATH] is returned.

Please specify root, static, static_uri, etc, temp, cache, and lib, etc.
 for [CONFIG_NAME].

package: L<Egg>.

=head2 $e->action

The action that dispatch set is returned by the ARRAY reference.

package: L<Egg>.

=head2 my $req= $e->request  or $e->req

The object to process the request is restored.

package: L<Egg::Request>, L<Egg::Request::Apache>, L<Egg::Request::CGI>,

=head2 $req->params  or  $req->parameters

The request query is returned by the HASH reference. 

package: L<Egg::Request>,

=head2 $req->param ([FIELD_NAME])

The value of specified [FIELD_NAME] is returned.
It is the same as $req->params->{[FIELD_NAME]}.

package: L<Egg::Request>,

=head2 $req->cookies

Cookie received from the client is returned by the HASH reference.

package: L<Egg::Request>,

=head2 $req->cookie ([FIELD_NAME])

The character string of cookie of specified [FIELD_NAME] is returned.
It is the same as $req->cookies->{[FIELD_NAME]}.

package: L<Egg::Request>,

=head2 $req->cookie_value ([FIELD_NAME])

The value of cookie of specified [FIELD_NAME] is returned.
It is the same as $req->cookies->{[FIELD_NAME]}->value.

package: L<Egg::Request>,

=head2 $req->path

Passing the request place is returned.

package: L<Egg::Request>,

=head2 my $res= $e->response  or $e->res

The object to process the response is restored.

package: L<Egg::Response>,

=head2 $res->body ([RESPONSE_BODY])

The content output to the client is set.

The value is returned by the SCALAR reference.

package: L<Egg::Response>,

=head2 $res->cookie ( [FIELD_NAME] => [HASH] )

Cookie to set it in the client is set.

  $res->cookie( field_name=> {
    value=> 'field_value',
    ...
    ...
    } );

package: L<Egg::Response>, L<Egg::Response::TieCookie>

=head2 $res->redirect ( [LOCATION], [STATUS] )

The screen is forwarded to the place of [LOCATION].

[STATUS] is omissible.

package: L<Egg::Response>,

=head2 my $d= $e->dispatch  or $e->d

The dispatch object is restored.

When the Egg object is received from the constructor directly, it is not 
possible to use it until $e->prepare_component is called. 

package: L<Egg::Dispatch>, L<Egg::Dispatch::Runmode>,

=head2 $d->page_title

The value of label obtained by the matched action returns. 
There is a value of $e->snip of the object as it is when label is not obtained.

package: L<Egg::Dispatch::Runmode>,

=head2 $d->label ([NUMBER])

The list of label obtained by the matched action returns.

When [NUM] is specified, label of the place is restored. 

package: L<Egg::Dispatch::Runmode>,

=head2 $d->mode_now ([NUMBER])

The value for the parameter of a present action is returned.

The subtracted value returns when [NUMBER] is given.

* When mode_param is chiefly called, this value is needed.

package: L<Egg::Dispatch::Runmode>,

=head2 $e->filter ([FILTER_CONFIG])

 type: Plugin
 name: Filter  or  Filter::EUC_JP

The extra one is removed from the request query. 

package: L<Egg::Plugin::Filter>, L<Egg::Plugin::Filter::EUC_JP>,

=head2 my $form= $e->form ([VALIDATE_CONFIG])

 type: Plugin
 name: FormValidator::Simple

The validity of the request query is checked.

package: L<Egg::Plugin::FormValidator::Simple>,

=head2 my $upload= $e->request->upload ([UPLOAD_FIELD_NAME]);

 type: Plugin
 name: Upload

A form object corresponding to the file upload is acquired. 

package: L<Egg::Plugin::Upload>,

=head2 $e->fillin_ok ([BOOLEAN])

 type: Plugin
 name: FillInForm

A form burial by FillInForm is permitted before contents are output.

* Please note the competition with the plug-in considering it in reading 
order when using it together with the plug-in that converts the character-code
 of contents before it outputs it.

package: L<Egg::Plugin::FillInForm>,

=head2 $e->call_to ([DISPATCH_SHORT_NAME], [DEFAULT_METHOD])

 type: Plugin
 name: Dispatch::AnyCall

The method of the action that the dispatch of specification corresponds is 
presumed and called.

The method to specify by [DEFAULT_METHOD] or $e->config->{template_default_name}
 is called when failing in the call. 

package: L<Egg::Plugin::Dispatch::AnyCall>,

=head2 $e->yaml_load ([YAML_DATA])

 type: Plugin
 name: YAML

The result of doing passed [YAML_DATA] in Perth is returned.

package: L<Egg::Plugin::YAML>,

=head2 $e->dbh

 type: Plugin
 name: DBI::CommitOK

The data base steering wheel is returned.

package: L<Egg::Plugin::DBI::CommitOK>,

=head2 $e->redirect_page ([LOCATION], [MESSAGE], [OPTION])

 type: Plugin
 name: Redirect::Page

When the page is switched, an easy page is displayed. 

package: L<Egg::Plugin::Redirect::Page>,

=head2 $e->pod2html ([MODULE_NAME])

 type: Plugin
 name: Pod::HTML

The HTML source of the POD document of the Perl module demanded by [MODULE_NAME]
is returned.

package: L<Egg::Plugin::Pod::HTML>,

=head1 SEE ALSO

Egg,
L<Egg::Engine>,
L<Egg::Request>,
L<Egg::Response>,
L<Egg::Engine>,
L<Egg::Dispatch>,
L<Egg::Helper>,
L<Egg::Model>,
L<Egg::View>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
