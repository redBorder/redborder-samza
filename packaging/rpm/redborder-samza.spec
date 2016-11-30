Name: redborder-samza
Version: %{__version}
Release: %{__release}%{?dist}
BuildArch: noarch
Summary: package with necessary utilities to manage redborder samza applications

License: AGPL 3.0
URL: https://github.com/redBorder/redborder-samza
Source0: %{name}-%{version}.tar.gz

Requires: redborder-manager

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}/usr/lib/redborder/bin
install -D -m 755 resources/bin/rb_samza.sh %{buildroot}/usr/lib/redborder/bin/rb_samza.sh

%clean
rm -rf %{buildroot}

%files
%defattr(0755,root,root)
/usr/lib/redborder/bin/rb_samza.sh

%changelog
* Tue Nov 29 2016 Alberto Rodriguez <arodriguez@redborder.com> - 0.0.1-1
- first spec version
