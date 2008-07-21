#! /usr/bin/perl -w
#
# Example of plugin module
# This is the API part of UsersPluginLDAPPasswordPolicy plugin
# - configuration of Password Policy of LDAP user (feature 301179)
#
# For documentation and examples of function arguments and return values, see
# UsersPluginLDAPAll.pm

package UsersPluginLDAPPasswordPolicy;

use strict;

use YaST::YCP qw(:LOGGING);
use YaPI;
use Data::Dumper;
use X500::DN;

textdomain("users");

our %TYPEINFO;

##--------------------------------------
##--------------------- global imports

YaST::YCP::Import ("SCR");
YaST::YCP::Import ("Ldap");

##--------------------------------------
##--------------------- global variables

# name of conflicting plugin
my $shadow_plugin	= "UsersPluginLDAPShadowAccount";

# error message, returned when some plugin function fails
my $error	= "";

# internal name
my $name	= "UsersPluginLDAPPasswordPolicy";

# if Password Policy is enabled on the server
my $ppolicy_enabled	= undef;


# value to write into pwdaccountlockedtime if user should be disabled
# see slapo-ppolicy man-page
my $disabled_user	= "000001010000Z";

##----------------------------------------
##--------------------- internal functions

# internal function:
# check if given key (second parameter) is contained in a list (1st parameter)
# if 3rd parameter is true (>0), ignore case
sub contains {
    my ($list, $key, $ignorecase) = @_;
    if (!defined $list || ref ($list) ne "ARRAY" || @{$list} == 0) {
	return 0;
    }
    if ($ignorecase) {
        if ( grep /^\Q$key\E$/i, @{$list} ) {
            return 1;
        }
    } else {
        if ( grep /^\Q$key\E$/, @{$list} ) {
            return 1;
        }
    }
    return 0;
}

# update the object data when removing plugin
# TODO is it possible when plugin is not removable?
sub remove_plugin_data {

    my ($config, $data) = @_;
    my @updated_oc;
    if (defined $data->{'pwdPolicySubEntry'}) {
	$data->{'pwdPolicySubEntry'}	= "";
    }
    return $data;
}

##------------------------------------------
##--------------------- global API functions

# return names of provided functions
BEGIN { $TYPEINFO{Interface} = ["function", ["list", "string"], "any", "any"];}
sub Interface {

    my $self		= shift;
    my @interface 	= (
	    "GUIClient",
	    "Check",
	    "Name",
	    "Summary",
	    "Restriction",
	    "WriteBefore",
	    "Write",
	    "AddBefore",
	    "Add",
	    "EditBefore",
	    "Edit",
	    "Interface",
	    "Disable",
	    "Enable",
	    "PluginPresent",
	    "PluginRemovable",
	    "Error",
    );
    return \@interface;
}

# return error message, generated by plugin
BEGIN { $TYPEINFO{Error} = ["function", "string", "any", "any"];}
sub Error {

    return $error;
}


# return plugin name, used for GUI (translated)
BEGIN { $TYPEINFO{Name} = ["function", "string", "any", "any"];}
sub Name {

    # plugin name
    return __("LDAP Password Policy");
}

##------------------------------------
# return plugin summary (to be shown in table with all plugins)
BEGIN { $TYPEINFO{Summary} = ["function", "string", "any", "any"];}
sub Summary {

    # user plugin summary (table item)
    return __("Edit Password Policy");
}

##------------------------------------
# checks the current data map of user (2nd parameter) and returns
# true if given user has this plugin
BEGIN { $TYPEINFO{PluginPresent} = ["function", "boolean", "any", "any"];}
sub PluginPresent {

    my ($self, $config, $data)  = @_;

    # check for PasswordPolicy at server
    if (not defined $ppolicy_enabled) {
	$ppolicy_enabled	= SCR->Execute (".ldap.ppolicy", {
	    "hostname"	=> Ldap->GetFirstServer (Ldap->server ()),
	    "bind_dn"	=> Ldap->GetDomain ()
	});
	y2milestone ("Password Policy enabled globaly: $ppolicy_enabled");
    }
    if (contains ($data->{'plugins'}, $name, 1) ||
	# already checked, still no data
	contains ((keys %$data), "pwdPolicySubEntry", 1)) # checking for data
    {
	y2milestone ("LDAPPasswordPolicy plugin present");
	return 1;
    } elsif ($ppolicy_enabled) {
	y2debug ("Password Policy enabled globaly");
	return 1;
    } else {
	y2debug ("LDAPPasswordPolicy plugin not present");
	return 0;
    }
}

##------------------------------------
# Is it possible to remove this plugin from user?
BEGIN { $TYPEINFO{PluginRemovable} = ["function", "boolean", "any", "any"];}
sub PluginRemovable {

    return YaST::YCP::Boolean (0);
}


##------------------------------------
# return name of YCP client defining YCP GUI
BEGIN { $TYPEINFO{GUIClient} = ["function", "string", "any", "any"];}
sub GUIClient {

    return "users_plugin_ldap_passwordpolicy";
}

##------------------------------------
# Type of objects this plugin is restricted to.
# Plugin is restricted to LDAP users
BEGIN { $TYPEINFO{Restriction} = ["function",
    ["map", "string", "any"], "any", "any"];}
sub Restriction {

    return {
	    "ldap"	=> 1,
	    "user"	=> 1
    };
}


##------------------------------------
# check if required atributes of LDAP entry are present and have correct form
# parameter is (whole) map of entry (user)
# return error message
BEGIN { $TYPEINFO{Check} = ["function",
    "string",
    "any",
    "any"];
}
sub Check {

    my ($self, $config, $data)  = @_;
    my $pwdpolicysubentry	= $data->{'pwdPolicySubEntry'};
    if (defined $pwdpolicysubentry && $pwdpolicysubentry ne "") {

	# validate DN
	if (not defined X500::DN->ParseRFC2253 ($pwdpolicysubentry)) {
	    # error popup, %s is object DN
	    return sprintf (__("Invalid DN syntax of \"%s\"."), $pwdpolicysubentry);
	}

	# ldap.init has been done before
	my $search	= SCR->Read (".ldap.search", {
	        "base_dn"	=> $pwdpolicysubentry,
		"attrs"		=> [ "objectClass" ],
		"map"		=> 1
	});
	if (not defined $search) {
	    my $error	= SCR->Read (".ldap.error");
	    # error popup, first %s is object DN, second is additional error message
	    return sprintf (__("Error while searching for \"%s\":
%s"), $pwdpolicysubentry, $error->{'msg'});
	}
	my $oc	= $search->{$pwdpolicysubentry}{'objectClass'};
	if (defined $oc && ref ($oc) eq "ARRAY") {
	    if (not contains ($oc, "pwdPolicy", 1)) {
		# error popup, %s is object DN
		return sprintf (__("The object \"%s\"
is not a Password Policy object"), $pwdpolicysubentry);
	    }
	}
    }
    return "";
}

# this will be called from Users::EnableUser
BEGIN { $TYPEINFO{Enable} = ["function",
    ["map", "string", "any"],
    "any", "any"];
}
sub Enable {

    my ($self, $config, $data)  = @_;
    y2debug ("Enable LDAPAll called");

    $data->{'pwdAccountLockedTime'}	= "";
    return $data;
}

# this will be called from Users::DisableUser
BEGIN { $TYPEINFO{Disable} = ["function",
    ["map", "string", "any"],
    "any", "any"];
}
sub Disable {

    my ($self, $config, $data)  = @_;
    y2debug ("Disable LDAPAll called");

    $data->{'pwdAccountLockedTime'}	= $disabled_user;
    return $data;
}


# this will be called at the beggining of Users::Add
# Could be called multiple times for one user
BEGIN { $TYPEINFO{AddBefore} = ["function",
    ["map", "string", "any"],
    "any", "any"];
}
sub AddBefore {

    my ($self, $config, $data)  = @_;

    if (!contains ($data->{'plugins_to_remove'}, $name, 1) &&
	contains ($data->{'plugins'}, $shadow_plugin, 1)) {
	# error popup
	$error	= __("It is not possible to add this plug-in when
the plugin for Shadow Account attributes is in use.
");
	return undef;
    }
    return $data;
}


# This will be called just after Users::Add - the data map probably contains
# the values which we could use to create new ones
# Could be called multiple times for one user!
BEGIN { $TYPEINFO{Add} = ["function", ["map", "string", "any"], "any", "any"];}
sub Add {

    my ($self, $config, $data)  = @_;
    if (contains ($data->{'plugins_to_remove'}, $name, 1)) {
	y2milestone ("removing plugin $name...");
	$data   = remove_plugin_data ($config, $data);
    }
    y2debug("Add LDAPAll called");
    return $data;
}

# this will be called at the beggining of Users::Edit
BEGIN { $TYPEINFO{EditBefore} = ["function",
    ["map", "string", "any"],
    "any", "any"];
}
sub EditBefore {

    my ($self, $config, $data)  = @_;
    # $data: only new data that will be copied to current user map
    # data of original user are saved as a submap of $config
    # data with key "org_data"

    # in $data hash, there could be "plugins_to_remove": list of plugins which
    # has to be removed from the user
    if (!contains ($data->{'plugins_to_remove'}, $name, 1) &&
	contains ($data->{'plugins'}, $shadow_plugin, 1)) {
	# error popup
	$error	= __("It is not possible to add this plug-in when
the plugin for Shadow Account attributes is in use.
");
	return undef;
    }
    if (!defined $config->{"org_data"}{"enabled"}) {
	$data->{"enabled"}    = YaST::YCP::Boolean (1);
	if (($config->{"org_data"}{"pwdAccountLockedTime"} || "") eq $disabled_user)
	{
	    $data->{"enabled"}	= YaST::YCP::Boolean (0);
	    y2milestone ("user is disabled");
	}
    }
    return $data;
}

# this will be called just after Users::Edit
BEGIN { $TYPEINFO{Edit} = ["function",
    ["map", "string", "any"],
    "any", "any"];
}
sub Edit {

    my ($self, $config, $data)  = @_;
    if (contains ($data->{'plugins_to_remove'}, $name, 1)) {
	y2milestone ("removing plugin $name...");
	$data   = remove_plugin_data ($config, $data);
    }
    y2debug ("Edit LDAPAll called");
    return $data;
}



# what should be done before user is finally written to LDAP
BEGIN { $TYPEINFO{WriteBefore} = ["function", "boolean", "any", "any"];}
sub WriteBefore {

    y2debug ("WriteBefore LDAPAll called");
    return YaST::YCP::Boolean (1);
}

# what should be done after user is finally written to LDAP
BEGIN { $TYPEINFO{Write} = ["function", "boolean", "any", "any"];}
sub Write {

    y2debug ("Write LDAPAll called");
    return YaST::YCP::Boolean (1);
}
1
# EOF
