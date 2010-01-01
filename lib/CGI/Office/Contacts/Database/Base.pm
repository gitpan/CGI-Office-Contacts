package CGI::Office::Contacts::Database::Base;

use Moose;

extends 'CGI::Office::Contacts::Base';

has db => (is => 'ro', isa => 'Any', required => 1);

use namespace::autoclean;

our $VERSION = '1.00';

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
