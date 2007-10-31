package Egg::Plugin::TemplateAuto;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: TemplateAuto.pm 200 2007-10-31 04:30:14Z lushe $
#
use strict;
use warnings;

our $VERSION = '2.01';

=head1 NAME

Egg::Plugin::TemplateAuto - Plugin in which it assists for template decision.

=head1 SYNOPSIS

  use Egg qw/ TemplateAuto /;
  
  __PACKAGE__->egg_startup(
    .......
    .....
    template_path        => ['<$e.template>', '<$e.comp>'],
    template_extension   => 'tt',
    plugin_template_auto => { ignore_names=> [qw/index/] },
    );
  
  __PACKAGE__->dispatch_map(
    .......
    .....
    hoge => {
      .....
      qr{^([a-zA-Z0-9]+)}=> sub {
        my($e, $dispatch, $parts)= @_;
        $e->template_auto('/hoge/', $parts->[0]);
        },
      },
    );

=head1 DESCRIPTION

This plugin decides the template based on the character string acquired from 
the action that matches to the regular expression of dispatch_map.

  __PACKAGE__->dispatch_map(
    .......
    qr{^(.+)}=> sub { $_[0]->template_auto('/boo/', $_[2]->[0]) },
    );

* Time when dispatch is set every time TEMPLETE is added can be saved by setting
  the match rule like the example above at the route level of dispatch.
  However, it is recommended to write dispatch lowered by one step whether to
  write the regular expression to match it by a certain format to set the code
  in which something is done separately because it embarrasses it if it matches
  it for everything.

  __PACKAGE__->dispatch_map(
    .......
    wanko => \&wanko,
    qr{^([A-Z][a-z0-9]+)}=> sub { $_[0]->template_auto('/boo/', $_[2]->[0]) },
    hoge => sub {
      qr{^(.+)}=> sub { $_[0]->template_auto('/hoge/', $_[2]->[0]) },
      },
    );

When a suitable template is not found from the directory set to 'template_path', 
$e-E<gt>finished(404) is set. * 404 Not Found.

=head1 CONFIGURATION

This plugin is set by 'Plugin_template_auto'.

Additionally, refer to 'template_path' and 'template_extension' of root configuration.

=head2 ignore_names => [ARRAY]

When the template is decided by the set name, '404 Not Found' is returned.

  plugin_template_auto => {
    ignore_names => [qw/ index default /],
    },

=head2 base_dir => [SCALAR]

When BASE_DIR passed to the template_auto method is omitted, this setting is
always used.

  plugin_template_auto => {
    base_dir => '/hoge/',
    },

=head1 METHODS

=cut
sub _setup {
	my($e)= @_;
	my $path= $e->config->{template_path};
	my $ext = $e->config->{template_extension} ||= 'tt';
	   $ext =~s{\.} [];
	my $conf= $e->config->{plugin_template_auto} ||= {};
	my $list;
	my $ignore= ($list= $conf->{ignore_names}) ? do {
		my $regex= join '|',
		   map{quotemeta}(ref($list) eq 'ARRAY' ? @$list: $list);
		 sub { $_[0]=~/^(?:$regex)$/ ? 1: 0 };
	  }: sub { };
	my $base_dir= $conf->{base_dir} || "";

	no warnings 'redefine';

=head2 template_auto ([BASE_DIR], [TEMPLATE_NAME])

When BASE_DIR is omitted, a target template is processed right under 'template_path'
assuming that it exists.

  $e->template_auto('/hoge/', 'nyanko');
  #
  #  /hoge/nyanko.tt returns to this.
  #

Please do not apply '/' to the head of BASE_DIR if it is unpalatable when there
is '/' on the head of the template name when L<HTML::Template> etc. are used.

  $e->template_auto('hoge/abc/', 'eteko');
  #
  #  Hoge/abc/eteko.tt is restored to this.
  #

=cut
	*template_auto= sub {
		my $egg = shift;
		my $base= shift || $base_dir || "";
		my $name= shift || return $egg->finished(404);
		$ignore->($name) and return $egg->finished(404);
		my $delimit= $base=~m{^/} ? '/': '';
		my $t_name = "${base}$name.$ext";
		for my $dir (@$path) {
			-e "${dir}${delimit}$t_name" || next;
			return $egg->template($t_name);
		}
		$egg->finished(404);
	  };

	$e->next::method;
}

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

1;
