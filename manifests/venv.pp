class python::venv($ensure=present,
                   $owner=undef,
                   $group=undef,
                   $umask=0022) inherits python::dev {

  package { "python-virtualenv":
    ensure => $ensure,
  }
}
