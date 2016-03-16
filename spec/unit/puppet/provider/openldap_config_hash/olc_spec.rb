require 'spec_helper'

describe Puppet::Type.type(:openldap_config_hash).provider(:olc) do

  let(:params) do
    {
      # openldap::server::config_hash { 'TLSCertificate':
      #    value => {
      #      'TLSCertificateFile'    => $::openldap::server::ssl_cert,
      #      'TLSCertificateKeyFile' => $::openldap::server::ssl_key,
      #    },
      #  }
      :title    => 'TLSCertificate',
      :value    => {
	:TLSCertificateFile    => '/etc/ssl/certs/cert.pem',
        :TLSCertificateKeyFile => '/etc/ssl/private/key.pem',
        :LogLevel              => 'stats'
      }
    }
  end

  let(:slapcat_output_exists) do
    <<-LDIF
dn: cn=config
olcTLSCertificateFile: /etc/ssl/certs/cert.pam
olcTLSCertificateKeyFile: /etc/ssl/private/key.pam
LDIF
  end

  let(:create_ldif) do
    <<-LDIF
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ssl/certs/cert.pem
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ssl/private/key.pem
-
add: olcLogLevel
olcLogLevel: stats
-
LDIF
  end

  let(:resource) do
    Puppet::Type.type(:openldap_config_hash).new(params)
  end

  let(:provider) do
    resource.provider
  end

  let(:instance) { provider.class.instances.first }

  before do
  end

  describe 'self.instances' do
    it 'returns an array of cn=config entry resources' do
      r = provider.class.
        stubs(:slapcat).
        with('(objectClass=olcGlobal)').
        returns(slapcat_output_exists)

      instances = provider.class.instances

      expect(instances.class).to match(Array)
    end
  end

  describe 'when creating' do
    it 'should create an entry in cn=config' do
      provider.stubs(:ldapmodify).returns(0)
      expect(provider.create).to eq(create_ldif)
    end
  end

  describe 'exists?' do
    it 'should return true' do
      provider.class.
        stubs(:slapcat).
        with('(objectClass=olcGlobal)').
        returns(slapcat_output_exists)
      expect(instance.exists?).to be_truthy
    end
  end
end
