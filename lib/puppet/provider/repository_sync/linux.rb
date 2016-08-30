require 'fileutils'

# Synchronized an artifatory repository by name to a destination
Puppet::Type.type(:repository_sync).provide :linux do
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
    nil
  end

  def repository_item_query(repository_name)
    query = []

    query << "items.find(\n"
    query << "  {\n"
    query << "    \"repo\":{\n"
    query << "      \"$eq\":\"" + repository_name + "\"\n"
    query << "    },\n"
    query << "    \"type\":{\n"
    query << "      \"$eq\":\"any\"\n"
    query << "    }\n"
    query << "  }\n"
    query << ")\n"
    query << ".include(\"name\", \"repo\", \"path\", \"type\", \"actual_sha1\", \"property\")\n"
    query << ".sort(\n"
    query << "  {\n"
    query << "    \"$asc\":[\n"
    query << "      \"type\",\n"
    query << "      \"name\"\n"
    query << "    ]\n"
    query << "  }\n"
    query << ")"

    query
  end

  def post_query(url, query, user_name, password_hash)
    uri_post = URI.parse(url)
    http_post = Net::HTTP.new(uri_post.host, uri_post.port)

    request_post = Net::HTTP::Post.new(uri_post.request_uri)

    request_post["Content-Type"] = "text/plain"
    request_post.basic_auth user_name, password_hash
    request_post.body = query.join

    response = http_post.request(request_post)

    response
  end

  desc "Synchronizes an Artifactory repository on a linux server."

  defaultfor osfamily: :RedHat

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
      return !all_directories.empty?
    else
      # Assign variables assigned by parameters
      artifactory_host = @resource.value(:artifactory_host)
      artifactory_port = @resource.value(:artifactory_port)
      destination      = @resource.value(:destination)
      user             = @resource.value(:user)
      password         = @resource.value(:password)

      repository_name  = resource[:name]

      # All of the directories under the root
      all_directories = Dir.glob(destination + '**/')

      # All of the files under the root
      all_files = Dir.glob(destination + '**/*').reject { |fn| File.directory?(fn) }

      # The directories that should not be removed
      current_directories = []

      # The files that should not be removed
      current_files = []

      # AQL api search url
      aql_url = "http://#{artifactory_host}:#{artifactory_port}/artifactory/api/search/aql"

      query = repository_item_query(repository_name)

      response = post_query(aql_url, query, user, password)

      results = JSON.parse(response.body)['results']

      results.each do |result|
        # Create item path and then remove all instances of ./
        item_path = destination + result['path'] + '/' + result['name']

        item_path.gsub!(%r{\/\.\/}, '/')
        item_path.gsub!(%r{\/\.$}, '')

        # If the file doesn't exist sync repo
        return false if !File.exist?(item_path)

        # Get owner and group
        owner = File.stat(item_path).uid
        group = File.stat(item_path).gid
        mode =  (File.stat(item_path).mode & 0o7777).to_s(8)

        artifactory_owner = get_value(result['properties'], 'owner')
        artifactory_group = get_value(result['properties'], 'group')
        artifactory_mode = get_value(result['properties'], 'mode')

        if !artifactory_owner.nil?
          artifactory_uid = if /\A\d+\z/ =~ artifactory_owner
                              artifactory_owner.to_i
                            elsif !artifactory_owner.nil?
                              Etc.getpwnam(artifactory_owner).uid
                            end
        end

        if !artifactory_group.nil?
          artifactory_gid = if /\A\d+\z/ =~ artifactory_group
                              artifactory_group.to_i
                            elsif !artifactory_group.nil?
                              Etc.getpwnam(artifactory_group).uid
                            end
        end

        # If the owner is defined make sure it matches
        if !artifactory_uid.nil? && artifactory_uid != owner
          return false
        end

        # If the group is defined make sure it matches
        if !artifactory_gid.nil? && artifactory_gid != group
          return false
        end

        # If the mode is defined make sure it matches
        if !artifactory_mode.nil? && artifactory_mode != mode
          # Remove leading 0 if on artifactory_mode
          artifactory_mode.gsub!(/^0/, '')

          if artifactory_mode != mode
            return false
          end
        end

        if result['type'] == 'folder'
          return false if !all_directories.include?(item_path + '/')

          current_directories.push item_path + '/'
        else
          current_files.push(item_path)

          return false if !File.exist?(item_path)
          # Compute digest for a file
          sha1 = Digest::SHA1.file item_path

          # Make sure the sha1 hashes match
          return false if sha1 != result['actual_sha1']
        end
      end

      file_differences = all_files - current_files

      if !file_differences.empty?
        return false
      end

      directory_differences = all_directories - current_directories

      if !directory_differences.empty?
        return false
      end

      return true
    end
  end

  # Write a new file to the destination
  def write_file(result, destination, artifactory_host, artifactory_port, user, password)
    uri = URI("http://#{artifactory_host}:#{artifactory_port}/artifactory/#{result['repo']}/#{result['path']}/#{result['name']}")
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new uri

      if user && password
        request.basic_auth user, password
      end

      http.request request do |response|
        if response.code == "200"
          open(destination + result['path'] + '/' + result['name'], 'wb') do |io|
            response.read_body do |chunk|
              io.write chunk
            end
          end
        end
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
    artifactory_port = @resource.value(:artifactory_port)
    destination      = @resource.value(:destination)
    user             = @resource.value(:user)
    password         = @resource.value(:password)

    repository_name  = resource[:name]

    # All of the directories under the root
    all_directories = Dir.glob(destination + '**/')

    # All of the files under the root
    all_files = Dir.glob(destination + '**/*').reject { |fn| File.directory?(fn) }

    # The directories that should not be removed
    current_directories = []

    # The files that should not be removed
    current_files = []

    # AQL api search url
    aql_url = "http://#{artifactory_host}:#{artifactory_port}/artifactory/api/search/aql"

    query = repository_item_query(repository_name)

    response = post_query(aql_url, query, user, password)

    results = JSON.parse(response.body)['results']

    results.each do |result|
      # Create item path and then remove all instances of ./
      item_path = destination + result['path'] + '/' + result['name']

      item_path.gsub!(%r{\/\.\/}, '/')
      item_path.gsub!(%r{\/\.$}, '')

      # If the item (folder or file) doesn't exist create it
      if !File.exist?(item_path)
        if result['type'] == 'folder'
          Dir.mkdir item_path
        else
          write_file result, destination, artifactory_host, artifactory_port, user, password
        end
      end

      # Get owner and group
      owner = File.stat(item_path).uid
      group = File.stat(item_path).gid
      mode =  (File.stat(item_path).mode & 0o7777).to_s(8)

      artifactory_owner = get_value(result['properties'], 'owner')
      artifactory_group = get_value(result['properties'], 'group')
      artifactory_mode = get_value(result['properties'], 'mode')

      if !artifactory_owner.nil?
        artifactory_uid = if /\A\d+\z/ =~ artifactory_owner
                            artifactory_owner.to_i
                          elsif !artifactory_owner.nil?
                            Etc.getpwnam(artifactory_owner).uid
                          end
      end

      if !artifactory_group.nil?
        artifactory_gid = if /\A\d+\z/ =~ artifactory_group
                            artifactory_group.to_i
                          elsif !artifactory_group.nil?
                            Etc.getpwnam(artifactory_group).uid
                          end
      end

      # If the owner is defined make sure it matches
      if !artifactory_uid.nil? && artifactory_uid != owner
        File.chown(artifactory_uid, nil, item_path)
      end

      if !artifactory_gid.nil? && artifactory_gid != group
        File.chown(nil, artifactory_gid, item_path)
      end

      # If the mode is defined make sure it matches
      if !artifactory_mode.nil? && artifactory_mode != mode

        artifactory_mode.gsub!(/^([1-9])/, '0\1')

        File.chmod(artifactory_mode.to_i(8), item_path)
      end

      if result['type'] == 'folder'
        current_directories.push item_path + '/'
      else
        current_files.push(item_path)

        # Compute digest for a file
        sha1 = Digest::SHA1.file item_path

        # Make sure the sha1 hashes match
        if sha1 != result['actual_sha1']
          write_file result, destination, artifactory_host, artifactory_port, user, password
        end
      end
    end

    delete_files = all_files - current_files

    delete_files.each { |delete_file|
      File.delete(delete_file)
    }

    delete_dirs = all_directories - current_directories

    delete_dirs.each { |delete_dir|
      Dir.delete(delete_dir)
    }
  end
end
