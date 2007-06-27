
use Test::More tests => 4;
use Egg::Helper::VirtualTest;

SKIP: {
eval{ require FormValidator::Simple };
skip 'FormValidator::Simple is not installed.', 4 if $@;

my $test= Egg::Helper::VirtualTest->new( prepare=> {
  controller=> { egg_includes=> [qw/ FormValidator::Simple /] },
  });

ok my $e= $test->egg_context;
can_ok $e, qw/ form set_invalid_form /;
ok my $form= $e->form;
isa_ok $form, 'FormValidator::Simple::Results';

  };

