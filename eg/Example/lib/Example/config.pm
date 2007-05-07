package Example::config;
#
# $Id$
#
use strict;
use warnings;

my $C= {

# Project Title.
title=> 'Example',

# Project root directory. (Absolutely path only)
root => './Example',

# Directory configuration.
static_uri=> '/',
dir => {
  lib      => '<$e.root>/lib',
  static   => '<$e.root>/htdocs',
  etc      => '<$e.root>/etc',
  cache    => '<$e.root>/cache',
  tmp      => '<$e.root>/tmp',
  template => '<$e.root>/root',
  comp     => '<$e.root>/comp',
  },

# Character code for processing.
#  character_in         => 'euc',  # euc or sjis or utf8
#  disable_encode_query => 0,

# Template.
#  template_default_name=> 'index',
#  template_extension=> '.tt',
template_path=> ['<$e.dir.template>', '<$e.dir.comp>'],

# Default content type and language.
#  content_type    => 'text/html; charset=euc-jp',
#  content_language=> 'ja',

# Upper bound of request directory hierarchy.
#  max_snip_deep=> 5,

# Accessor to stash. * Do not overwrite a regular method.
#  accessor_names=> [qw/hoge/],

# Cookie default setup.
#  cookie => {
#    domain  => 'mydomain',
#    path    => '/',
#    expires => 0,
#    secure  => 0,
#    },

# Model configuration.
#  MODEL=> [
#    [ DBI => {
#        dsn=> 'dbi:[DBD]:dbname=[DB];host=localhost;port=5432',
#        user    => '[USERNAME]',
#        password=> '[PASSWORD]',
#        options => { AutoCommit=> 1, RaiseError=> 0 },
#        },
#      ],
#    ],

# View configuration.
  VIEW=> [
    [ Template => {
#
#   * Please refer to document of HTML::Template
#   http://search.cpan.org/dist/HTML-Template/
#
        path=> ['<$e.dir.template>', '<$e.dir.comp>'],
        global_vars=> 1,
        die_on_bad_params=> 0,
      # cache=> 1,
        },
      ],
#   [ Mason => {
#
#   * Please refer to document of HTML::Mason.
#   http://search.cpan.org/dist/HTML::Mason/
#   http://www.masonhq.com/
#
#       comp_root=> [
#         [ main   => '<$e.dir.template>' ],
#         [ private=> '<$e.dir.comp>' ],
#         ],
#        data_dir=> '<$e.root>/tmp',
#       },
#     ],
    ],

# request => {
#   DISABLE_UPLOADS => 0,
#   TEMP_DIR => '<$e.dir.tmp>',
#   POST_MAX => 10240,
#   },

# * For ErrorDocument plugin.
# plugin_error_document=> {
#   view_name => 'Mason',
#   template  => 'error/document.tt',
#   },

# * For FillInForm plugin.
# plugin_fillinform=> {
#   ignore_fields => [qw{ ticket }],
#   fill_password => 0,
#   },

# * For Pod::HTML plugin.
# plugin_pod2html=> {
#   lib_path  => [qw{ /path/to/lib }],
#   extension => '.pm',
#   },

  };

sub out { $C }

1;
