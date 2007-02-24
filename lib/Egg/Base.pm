package Egg::Base;
use strict;
use UNIVERSAL::require;
use base qw/Egg::Component/;

our $VERSION= '0.01';

{
	no strict 'refs';  ## no critic

	sub config {
		my $class= shift;
		my $basename= ref($class) || $class;
		return ${"$basename\::__CONFIGURATION"} unless @_;
		${"$basename\::__CONFIGURATION"}= ref($_[0]) eq 'HASH' ? $_[0]: {@_};
	}
	sub init_name {
		my $class= shift;
		my $basename= ref($class) || $class;
		return ${"$basename\::__INIT_NAME"} unless @_;
		${"$basename\::__INIT_NAME"}= shift || "";
	}
	sub include {
		my $class= shift;
		my $pkg= shift || return 0;
		$pkg->require or Egg::Error->throw($@);
		my $basename= ref($class) || $class;
		my $inc= ${"$basename\::__INCLUDES"} ||= [];
		push @$inc, $pkg;
		1;
	}
	sub include_packages {
		my $class= shift;
		my $basename= ref($class) || $class;
		${"$basename\::__INCLUDES"} || [];
	}

  };

1;
