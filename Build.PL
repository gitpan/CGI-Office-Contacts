use Module::Build;

Module::Build -> new
(
	module_name    => 'CGI::Office::Contacts',
	license        => 'artistic',
	dist_abstract  => 'A web-based contacts manager',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::More => 0,
		Test::Pod  => 0,
	},
	requires =>
	{
		Carp                     => 0,
		CGI                      => 0,
		CGI::Application         => 0,
		CGI::Session             => 0,
		Config::Tiny             => 0,
		Data::Verifier           => 0,
		DateTime                 => 0,
		Date::Simple             => 0,
		DBD::Pg                  => 0,
		DBI                      => 0,
		DBIx::Admin::CreateTable => 0,
		FindBin::Real            => 0,
		HTML::Template           => 0,
		JSON::XS                 => 0,
		Log::Dispatch            => 0,
		Log::Dispatch::DBI       => 0,
		Moose                    => 0,
		namespace::autoclean     => 0,
		Path::Class              => 0,
		Sub::Exporter            => 0,
		Time::Elapsed            => 0,
},
) -> create_build_script;
