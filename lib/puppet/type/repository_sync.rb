#require 'etc'
#require 'facter'
#require 'puppet/parameter/boolean'
#require 'puppet/property/list'
#require 'puppet/property/ordered_list'
#require 'puppet/property/keyvalue'

Puppet::Type.newtype(:repository_sync) do
  @doc = "Synchronizes an Artifactory repoisitory on the local file system."
  ensurable

  newparam(:repository, :namevar => true) do
    desc "The artifactory repository we are looking to synchronize locally."

    validate do |value|
      raise ArgumentError, "Repository name must not be empty." if value.empty?
    end
  end

  newparam(:artifactory_host) do
    desc "The host of the artifactory server."

    validate do |value|
      raise ArgumentError, "Artifactory host name must not be empty." if value.empty?
    end
  end

  newparam(:destination) do
    desc "The file system destination for the repository synchronization."

    munge do |value|
        case value
        when /^.*\/$/
          value
        else
          value + '/'
        end
      end

    validate do |value|
      raise ArgumentError, "The destination of the repository synchronization must not be empty." if value.empty?
    end
  end

  newparam(:user) do
    desc "The user for Artifactory basic auth."
  end

  newparam(:password) do
    desc "The user password for Artifactory basic auth."
  end
end
