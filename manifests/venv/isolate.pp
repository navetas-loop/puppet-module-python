define python::venv::isolate($ensure=present,
                             $version=latest,
                             $requirements=undef,
                             $alternative_index=undef) {
  $root = $name
  $owner = $python::venv::owner
  $group = $python::venv::group
  $umask = $python::venv::umask

  $python = $version ? {
    'latest' => "python",
    default => "python${version}",
  }

  if $ensure == 'present' {
    # Parent directory of root directory. /var/www for /var/www/blog
    $root_parent = inline_template("<%= @root.match(%r!(.+)/.+!)[1] %>")

    if !defined(File[$root_parent]) {
      file { $root_parent:
        ensure => directory,
        owner => $owner,
        group => $group,
      }
    }

    Exec {
      user => $owner,
      group => $group,
      cwd => "/tmp",
    }

    # Does not successfully run as www-data on Debian:
    exec { "python::venv $root":
      command => "virtualenv -p `which ${python}` ${root}",
      creates => $root,
      notify => Exec["update distribute and pip in $root"],
      umask => $umask,
      require => [File[$root_parent],
                  Package["python-virtualenv"]],
    }

    # Some newer Python packages require an updated distribute
    # from the one that is in repos on most systems:
    exec { "update distribute and pip in $root":
      command => "$root/bin/pip install -U pip distribute",
      umask => $umask,
      refreshonly => true,
    }

    if $requirements {
      python::pip::requirements { $requirements:
        venv => $root,
        owner => $owner,
        group => $group,
        alternative_index => $alternative_index,
        require => Exec["python::venv $root"],
      }
    }

  } elsif $ensure == 'absent' {

    file { $root:
      ensure => $ensure,
      owner => $owner,
      group => $group,
      recurse => true,
      purge => true,
      force => true,
    }
  }
}
