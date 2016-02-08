Puppet::Type.type(:repository_sync).provide :linux do
  desc "Synchronizes an Artifactory repository on a linux server."


  defaultfor :osfamily => :RedHat

  def write_file(result, destination, artifactorty_host)
    Net::HTTP.start(artifactorty_host) do |http|
      resp = http.get('/artifactory/' + result['repo'] + '/' + result['path'] + '/' + result['name'])
      open(destination + '/' + result['path'] + '/' + result['name'], 'wb') do |file|
        file.write(resp.body)
      end
    end
  end

  def create
    # All of the directories under the root
    all_directories = Dir.glob(:destination + '/**/')

    # All of the files under the root
    all_files = Dir.glob(:destination + '/**/*').reject {|fn| File.directory?(fn) }

    # The directories that should not be removed
    current_directories = []

    current_directories.push(:destination)

    # The files that should not be removed
    current_files = []

    site = RestClient::Resource.new('http://' + :artifactory_host + 'artifactory/api/search/aql', 'bryanjbelanger', 'AP72yHkFrzshjdcHt6R3WbJxqsq')

    response = site.post  'items.find( { "repo":{"$eq":"libs-release-local"}, "type":{"$eq":"any"} }).include("name", "repo", "path", "type", "actual_sha1").sort({"$asc" : ["type","name"]})', :content_type => 'text/plain'

    results = JSON.parse(response.to_str)['results']

    results.each{ |result|
      if result['type'] == 'folder'
        FileUtils.mkdir_p :destination + '/' + result['path'] + '/' + result['name']
        current_directories.push('/tmp/' + result['path'] + '/' + result['name'] + '/')
      end
    }
  end
end
