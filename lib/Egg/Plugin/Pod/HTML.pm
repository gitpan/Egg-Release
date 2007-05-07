package Egg::Plugin::Pod::HTML;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: HTML.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Pod::HTML - pod2html for Egg Plugin.

=head1 SYNOPSIS

  use Egg qw/ Pod::HTML /;
  
  __PACKAGE__->egg_startup(
    ...
    .....
  
    plugin_pod2html => {
      pod_libs    => [qw{ /path/to/lib /path/to/perl-lib }],
      output_code => 'utf8',
      },
  
    );
  
  __PACKAGE__->run_modes(
    ...
    .....
  
  #
  # The request named/pod/[MODULE_NAME] is caught.
  # Refer to [MODULE_NAME] by $e->snip(1).
  #
    pod => sub {
      my($d, $e)= @_;
      my $pod_body= $e->pod2html( $e->snip(1) );
      
      # If $e->finished(NOT_FOUND) etc. are not done, body is set.
      $e->response->body($pod_body) unless $e->finished;
      },
  
    );

=head1 DESCRIPTION

It is a plugin to output the pod document as contents. 

=head1 CONFIGURATION

The item name of the setting is 'plugin_pod2html'.

=head2 cmd_path => [COMAND_PATH],

PATH to pod2html command.

Acquisition is tried by L<File::Which> when omitted.
Default when failing in acquisition is '/usr/bin/pod2html'.

  cmd_path => '/usr/local/bin/pod2html',

=head2 pod_libs => [LIN_DIR_ARRAY],

PATH list of place in which it looks for Pod document.

  pod_libs => [qw{ /usr/lib/perl5/5.8.0 /home/perl-lib }],

=head2 extension => [FILE_EXTENSION],

Extension of Pod document file of object.

Default is 'pm'.

  extension => 'pod',

=head2 output_code => [ENCODE_CODE],

When L<Egg::Plugin::Encode> is loaded, it is possible to set it.

It is invalid when there is no $e-E<gt> "[ENCODE_CODE]_conv" method.

  output_code => 'utf8',

* When this setting is undefined, Pod is output as it is.

=cut
use strict;
use warnings;
use Egg::Const;
use File::Temp;

our $VERSION = '2.00';

sub _setup {
	my($e)= @_;
	my $conf= $e->config->{plugin_pod2html} ||= {};
	unless ($conf->{cmd_path}) {
		require File::Which;
		$conf->{cmd_path}= &File::Which::which('pod2html')
		                || '/usr/bin/pod2html';
	}
	$conf->{pod_libs}  || die q{ I want plugin_pod2html->{pod_libs} };
	$conf->{extension} ||= 'pm';

	my $ocode;
	if ($ocode= $conf->{output_code}
	   and $e->isa('Egg::Plugin::Encode')
	   and $e->can("${ocode}_conv")
	   ) {
		my $conv= "${ocode}_conv";
		no warnings 'redefine';
		*_podout_conv= sub {
			my($egg, $str)= @_;
			$$str= $egg->$conv($str);
			$str;
		  };
		$e->debug_out("# + pod2html output code setup : ${ocode}");
	}

	$e->next::method;
}

=head1 METHODS

=head2 pod2html ( [MODULE_NAME], [OPTION_HASH] )

If MODULE_NAME is found in pod_libs, the HTML source is returned by the
SCALAR reference.

If MODULE_NAME cannot be recognized as a module name, $e->finished(FORBIDDEN)
is returned.
Another and '-' of usual ':' are allowed in the delimiter of MODULE_NAME.

When MODULE_NAME is not found, $e->finished(NOT_FOUND) is returned.

Can it pass to the pod2html command in OPTION_HASH, and following option be
specified.

  backlink, css, header, hiddendirs, index, quiet, recurse, verbose,

  pod => sub {
     my($d, $e)= @_;
     my $body= $e->pod2html('Egg::Plugin::Pod::HTML');
     $e->response->body($body) unless $e->finished;
   },

=cut
sub pod2html {
	my $e = shift;
	my $pm= shift || return $e->finished( NOT_FOUND );
	return $e->finished( FORBIDDEN ) if $pm!~/^[A-Za-z_][A-Za-z0-9_\-\:]+$/;

	my $arg = shift || {};
	my $conf= $e->config->{plugin_pod2html};
	my $base= $arg->{pod_libs}  || $conf->{pod_libs};
	my $ext = $arg->{extension} || $conf->{extension};
	   $ext =~s{^\.} [];
	my $file= $pm; $file=~s{[\:\-]+} [/]g;
	my $temp= &File::Temp::tempdir( CLEANUP=> 1 );
	my $infile;
	my @inc= @INC;
	ref($base) ? splice @inc, 0, 0, @$base
	           : unshift @inc, $base;
	for (@inc) {
		next unless -f "$_/$file.$ext";
		$infile= "$_/$file.$ext";
		last;
	}
	$infile || return $e->finished( NOT_FOUND );

	my $opt= Egg::Plugin::Pod::HTML::options->new($arg, $conf);

	for (qw/backlink/) { $opt->set($_, 1) }
	for (qw/css/) { $opt->set($_) }
	for (qw/header hiddendirs index quiet recurse verbose/)
	  { $opt->set_flag($_) }
	$opt->push_option( "title=$pm" );
	$opt->push_option( "infile=$infile" );
	$opt->push_option( "cachedir=$temp" );
	$opt->push_option( "htmlroot=$temp" );

	my $result= $opt->output($e) || return $e->finished( FORBIDDEN );

	$e->_podout_conv($result);
}

=head2 pod2html_body ( [MODULE_NAME], [OPTION_HASH] )

It deletes from HTML received from 'pod2html' method excluding
E<lt>bodyE<gt> ... E<lt>/bodyE<gt> part and it returns it.

When the Pod document is built into arbitrary contents, this is convenient.

  pod => sub {
     my $body= $e->pod2html_body('Egg::Plugin::Pod::HTML');
     $e->view->param( pod_body => sub { $$body || "" } ) unless $e->finished;
   },
  
  #
  # And, it builds it in the pod.tt template.
  #

=cut
sub pod2html_body {
	my $result= shift->pod2html(@_);
	$$result=~s{^.+?<body.*?>}  []is;
	$$result=~s{</body.*?>.*?$} []is;
	$result;
}

sub _podout_conv { $_[1] }


package Egg::Plugin::Pod::HTML::options;
use strict;
use base qw/Class::Accessor::Fast/;

=head1 OPTIONS METHODS

It is a method for the construction of the option of pod2html.
This is not the one preparing it to call it from the outside by the one that
this module uses.

=over 4

=item * new, set, set_flag, push_option, output,

=back

=cut

__PACKAGE__->mk_accessors( qw/arg conf/ );

sub new {
	my($class, $arg, $conf)= @_;
	bless { options=> [], arg=> $arg, conf=> $conf }, $class;
}
sub set {
	my $self= shift;
	my $key = shift;
	my $quot= $_[0] ? sub { qq{$key="$_[0]"} }: sub { qq{$key=$_[0]} };
	my $value;
	  exists($self->arg->{$key})
	  ? do { $value= $self->arg->{$key}  || return 0 }
	: exists($self->conf->{$key})
	  ? do { $value= $self->conf->{$key} || return 0 }
	: return 0;
	$self->push_option( $quot->($value) );
}
sub set_flag {
	my($self, $key)= @_;
	  exists($self->arg->{$key})
	  ? do { $key= "no$key" unless ($self->arg->{$key})  }
	: exists($self->conf->{$key})
	  ? do { $key= "no$key" unless ($self->conf->{$key}) }
	: return 0;
	$self->push_option( $key );
}
sub push_option {
	my($self, $value)= @_;
	push @{$self->{options}}, "--$value";
	1;
}
sub output {
	my($self, $e)= @_;
	my $bin= $self->conf->{cmd_path};
	my $option= join ' ', @{$self->{options}};
	$e->debug_out("# + pod2html cmd line: $bin $option");
	open OUT, "$bin $option |" || return 0;  ## no critic
	my $result= join '', <OUT>;
	close OUT;
	return \$result;
}

=head1 SEE ALSO

L<File::Temp>,
L<File::Which>,
L<Egg::Plugin::Encode>,
L<Egg::Const>,
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
