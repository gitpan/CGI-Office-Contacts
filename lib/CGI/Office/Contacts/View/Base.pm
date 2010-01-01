package CGI::Office::Contacts::View::Base;

use DateTime;

use HTML::Template;

use Path::Class; # For file().

use Moose;

extends 'CGI::Office::Contacts::Database::Base';

has config    => (is => 'ro', isa => 'HashRef', required => 1);
has session   => (is => 'ro', isa => 'CGI::Session', required => 1);
has tmpl_path => (is => 'ro', isa => 'Str', required => 1);

use namespace::autoclean;

our $VERSION = '1.00';

# -----------------------------------------------

sub build_select
{
	my($self, $table_name, $suffix, $default, $limit, $on_change) = @_;
	my($table_map) = $self -> db -> util -> table_map;
	my($singular)  = $$table_map{$table_name}{'singular'};
	$suffix        .= '';
	my($id_name)   = "${singular}_id$suffix";
	$default       ||= 1;
	$limit         ||= '';
	$on_change     ||= '';
	my($method)    = "get_$table_name";
	my($option)    = $self -> db -> util -> $method($limit);
	my($template)  = $self -> load_tmpl('select.tmpl');

	$template -> param(on_change => $on_change);
	$template -> param(name      => $id_name);
	$template -> param(loop      => [map{ {default => ($$option{$_} == $default ? 1 : 0), name => $_, value => $$option{$_} } } sort keys %$option]);

	return $template -> output;

} # End of build_select.

# -----------------------------------------------

sub format_timestamp
{
	my($self, $timestamp) = @_;
	my(@field)     = split(/[- :]/, $timestamp);
	my($datestamp) = DateTime -> new
	(
	 year   => $field[0],
	 month  => $field[1],
	 day    => $field[2],
	 hour   => $field[3],
	 minute => $field[4],
	 second => $field[5],
	);

	return $datestamp -> strftime('%A, %e %B %Y %I:%M:%S %P');

} # End of format_timestamp.

# -----------------------------------------------

sub load_tmpl
{
	my($self, $name, @options) = @_;

	return HTML::Template -> new(filename => file($self -> tmpl_path, $name), @options);

} # End of load_tmpl.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
