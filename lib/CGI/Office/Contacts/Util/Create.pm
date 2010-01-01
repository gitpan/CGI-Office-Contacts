package CGI::Office::Contacts::Util::Create;

use Carp;

use CGI::Office::Contacts::Database;
use CGI::Office::Contacts::Util::Config;

use DBI;

use DBIx::Admin::CreateTable;

use FindBin::Real;

use Log::Dispatch;
use Log::Dispatch::DBI;

use Time::Elapsed;

use Moose;

has config         => (is => 'rw', isa => 'HashRef');
has creator        => (is => 'rw', isa => 'DBIx::Admin::CreateTable');
has db             => (is => 'rw', isa => 'CGI::Office::Contacts::Database');
has last_insert_id => (is => 'rw', isa => 'Int');
has logger         => (is => 'rw', isa => 'Log::Dispatch');
has start_time     => (is => 'rw', isa => 'Int', default => time);
has table_names    => (is => 'rw', isa => 'HashRef');
has time_option    => (is => 'rw', isa => 'Str');
has verbose        => (is => 'rw', isa => 'Int', default => 0);

use namespace::autoclean;

our $VERSION = '1.00';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> config(CGI::Office::Contacts::Util::Config -> new -> config);
	$self -> logger(Log::Dispatch -> new);
	$self -> db(CGI::Office::Contacts::Database -> new
	(
		config => $self -> config,
		logger => $self -> logger
	) );
	$self -> creator(DBIx::Admin::CreateTable -> new(dbh => $self -> db -> dbh, verbose => 0) );
	$self -> time_option($self -> creator -> db_vendor =~ /(?:MySQL|Postgres)/i ? '(0) without time zone' : '');

	# SQLite insists we create the table before calling Log::Dispatch::DBI.
	# But that means calling drop_all_tables() and then create_all_tables()
	# won't work unless we first re-create this log table. So we create it
	# first, and then if necessary, re-create it in create_all_tables().
	# Lastly, use eval{} in case the log table already exists.

	if (! $self -> log_table_exists)
	{
		$self -> create_log_table;
	};

	$self -> logger -> add
	(
		Log::Dispatch::DBI -> new
		(
		 dbh       => $self -> db -> dbh,
		 min_level => 'info',
		 name      => 'Contacts',
		)
	);
	$self -> logger -> log(level => 'info', message => 'Start run');

	return $self;

}	# End of BUILD.

# -----------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	# See comment above re SQLite for why we do this.

	if (! $self -> log_table_exists)
	{
		$self -> create_log_table;
	};

	# Warning: The order is important.

	my($method);
	my($table_name);

	for $table_name (qw/
sessions
broadcasts
communication_types
genders
report_entities
reports
yes_nos
titles
roles
people
organizations
spouses
email_address_types
phone_number_types
email_addresses
phone_numbers
email_organizations
email_people
phone_organizations
phone_people
occupation_titles
occupations
table_names
notes
/)
	{
		$method = "create_${table_name}_table";

		$self -> $method;
	}

}	# End of create_all_tables.

# --------------------------------------------------

sub create_broadcasts_table
{
	my($self)        = @_;
	my($table_name)  = 'broadcasts';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_broadcasts_table.

# --------------------------------------------------

sub create_communication_types_table
{
	my($self)        = @_;
	my($table_name)  = 'communication_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_communication_types_table.

# --------------------------------------------------

sub create_email_addresses_table
{
	my($self)        = @_;
	my($table_name)  = 'email_addresses';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
email_address_type_id integer not null references email_address_types(id),
address varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_email_addresses_table.

# --------------------------------------------------

sub create_email_address_types_table
{
	my($self)        = @_;
	my($table_name)  = 'email_address_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_email_address_types_table.

# --------------------------------------------------

sub create_email_organizations_table
{
	my($self)        = @_;
	my($table_name)  = 'email_organizations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
email_address_id integer not null references email_addresses(id),
organization_id integer not null references organizations(id)
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_email_organizations_table.

# --------------------------------------------------

sub create_email_people_table
{
	my($self)        = @_;
	my($table_name)  = 'email_people';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
email_address_id integer not null references email_addresses(id),
person_id integer not null references people(id)
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_email_people_table.

# --------------------------------------------------

sub create_genders_table
{
	my($self)        = @_;
	my($table_name)  = 'genders';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_genders_table.

# --------------------------------------------------

sub create_log_table
{
	my($self)        = @_;
	my($table_name)  = 'log';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
level varchar(9) not null,
message varchar(255) not null,
timestamp timestamp $time_option not null default current_timestamp
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_log_table.

# --------------------------------------------------

sub create_notes_table
{
	my($self)        = @_;
	my($table_name)  = 'notes';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
creator_id integer not null,
table_id integer not null,
table_name_id integer not null references table_names(id),
note text not null,
timestamp timestamp $time_option not null default current_timestamp
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_notes_table.

# --------------------------------------------------

sub create_occupation_titles_table
{
	my($self)        = @_;
	my($table_name)  = 'occupation_titles';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_occupation_titles_table.

# --------------------------------------------------

sub create_occupations_table
{
	my($self)        = @_;
	my($table_name)  = 'occupations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
creator_id integer not null,
occupation_title_id integer not null references occupation_titles(id),
organization_id integer not null references organizations(id),
person_id integer not null references people(id)
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_occupations_table.

# --------------------------------------------------

sub create_organizations_table
{
	my($self)        = @_;
	my($table_name)  = 'organizations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
broadcast_id integer not null references broadcasts(id),
communication_type_id integer not null references communication_types(id),
creator_id integer not null,
role_id integer not null references roles(id),
home_page varchar(255) not null,
name varchar(255) not null,
timestamp timestamp $time_option not null default current_timestamp
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_organizations_table.

# --------------------------------------------------

sub create_people_table
{
	my($self)        = @_;
	my($table_name)  = 'people';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
broadcast_id integer not null references broadcasts(id),
communication_type_id integer not null references communication_types(id),
creator_id integer not null,
gender_id integer not null references genders(id),
role_id integer not null references roles(id),
title_id integer not null references titles(id),
date_of_birth date not null,
given_names varchar(255) not null,
home_page varchar(255) not null,
name varchar(255) not null,
preferred_name varchar(255) not null,
surname varchar(255) not null,
timestamp timestamp $time_option not null default current_timestamp
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_people_table.

# --------------------------------------------------

sub create_phone_numbers_table
{
	my($self)        = @_;
	my($table_name)  = 'phone_numbers';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
phone_number_type_id integer not null references phone_number_types(id),
number varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_phone_numbers_table.

# --------------------------------------------------

sub create_phone_number_types_table
{
	my($self)        = @_;
	my($table_name)  = 'phone_number_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_phone_number_types_table.

# --------------------------------------------------

sub create_phone_organizations_table
{
	my($self)        = @_;
	my($table_name)  = 'phone_organizations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
organization_id integer not null references organizations(id),
phone_number_id integer not null references phone_numbers(id)
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_phone_organizations_table.

# --------------------------------------------------

sub create_phone_people_table
{
	my($self)        = @_;
	my($table_name)  = 'phone_people';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
person_id integer not null references people(id),
phone_number_id integer not null references phone_numbers(id)
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_phone_people_table.

# --------------------------------------------------

sub create_report_entities_table
{
	my($self)        = @_;
	my($table_name)  = 'report_entities';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_report_entities_table.

# --------------------------------------------------

sub create_reports_table
{
	my($self)        = @_;
	my($table_name)  = 'reports';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_reports_table.

# --------------------------------------------------

sub create_roles_table
{
	my($self)        = @_;
	my($table_name)  = 'roles';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_roles_table.

# -----------------------------------------------

sub create_sessions_table
{
	my($self)       = @_;
	my($table_name) = 'sessions';
	my($type)       = $self -> creator -> db_vendor eq 'ORACLE' ? 'long' : 'text';
	my($result)     = $self -> creator -> create_table(<<SQL, {no_sequence => 1});
create table $table_name
(
id char(32) not null primary key,
a_session $type not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_sessions_table.

# --------------------------------------------------

sub create_spouses_table
{
	my($self)        = @_;
	my($table_name)  = 'spouses';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
person_id integer not null references people(id),
spouse_id integer not null references people(id)
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_spouses_table.

# --------------------------------------------------

sub create_table_names_table
{
	my($self)        = @_;
	my($table_name)  = 'table_names';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
singular varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_table_names_table.

# --------------------------------------------------

sub create_titles_table
{
	my($self)        = @_;
	my($table_name)  = 'titles';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_titles_table.

# --------------------------------------------------

sub create_yes_nos_table
{
	my($self)        = @_;
	my($table_name)  = 'yes_nos';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_yes_nos_table.

# -----------------------------------------------

sub DEMOLISH
{
	my($self) = @_;

	$self -> pwint("Elapsed time: " . Time::Elapsed::elapsed(time - $self -> start_time) );

} # End of DEMOLISH.

# -----------------------------------------------

sub drop_table
{
	my($self, $table_name) = @_;

	$self -> creator -> drop_table($table_name);

} # End of drop_table.

# -----------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	my($table_name);

	for $table_name (qw/
email_organizations
email_people
phone_organizations
phone_people
email_addresses
phone_numbers
occupations
occupation_titles
email_address_types
phone_number_types
notes
table_names
spouses
organizations
people
broadcasts
communication_types
genders
reports
report_entities
titles
yes_nos
roles
sessions
log
/)
	{
		$self -> drop_table($table_name);
	}

}	# End of drop_all_tables.

# -----------------------------------------------

sub drop_and_create_all_tables
{
	my($self) = @_;

	$self -> drop_all_tables;
	$self -> create_all_tables;

	return 0;

} # End of drop_and_create_all_tables.

# -----------------------------------------------

sub dump
{
	my($self, $table_name) = @_;

	if ($self -> verbose < 2)
	{
		return;
	}

	my($row) = $self -> db -> dbh -> selectall_arrayref("select * from $table_name");

	$self -> pwint("\tTable: $table_name:");

	for my $record (@$row)
	{
		$self -> pwint("\t" . join('. ', map{"$_ => $$record{$_}"} sort keys %$record) );
	}

	$self -> pwint;

} # End of dump.

# -----------------------------------------------

sub get_table_names
{
	my($self) = @_;

	return $self -> db -> util -> select_map('select name, id from table_names');

} # End of get_table_names.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;

	$self -> logger -> log(level => 'info', message => $s ? $s : '');

}	# End of log.

# -----------------------------------------------

sub log_table_exists
{
	my($self)   = @_;
	my($exists) = 0;
	my($sth)    = $self -> db -> dbh -> table_info(undef, undef, '%', 'TABLE');

	my($table_data, $table_name);

	while ($table_data = $sth -> fetchrow_hashref)
	{
		if ($$table_data{'TABLE_NAME'} eq 'log')
		{
			$exists = 1;
		}
	}

	return $exists;

} # End of log_table_exists.

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	$self -> pwint("Populating tables for database 'contacts'");

	# Warning: The order of these calls is important.

	$self -> populate_broadcasts_table;
	$self -> populate_communication_types_table;
	$self -> populate_genders_table;
	$self -> populate_report_entities_table;
	$self -> populate_reports_table;
	$self -> populate_roles_table;
	$self -> populate_titles_table;
	$self -> populate_yes_nos_table;

	$self -> populate_table_names_table;

	$self -> table_names($self -> get_table_names);

	$self -> populate_email_address_types_table;
	$self -> populate_email_addresses_table;

	$self -> populate_phone_number_types_table;
	$self -> populate_phone_numbers_table;

	$self -> populate_occupation_titles_table;
	$self -> populate_organizations_table;

	$self -> pwint('Finished populating tables');

	return 0;

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_broadcasts_table
{
	my($self)       = @_;
	my($table_name) = 'broadcasts';
	my($data)       = $self -> read_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_broadcasts_table.

# -----------------------------------------------

sub populate_communication_types_table
{
	my($self)       = @_;
	my($table_name) = 'communication_types';
	my($data)       = $self -> read_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_communication_types_table.

# -----------------------------------------------

sub populate_email_address_types_table
{
	my($self)       = @_;
	my($table_name) = 'email_address_types';
	my($data)       = $self -> read_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_email_address_types_table.

# -----------------------------------------------

sub populate_email_addresses_table
{
	my($self)       = @_;
	my($table_name) = 'email_addresses';
	my($data)       = $self -> read_file("$table_name.txt");

	my(@field, %field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);
		%field = map{($_ => shift @field)} (qw/email_address_type_id address/);

		$self -> db -> util -> insert_hash_get_id($table_name, \%field);
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_email_addresses_table.

# -----------------------------------------------

sub populate_email_people_table
{
	my($self)       = @_;
	my($table_name) = 'email_people';
	my($data)       = $self -> read_file("$table_name.txt");

	my(@field, %field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);
		%field = map{($_ => shift @field)} (qw/email_address_id person_id/);

		$self -> db -> util -> insert_hash_get_id($table_name, \%field);
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_email_people_table.

# -----------------------------------------------

sub populate_fake_data
{
	my($self) = @_;

	$self -> populate_people_table;
	$self -> populate_email_people_table;
	$self -> populate_phone_people_table;

	return 0;

} # End of populate_fake_data.

# -----------------------------------------------

sub populate_genders_table
{
	my($self)       = @_;
	my($table_name) = 'genders';
	my($data)       = $self -> read_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_genders_table.

# -----------------------------------------------

sub populate_occupation_titles_table
{
	my($self)       = @_;
	my($table_name) = 'occupation_titles';
	my($data)       = $self -> read_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_occupation_titles_table.

# -----------------------------------------------

sub populate_organizations_table
{
	my($self)       = @_;
	my($table_name) = 'organizations';
	my($data)       = $self -> read_file("$table_name.txt");

	my(@field, %field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);
		%field = map{($_ => shift @field)} (qw/broadcast_id communication_type_id creator_id role_id home_page name/);

		$self -> db -> util -> insert_hash_get_id($table_name, \%field);
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_organizations_table.

# -----------------------------------------------

sub populate_people_table
{
	my($self)       = @_;
	my($table_name) = 'people';
	my($data)       = $self -> read_file("$table_name.txt");

	my(@field, %field);

	for (@$data)
	{
		@field             = split(/\s*,\s*/, $_);
		%field             = map{($_ => shift @field)} (qw/broadcast_id communication_type_id creator_id gender_id role_id title_id date_of_birth given_names home_page name preferred_name surname/);
		$self -> db -> util -> insert_hash_get_id($table_name, \%field);
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_people_table.

# -----------------------------------------------

sub populate_phone_number_types_table
{
	my($self)       = @_;
	my($table_name) = 'phone_number_types';
	my($data)       = $self -> read_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_phone_number_types_table.

# -----------------------------------------------

sub populate_phone_numbers_table
{
	my($self)       = @_;
	my($table_name) = 'phone_numbers';
	my($data)       = $self -> read_file("$table_name.txt");

	my(@field, %field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);
		%field = map{($_ => shift @field)} (qw/phone_number_type_id number/);

		$self -> db -> util -> insert_hash_get_id($table_name, \%field);
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_phone_numbers_table.

# -----------------------------------------------

sub populate_phone_people_table
{
	my($self)       = @_;
	my($table_name) = 'phone_people';
	my($data)       = $self -> read_file("$table_name.txt");

	my(@field, %field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);
		%field = map{($_ => shift @field)} (qw/person_id phone_number_id/);

		$self -> db -> util -> insert_hash_get_id($table_name, \%field);
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_phone_people_table.

# -----------------------------------------------

sub populate_report_entities_table
{
	my($self)       = @_;
	my($table_name) = 'report_entities';
	my($data)       = $self -> read_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_report_entities_table.

# -----------------------------------------------

sub populate_reports_table
{
	my($self)       = @_;
	my($table_name) = 'reports';
	my($data)       = $self -> read_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_reports_table.

# -----------------------------------------------

sub populate_roles_table
{
	my($self)       = @_;
	my($table_name) = 'roles';
	my($data)       = $self -> read_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_roles_table.

# -----------------------------------------------

sub populate_table_names_table
{
	my($self)       = @_;
	my($table_name) = 'table_names';
	my($data)       = $self -> read_file("$table_name.txt");

	my(@field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);

		$self -> db -> util -> insert_hash_get_id($table_name, {name => $field[0], singular => $field[1]});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_table_names_table.

# -----------------------------------------------

sub populate_titles_table
{
	my($self)       = @_;
	my($table_name) = 'titles';
	my($data)       = $self -> read_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_titles_table.

# -----------------------------------------------

sub populate_yes_nos_table
{
	my($self)       = @_;
	my($table_name) = 'yes_nos';
	my($data)       = $self -> read_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_yes_nos_table.

# -----------------------------------------------

sub pwint
{
	my($self, $msg, $level) = @_;
	$msg   ||= '';
	$level ||= 0;

	if ($self -> verbose > $level)
	{
		print "$msg\n";
	}

} # End of pwint.

# --------------------------------------------------

sub read_file
{
	my($self, $input_file_name) = @_;
	$input_file_name            = FindBin::Real::Bin . "/../data/$input_file_name";

	open(INX, $input_file_name) || Carp::croak("Can't open($input_file_name): $!");
	my(@line) = grep{! /^$/ && ! /^#/} map{s/^\s+//; s/\s+$//; $_} <INX>;
	close INX;
	chomp @line;

	return [@line];

}	# End of read_file.

# -----------------------------------------------

sub report
{
	my($self, $table_name, $message, $result) = @_;

	if ($result)
	{
		Carp::croak "Table '$table_name' $result. \n";
	}
	elsif ($self -> verbose)
	{
		print STDERR "Table '$table_name' $message. \n";
	}

}	# End of report.

# -----------------------------------------------

sub report_all_tables
{
	my($self)       = @_;
	my($table_name) = 'table_names';
	my($data)       = $self -> read_file("$table_name.txt");

	my($count);
	my(@field);

	for (sort @$data)
	{
		@field = split(/\s*,\s*/, $_);
		$count = $self -> db -> dbh -> selectrow_hashref("select count(*) from $field[0]");
		$count = $count ? $$count{'count'} : 0;

		print "Table: $field[0]. Row count: $count. \n";
	}

}	# End of report_all_tables.

# --------------------------------------------------

sub run
{
	my($self) = @_;

} # End of run.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
