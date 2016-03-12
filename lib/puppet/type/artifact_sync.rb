Puppet::Type.newtype(:artifact_sync) do
  @doc = "Synchronizes an artifact to the local file system."
  ensurable

  autorequire(:package) do
    'rest-client'
  end

  newparam(:artifactory_host) do
    desc "The host of the artifactory server."

    validate do |value|
      raise ArgumentError, "Artifactory host name must not be empty." if value.empty?
    end
  end

  newparam(:destination, :namevar => true) do
    desc "The file system destination for the repository synchronization."

    validate do |value|
      raise ArgumentError, "The destination for the artifact to be placed." if value.empty?
    end
  end

  newparam(:repository_name) do
    desc "The repository that holds the artifact to sync."

    validate do |value|
      raise ArgumentError, "The repository name must not be empty." if value.empty?
    end         
  end

  newparam(:path_to_file) do
    desc "The path to the file to sync."

    validate do |value|
      raise ArgumentError, "The file path must not be empty." if value.empty?
    end         
  end

  newparam(:user) do
    desc "The user for Artifactory basic auth."
  end

  newparam(:password) do
    desc "The user password for Artifactory basic auth."
  end
end
