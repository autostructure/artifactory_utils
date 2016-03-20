require 'fileutils'

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

    response = http_get.request(request_get)

    return response
  end

  def post_query(url, query, user_name, password_hash)
    uri_post = URI.parse(url)
    http_post = Net::HTTP.new(uri_post.host, uri_post.port)

    request_post = Net::HTTP::Post.new(uri_post.request_uri)

    request_post["Content-Type"] = "text/plain"
    request_post.basic_auth user_name, password_hash
    request_post.body = query.join

    response = http_post.request(request_post)

    return response
  end

  # Write a new file to the destination
  def write_file(repository_name, path_to_file, destination, artifactory_host)
    Net::HTTP.start(artifactory_host) do |http|
      resp = http.get('/artifactory/' + repository_name + '/' + path_to_file)

      open(destination, 'wb') do |file|
        file.write(resp.body)
      end
    end
  end

  # The resource exists if all files and folders in place and
  # the files match the ones in Artifactory
  def exists?
    ensured_value = @resource.value(:ensure).to_s

    # Assign variables assigned by parameters
    destination      = resource[:name]

    artifactory_host = @resource.value(:artifactory_host)
    user             = @resource.value(:user)
    password         = @resource.value(:password)
    repository_name  = @resource.value(:repository_name)
    path_to_file     = @resource.value(:path_to_file)

    #destination      = '/tmp/test.txt'

    #artifactory_host = 'artifactory.azcender.com'
    #user             = 'bryan'
    #password         = 'AP3BsrCHWPkwniwUgbgp28RYqKW'
    #repository_name  = 'sync-local'
    #path_to_file     = '/fslink/11gR2/dir1/app1/file1.txt'

    # If the destination doesn't exists return false
    if !File.exists?(destination)
      return false
    end

    case ensured_value
    when 'absent'
      return true
    else
      # Get SHA1 value from Artifactory

      # File info URL
      file_info = 'http://' + artifactory_host + '/artifactory/api/storage/' + repository_name + '/' + path_to_file

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

    artifactory_host = @resource.value(:artifactory_host)
    user             = @resource.value(:user)
    password         = @resource.value(:password)
    repository_name  = @resource.value(:repository_name)
    path_to_file     = @resource.value(:path_to_file)

    # File info URL
    file_info = 'http://' + artifactory_host + '/artifactory/' + repository_name + '/' + path_to_file

    response  = get_query(file_info, user, password)

    write_file repository_name, path_to_file, destination, artifactory_host
  end
end
