package CGI::Office::Contacts::Database::Occupation;

use Moose;

extends 'CGI::Office::Contacts::Database::Base';

use namespace::autoclean;

our $VERSION = '1.00';

# --------------------------------------------------

sub add
{
	my($self, $occupation) = @_;

	$self -> log(debug => 'Entered add');

	$self -> save_occupation_record('add', $occupation);

} # End of add.

# -----------------------------------------------

sub delete_via_organization
{
	my($self, $organization_id, @occupation_id) = @_;

	$self -> log(debug => 'Entered delete_via_organization');

	my($count) = $#occupation_id + 1;
	my($sql)   = 'delete from occupations where organization_id = ? and id in (' . ('?, ') x $#occupation_id . '?)';

	$self -> db -> dbh -> do($sql, {}, $organization_id, @occupation_id);

	return $count;

} # End of delete_via_organization.

# -----------------------------------------------

sub delete_via_person
{
	my($self, $person_id, @occupation_id) = @_;

	$self -> log(debug => 'Entered delete_via_person');

	my($count) = $#occupation_id + 1;
	my($sql)   = 'delete from occupations where person_id = ? and id in (' . ('?, ') x $#occupation_id . '?)';

	$self -> db -> dbh -> do($sql, {}, $person_id, @occupation_id);

	return $count;

} # End of delete_via_person.

# -----------------------------------------------

sub get_occupation_id_via_name
{
	my($self, $name) = @_;

	$self -> log(debug => "Entered get_occupation_id_via_name: $name");

	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from occupation_titles where name = ?', {Slice => {} }, $name);

	return $id ? $$id{'id'} : 0;

} # End of get_occupation_id_via_name.

# -----------------------------------------------

sub get_occupation_id_via_person
{
	my($self, $person_id) = @_;

	$self -> log(debug => "Entered get_occupation_id_via_person: $person_id");

	return $self -> db -> dbh -> selectall_arrayref('select * from occupations where person_id = ?', {Slice => {} }, $person_id) || [];

} # End of get_occupation_id_via_person.

# -----------------------------------------------

sub get_occupation_title_via_id
{
	my($self, $id) = @_;

	$self -> log(debug => "Entered get_occupation_title_via_id: $id");

	my($name) = $self -> db -> dbh -> selectrow_hashref("select name from occupation_titles where id = ?", {Slice => {} }, $id);

	return $name ? $$name{'name'} : '';

} # End of get_occupation_title_via_id.

# -----------------------------------------------

sub get_occupation_titles_via_name_prefix
{
	my($self, $prefix) = @_;

	$self -> log(debug => "Entered get_occupation_titles_via_name_prefix: $prefix");

	$prefix      = uc $prefix;
	my($id2name) = $self -> db -> dbh -> select_map("select id, name from occupation_titles where upper(name) like '$prefix%'");

	my($id);
	my(@result);

	for $id (keys %$id2name)
	{
		push @result, [$$id2name{$id}, $id];
	}

	return [@result];

} # End of get_occupation_titles_via_name_prefix.

# -----------------------------------------------

sub get_occupation_via_id
{
	my($self, $occupation) = @_;

	$self -> log(debug => 'Entered get_occupation_via_id');

	my($person)            = $self -> db -> person -> get_person_via_id($$occupation{'person_id'});
	my($organization)      = $self -> db -> organization -> get_organization_via_id($$occupation{'organization_id'});
	my($title)             = $self -> get_occupation_title_via_id($$occupation{'occupation_title_id'});

	return
	{
		title             => $title,
		organization_id   => $$occupation{'organization_id'},
		organization_name => $$organization{'name'},
		person_id         => $$person{'id'},
		person_name       => $$person{'name'},
	};

} # End of get_occupation_via_id.

# -----------------------------------------------

sub get_occupation_via_organization
{
	my($self, $organization_id) = @_;

	$self -> log(debug => "Entered get_occupation_via_organization: $organization_id");

	return $self -> db -> dbh -> selectall_arrayref('select * from occupations where organization_id = ?', {Slice => {} }, $organization_id) || [];

} # End of get_occupation_via_organization.

# --------------------------------------------------

sub save_occupation_record
{
	my($self, $context, $occupation) = @_;

	$self -> log(debug => 'Entered save_occupation_record');

	my($table_name) = 'occupations';
	my(@field)      = (qw/creator_id occupation_title_id organization_id person_id/);
	my($data)       = {};
	my(%id)         =
	(
	 creator          => 1,
	 occupation_title => 1,
	 organization     => 1,
	 person           => 1,
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

		$$data{$field_name} = $$occupation{$_};
	}

	if ($context eq 'add')
	{
		$self -> util -> insert_hash_get_id($table_name, $data);

		$$occupation{'id'} = $$data{'id'} = $self -> util -> last_insert_id($table_name);
	}
	else
	{
		# TODO.

		my($sql) = "update $table_name set where id = $$occupation{'id'}";

	 	$self -> db -> dbh -> do($sql, {}, $data);
	}

} # End of save_occupation_record.

# --------------------------------------------------

sub save_occupation_title
{
	my($self, $title, $creator_id) = @_;

	$self -> log(debug => 'Entered save_occupation_title');

	my($data)       = {name => $title};
	my($table_name) = 'occupation_titles';

	$self -> util -> insert_hash_get_id($table_name, $data);

	my($id) = $self -> db -> dbh -> last_insert_id($table_name);

	return $id;

} # End of save_occupation_title.

# --------------------------------------------------

sub validate_occupation_ac_name
{
	my($self, $value) = @_;

	$self -> log(debug => 'Entered validate_occupation_ac_name');

	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from occupation_titles where name = ?', {Slice => {} }, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_occupation_ac_name.

# --------------------------------------------------

sub validate_organization_ac_name
{
	my($self, $value) = @_;

	$self -> log(debug => 'Entered validate_organization_ac_name');

	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from organizations where name = ?', {Slice => {} }, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_organization_ac_name.

# --------------------------------------------------

sub validate_person_ac_name
{
	my($self, $value) = @_;

	$self -> log(debug => 'Entered validate_person_ac_name');

	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from people where name = ?', {Slice => {} }, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_person_ac_name.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
