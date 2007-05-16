package Egg::Release;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Release.pm 150 2007-05-14 16:15:20Z lushe $
#

=head1 NAME

Egg::Release - Version of Egg WEB Application Framework.

=cut
use strict;
use warnings;

our $VERSION = '2.06';
our $DISTURL = 'http://egg.bomcity.com/';

=head1 DESCRIPTION

'Egg' is MVC framework that is influenced from 'Catalyst' and developed.

It consists of a simple module composition.
and the residing memory is comparatively few and operates at high speed, too.

=head2 Model

L<Egg::Model::DBI> is attached by the standard.

Because L<Egg::Model::DBI> is registered in CPAN, we am separately used 
properly by the favorite.

=head2 View

L<Egg::View::Template> and L<Egg::View::Mason> is attached by the
standard. L<Egg::View::Template> is loaded in default.

Moreover, L<Egg::View::TT> is registered in CPAN, and use it by the favorite 
separately, please.

=head2 Controller

It generates it with helper script (L<Egg::Helper>).

B<Configuration> and B<Dispatch> is included in the controller.

=over 4

=item * Configuration

It is loaded by L<Egg::Plugin::ConfigLoader> in default.

=item * Dispatch

L<Egg::Plugin::Dispatch::Standard > is used by the standard.
L<Egg::Plugin::Dispatch::Fast > that operates at high speed or more can be 
selected, too.

=back

=head2 Request

Either of L<Egg::Request::Apache>::* or L<Egg::Request::CGI> or L<Egg::Request::FastCGI>
 is loaded judging the environment.

=head2 Response

L<Egg::Response> is used fixing. 

Moreover, all enhanced features rely on B<Plugin>.

Please refer to the document of the module of the object for details or more 
for each part.

=head1 PROJECT

Egg constructs the application in each project generated with L<Egg::Helper>.

  % perl egg_helper.pl Project NewProject

The helper script generates the project file with the following compositions.

=head2 PROJECT ROOT

The helper script makes the root directory of the project for a suitable place.
And, all configuration files are generated to the directory.

=head2 SCRIPT FILE

Some following scripts concerning the project. It is generated to '/bin'.

=over 4

=item * [PROJECT_NAME]_helper.pl

Helper script only for project.

=item * [PROJECT_NAME]_tester.pl

Test script only for project.
The operational condition of the project can be checked by requesting WEB virtual.

=item * trigger.cgi

Script that becomes trigger when operating as usual CGI.
When managing it by this, it moves to an appropriate place and WEB is requested
to this script.

=item * dispatch.fcgi

Script used when operating with FastCGI.

=back

=head2 Static contents

The banner image etc. of some Egg are generated to ./htdocs as static contents.

=head2 Library

The controller and the configuration for the project are generated to ./lib.

=head2 Directory

Additionally, the following directories are generated according to the usage.

=over 4

=item * cache

Empty directory for file cash.
Please give the proper permission when you use it.

=item * root

Preservation place of template.

=item * comp

Preservation place of template only for include.

=item * etc

Other configuration file depositories etc.

=item * tmp

Temporary work directory.
Please give the proper permission when you use it.

=item * t

Test file depository when project complete set is managed as Perl module.

=back

=head1 CONTROLLER

The controller of the project contains processing importance the application
is composed, and the following.

=over 4

=item * Loading of Egg

Egg is read with use and the plugin and the flag that wants to load it by the
argument are passed.

  use Egg qw/
    -Debug
    ConfigLoader
    Encode
    Upload
    Tools
    Dispatch::Standard
    Debugging
    Log
    FormValidator::Simple
    ErrorDocument
    DBI::Transaction
    +MyApp::Plugin
    /;

Because the method such as 'dispatch' and 'debug' and 'log' that Egg demands
is included as for 'Dispatch::*' and 'Debugging' and 'Log', it is necessary to
load it.

In addition, please refer to the document of L<Egg> for details.

=item * Initialization of Egg.

The configuration of an appropriate place is loaded by ConfigLoader in default.
Please refer to the document of L<Egg::Plugin::ConfigLoader> for details.

However, if it is not a platform where the perpetuity objects such as mod_perl
and FastCGI are treated, it always costs the behavior cost in initial operation.
To evade this, the configuration is passed directly to 'egg_startup'.

  __PACKAGE__->egg_startup({
    title => 'project_name',
    .....
    ...
    .
    });

Please refer to the document of L<Egg> for a set item of Egg.

=item * Dispatch ‚ÌÝ’è

The setting for loaded Dispatch is set up by 'run_modes'.

  __PACKAGE__->run_modes(
    .....
    ...
    .
    );

Please refer to the document of L<Egg::Plugin::Dispatch::Standard> and
L<Egg::Plugin::Dispatch::Fast> for details for the setting method.

=back

Additionally, Egg does a little tricky processing that adds the plugin and
oneself to controller's @ISA.
Therefore, the method of the addition to the controller is given to priority
more than any module included in controller's @ISA.

$e-E<gt>next::method is used to process it of returning the method of other 
modules to former processing after override is done as a controller.

  sub overwrite_method {
     my($e)= @_;
     .......
     ....
     ..
     $e->next::method;
  }

=head1 PLUGINS

It is the main list of the plug-in for Egg.
* The one other than the standard are included.

=head2 Blosxom

It is a plugin to use ModBlosxom that uses blosxom of a famous Blog system as
a module.

L<Egg::Plugin::Blosxom>,

=head2 CGIrun

Arbitrary CGI is moved in Egg and the result is output.

L<Egg::Plugin::CGIrun>,

* I think that there is a thing that doesn't operate well according to CGI either.

=head2 Cache

The use of an arbitrary cash module becomes convenient.

L<Egg::Plugin::Cache>

=head2 Charset

It appropriately processes it concerning the character set of the output contents.

The following plug-in is loaded and used.

L<Egg::Plugin::Charset::Charset::UTF8>,
L<Egg::Plugin::Charset::EUC_JP>, 
L<Egg::Plugin::Charset::Shift_JIS>,

=head2 ConfigLoader

The configuration of an appropriate place is loaded.

L<Egg::Plugin::ConfigLoader>,

=head2 Crypt::CBC

Plugin to use L<Crypt::CBC>.

L<Egg::Plugin::Crypt::CBC>,

=head2 DBI::Easy

It comes to be able to write the code of troublesome DBI simply variously.

L<Egg::Plugin::DBI::Easy>

=head2 DBI::Transaction

The processing of Transaction by L<Egg::Model::DBI> is automated.

L<Egg::Plugin::DBI::Transaction>

=head2 DBIC::Transaction

The processing of Transaction by L<Egg::Model::DBIC> is automated.

L<Egg::Plugin::DBIC::Transaction>

* It is not possible to use it at the same time with 'DBI::Transaction'.

=head2 Debugging

'debug' method demanded by Egg is offered. It is an indispensable plugin.

L<Egg::Plugin::Debugging>

=head2 Dispatch

'dispatch' method demanded by Egg is offered. It is an indispensable plugin.

Please load the following either.

L<Egg::Plugin::Dispatch::Fast>,
L<Egg::Plugin::Dispatch::Standard>,

=head2 Encode

It processes it concerning the character-code conversion or union.

L<Egg::Plugin::Encode>.

=head2 ErrorDocument

The contents output when it makes an error of '404 Not Found' and '403 Forbidden',
etc. is helped.

L<Egg::Plugin::ErrorDocument>

* It does without relation to the processing when the exception is generated.

=head2 File::Rotate

The file is rotated and the file before is left.

L<Egg::Plugin::File::Rotate>

=head2 FillInForm

Plugin to use 'L<HTML::FillInForm>'.

=head2 Filter

It is a plugin to receive the data regularized by Filter.

L<Egg::Plugin::Filter>.

Plugin:
L<Egg::Plugin::Filter::Plugin::Japanese::UTF8>,
L<Egg::Plugin::Filter::Plugin::Japanese::EUC>,
L<Egg::Plugin::Filter::Plugin::Japanese::Shift_JIS>,

=head2 FormValidator::Simple

Plugin to use 'L<FormValidator::Simple>'.

L<Egg::Plugin::FormValidator::Simple>.

=head2 HTTP::HeadParser

Parsing when response header and request header are received by text.

L<Egg::Plugin::HTTP::HeadParser>.

=head2 LWP

Plugin to use 'L<LWP::UserAgent>'.

L<Egg::Plugin::LWP>.

=head2 Log

'log' method demanded by Egg is offered. It is an indispensable plugin.

L<Egg::Plugin::Log>.

=head2 MailSend

Plugin to do Mail Sending.

L<Egg::Plugin::MailSend>.

=head2 Net::Ping

Plugin to use 'L<Net::Ping>'.

L<Egg::Plugin::Net::Ping>.

=head2 Net::Scan

It connects with an arbitrary port and a target service situation is checked.

L<Egg::Plugin::Net::Scan>.

=head2 Pod::HTML

The Pod document is output.

L<Egg::Plugin::Pod::HTML>.

=head2 Prototype

Plugin to use 'L<Prototype>'.

L<Egg::Plugin::Prototype>.

=head2 Redirect::Body

An easy HTML source for Redirect is offered and output.

L<Egg::Plugin::Redirect::Body>

=head2 SessionKit

The session function is offered.

L<Egg::Plugin::SessionKit>.

=head2 Tools

It is a plugin that offers a convenient method.

L<Egg::Plugin::Tools>.

=head2 Upload

Plugin to support file up-loading.

L<Egg::Plugin::Upload>.

=head2 YAML

Plugin to use 'L<YAML>'.

L<Egg::Plugin::YAML>

=head2 rc

Plugin to read resource code file.

L<Egg::Plugin::rc>.

=head1 SUPPORT

Distribution site.

  L<http://egg.bomcity.com/>.

sourcefoge project.

  L<http://sourceforge.jp/projects/egg/>.

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
