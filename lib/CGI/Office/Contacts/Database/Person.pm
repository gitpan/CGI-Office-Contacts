package CGI::Office::Contacts::Database::Person;

use Moose;

extends 'CGI::Office::Contacts::Database::Base';

use namespace::autoclean;

our $VERSION = '1.00';

# --------------------------------------------------

sub add
{
	my($self, $person) = @_;

	$self -> log(debug => 'Entered add');

	# Does a person with this name already exist?

	my($id) = $self -> get_person_id_via_name($$person{'name'} || '');

	$self -> save_person_transaction('add', $person);

	my($result) = "Added '$$person{'name'}'";

	if ($id)
	{
		$result .= '<br /><span class="dfv_errors">Note: This name was on file already</span>';
	}

	return $result;

} # End of add.

# -----------------------------------------------

sub delete
{
	my($self, $id, $input_name) = @_;

	$self -> log(debug => "Entered delete: $input_name");

	my($name) = $self -> db -> dbh -> selectrow_hashref('select name from people where broadcast_id != 3 and id = ?', {}, $id);
	$name     = $name ? $$name{'name'} : '';

	$self -> log(debug => "delete_person. name result: " . $name ? $name : "N/A");

	my($result);

	if ($name && ($name eq $input_name) )
	{
		$self -> db -> dbh -> do("update people set broadcast_id = 3 where id = ?", {}, $id);

		$result = "Deleted '$input_name'";
	}
	else
	{
		$result = "'$input_name' not deleted: Not on file";
	}

	return $result;

} # End of delete.

# -----------------------------------------------

sub get_people
{
	my($self, $user_id, $name) = @_;

	$self -> log(debug => "Entered get_people: $name");

	my($broadcast)  = $self -> db -> util -> get_broadcasts;
	my($deleted_id) = $$broadcast{'(Hidden)'};
	my($pop)        = $self -> db -> dbh -> selectall_arrayref("select * from people where upper(name) like ? order by name", {Slice => {} }, uc "%$name%");
	my($result)     = [];

	$self -> log(debug => "People count: @{[scalar @$pop]}");

	my($email);
	my($occupation);
	my($person);
	my($skip);

	for $person (@$pop)
	{
		# Filter out the people whose broadcast status is no-one.

		$skip = 0;

		if ($$person{'broadcast_id'} == $deleted_id)
		{
			$skip = 1;
		}

		# Let the user see their own record.

		if ($$person{'id'} == $user_id)
		{
			$skip = 0;
		}

		# Let the user see records they created.

		if ( ($user_id > 0) && ($$person{'creator_id'} == $user_id) )
		{
			$skip = 0;
		}

		if ($skip)
		{
			next;
		}

		$email      = $self -> get_persons_emails_and_phones($$person{'id'});
		$occupation = $self -> get_persons_occupations($$person{'id'});

		push @$result,
		{
			broadcast_id          => $$person{'broadcast_id'},
			communication_type_id => $$person{'communication_type_id'},
			email_phone           => $email,
			gender_id             => $$person{'gender_id'},
			given_names           => $$person{'given_names'},
			home_page             => $$person{'home_page'},
			id                    => $$person{'id'},
			name                  => $$person{'name'},
			occupation            => $occupation,
			preferred_name        => $$person{'preferred_name'},
			role_id               => $$person{'role_id'},
			surname               => $$person{'surname'},
			title_id              => $$person{'title_id'},
		};
	}

	return $result;

} # End of get_people.

# -----------------------------------------------

sub get_people_for_report
{
	my($self) = @_;

	$self -> log(debug => 'Entered get_people_for_report');

	return $self -> db -> dbh -> selectall_arrayref('select * from people', {Slice => {} }) || [];

} # End of get_people_for_report.

# -----------------------------------------------

sub get_people_via_name_prefix
{
	my($self, $prefix) = @_;

	$self -> log(debug => "Entered get_people_via_name_prefix: $prefix");

	$prefix      = uc $prefix;
	my($id2name) = $self -> db -> dbh -> select_map("select id, name from people where broadcast_id != 3 and upper(name) like '$prefix%'");

	my($email_user, $email_address);
	my($id, $i);
	my(@result);

	for $id (keys %$id2name)
	{
		$email_user = $self -> db -> email_address -> get_email_address_id_via_person($id);

		for $i (0 .. $#$email_user)
		{
			$email_address = $self -> db -> email_address -> get_email_address_via_id($$email_user[$i]{'email_address_id'});

			push @result, ["$$id2name{$id} ($$email_address{'address'})", $id];
		}

		if ($#$email_user < 0)
		{
			push @result, [$$id2name{$id}, $id];
		}
	}

	return [@result];

} # End of get_people_via_name_prefix.

# -----------------------------------------------

sub get_person
{
	my($self, $user_id, $id) = @_;

	$self -> log(debug => "Entered get_person: $id");

	# Filter out people with the same name but the 'wrong' id.
	my($name)   = $self -> db -> dbh -> selectrow_hashref('select name from people where broadcast_id != 3 and id = ?', {}, $id);
	$name       = $name ? $$name{'name'} : '';
	my($people) = $name ? [grep{$$_{'id'} == $id} @{$self -> get_people($user_id, $name)}] : [];

	return $people;

} # End of get_person.

# -----------------------------------------------

sub get_person_id_via_name
{
	my($self, $name) = @_;

	$self -> log(debug => "Entered get_person_id_via_name: $name");

	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from people where broadcast_id != 3 and name = ?', {}, $name);

	return $id ? $$id{'id'} : 0;

} # End of get_person_id_via_name.

# -----------------------------------------------

sub get_person_via_id
{
	my($self, $id) = @_;

	$self -> log(debug => "Entered get_person_via_id: $id");

	return $self -> db -> dbh -> selectrow_hashref('select * from people where broadcast_id != 3 and id = ?', {}, $id);

} # End of get_person_via_id.

# -----------------------------------------------

sub get_persons_emails_and_phones
{
	my($self, $id)  = @_;

	$self -> log(debug => "Entered get_persons_emails_and_phones: $id");

	my($email_user) = $self -> db -> email_address -> get_email_address_id_via_person($id);
	my($phone_user) = $self -> db -> phone_number -> get_phone_number_id_via_person($id);
	my($max)        = ($#$email_user > $#$phone_user) ? $#$email_user : $#$phone_user;

	my(@data);
	my($email_address);
	my($i);
	my($phone_number);

	for $i (0 .. $max)
	{
		if ($i <= $#$email_user)
		{
			$email_address = $self -> db -> email_address -> get_email_address_via_id($$email_user[$i]{'email_address_id'});
		}
		else
		{
			$email_address = {address => '', type_id => 0, type_name => ''};
		}

		if ($i <= $#$phone_user)
		{
			$phone_number = $self -> db -> phone_number -> get_phone_number_via_id($$phone_user[$i]{'phone_number_id'});
		}
		else
		{
			$phone_number = {number => '', type_id => 0, type_name => ''};
		}

		push @data,
		{
			email =>
			{
				address   => $$email_address{'address'},
				type_id   => $$email_address{'type_id'},
				type_name => $$email_address{'type_name'},
			},
			phone =>
			{
				number    => $$phone_number{'number'},
				type_id   => $$phone_number{'type_id'},
				type_name => $$phone_number{'type_name'},
			},
		};

	}

	if ($#data < 0)
	{
		$data[0] =
		{
			email =>
			{
				address   => '',
				type_id   => 0,
				type_name => '',
			},
			phone =>
			{
				number    => '',
				type_id   => 0,
				type_name => '',
			},
		};
	}

	return [@data];

} # End of get_persons_emails_and_phones.

# -----------------------------------------------

sub get_persons_occupations
{
	my($self, $id) = @_;

	$self -> log(debug => "Entered get_persons_occupations: $id");

	my($occupation) = $self -> db -> occupation -> get_occupation_id_via_person($id);

	my(@data);
	my($i);
	my($occ);

	for $i (0 .. $#$occupation)
	{
		$occ = $self -> db -> occupation -> get_occupation_via_id($$occupation[$i]);

		push @data,
		{
			occupation_id     => $$occupation[$i]{'id'},
			occupation_title  => $$occ{'title'},
			organization_id   => $$occ{'organization_id'},
			organization_name => $$occ{'organization_name'},
		};
	}

	@data = sort
	{
		$$a{'organization_name'} cmp $$b{'organization_name'} || $$a{'occupation_title'} cmp $$b{'occupation_title'}
	} @data;

	return [@data];

} # End of get_persons_occupations.

# --------------------------------------------------

sub save_person_record
{
	my($self, $context, $person) = @_;

	$self -> log(debug => 'Entered save_person_record');

	my($table_name)              = 'people';
	my(@field)                   = (qw/broadcast_id communication_type_id creator_id date_of_birth gender_id given_names home_page name preferred_name role_id surname title_id/);
	$$person{'date_of_birth'}    = 'now()'; # Not yet in use.
	my($data)                    = {};

	for (@field)
	{
		$$data{$_} = $$person{$_};
	}

	if ($context eq 'add')
	{
		$self -> db -> util -> insert_hash_get_id($table_name, $data);

		$$person{'id'} = $$data{'id'} = $self -> db -> util -> last_insert_id($table_name);

	}
	else
	{
		my($s) = join(', ', map{"$_ = ?"} sort keys %$data);
		$s     = "update $table_name set $s where id = $$person{'id'}";

	 	$self -> db -> dbh -> do($s, {}, map{$$data{$_} } sort keys %$data);
	}

} # End of save_person_record.

# --------------------------------------------------

sub save_person_transaction
{
	my($self, $context, $person) = @_;

	$self -> log(debug => 'Entered save_person_transaction');

	# Save person.

	$self -> save_person_record($context, $person);

	# Save email addresses.

	my($email_people) = $self -> db -> email_address -> get_email_address_id_via_person($$person{'id'});

	my($address);
	my($id);
	my(%old_address);

	for $id (@$email_people)
	{
		$address                            = $self -> db -> email_address -> get_email_address_via_id($$id{'email_address_id'});
		$old_address{$$address{'address'} } =
		{                                           # Table:
			people_id  => $$id{'id'},               # email_people
			address_id => $$id{'email_address_id'}, # email_addresses
			type_id    => $$address{'type_id'},     # email_address_types
			type_name  => $$address{'type_name'},   # email_address_types
		};
	}

	my($count);
	my(%new_address);
	my(%new_type);

	for $count (map{s/email_//; $_} grep{/email_\d/} sort keys %$person)
	{
		$address = $$person{"email_$count"};

		if ($address)
		{
			$new_address{$address} = $count;
			$new_type{$address}    = $$person{"email_address_type_id_$count"};
		}
	}

	my(%address) = (%old_address, %new_address);

	for $address (keys %address)
	{
		if ($old_address{$address} && $new_address{$address})
		{
			# The email address type might have changed.

			if ($old_address{$address}{'type_id'} != $new_type{$address})
			{
				$old_address{$address}{'type_id'} = $new_type{$address};

				$self -> db -> email_address -> update_email_address_type($$person{'creator_id'}, $old_address{$address});
			}
		}
		elsif ($old_address{$address}) # And ! new address.
		{
			# Address has vanished, so delete old address.

			$self -> db -> email_address -> delete_email_address_person($$person{'creator_id'}, $old_address{$address}{'people_id'});
		}
		else # ! old address, just new one.
		{
			# Address has appeared, so add new address.

			$self -> db -> email_address -> save_email_address_for_person($context, $person, $new_address{$address});
		}
	}

	# Save phone numbers.

	my($phone_people) = $self -> db -> phone_number -> get_phone_number_id_via_person($$person{'id'});

	my($number);
	my(%old_number);

	for $id (@$phone_people)
	{
		$number                          = $self -> db -> phone_number -> get_phone_number_via_id($$id{'phone_number_id'});
		$old_number{$$number{'number'} } =
		{                                         # Table:
			people_id => $$id{'id'},              # phone_people
			number_id => $$id{'phone_number_id'}, # phone_numbers
			type_id   => $$number{'type_id'},     # phone_number_types
			type_name => $$number{'type_name'},   # phone_number_types
		};
	}

	%new_type = ();

	my(%new_number);

	for $count (map{s/phone_//; $_} grep{/phone_\d/} sort keys %$person)
	{
		$number = $$person{"phone_$count"};

		if ($number)
		{
			$new_number{$number} = $count;
			$new_type{$number}   = $$person{"phone_number_type_id_$count"};
		}
	}

	my(%number) = (%old_number, %new_number);

	for $number (keys %number)
	{
		if ($old_number{$number} && $new_number{$number})
		{
			# The phone number type might have changed.

			if ($old_number{$number}{'type_id'} != $new_type{$number})
			{
				$old_number{$number}{'type_id'} = $new_type{$number};

				$self -> db -> phone_number -> update_phone_number_type($$person{'creator_id'}, $old_number{$number});
			}
		}
		elsif ($old_number{$number}) # And ! new number.
		{
			# Number has vanished, so delete old number.

			$self -> db -> phone_number -> delete_phone_number_person($$person{'creator_id'}, $old_number{$number}{'people_id'});
		}
		else # ! old number, just new one.
		{
			# Number has appeared, so add new number.

			$self -> db -> phone_number -> save_phone_number_for_person($context, $person, $new_number{$number});
		}
	}

} # End of save_person_transaction.

# --------------------------------------------------

sub update
{
	my($self, $person) = @_;

	$self -> log(debug => 'Entered update');

	my($result);

	$self -> save_person_transaction('update', $person);

	$result = "Updated '$$person{'name'}'";

	return $result;

} # End of update.

# --------------------------------------------------

no Moose;__PACKAGE__ -> meta -> make_immutable;

1;
