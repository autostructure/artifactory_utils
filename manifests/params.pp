# == Class artifactory_utils::params
#
# This class is meant to be called from artifactory_utils.
# It sets variables according to platform.
#
class artifactory_utils::params {
  #  case $::osfamily {
  #  'Debian': {
  #    $package_name = 'artifactory_utils'
  #    $service_name = 'artifactory_utils'
  #  }
  #  'RedHat', 'Amazon': {
  #    $package_name = 'artifactory_utils'
  #    $service_name = 'artifactory_utils'
  #  }
  #  default: {
  #    fail("${::operatingsystem} not supported")
  #  }
  #}
}
