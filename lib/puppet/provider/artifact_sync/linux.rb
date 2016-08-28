require 'fileutils'

# Synchronized an artifatory repository by name to a destination
Puppet::Type.type(:artifact_sync).provide :linux do
  desc "Synchronizes an Artifactory repository on a linux server."

  # Is it gone?

  defaultfor osfamily: :RedHat

  def get_header(source_url, user_name, password_hash)
    # [RELEASE] has special signifiance in Artifactory. Let's escape it
    url = source_url.gsub(/\[RELEASE\]/, '%5BRELEASE%5D')

    uri_get = URI.parse(url)

    http = Net::HTTP.start(uri_get.host, uri_get.port, use_ssl: (uri_get.scheme == 'https'), verify_mode: OpenSSL::SSL::VERIFY_NONE )

    request = Net::HTTP::Head.new(uri_get)

    if user_name && password_hash
      request.basic_auth user_name, password_hash
    end

    response = http.request request

    if response.code == 301
      response = get_query(URI.parse(response.header['location']), user_name, password_hash)
    end

    response
  end

  def get_query(source_url, user_name, password_hash)
    # [RELEASE] has special signifiance in Artifactory. Let's escape it
    url = source_url.gsub(/\[RELEASE\]/, '%5BRELEASE%5D')

    # user and password_hash are here use auth
    if user_name && password_hash
      return open(url, http_basic_authentication: [user_name, password_hash])
    else
      return open(url)
    end
  end

  # Write a new file to the destination
  def write_file(url, destination, user_name, password_hash, owner, group)
    # [RELEASE] has special signifiance in Artifactory. Let's escape it
    escaped_url = url.gsub(/\[RELEASE\]/, '%5BRELEASE%5D')

    uri = URI(escaped_url)

    Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https'), verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Get.new uri

      if user_name && password_hash
        request.basic_auth user_name, password_hash
      end

      http.request request do |response|
        if response.code == "200"
          open destination, 'w' do |io|
            response.read_body do |chunk|
              io.write chunk
            end
          end
        elsif response.code == "404"
          raise Puppet::Error, 'No file can be found at ' + url
        else
          raise Puppet::Error, 'Error retrieving file at ' + url + " (Response code: " + response.code + ")"
        end
      end

      FileUtils.chown owner, group, destination
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
    if !File.exist?(destination)
      return false
    end

    if ensured_value != 'absent'
      response = get_header(source_url, user, password)

      # We should only move forward on a 200
      if response.code == "401"
        raise Puppet::Error, 'You do not have permission to access ' + source_url
      elsif response.code != "200"
        raise Puppet::Error, 'Error retrieving file at ' + source_url + " (Response code: " + response.code + ")"
      end

      # Checksum returned by the http response
      current_sha1 = response['x-checksum-sha1']

      # Compute digest for a file
      sha1 = Digest::SHA1.file destination

      # Make sure the sha1 hashes match
      if sha1 != current_sha1
        return false
      end
    end

    true
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
    owner            = @resource.value(:owner)
    group            = @resource.value(:group)

    write_file source_url, destination, user, password, owner, group
  end
end
