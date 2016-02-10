# == Class artifactory_utils::params
#
# This class is meant to be called from artifactory_utils.
# It sets variables according to platform.
#
class artifactory_utils::params {
  case $::osfamily {
    'Debian': {
      $package_name = 'artifactory_utils'
      $service_name = 'artifactory_utils'
    }
    'RedHat', 'Amazon': {
      $package_name = 'artifactory_utils'
      $service_name = 'artifactory_utils'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }

  # Requires some gems
  package {'rest-client':
    ensure   => present,
    provider => 'puppet_gem',
    require  => [ Package['gcc'], Package['ruby-devel'], Package['rubygem'] ],
  }

  package { 'gcc':
    ensure => present,
  }

  ensure { 'ruby-devel':
    ensure => present,
  }

  ensure { 'rubygem':
    ensure => present,
  }
}
