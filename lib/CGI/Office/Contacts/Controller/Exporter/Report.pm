package CGI::Office::Contacts::Controller::Exporter::Report;

use strict;
use warnings;

use CGI::Office::Contacts::Util::Validator;

use JSON::XS;

use Sub::Exporter -setup =>
{
	exports =>
	[qw/
		display
	/],
};

our $VERSION = '1.01';

# -----------------------------------------------

sub display
{
	my($self)        = @_;
	my($report_name) = $self -> param('id');

	$self -> log(debug => "Entered display: $report_name");

	my($input) = CGI::Office::Contacts::Util::Validator -> new
	(
		config => $self -> param('config'),
		db     => $self -> param('db'),
		query  => $self -> query,
	) -> report;

	my($report) = $self -> param('view') -> report -> generate_report($input, $report_name);

	return JSON::XS -> new -> encode({results => $report});

} # End of display.

# -----------------------------------------------

1;
