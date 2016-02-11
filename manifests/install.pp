# == Class artifactory_utils::install
#
# This class is called from artifactory_utils for install.
#
class artifactory_utils::install {
  # Requires some gems
  package {'rest-client':
    ensure   => present,
    provider => 'puppet_gem',
    require  => [ Package['gcc'], Package['ruby-devel'] ],
  }

  package { 'gcc':
    ensure => present,
  }

  package { 'ruby-devel':
    ensure => present,
  }

  #package { 'rubygem':
  #  ensure => present,
  #}

  #package { 'rubygem-rest-client':
  #  ensure => present,
  #}
}
