require 'etc'
require 'facter'
require 'puppet/parameter/boolean'
require 'puppet/property/list'
require 'puppet/property/ordered_list'
require 'puppet/property/keyvalue'

module Puppet::Type.newType(:repository_sync) do
  @doc = "Synchronizes an Artifactory repoisitory on the local file system."
  ensurable

  newproperty(:repository) do
    desc "The artifactory repository we are looking to synchronize locally."

    validate do |value|
      raise ArgumentError, "Repository name must not be empty." if value.empty?
    end
  end

  newproperty(:artifactory_host) do
    desc "The host of the artifactory server."

    validate do |value|
      raise ArgumentError, "Artifactory host name must not be empty." if value.empty?
    end
  end

  newproperty(:destination) do
    desc "The file system destination for the repository synchronization."

    validate do |value|
      raise ArgumentError, "The destination of the repository synchronization must not be empty." if value.empty?
    end
  end

  newproperty(:user) do
    desc "The user for Artifactory basic auth."
  end

  newproperty(:password) do
    desc "The user password for Artifactory basic auth."
  end
end
