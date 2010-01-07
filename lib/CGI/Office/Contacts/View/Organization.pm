package CGI::Office::Contacts::View::Organization;

use Moose;

extends 'CGI::Office::Contacts::View::Base';

use namespace::autoclean;

our $VERSION = '1.01';

# -----------------------------------------------

sub build_add_organization_html
{
	my($self) = @_;

	$self -> log(debug => 'Entered build_add_organization_html');

	my($html) = $self -> load_tmpl('update.organization.tmpl');

	$html -> param(action                => 201); # Add.
	$html -> param(broadcasts            => $self -> build_select('broadcasts') );
	$html -> param(communication_types   => $self -> build_select('communication_types') );
	$html -> param(context               => 'add');
	$html -> param(email_address_types_1 => $self -> build_select('email_address_types', '_1') );
	$html -> param(email_address_types_2 => $self -> build_select('email_address_types', '_2') );
	$html -> param(email_address_types_3 => $self -> build_select('email_address_types', '_3') );
	$html -> param(email_address_types_4 => $self -> build_select('email_address_types', '_4') );
	$html -> param(go                    => 'Add');
	$html -> param(name                  => '');
	$html -> param(phone_number_types_1  => $self -> build_select('phone_number_types', '_1') );
	$html -> param(phone_number_types_2  => $self -> build_select('phone_number_types', '_2') );
	$html -> param(phone_number_types_3  => $self -> build_select('phone_number_types', '_3') );
	$html -> param(phone_number_types_4  => $self -> build_select('phone_number_types', '_4') );
	$html -> param(reset_button          => 1);
	$html -> param(result                => 'New organization');
	$html -> param(roles                 => $self -> build_select('roles') );
	$html -> param(sid                   => $self -> session -> id);
	$html -> param(target_id             => 0);

	# Make YUI happy by turning the HTML into 1 long line.

	$html = $html -> output;
	$html =~ s/\n//g;

	return $html;

} # End of build_add_organization_html.

# -----------------------------------------------

sub build_add_organization_js
{
	my($self) = @_;

	$self -> log(debug => 'Entered build_add_organization_js');

	my($js) = $self -> load_tmpl('update.organization.js');

	$js -> param(context     => 'add');
	$js -> param(form_action => ${$self -> config}{'form_action'});

	return $js -> output;

} # End of build_add_organization_js.

# -----------------------------------------------

sub build_update_organization_html
{
	my($self, $target_id, $organization) = @_;

	$self -> log(debug => 'Entered build_update_organization_html');

	my($template) = $self -> load_tmpl('update.organization.tmpl');

	$template -> param(action              => 205); # Update.
	$template -> param(broadcasts          => $self -> build_select('broadcasts', '', $$organization{'broadcast_id'}) );
	$template -> param(communication_types => $self -> build_select('communication_types', '', $$organization{'communication_type_id'}) );
	$template -> param(context             => 'update');
	$template -> param(go                  => 'Update');
	$template -> param(home_page           => $$organization{'home_page'});
	$template -> param(name                => $$organization{'name'});
	$template -> param(reset_button        => 0);
	$template -> param(result              => $$organization{'name'});
	$template -> param(roles               => $self -> build_select('roles', '', $$organization{'role_id'}) );
	$template -> param(sid                 => $self -> session -> id);
	$template -> param(target_id           => $target_id);

	my($email);
	my($field);
	my($i);
	my($phone);
	my($type);

	# Hard-code 0 .. 3 email addresses and phone numbers.
	# If we don't then less than 3 means the type menus don't appear,
	# in which case we'd need a separate loop just to display them.

	for $i (0 .. 3)
	{
		$email = $i <= $#{$$organization{'email_phone'} } ? $$organization{'email_phone'}[$i]{'email'} : {};
		$phone = $i <= $#{$$organization{'email_phone'} } ? $$organization{'email_phone'}[$i]{'phone'} : {};
		$field = 'email_' . ($i + 1);
		$type  = 'email_address_types_' . ($i + 1);

		if ($$email{'address'})
		{
			$template -> param($field => $$email{'address'});
		}

		$template -> param($type => $self -> build_select('email_address_types', '_' . ($i + 1), $$email{'type_id'} || 1) );

		$field = 'phone_' . ($i + 1);
		$type  = 'phone_number_types_' . ($i + 1);

		if ($$phone{'number'})
		{
			$template -> param($field => $$phone{'number'});
		}

		$template -> param($type => $self -> build_select('phone_number_types', '_' . ($i + 1), $$phone{'type_id'} || 1) );
	}

	my($link);
	my(@people);

	for $field (@{$$organization{'people'} })
	{
		$link = qq|<a href="#tab1" onClick="display_person($$field{'person_id'})">$$field{'person_name'}</a>|;

		push @people,
		{
			occupation_id => $$field{'occupation_id'},
			name          => $link,
			title         => $$field{'occupation_title'},
		};
	}

	$template -> param(people_loop => [@people]);

	# Make YUI happy by turning the HTML into 1 long line.

	$template = $template -> output;
	$template =~ s/\n//g;

	return $template;

} # End of build_update_organization_html.

# -----------------------------------------------

sub build_update_organization_js
{
	my($self) = @_;

	$self -> log(debug => 'Entered build_update_organization_js');

	my($js) = $self -> load_tmpl('update.organization.js');

	$js -> param(context     => 'update');
	$js -> param(form_action => ${$self -> config}{'form_action'});

	return $js -> output;

} # End of build_update_organization_js.

# -----------------------------------------------

sub format_search_result
{
	my($self, $name, $organizations) = @_;

	$self -> log(debug => 'Entered format_search_result');

	my(@row);

	if ($name && ($#$organizations >= 0) )
	{
		my($email);
		my($i);
		my($organization);
		my($phone);

		for $organization (@$organizations)
		{
			$name = $$organization{'name'};

			for $i (0 .. $#{$$organization{'email_phone'} })
			{
				$email  = $$organization{'email_phone'}[$i]{'email'};
				$phone  = $$organization{'email_phone'}[$i]{'phone'};

				push @row,
				{
					email      => qq|<a href="mailto:$$email{'address'}">$$email{'address'}</a>|,
					email_type => $$email{'type_name'},
					id         => $$organization{'id'},
					name       => $name ? qq|<a href="#tab1" onClick="display_organization($$organization{'id'})">$name</a>| : '',
					phone      => $$phone{'number'},
					phone_type => $$phone{'type_name'},
					role       => $name ? $self -> db -> util -> get_role_via_id($$organization{'role_id'}) : '',
				};

				# Blanking out the name means it is not repeated in the output (HTML) table.

				$name = '';
			}
		}
	}

	return [@row];

} # End of format_search_result.

# -----------------------------------------------

sub report_add
{
	my($self, $user_id, $result) = @_;

	$self -> log(debug => 'Entered report_add');

	my($template) = $self -> load_tmpl('update.report.tmpl');

	if ($result -> success)
	{
		# Force the user_id into the organizations's record, so it is available elsewhere.
		# Note: This is the user_id of the person logged on.

		my($organization)            = {};
		$$organization{'creator_id'} = $user_id;

		for my $field_name ($result -> valids)
		{
			$$organization{$field_name} = $result -> get_value($field_name) || '';
		}

		$self -> log(debug => '-' x 50);
		$self -> log(debug => "Adding organization $$organization{'name'}...");
		$self -> log(debug => "$_ => $$organization{$_}") for sort keys %$organization;
		$self -> log(debug => '-' x 50);

		$template -> param(message => $self -> db -> organization -> add($organization) );
	}
	else
	{
		$self -> db -> util -> build_error_report($result, $template);

		$template -> param(message => 'Failed to add organization');
	}

	return $template -> output;

} # End of report_add.

# -----------------------------------------------

sub report_update
{
	my($self, $user_id, $id, $result) = @_;

	$self -> log(debug => 'Entered report_update');

	my($template) = $self -> load_tmpl('update.report.tmpl');

	if ($result -> success)
	{
		# Force the user_id into the person's record, so it is available elsewhere.
		# Note: This is the user_id of the person logged on.

		my($organization)            = {};
		$$organization{'creator_id'} = $user_id;

		# Force the organization's id to be the id from the form.

		$$organization{'id'} = $id;

		for my $field_name ($result -> valids)
		{
			$$organization{$field_name} = $result -> get_value($field_name) || '';
		}

		$self -> log(debug => '-' x 50);
		$self -> log(debug => "Updating organization $$organization{'name'}...");
		$self -> log(debug => "$_ => $$organization{$_}") for sort keys %$organization;
		$self -> log(debug => '-' x 50);

		$template -> param(message => $self -> db -> organization -> update($organization) );
	}
	else
	{
		$self -> db -> util -> build_error_report($result, $template);

		$template -> param(message => 'Failed to add organization');
	}

	return $template -> output;

} # End of report_update.

# -----------------------------------------------

no Moose;__PACKAGE__ -> meta -> make_immutable;

1;
