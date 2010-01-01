package CGI::Office::Contacts::View::Role::Report;

use JSON::XS;

use Moose::Role;

our $VERSION = '1.00';

# -----------------------------------------------

sub build_report_html
{
	my($self) = @_;
	my($html) = $self -> load_tmpl('report.tmpl');

	$self -> log(debug => 'Entered build_report_html');

	$html -> param(broadcasts          => $self -> build_select('broadcasts') );
	$html -> param(communication_types => $self -> build_select('communication_types') );
	$html -> param(genders             => $self -> build_select('genders') );
	$html -> param(reports             => $self -> build_select('reports') );
	$html -> param(report_entities     => $self -> build_select('report_entities') );
	$html -> param(roles               => $self -> build_select('roles') );
	$html -> param(sid                 => $self -> session -> id);

	# Make YUI happy by turning the HTML into 1 long line.
	# Also, the embedded single quotes need to be escaped, because in
	# Initialize.build_head_init(), the output of this sub is inserted
	# into this Javascript:
	# content: '$report_html'.

	$html = $html -> output;
	$html =~ s/\n//g;
	$html =~ s/'/\\'/g;

	return $html;

} # End of build_report_html.

# -----------------------------------------------

sub build_update_report_js
{
	my($self) = @_;

	$self -> log(debug => 'Entered build_update_report_js');

	my($js) = $self -> load_tmpl('report.js');

	$js -> param(form_action => ${$self -> config}{'form_action'});

	return $js -> output;

} # End of build_update_organization_js.

# -----------------------------------------------

sub format_record_report
{
	my($self, $record) = @_;
	my($count)         = 0;

	$self -> log(debug => 'Entered format_record_report');

	my(@row);

	for my $item (@$record)
	{
		push @row,
		{
			# These fields must match those in report.js.

			name   => $$item{'data'}{'name'},
			number => ++$count,
			type   => $$item{'type'},
		};
	}

	return [@row];

} # End of format_record_report.

# -----------------------------------------------

sub generate_record_report
{
	my($self, $result) = @_;

	$self -> log(debug => 'Entered generate_record_report');

	my($report) = {};

	for my $field_name ($result -> valids)
	{
		$$report{$field_name} = $result -> get_value($field_name) || '';
	}

	my($organizations_table_id) = ${$self -> db -> util -> table_map}{'organizations'}{'id'};
	my($people_table_id)        = ${$self -> db -> util -> table_map}{'people'}{'id'};
	my($report_entity)          = $self -> db -> util -> get_report_entities;
	my($organization_entity_id) = $$report_entity{'Organizations'};
	my($people_entity_id)       = $$report_entity{'People'};

	my($broadcast_id);
	my($communication_type_id);
	my($gender_id, $gender);
	my($item, @item);
	my($role_id, $role);

	# Filter out unwanted records.
	# 1. Does the user just want organizations, or just people, or both?

	if ($$report{'report_entity_id'} != $people_entity_id)
	{
		my($organization) = $self -> db -> organization -> get_organizations_for_report('-');

		for $item (@$organization)
		{
			$broadcast_id          = $$item{'broadcast_id'};
			$communication_type_id = $$item{'communication_type_id'};
			$role_id               = $$item{'role_id'};

			# 2. Does the user just want entities with a specific broadcast?

			if ( (! $$report{'ignore_broadcast'}) && ($$report{'broadcast_id'} != $broadcast_id) )
			{
				next;
			}

			# 3. Does the user just want entities with a specific communication_type?

			if ( (! $$report{'ignore_communication_type'}) && ($$report{'communication_type_id'} != $communication_type_id) )
			{
				next;
			}

			# 4. Does the user just want entities with a specific gender?
			#		Does not apply to organizations...
			# 5. Does the user just want entities or people with a specific role?

			if ( (! $$report{'ignore_role'}) && ($$report{'role_id'} != $role_id) )
			{
				next;
			}

			push @item,
			{
				data => {%$item},
				type => 'organization',
			};
		}
	}

	# 1. Does the user just want organizations, or just people, or both?

	if ($$report{'report_entity_id'} != $organization_entity_id)
	{
		my($person) = $self -> db -> person -> get_people_for_report;

		for $item (@$person)
		{
			$broadcast_id          = $$item{'broadcast_id'};
			$communication_type_id = $$item{'communication_type_id'};
			$gender_id             = $$item{'gender_id'};
			$role_id               = $$item{'role_id'};

			# 2. Does the user just want entities with a specific broadcast?

			if ( (! $$report{'ignore_broadcast'}) && ($$report{'broadcast_id'} != $broadcast_id) )
			{
				next;
			}

			# 3. Does the user just want entities with a specific communication_type?

			if ( (! $$report{'ignore_communication_type'}) && ($$report{'communication_type_id'} != $communication_type_id) )
			{
				next;
			}

			# 4. Does the user just want entities with a specific gender?

			if ( (! $$report{'ignore_gender'}) && ($$report{'gender_id'} != $gender_id) )
			{
				next;
			}

			# 5. Does the user just want entities with a specific role?

			if ( (! $$report{'ignore_role'}) && ($$report{'role_id'} != $role_id) )
			{
				next;
			}

			push @item,
			{
				data => {%$item},
				type => 'person',
			};
		}
	}

	return $self -> format_record_report([@item]);

} # End of generate_record_report.

# -----------------------------------------------

no Moose::Role;

1;
