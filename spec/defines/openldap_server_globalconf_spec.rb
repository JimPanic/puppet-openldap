require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. lib puppet_x openldap pw_hash.rb]))

describe 'openldap::server::globalconf' do

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      let :pre_condition do
        "class { 'openldap::server': }"
      end

      context 'without value' do
        it { expect { is_expected.to compile } }
      end

      context 'with a string value' do
        context 'with olc provider' do
          let (:title) { 'Security-18dec4827672e3bbe0f4bfb89be49936' }
          let (:params) {
            {
              :key   => 'Security',
              :value => 'tls=128',
            }
          }

          hash = Puppet::Puppet_X::Openldap::PwHash.hash_string('tls=128',
                                                                :openldapglobalconf)
          expected_title = "Security-#{hash}"

          it { is_expected.to contain_openldap__server__globalconf(expected_title).with({
            :key   => 'Security',
            :value => 'tls=128',
          })}
        end
      end

      context 'with an array value' do
        let (:title) { 'Security-18dec4827672e3bbe0f4bfb89be49936' }
        let(:params) {{ :value => ['bar', 'boo', 'baz'].sort }}

        context 'with olc provider' do
          let :pre_condition do
            "class { 'openldap::server': }"
          end

          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
