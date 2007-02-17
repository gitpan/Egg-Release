package Egg::View::Mason;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Mason.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use base qw/Egg::View/;
use HTML::Mason;

our $VERSION= '0.03';

sub setup {
	my($class, $e, $conf)= @_;
	$conf->{comp_root} ||= do {
		my $c= $e->config;
		my @options= ['main', $c->{template_path}[0]];
		for (1..$#{$c->{template_path}}) {
			push @options, ['private', $c->{template_path}[1]],
		}
		\@options;
	  };
	$conf->{data_dir} ||= $e->config->{temp};
}
sub output {
	my($view, $e)= @_;
	my $template= $view->template_file($e) || return;
	my $body= $view->render($template);
	$e->response->body($body);
	1;
}
sub render {
	my $view= shift;
	my $template= shift || return(undef);
	$template=~m{^[^/]} and $template= "/$template";
	my $body;
	my $mason= HTML::Mason::Interp->new(
	  %{$view->config},
	  allow_globals=> [qw/$e $p/],
	  out_method   => \$body,
	  );
	$mason->set_global(@$_)
	  for ( [ '$e'=> $view->{e} ], [ '$p'=> $view->params ] );
	$mason->exec($template);
	return \$body;
}

1;

__END__

=head1 NAME

Egg::View::Mason - HTML::Mason is used for View of Egg.

=head1 SYNOPSIS

This is a setting example.

 VIEW=> [
   [ 'Mason' => {
     comp_root=> [
       [ main   => '/path/to/root' ],
       [ private=> '/path/to/comp' ],
       ],
     data_dir=> '/path/to/temp',
     ... etc.
     } ],
   ],

Example of code.

 $e->stash->{param1}= "fooooo";
 
 $e->view->param( 'param2'=> 'booooo' );
 
 # Scalar reference is received.
 my $body= $e->view->render( 'template.tt' );
 
   or
 
 # It outputs it later.
 $e->template( 'template.tt' );

Example of template.

 <& /comp/html_header, a=> { page_title=> 'test-page' } &>
 <& /comp/banner_head, a=> { type => 1 } &>
 <& /comp/side_menu,   a=> { guest=> 1 } &>
 
 <h1><% $e->stash->{param1} %></h1>
 
 <h2><% $p->{param2} %></h2>
 
 <%init>
 my $array= [
   { name=> 'foo', value=> 'foofoofoo' },
   { name=> 'baa', value=> 'baabaabaa' },
   { name=> 'baa', value=> 'baabaabaa' },
   ];
 </%init>
 <div id="content">
 - Your request passing: <% $e->request->path |h %><hr>
 - Your IP address: <% $e->request->address |h %><hr>
 - Test Array:
 %
 % for my $hash (@$array) {
  [ <% $hash->{name} |h %> = <% $hash->{value} |h %> ],
 % }
 %
 </div>
 <& /comp/html_footer &>

!! It solves it by <% $e->escape_html($var) %> when garbling in <% $var |h %>.

=head1 DESCRIPTION

The following global variable can be used.

=over 4

=item * $e = Egg object.

=item * $p = $e->view->params.

=back

=head1 SEE ALSO

L<HTML::Mason>,
L<Egg::View>,
L<Egg::Component>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
