require 'spec_helper'

describe Puppet::Type.type(:openldap_global_conf).provider(:olc) do

  let(:params) do
    {
      :title    => 'Security',
      :value    => 'tls=128'
    }
  end

  let(:slapcat_output_exists) do
    <<-LDIF
dn: cn=config
olcSecurity: tls=128
LDIF
  end

  let(:create_ldif) do
    <<-LDIF
dn: cn=config
add: olc#{params[:title]}
olc#{params[:title]}: #{params[:value]}
LDIF
  end

  let(:resource) do
    Puppet::Type.type(:openldap_global_conf).new(params)
  end

  let(:provider) do
    resource.provider
  end

  let(:instance) { provider.class.instances.first }

  before do
  end

  describe 'self.instances' do
    it 'returns an array of cn=config entry resources' do
      provider.class.
        stubs(:slapcat).
        with('-b', 'cn=config', '-H', 'ldap:///???(objectClass=olcGlobal)').
        returns(slapcat_output_exists)

      instance = provider.class.instances.first

      expect(params[:title]).to match(instance.name)
      expect(params[:value]).to match(instance.value)
      expect(instance.ensure).to match(:present)
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
        with('-b', 'cn=config', '-H', 'ldap:///???(objectClass=olcGlobal)').
        returns(slapcat_output_exists)
      expect(instance.exists?).to be_truthy
    end
  end
end
