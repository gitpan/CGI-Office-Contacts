package CGI::Office::Contacts::View::Report;

use Moose;

extends 'CGI::Office::Contacts::View::Base';

with 'CGI::Office::Contacts::View::Role::Report';

use namespace::autoclean;

our $VERSION = '1.00';

# -----------------------------------------------

sub generate_report
{
	my($self, $input, $report_name) = @_;

	# There is only one possible report for Contacts.
	# See also CGI::Office::Contacts::Donations::View::Report.

	return $self -> generate_record_report($input);

} # ENd of generate_report.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
