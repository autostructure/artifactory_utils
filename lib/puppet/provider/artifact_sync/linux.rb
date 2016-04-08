require 'fileutils'
require 'oper-uri'

# Synchronized an artifatory repository by name to a destination
Puppet::Type.type(:artifact_sync).provide :linux do
  desc "Synchronizes an Artifactory repository on a linux server."

  defaultfor :osfamily => :RedHat

  # Given a key and properties array return the value
  def get_value(properties, key)
    # If the array is nil return nil
    if properties.nil?
      return nil
    end

    properties.each do |property|
      # Check key
      if property['key'] == key
        return property['value']
      end
    end

    # return nil if no value found
    return nil
  end

  def get_query(url,  user_name, password_hash)
    uri_get = URI.parse(url)
    http_get = Net::HTTP.new(uri_get.host, uri_get.port)

    request_get = Net::HTTP::Get.new(uri_get.request_uri)

    # user and password_hash are here use auth
    if user_name and password_hash {
      request_get.basic_auth user_name, password_hash
    }

    response = http_get.request(request_get)

    return response
  end

  # Write a new file to the destination
  def write_file(source, destination)
    open(destination) do |file|
      file << open(ource).read
    end
  end

  # The resource exists if all files and folders in place and
  # the files match the ones in Artifactory
  def exists?
    ensured_value = @resource.value(:ensure).to_s

    # Assign variables assigned by parameters
    destination      = resource[:name]

    source           = @resource.value(:source)
    user             = @resource.value(:user)
    password         = @resource.value(:password)

    # If the destination doesn't exists return false
    if !File.exists?(destination)
      return false
    end

    case ensured_value
    when 'absent'
      return true
    else
      # Get the file path
      file_path = source.scan(/.+\/artifactory\/(.+)$/)

      # File info URL
      file_info = 'http://' + artifactory_host + '/artifactory/api/storage/' + file_path

      response  = get_query(file_info, user, password)

      current_sha1 =  JSON.parse(response.body)['checksums']['sha1']

      # Compute digest for a file
      sha1 = Digest::SHA1.file destination

      # Make sure the sha1 hashes match
      if sha1 != current_sha1
        return false
      end

      return true
    end
  end

  # Delete all directories and files under destination
  def destroy
    destination = @resource.value(:destination)

    # Get all top level directories
    all_directories = Dir.glob(destination + '*')

    # Delete each and every directory
    FileUtils.rm_r all_directories
  end

  def create
    # Assign variables assigned by parameters
    destination      = resource[:name]

    source           = @resource.value(:source)
    user             = @resource.value(:user)
    password         = @resource.value(:password)

    write_file source, destination
  end
end
