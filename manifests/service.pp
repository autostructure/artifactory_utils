# == Class artifactory_utils::service
#
# This class is meant to be called from artifactory_utils.
# It ensure the service is running.
#
class artifactory_utils::service {
  # No service to install
  #  service { $::artifactory_utils::service_name:
  #  ensure     => running,
  #  enable     => true,
  #  hasstatus  => true,
  #  hasrestart => true,
  #}
}
