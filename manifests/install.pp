# == Class artifactory_utils::install
#
# This class is called from artifactory_utils for install.
#
class artifactory_utils::install {

  package { $::artifactory_utils::package_name:
    ensure => present,
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

  package { 'ruby-devel':
    ensure => present,
  }

  package { 'rubygem':
    ensure => present,
  }
}
