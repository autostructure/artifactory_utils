require 'fileutils'

# Synchronized an artifatory repository by name to a destination
Puppet::Type.type(:artifact_sync).provide :linux do
  desc "Synchronizes an Artifactory repository on a linux server."

  defaultfor :osfamily => :RedHat

  def get_query(source_url,  user_name, password_hash)
    # [RELEASE] has special signifiance in Artifactory. Let's escape it
     url = source_url.gsub(/\[RELEASE\]/, '%5BRELEASE%5D')

    uri_get = URI.parse(url)
    http_get = Net::HTTP.new(uri_get.host, uri_get.port)

    request_get = Net::HTTP::Get.new(uri_get.request_uri)

    # user and password_hash are here use auth
    if user_name and password_hash
      request_get.basic_auth user_name, password_hash
    end

    response = http_get.request(request_get)

    return response
  end

  # Write a new file to the destination
  def write_file(url, destination, user_name, password_hash)
    response = get_query(url, user_name, password_hash)

    if response.code == "200"
      open(destination, 'wb') do |file|
        file.write(response.body)
      end
    else
      raise Puppet::Error, 'No file can be found at ' + url
    end
  end

  # The resource exists if all files and folders in place and
  # the files match the ones in Artifactory
  def exists?
    ensured_value = @resource.value(:ensure).to_s

    # Assign variables assigned by parameters
    destination      = resource[:name]

    source_url       = @resource.value(:source_url)
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
      # Separate the path to access storage api
      source_components = source_url.scan(/(.+\/artifactory)\/(.+)$/)[0]

      artifactory_path = source_components[0]
      war_path  = source_components[1]

      # File info URL
      file_info = artifactory_path + '/api/storage/' + war_path

      response  = get_query(file_info, user, password)

      # We should only move forward on a 200
      if response.code == "401"
        raise Puppet::Error, 'You do not have permission to access ' + source_url
      elsif response.code != "200"
        raise Puppet::Error, 'No file can be found at ' + source_url
      end

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

    source_url       = @resource.value(:source_url)
    user             = @resource.value(:user)
    password         = @resource.value(:password)

    write_file source_url, destination, user, password
  end
end
