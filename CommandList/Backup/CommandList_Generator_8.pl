# CommandList Version 2.0
# Created by Blacky


#!/usr/bin/perl -w
use strict;
use XML::Simple;
use XML::Parser;
use XML::SAX::PurePerl;
use Data::Dumper;
use File::HomeDir;

my $xml_config;
our %xml;
our $configfile			= "config.cfg";
our $config_file 		= "commands.txt";
our $config_split		= 0;
our $config_sort		= 0;
our $config_unique		= 0;
our $config_hidecommands = 0;


print "\n";
print "Brenbot CommandList Generator Tool\n";
print "\n";
print "Generates Commands.txt.\n";
print "Run this program whenever you add/remove BRenBot plugins.\n";
print "Run this when you add/remove aliases for commands.\n";
print "\n";

# Loads all config data
ReadConfig();
readXMLData();
my @commands = ();
my @plugins = ();
my @mastercommands = ();
my @uniquecommands = ();
my @uniqueplugins = ();
my @uniquemaster = ();
@commands = read_commands();
@plugins = get_plugins();

if ( scalar(@commands) == 0 ) { print "ERROR no commands returned.\n"; }
if ( scalar(@plugins) == 0 ) { print "No plugin Commands.\n"; }

my @mastercommands = (@commands, @plugins);

if ( $config_unique == 1 )
{
	@uniquecommands = unique_commands(@commands);
	@uniqueplugins = unique_commands(@plugins);
	@uniquemaster = unique_commands(@mastercommands);
}

if ( scalar(@uniquecommands) == 0 ) { @uniquecommands = @commands;  }
if ( scalar(@uniqueplugins) == 0 ) { @uniqueplugins = @plugins; }
if ( scalar(@uniquemaster) == 0 ) { @uniquemaster = @mastercommands; }

my @sorted_commands = sort @uniquecommands; #sort alphabetically
my @sorted_plugins = sort @uniqueplugins; #sort alphabetically
my @sorted_master = sort @uniquemaster; #sort alphabetically

if ( $config_sort != 0 )
{
	@commands = @sorted_commands;
	@plugins = @sorted_plugins;
	@mastercommands = @sorted_master;
}
else
{
	@mastercommands = @uniquemaster;
}

if ($config_sort == 2 ) 
{
	@commands = reverse @commands;
	@plugins = reverse @plugins;
	@mastercommands = reverse @mastercommands; #sort reverse
}

#Sort by Plugin
if ($config_sort == 3 ) 
{
	@sorted_plugins = ();
	
	# Since the array element is a single string put the plugin name in the front of the string so we can sort it by the plugin name
	foreach ( @plugins )
	{
		my @entrys = split (";", $_);
		my $syntax		= $entrys[1];
		my $modlevel	= $entrys[2];
		my $plugin		= $entrys[3];
		my $alias		= $entrys[4];
		
		if ( defined($alias) ) { 
			push(@sorted_plugins, ";$plugin;$modlevel;$syntax;$alias");
		}
		else {
			push(@sorted_plugins, ";$plugin;$modlevel;$syntax;");
		}
	}
	@sorted_plugins = SortByPlugin();
	@plugins = ();
	@sorted_plugins = sort @sorted_plugins;
	
	#Now that it is sorted by the plugin name create a new array with our original format
	foreach ( @sorted_plugins )
	{
		my @entrys = split (";", $_);
		my $plugin		= $entrys[1];
		my $modlevel	= $entrys[2];
		my $syntax		= $entrys[3];
		my $alias		= $entrys[4];
		
		if ( defined($alias) ) { 
			push(@plugins, ";$syntax;$modlevel;$plugin;$alias");
		}
		else {
			push(@plugins, ";$syntax;$modlevel;$plugin");
		}
	}
	
	@mastercommands = ();
	@mastercommands = (@commands, @plugins);
}

sub SortByType
{
	my $array = shift;
	my $type = shift;
	my @sorted = ();
	foreach ( @$array )
	{
		my @entrys = split (";", $_);
		my $syntax		= $entrys[1];
		my $modlevel	= $entrys[2];
		my $plugin		= $entrys[3];
		my $alias		= $entrys[4];
		
		if ( $type == 2 )
		{
			$modlevel = $entrys[1];
		}
		
		if ( $type == 3 )
		{
			$plugin = $entrys[1];
		}
		
		
		if ( defined($alias) ) { 
			push(@sorted, ";$entrys[$type];$modlevel;$plugin;$alias");
		}
		else {
			push(@sorted, ";$plugin;$modlevel;$syntax;");
		}
	}
	return @sorted;
}

sub RestoreStringFormat
{
	my @array = (@_);
	my @sorted = ();
	foreach ( @plugins )
	{
		my @entrys = split (";", $_);
		my $syntax		= $entrys[1];
		my $modlevel	= $entrys[2];
		my $plugin		= $entrys[3];
		my $alias		= $entrys[4];
		
		if ( defined($alias) ) { 
			push(@plugins, ";$syntax;$modlevel;$plugin;$alias");
		}
		else {
			push(@plugins, ";$syntax;$modlevel;$plugin");
		}
	}
	return @sorted;
}

if ($config_sort == 4 ) 
{
	@commands = reverse @commands;
	@plugins = reverse @plugins;
	@mastercommands = reverse @mastercommands; #sort reverse
}


unlink "Commands.txt";
CommandCreate("Generated by CommandList Version 2.0\n");


print "Writing Hide Commands List.\n";

if ( $config_split == 1 ) 
{
	CommandWrite( "" );
	CommandWrite( "-------------------------------------" );
	CommandWrite( "COMMANDS" );
	CommandWrite( "-------------------------------------" );
	CommandWrite( "" );
	WriteCommands(@commands);
	CommandWrite( "" );
	CommandWrite( "-------------------------------------" );
	CommandWrite( "Plugins" );
	CommandWrite( "-------------------------------------" );
	CommandWrite( "" );
	WriteCommands(@plugins);
}
else
{
	WriteCommands(@mastercommands);
}

print "\n";
print "Commands.txt Done\n";

sleep(5);
exit(1);


sub WriteCommands
{
	my @array = (@_);
	foreach ( @array )
	{
		my @entrys = split (";", $_);
		my $syntax		= $entrys[1];
		my $modlevel	= $entrys[2];
		my $plugin		= $entrys[3];
		my $alias		= $entrys[4];
		
		#print ";$syntax;$modlevel;$plugin;$alias\n";
		
		if ( $config_hidecommands == 0 ) 
		{
			#CommandWrite( "-------------------------------------" );
			CommandWrite( "!$syntax" );
			CommandWrite( "$alias" ) if ( defined($alias) );
			CommandWrite( "$modlevel" );
			CommandWrite( "Plugin: $plugin" ) if ( defined($plugin) && $plugin ne "" );
			CommandWrite( "" );
			#CommandWrite( "-------------------------------------" );
		}
		else
		{
			#Write HideCommands File
			if ( $syntax =~ /^(.+?)\s.+$/ ) {
				CommandWrite( '!'.$1." = 1" );
			}
			else{
				print "Command $syntax syntax ERROR did not match command.\n";
			}
		}
	}
}

sub unique_commands
{
	my %seen;
	my @array = (@_);
	my @unique = ();
	foreach my $value (@array) 
	{
		my @entrys = split (";", $value);
		my $entry		= $entrys[1];
		if (!defined($seen{$entry})) { 
			push @unique, $value;
			$seen{$entry} = 1;
		}
	}
	return @unique;
}

sub readXMLData
{
	my $xmlOld = $xml_config;
	$xml_config = "";
	my $error;
	eval
	{
		print "Reading commands.xml \n";
		$xml_config = XMLin("commands.xml", ForceArray => [ 'group' ] );
		while ( my ($k, $v) = each %{$xml_config->{command}} )
		{
			$v->{syntax}->{value} =~ s/&gt;/>/gi;
			$v->{syntax}->{value} =~ s/&lt;/</gi;
		}
	}
	or $error = $@;
	if ( $error )
	{
		if ( ! -e "commands.xml")
		{
			print "commands.xml doesn't exist! commands.xml must be in the same folder as CommandList_Generator.exe.\n";
		}
		else
		{
			print "Error while reading commands.xml! \n";
			print "$error\n";
		}
		sleep(5);
		exit(1);
	}
}

sub read_commands
{
	my @commands = ();
	while ( my ($key, $value) = each %{$xml_config->{command}} )
	{
		continue if ( !defined($value) || !defined($key) );
		my $alias;
		if ( $value->{enabled}->{value} == 1 )
		{
			#Debug("Commands: Get Command $key"); #print "Commands: Get Command $key\n";
			my $syn = "$value->{syntax}->{value}";
			$syn =~ s/\!//g;
			my $syntax = "$syn - $value->{help}->{value}";
			if ( $value->{alias} )
			{
				$alias = "Command Alias: ";
				if ( ref($value->{alias}) eq "ARRAY" )
				{
					my $numAliases = scalar($value->{alias});
					foreach ( @{$value->{alias}} )
					{
						my %alias = ( 'name' => $_, 'alias' => $key );
						$alias = $alias . "!" . $alias{name} . " ";
					}
				}
				else
				{
					my %alias = ( 'name' => $value->{alias}, 'alias' => $key );
					$alias = $alias . "!" . $alias{name} . " ";
				}
			}
			
			my $permission = get_permission($value->{permission}->{level});
			my $modlevel = "Mod Level: $permission";
			if ( defined($alias) ) {
				push(@commands, ";$syntax;$modlevel;;$alias");
			}
			else {
				push(@commands, ";$syntax;$modlevel;;");
			}
		}
	}
	return @commands;
}



sub get_plugins
{
	unless(opendir(DATADIR, "plugins/"))
	{
		print "No plugins folder found.\n";
		return ();
	}

	my @plugin_files;
	@plugin_files = grep(/\.pm$/i,readdir(DATADIR));
	my @mastercommands = ();

	foreach (@plugin_files)
	{
		my $plugin = $_;
		my $error;
		$plugin =~ s/\.pm$//g;
		print "Reading $plugin.xml\n";
		eval
		{
			$xml{$plugin} = XMLin( "plugins/$plugin.xml", ForceArray => [ qw(event group command hook) ], KeyAttr => [ 'name', 'key', 'id', 'event' ] );
		}
		or $error=$@;
		if ($error)
		{
			print "Error while reading $plugin.xml!";
			print "$error";
			next;
		}	
		@mastercommands = (@mastercommands, get_commands($xml{$plugin}, $plugin) );
	}
	return @mastercommands; 
}

sub get_commands
{
	my $xml    = shift;
	my $plugin = shift;

	my $c = $xml->{command};
	my @commands = ();

	return if ( !defined($c) );
	while (my ($key, $value) = each %{$c})
	{
		my $alias;
		if ( $value->{enabled}->{value} == 1 )
		{
			my $syn = "$value->{syntax}->{value}";
			$syn =~ s/\!//g;
			my $syntax = "$syn - $value->{help}->{value}";
			if ( $value->{alias} )
			{
				$alias = "Command Alias: ";
				if ( ref($value->{alias}) eq "ARRAY" )
				{
					my $numAliases = scalar($value->{alias});
					foreach ( @{$value->{alias}} )
					{
						my %alias = ( 'name' => $_, 'alias' => $key );
						$alias = $alias . "!" . $alias{name} . " ";
					}
				}
				else
				{
					my %alias = ( 'name' => $value->{alias}, 'alias' => $key );
					$alias = $alias . "!" . $alias{name} . " ";
				}
			}
			
			my $permission = get_permission($value->{permission}->{level});
			my $modlevel = "Mod Level: $permission";
			if ( defined($alias) ) { 
				push(@commands, ";$syntax;$modlevel;$plugin;$alias");
			}
			else {
				push(@commands, ";$syntax;$modlevel;$plugin");
			}
		}
	}
	return @commands;
}

sub get_permission
{
	my $permission = shift;
	my $permission_name = "None";
	if ( $permission == 0 ) { $permission_name = "Normal Ingame Users"; }
	elsif ( $permission == 1 ) { $permission_name = "Temporary Moderators"; }
	elsif ( $permission == 2 ) { $permission_name = "Half Moderators"; }
	elsif ( $permission == 3 ) { $permission_name = "Full Moderators"; }
	elsif ( $permission == 4 ) { $permission_name = "Administrators"; }
	return $permission_name;
}

sub ReadConfig
{
	my $fh;
	open ( $fh, $configfile ) or die "Config_File_Read: $!,";
	while ( <$fh> )
	{
		if ( $_ !~ m/^\#/ && $_ !~ m/^\s+$/ )		# If the line starts with a hash or is blank ignore it
		{
			if (/^\s*File\s*\=\s*(\S+)/i)								{ $config_file = $1; }
			if (/^\s*Split\s*=\s*(\d+)/i)		 						{ $config_split = $1; }
			if (/^\s*Sort\s*=\s*(\d+)/i)		 						{ $config_sort = $1; }
			if (/^\s*UniqueCommands\s*=\s*(\d+)/i)						{ $config_unique = $1; }
			if (/^\s*HideCommands\s*=\s*(\d+)/i)						{ $config_hidecommands = $1; }
		}
	}

	my $config_error;
	$config_error .= "File " if (!$config_file);
	if ($config_error)
	{
		main::console_output ( "[Config] ERROR: Missing config file option(s): $config_error" );
		sleep ( 10 );
		exit;
	}

	close $fh;
}

sub CommandCreate
{
	my $msg	= shift;
	open ( COMMANDFILE, '>' . $config_file );
	print COMMANDFILE "$msg\n";
	close COMMANDFILE;
}

sub CommandWrite
{
	my $msg	= shift;
	open ( COMMANDFILE, '>>' . $config_file );
	print COMMANDFILE "$msg\n";
	close COMMANDFILE;
}

sub Debug
{
	my $msg	= shift;
	open ( COMMANDFILE, '>>debug.txt' );
	print COMMANDFILE "$msg\n";
	close COMMANDFILE;
}