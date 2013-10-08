#
# spec file for package yast2-users
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-users
Version:        3.1.0
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:		System/YaST
License:	GPL-2.0
BuildRequires:	cracklib-devel doxygen gcc-c++ perl-Digest-SHA1 perl-XML-Writer update-desktop-files libtool
BuildRequires:  yast2 yast2-ldap-client yast2-perl-bindings yast2-security yast2-testsuite yast2-core-devel
BuildRequires:  yast2-devtools >= 3.0.6

Requires:	yast2-country yast2-pam yast2-security cracklib perl-Digest-SHA1 perl-X500-DN perl-gettext
Obsoletes:	yast2-config-users y2c_users yast2-trans-users y2t_users yast2-trans-inst-user yast2-trans-users y2t_inst-user
Provides:	yast2-config-users y2c_users yast2-trans-users y2t_users yast2-trans-inst-user yast2-trans-users y2t_inst-user

# y2usernote, y2useritem
Requires:	yast2-perl-bindings >= 2.18.0

# this forces using yast2-ldap with orrect LDAP object names (fate#303596)
Requires:	yast2-ldap-client >= 2.17.1

# Syslog.ycp
Requires:       yast2 >= 2.23.7
# cryptsha256, cryptsha516
Requires:       yast2-core >= 2.21.0

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - User and Group Configuration

%description
This package provides GUI for maintenance of linux users and groups.

%package devel-doc
Requires:       yast2-users = %version
Group:          System/YaST
Summary:        YaST2 - User and Group Configuration - Development Documentation

%description devel-doc
This package contains development documentation for using the API
provided by yast2-users package.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/users
%dir %{yast_moduledir}/YaPI
%{yast_clientdir}/*.rb
%{yast_desktopdir}/*.desktop
%{yast_moduledir}/*.pm
%{yast_moduledir}/UsersUI.rb
%{yast_moduledir}/YaPI/*.pm
%{yast_yncludedir}/users/*
%{yast_schemadir}/autoyast/rnc/users.rnc
#agents:
%{yast_scrconfdir}/*.scr
%{yast_agentdir}/ag_nis
%{yast_agentdir}/ag_uid
%{yast_plugindir}/libpy2ag_crack.so.*
%{yast_plugindir}/libpy2ag_crack.so
%{yast_plugindir}/libpy2ag_crack.la
%dir %{yast_docdir}
%doc %{yast_docdir}/README
%doc %{yast_docdir}/COPYING
%doc %{yast_docdir}/TODO.txt
%doc %{yast_docdir}/users.html

%files devel-doc
%doc %{yast_docdir}/autodocs
%doc %{yast_docdir}/crack.html
