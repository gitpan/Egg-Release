package Egg::View::Mason;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Mason.pm 248 2007-02-25 11:33:06Z lushe $
#
use strict;
use base qw/Egg::View/;
use HTML::Mason;

our $VERSION= '0.05';

sub setup {
	my($class, $e, $conf)= @_;
	$conf->{comp_root} ||= do {
		my $path= $e->config->{template_path};
		my @options= ['main', $path->[0]];
		push @options, ["private$_", $path->[$_]] for (1..$#{$$path});
		\@options;
	  };
	$conf->{data_dir} ||= $e->config->{temp};
}
sub output {
	my($view, $e)= splice @_, 0, 2;
	my $template = shift || $view->template_file($e)
	   || Egg::Error->throw('I want template.');
	my $body= $view->render($template);
	$e->response->body($body);
}
sub render {
	my $view= shift;
	my $template= shift || return(undef);
	my $args= $_[0] ? ($_[1] ? {@_}: $_[0]): {};
	$template=~m{^[^/]} and $template= "/$template";
	my $body;
	my %conf= %{$view->config};
	@conf{keys %$args}= values %$args;
	my $mason= HTML::Mason::Interp->new(
	  %conf,
	  allow_globals=> [qw/$e $s $p/],
	  out_method   => \$body,
	  );
	$mason->set_global(@$_) for (
	  [ '$e' => $view->{e} ],
	  [ '$s' => $view->{e}->stash ],
	  [ '$p' => $view->params ],
	  );
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

 $s->{param1}= "fooooo";
 
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
 
 <h1><% $s->{param1} %></h1>
 
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

=item * $s = $e->stash.

=item * $p = $e->view->params.

=back

=head1 METHODS

=head2 output ([EGG_OBJECT], [TEMPLATE])

The template is output, and it sets it in $e->response->body.

=head2 render ([TEMPLATE])

The template is output, and it returns it by the SCALAR reference.

=head1 SEE ALSO

L<HTML::Mason>,
L<Egg::View>,
L<Egg::Engine>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
