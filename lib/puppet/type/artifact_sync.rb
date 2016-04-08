Puppet::Type.newtype(:artifact_sync) do
  @doc = "Synchronizes an artifact to the local file system."
  ensurable

  autorequire(:package) do
    'rest-client'
  end

  newparam(:destination, :namevar => true) do
    desc "The file system destination for the repository synchronization."

    validate do |value|
      raise ArgumentError, "The destination for the artifact to be placed." if value.empty?
    end
  end

  newparam(:source) do
    desc "The url of the file to sync."

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
