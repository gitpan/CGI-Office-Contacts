package CGI::Office::Contacts::Controller::Exporter::Notes;

use strict;
use warnings;

use CGI::Office::Contacts::Util::Validator;

use Sub::Exporter -setup =>
{
	exports =>
	[qw/
		add
		cgiapp_init
		delete
		display
		organization_notes
		person_notes
	/],
};

our $VERSION = '1.00';

# -----------------------------------------------

sub add
{
	my($self) = @_;

	$self -> log(debug => 'Entered add');

	my($id)          = $self -> query -> param('target_id');
	my($type)        = $self -> param('id');
	my($method)      = "get_${type}_via_id";
	my($entity)      = $self -> param('db') -> $type -> $method($id);
	my($entity_name) = $$entity{'name'};
	my($result)      = CGI::Office::Contacts::Util::Validator -> new
	(
		config => $self -> param('config'),
		db     => $self -> param('db'),
		query  => $self -> query,
	) -> notes;

	my($report) = $self -> param('view') -> notes -> report_add($self -> param('user_id'), $result, $type, $id, $entity_name);

	return $self -> display($report);

} # End of add.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/add delete/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub delete
{
	my($self) = @_;

	$self -> log(debug => 'Entered delete');

	my($id)          = $self -> query -> param('target_id');
	my($type)        = $self -> param('id');
	my($method_name) = "get_${type}_via_id";
	my($entity)      = $self -> param('db') -> $type -> $method_name($id);
	my($entity_name) = $$entity{'name'};
	my(@note_id)     = split(/,/, $self -> query -> param('notes_id') );

	# Discard the 0.

	shift @note_id;

	my($count) = $self -> param('db') -> notes -> delete($type, $id, @note_id);

	$self -> display("Deleted $count note" . ($count == 1 ? '' : 's') . " for '$entity_name'");

} # End of delete.

# -----------------------------------------------

sub display
{
	my($self, $report) = @_;

	$self -> log(debug => 'Entered display');

	my($id)     = $self -> query -> param('target_id');
	my($type)   = $self -> param('id');
	my($method) = "${type}_notes";

	return $self -> $method($id, $report);

} # End of display.

# -----------------------------------------------

sub organization_notes
{
	my($self, $id, $report) = @_;

	$self -> log(debug => 'Entered organization_notes');

	my($organization) = $self -> param('db') -> organization -> get_organization_via_id($id);
	my($note)         = $self -> param('db') -> notes -> get_notes('organizations', $id);
	my($result)       = $self -> param('view') -> notes -> display($id, $organization, $note, 'organization', $report);

	return $result;

} # End of organization_notes.

# -----------------------------------------------

sub person_notes
{
	my($self, $id, $report) = @_;

	$self -> log(debug => 'Entered person_notes');

	my($person) = $self -> param('db') -> person -> get_person_via_id($id);
	my($note)   = $self -> param('db') -> notes -> get_notes('people', $id);
	my($result) = $self -> param('view') -> notes -> display($id, $person, $note, 'person', $report);

	return $result;

} # End of person_notes.

# -----------------------------------------------

1;
