# == Class artifactory_utils::install
#
# This class is called from artifactory_utils for install.
#
class artifactory_utils::install {

  package { $::artifactory_utils::package_name:
    ensure => present,
  }
}
