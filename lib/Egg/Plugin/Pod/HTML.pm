package Egg::Plugin::Pod::HTML;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: HTML.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;
use Egg::Const;

our $VERSION = '0.01';

sub setup {
	my($e)= @_;
	my $config= $e->config->{plugin_pod2html} ||= {};
	unless ($config->{bin_path}) {
		File::Which->require
		  and $config->{bin_path}= &File::Which::which('pod2html');
		$config->{bin_path} ||= '/usr/bin/pod2html';
	}
	$config->{lib_path}
	  || Egg::Error->throw(q/I want plugin_pod2html->{lib_path}/);
	$config->{extension} ||= '.pm';
	$e->next::method;
}
sub pod2html {
	my $e = shift;
	my $pm= shift || return $e->finished( NOT_FOUND );
	return $e->finished( FORBIDDEN ) if $pm!~/^[A-Za-z_][A-Za-z0-9_\-\:]+$/;

	File::Temp->require;
	my $arg = shift || {};
	my $cf  = $e->config->{plugin_pod2html};
	my $base= $arg->{lib_path} || $cf->{lib_path};
	my $ext = $arg->{extension} || $cf->{extension};
	my $file= $pm; $file=~s{[\:\-]+} [/]g;
	my $temp= &File::Temp::tempdir( CLEANUP=> 1 );
	my $result_func;
	if ($cf->{output_code}) {  # 'euc' or 'sjis' or 'utf8'.
		my $code= "$cf->{output_code}_conv";
		$result_func= sub {
			${$_[0]}= $e->$code($_[0]);
			return $_[0];
		  };
	} else {
		$result_func= sub { $_[0] };
	}
	my $infile;
	my @inc= @INC;
	ref($base) ? splice @inc, 0, 0, @$base
	           : unshift @inc, $base;
	for (@inc) {
		next unless -f "$_/$file$ext";
		$infile= "$_/$file$ext";
		last;
	}
	$infile || return $e->finished( NOT_FOUND );

	my $opt= Egg::Plugin::Pod::HTML::options->new($arg, $cf);

	for (qw/backlink/) { $opt->set($_, 1) }
	for (qw/css/) { $opt->set($_) }
	for (qw/header hiddendirs index quiet recurse verbose/)
	  { $opt->set_flag($_) }
	$opt->push_option( "title=$pm" );
	$opt->push_option( "infile=$infile" );
	$opt->push_option( "cachedir=$temp" );
	$opt->push_option( "htmlroot=$temp" );

	my $result= $opt->output($e) || return $e->finished( FORBIDDEN );

	return $result_func->($result);
}
sub pod2html_body {
	my $result= shift->pod2html(@_);
	$$result=~s{^.+?<body.*?>} []is;
	$$result=~s{</body.*?>.*?$} []is;
	return $result;
}

package Egg::Plugin::Pod::HTML::options;
use strict;
use base qw/Class::Accessor::Fast/;

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
	my $bin= $self->conf->{bin_path};
	my $option= join ' ', @{$self->{options}};
	$e->debug_out("# + pod2html cmd line: $bin $option");
	open OUT, "$bin $option |" || return 0;  ## no critic
	my $result= join '', <OUT>;
	close OUT;
	return \$result;
}

1;

__END__

=head1 NAME

Egg::Plugin::Pod::HTML - pod2html for Egg.

=head1 SYNOPSIS

Contoller.

  package MYPROJECT;
  use strict;
  use Egg qw/Pod::HTML/;

Configuration.

  plugin_pod2html => {
    lib_path=> [qw{ /home/lib /home/perl-lib }],
    },

Dispatch.

  __PACKAGE__->run_modes(
  
    pod => sub {
      my($dispat, $e)= @_;
      my $body= $e->pod2html( $e->snip(1) ) || return $e->finished( 404 );
      $e->response->body( $body );
      },
  
    );

Request url.

  http://domain.name/pod/HTML::Mason

=head1 METHODS

=head2 pod2html ([MODULE_NAME], [ARGS])

The result of the return of 'pod2html' command is returned by the SCALAR reference.

  my $html= $e->pod2html('CGI::Cookie');

=head2 pod2html_body ([MODULE_NAME], [ARGS])

The part of '<body> ... </body>' is returned from the result of pod2html.

  my $body= $e->pod2html_body('CGI::Cookie');

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
