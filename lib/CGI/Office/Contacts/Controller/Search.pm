package CGI::Office::Contacts::Controller::Search;

use base 'CGI::Office::Contacts::Controller';
use strict;
use warnings;

use CGI::Office::Contacts::Controller::Exporter::Search qw/-all/;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '1.01';

# -----------------------------------------------

1;
