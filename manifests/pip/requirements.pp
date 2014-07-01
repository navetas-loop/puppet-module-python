# Installs packages in a requirements file for a virtualenv.
# Pip tries to upgrade packages when the requirements file changes.
define python::pip::requirements($venv, $owner=undef, $group=undef, $alternative_index=undef) {
  $requirements = $name
  $requirements_path = split($requirements, '/')
  $requirements_dir = inline_template("<%= (@requirements_path).first(@requirements_path.size() - 1).join('/') %>")
  $checksum = "$venv/requirements.checksum"

  $pip_install_base_command = "$venv/bin/pip install --download-cache=$venv/cache -Ur $requirements"
  $pip_install_command = $alternative_index ? {
    undef   => $pip_install_base_command,
    default => "$pip_install_base_command --no-index --find-links $alternative_index",
  }

  Exec {
    user => $owner,
    group => $group,
    cwd => "/tmp",
  }

  if !defined(File["$requirements"]){
    file { $requirements:
      ensure => present,
      replace => false,
      owner => $owner,
      group => $group,
      content => "# Puppet will install packages listed here and update them if
  # the the contents of this file changes.",
    }
  }

  # We create a sha1 checksum of the requirements file so that
  # we can detect when it changes:
  exec { "create new checksum of $name requirements":
    command => "sha1sum $requirements > $checksum",
    require => File[$requirements],
    refreshonly => true,
  }

  exec { "update $name requirements":
    command => $pip_install_command,
    cwd => $requirements_dir,
    timeout => 1800, # sometimes, this can take a while
    require => File[$requirements],
    unless => "sha1sum -c $checksum",
    notify => Exec["create new checksum of $name requirements"],
    logoutput => "on_failure",
  }
}
