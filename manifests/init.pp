# Class: xinetd
#
# This module manages xinetd
#
# Sample Usage:
#   xinetd::service { 'rsync':
#     port        => '873',
#     server      => '/usr/bin/rsync',
#     server_args => '--daemon --config /etc/rsync.conf',
#  }
#
class xinetd (
  $confdir       = $xinetd::params::confdir,
  $confdir_purge = false,
  $conffile      = $xinetd::params::conffile,
  $package_name  = $xinetd::params::package_name,
  $service_name  = $xinetd::params::service_name
) inherits xinetd::params {

  File {
    owner   => 'root',
    group   => '0',
    notify  => Service[$service_name],
    require => Package[$package_name],
  }

  file { $confdir:
    ensure  => directory,
    mode    => '0755',
    recurse => $confdir_purge,
    purge   => $confdir_purge,
    force   => $confdir_purge,
  }

  # Template uses:
  #   $confdir
  file { $conffile:
    ensure  => file,
    mode    => '0644',
    content => template('xinetd/xinetd.conf.erb'),
  }

  package { $package_name:
    ensure => installed,
    before => Service[$service_name],
  }

  service { $service_name:
    ensure     => running,
    enable     => true,
    hasrestart => false,
    # LOL OPS-774. xinetd's init script leaves much to be desired. Like the 11
    # o'clock show at the Tropicana, it's racy.
    #
    # So we do it by hand. Note that the xinetd packages contain both
    # /etc/init.d/xinetd and /etc/init/xinetd.conf so it is essential that we
    # use the 'service' abstraction. Otherwise we can end up with two xinetds!
    restart    => 'bash -c "service xinetd stop ; sleep 7 ; service xinetd start"',
    start      => 'bash -c "service xinetd start"',
    stop       => 'bash -c "service xinetd stop"',
    hasstatus  => true,
    require    => File[$conffile],
  }

}
