package CGI::Office::Contacts::View::Notes;

use Moose;

extends 'CGI::Office::Contacts::View::Base';

use namespace::autoclean;

our $VERSION = '1.01';

# -----------------------------------------------

sub build_notes_js
{
	my($self, $context) = @_;

	$self -> log(debug => 'Entered build_notes_js');

	my($js) = $self -> load_tmpl('update.notes.js');

	$js -> param(context     => $context);
	$js -> param(form_action => ${$self -> config}{'form_action'});

	return $js -> output;

} # End of build_notes_js.

# -----------------------------------------------

sub display
{
	my($self, $id, $entity, $note, $entity_type, $report) = @_;

	$self -> log(debug => 'Entered display');

	my($template) = $self -> load_tmpl('update.notes.tmpl');

	$template -> param
	(
	 notes_loop =>
	 [
	  map
	  {
		  {
			  note      => $$_{'note'},
			  notes_id  => $$_{'id'},
			  timestamp => $self -> format_timestamp($$_{'timestamp'}),
		  }
	  } @$note
	 ]
	);

	$template -> param(context   => $entity_type);
	$template -> param(result    => $report ? $report : "Notes for '$$entity{'name'}'");
	$template -> param(sid       => $self -> session -> id);
	$template -> param(target_id => $id);

	return $template -> output;

} # End of display.

# -----------------------------------------------

sub report_add
{
	my($self, $user_id, $result, $entity_type, $id, $name) = @_;

	$self -> log(debug => 'Entered report_add');

	my($template) = $self -> load_tmpl('update.report.tmpl');

	if ($result -> success)
	{
		# Force the user_id into the person's record, so it is available elsewhere.
		# Note: This is the user_id of the person logged on.

		my($note)            = {};
		$$note{'creator_id'} = $user_id;
		$$note{'note'}       = $result -> get_value('note');

		# Convert id to table_name_id and table_id.

		$$note{'table_id'} = $id;
		my(%table_name)    =
		(
		 organization => 'organizations',
		 person       => 'people',
		);
		my($table_name)         = $table_name{$entity_type};
		$$note{'table_name_id'} = ${$self -> db -> util -> table_map}{$table_name}{'id'};

		$self -> log(debug => '-' x 50);
		$self -> log(debug => 'Adding note ...'); # Skip note because of Log::Dispatch::DBI's limit.
		$self -> log(debug => "$_ => $$note{$_}") for sort grep{! /^note$/} keys %$note;
		$self -> log(debug => '-' x 50);

		$template -> param(message => $self -> db -> notes -> add($note, $name) );
	}
	else
	{
		$self -> db -> util -> build_error_report($result, $template);

		$template -> param(message => "Failed to add note for '$name'");
	}

	return $template -> output;

} # End of report_add.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
