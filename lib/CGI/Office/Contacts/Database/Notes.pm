package CGI::Office::Contacts::Database::Notes;

use Moose;

extends 'CGI::Office::Contacts::Database::Base';

use namespace::autoclean;

our $VERSION = '1.01';

# -----------------------------------------------

sub add
{
	my($self, $note, $name) = @_;

	$self -> log(debug => 'Entered add');

	$self -> save_notes_record('add', $note);

	return "Added note for '$name'";

} # End of add.

# -----------------------------------------------

sub delete
{
	my($self, $entity_type, $table_id, @note_id) = @_;

	$self -> log(debug => 'Entered delete');

	my($count) = $#note_id + 1;
	my($sql)   = 'delete from notes where table_id = ? and id in (' . ('?, ') x $#note_id . '?)';

	$self -> db -> dbh -> do($sql, {}, $table_id, @note_id);

	return $count;

} # End of delete.

# -----------------------------------------------

sub get_notes
{
	my($self, $table_name, $table_id) = @_;

	$self -> log(debug => 'Entered get_notes');

	my($table_map)   = $self -> db -> util -> table_map;
	my($table_entry) = $$table_map{$table_name};

	return $self -> db -> dbh -> selectall_arrayref('select * from notes where table_name_id = ? and table_id = ? order by timestamp desc', {Slice => {} }, $$table_entry{'id'}, $table_id) || [];

} # End of get_notes.

# --------------------------------------------------

sub save_notes_record
{
	my($self, $context, $note) = @_;

	$self -> log(debug => 'Entered save_notes_record');

	my($table_name) = 'notes';
	my(@field)      = (qw/creator_id table_id table_name_id note/);
	my($data)       = {};
	my(%id)         =
	(
	 creator    => 1,
	 person     => 1,
	 table      => 1,
	 table_name => 1,
	);

	my($field_name);

	for (@field)
	{
		if ($id{$_})
		{
			$field_name = "${_}_id";
		}
		else
		{
			$field_name = $_;
		}

		$$data{$field_name} = $$note{$_};
	}

	if ($context eq 'add')
	{
		$self -> db -> util -> insert_hash_get_id($table_name, $data);

		$$note{'id'} = $$data{'id'} = $self -> db -> util -> last_insert_id($table_name);
	}
	else
	{
		# TODO.

	 	$self -> db -> dbh -> do("update $table_name set where id = $$note{'id'}", {}, $data);
	}

} # End of save_notes_record.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
