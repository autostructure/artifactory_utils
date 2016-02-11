require 'fileutils'
require 'rest-client'

# Synchronized an artifatory repository by name to a destination
Puppet::Type.type(:repository_sync).provide :linux do
  desc "Synchronizes an Artifactory repository on a linux server."

  defaultfor :osfamily => :RedHat

  # The resource exists if all files and folders in place and
  # the files match the ones in Artifactory
  def exists?
    ensured_value = @resource.value(:ensure).to_s

    case ensured_value
    when 'absent'
      destination = @resource.value(:destination)

      # Get all top level directories
      all_directories = Dir.glob(destination + '*')

      # If there are any directories or files return true
      if all_directories.length > 0
        return true
      else
        return false
      end

    else
      # Assign variables assigned by parameters
      artifactory_host = @resource.value(:artifactory_host)
      destination      = @resource.value(:destination)
      user             = @resource.value(:user)
      password         = @resource.value(:password)

      repository_name  = resource[:name]

      # All of the directories under the root
      all_directories = Dir.glob(destination + '**/')

      # All of the files under the root
      all_files = Dir.glob(destination + '**/*').reject {|fn| File.directory?(fn) }

      # The directories that should not be removed
      current_directories = []

      # The files that should not be removed
      current_files = []

      # AQL api search url
      aql_url = 'http://' + artifactory_host + '/artifactory/api/search/aql'

      # Credential are supplied use them. Otherwise try anonymous
      if defined?(user) and defined?(password)
        site = RestClient::Resource.new aql_url, user, password
      else
        site = RestClient::Resource.new aql_url
      end

      response = site.post 'items.find( { "repo":{"$eq":"' + repository_name + '"}, "type":{"$eq":"any"} }).include("name", "repo", "path", "type", "actual_sha1").sort({"$asc" : ["type","name"]})', :content_type => 'text/plain'

      results = JSON.parse(response.to_str)['results']

      results.each do |result|
        # Create item path and then remove all instances of ./
        item_path = destination + result['path'] + '/' + result['name']

        item_path.gsub!(/\/\.\//, '/')
        item_path.gsub!(/\/\.$/, '')


        if result['type'] == 'folder'
          if !all_directories.include?(item_path + '/')
            return false
          else
            current_directories.push item_path + '/'
          end
        else
          current_files.push(item_path)

          if !File.exist?(item_path)
            return false
          else
            # Compute digest for a file
            sha1 = Digest::SHA1.file item_path

            # Make sure the sha1 hashes match
            if sha1 != result['actual_sha1']
              return false
            end
          end
        end
      end

      file_differences = all_files - current_files

      if file_differences.length > 0
        return false
      end

      directory_differences = all_directories - current_directories

      if directory_differences.length > 0
        return false
      end

      return true
    end
  end

  # Write a new file to the destination
  def write_file(result, destination, artifactory_host)
    Net::HTTP.start(artifactory_host) do |http|
      resp = http.get('/artifactory/' + result['repo'] + '/' + result['path'] + '/' + result['name'])
      open(destination + result['path'] + '/' + result['name'], 'wb') do |file|
        file.write(resp.body)
      end
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
    artifactory_host = @resource.value(:artifactory_host)
    destination      = @resource.value(:destination)
    user             = @resource.value(:user)
    password         = @resource.value(:password)

    repository_name  = resource[:name]


    # All of the directories under the root
    all_directories = Dir.glob(destination + '**/')

    # All of the files under the root
    all_files = Dir.glob(destination + '**/*').reject {|fn| File.directory?(fn) }

    # The directories that should not be removed
    current_directories = []

    # The files that should not be removed
    current_files = []

    # AQL api search url
    aql_url = 'http://' + artifactory_host + '/artifactory/api/search/aql'

    # Credential are supplied use them. Otherwise try anonymous
    if defined?(user) and defined?(password)
      site = RestClient::Resource.new aql_url, user, password
    else
      site = RestClient::Resource.new aql_url
    end

    response = site.post 'items.find( { "repo":{"$eq":"' + repository_name + '"}, "type":{"$eq":"any"} }).include("name", "repo", "path", "type", "actual_sha1").sort({"$asc" : ["type","name"]})', :content_type => 'text/plain'

    results = JSON.parse(response.to_str)['results']

    results.each do |result|
      # Create item path and then remove all instances of ./
      item_path = destination + result['path'] + '/' + result['name']

      item_path.gsub!(/\/\.\//, '/')
      item_path.gsub!(/\/\.$/, '')

      if result['type'] == 'folder'
        current_directories.push item_path + '/'
        FileUtils.mkdir_p item_path
      else
        current_files.push(item_path)

        if !File.exist?(item_path)
          write_file result, destination, artifactory_host
        else
          # Compute digest for a file
          sha1 = Digest::SHA1.file item_path

          # Make sure the sha1 hashes match
          if sha1 != result['actual_sha1']
            write_file result, destination, artifactory_host
          end
        end
      end
    end

    delete_files = all_files - current_files

    delete_files.each {|delete_file|
      File.delete(delete_file)
    }

    delete_dirs = all_directories - current_directories

    delete_dirs.each {|delete_dir|
      Dir.delete(delete_dir)
    }
  end
end
