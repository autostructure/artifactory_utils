require 'spec_helper_acceptance'

describe 'artifactory_utils::artifact_sync' do
  let(:title) { '/tmp/my_app.war' }

  let(:params) {
    {
      ensure: 'present',
      source_url: 'http://artifactory.azcender.com/artifactory/temp/org/apache/sample/1.0.0/sample-1.0.0.war'
    }
  }

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end
      end
    end
  end

  # context 'default parameters' do
  #   # Using puppet_apply as a helper
  #   it 'should work idempotently with no errors' do
  #     pp = <<-EOS
  #     class { 'artifactory_utils': }
  #     EOS

  #     # Run it twice and test for idempotency
  #     apply_manifest(pp, catch_failures: true)
  #     apply_manifest(pp, catch_changes: true)
  #   end
  # end
end
