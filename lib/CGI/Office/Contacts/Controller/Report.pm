package CGI::Office::Contacts::Controller::Report;

use base 'CGI::Office::Contacts::Controller';
use strict;
use warnings;

use CGI::Office::Contacts::Controller::Exporter::Report qw/-all/;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '1.00';

# -----------------------------------------------

1;
