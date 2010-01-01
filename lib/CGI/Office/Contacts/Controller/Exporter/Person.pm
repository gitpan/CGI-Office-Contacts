package CGI::Office::Contacts::Controller::Exporter::Person;

use strict;
use warnings;

use CGI::Office::Contacts::Util::Validator;

use JSON::XS;

use Sub::Exporter -setup =>
{
	exports =>
	[qw/
		add
		cgiapp_init
		delete_occupation_via_person
		display
		person_autocomplete
		update
	/],
};

our $VERSION = '1.00';

# -----------------------------------------------

sub add
{
	my($self) = @_;

	$self -> log(debug => 'Entered add');

	my($result) = CGI::Office::Contacts::Util::Validator -> new
	(
		config => $self -> param('config'),
		db     => $self -> param('db'),
		query  => $self -> query,
	) -> person;

	return $self -> param('view') -> person -> report_add($self -> param('user_id'), $result);

} # End of add.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/add update/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub delete_occupation_via_person
{
	my($self) = @_;

	$self -> log(debug => 'Entered delete_occupation_via_person');

	my($id)            = $self -> query -> param('target_id');
	my($person)        = $self -> param('db') -> person -> get_person_via_id($id);
	my(@occupation_id) = split(/,/, $self -> query -> param('occupation_id') );

	# Discard the 0.
	# See update.person.js's function <tmpl_var name=context>_person_occupation_onsubmit() for details.

	shift @occupation_id;

	my($result) = $self -> param('db') -> occupation -> delete_via_person($id, @occupation_id);

	if ($result > 0)
	{
		$result = "Deleted $result occupation" . ($result == 1 ? '' : 's') . " for '$$person{'name'}' (Hint: Refresh via Search tab)";
	}
	else
	{
		$result = "No such occupation for $$person{'name'}";
	}

	return $result;

} # End of delete_occupation_via_person.

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> log(debug => 'Entered display');

	my($id)     = $self -> query -> param('target_id');
	my($person) = $self -> param('db') -> person -> get_person($self -> param('user_id'), $id);
	my($result) = "No person has the requested id. (Hint: Run another search)";

	if ($id && ($#$person >= 0) )
	{
		$result = $self -> param('view') -> person -> build_update_person_html($id, $$person[0]);
	}

	return $result;

} # End of display.

# -----------------------------------------------

sub person_autocomplete
{
	my($self) = @_;

	$self -> log(debug => 'Entered person_autocomplete');

	my($json) = JSON::XS -> new;
	my($name) = $self -> query -> param('name') || ''; # TODO. Was $self -> param('query').
	my($list) = $self -> param('db') -> person -> get_people_via_name_prefix($name);

	if ($#$list < 0)
	{
		$list = [ [$name, 0] ];
	}

	return $json -> encode({results => [map{ {name => $$_[0], id => $$_[1]} } @$list]});

} # End of person_autocomplete.

# -----------------------------------------------

sub update
{
	my($self) = @_;

	$self -> log(debug => 'Entered update');

	my($id)          = $self -> query -> param('target_id');
	my($action)      = $self -> query -> param('submit_person_delete') || 'Update';
	my($given_names) = $self -> query -> param('given_names') || '';
	my($surname)     = $self -> query -> param('surname')     || '';
	my($name)        = "$given_names $surname";
	my($user_id)     = $self -> param('user_id');
	my($person)      = $self -> param('db') -> person -> get_person($user_id, $id);

	my($result);

	if ($#$person < 0)
	{
		$result = "'$name' not on file";
	}
	elsif ($action eq 'Delete')
	{
		$action       = $self -> param('db') -> person -> delete($id, $name);
		my($template) = $self -> load_tmpl('update.report.tmpl');

		$template -> param(message => $action);

		$result =  $template -> output;
	}
	else # Update.
	{
		my($input) = CGI::Office::Contacts::Util::Validator -> new
		(
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> person;

		$result = $self -> param('view') -> person -> report_update($user_id, $id, $input);
	}

	return $result;

} # End of update.

# -----------------------------------------------

1;
