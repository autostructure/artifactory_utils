# Class: artifactory_utils
# ===========================
#
# Full description of class artifactory_utils here.
#
# Parameters
# ----------
#
# * `sample parameter`
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
class artifactory_utils (
  $package_name = $::artifactory_utils::params::package_name,
  $service_name = $::artifactory_utils::params::service_name,
) inherits ::artifactory_utils::params {

  # validate parameters here

  class { '::artifactory_utils::install': } ->
  class { '::artifactory_utils::config': } ~>
  class { '::artifactory_utils::service': } ->
  Class['::artifactory_utils']
}
