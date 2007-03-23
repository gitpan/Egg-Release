package Egg::View::Template::Ex;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Ex.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use base qw/Egg::View::Template/;
use HTML::Template::Ex;

our $VERSION= '0.03';

sub render {
	my $view= shift;
	my $conf= $view->_create_config(@_);
	my $tmpl= HTML::Template::Ex->new($view->{e}, $conf);
	my $body= $tmpl->output;
	return \$body;
}

1;

__END__

=head1 NAME

Egg::View::Template::Ex - An arbitrary code is moved in the template.

=head1 SYNOPSIS

This is a setting example.

 VIEW=> [
   [ 'Template::Ex'=> {
     path=> [qw( /path/to/root /path/to/comp )],
     ... etc.
     } ],
   ],

* Example of template.

 <tmpl_include name="html_header.tmpl">
 <tmpl_include name="banner_head.tmpl">
 <tmpl_include name="side_menu.tmpl">
 <div id="content">
 - Your request path: <tmpl_var name="request_path" escape="html" %><hr>
 - Your IP address: <tmpl_var name="remote_addr" escape="html" %><hr>
 - Test Array:
 <tmpl_ex>
   my($e, $tmpl_param)= @_;
   my $disp;
   for my $hash (
     { name=> 'foo', value=> 'foofoofoo' },
     { name=> 'baa', value=> 'baabaabaa' },
     { name=> 'baa', value=> 'baabaabaa' },
     ) {
     $disp.= "[ ". $e->escape_html($hash->{name})
       . " = ". $e->escape_html($hash->{value}). "]\n";
   }
   return $disp;
 </tmpl_ex>
 </div>
 <tmpl_include name="html_footer.tmpl">

=head1 DESCRIPTION

It suffers from a very troublesome thing though it is a module appended in 
 circumstances.

Even if the error occurs, what has happened cannot be understood.

It risks it. HTML::Template::Ex does very high-speed operation in the template
engine that evaluates the code.

Please try crazy once. 

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View::Template>,
L<HTML::Template::Ex>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
