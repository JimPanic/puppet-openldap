require 'tempfile'

Puppet::Type.type(:openldap_global_conf).provide(:olc) do

  # TODO: Use ruby bindings (can't find one that support IPC)

  defaultfor :osfamily => :debian, :osfamily => :redhat

  commands :slapcat => `which slapcat`.chomp,
           :slapadd => `which slapadd`.chomp

  mk_resource_methods

  def self.instances
    items = slapcat(
      '-b',
      'cn=config',
      '-H',
      'ldap:///???(objectClass=olcGlobal)'
    )
    items.split("\n").select{|e| e =~ /^olc/}.collect do |line|
      name, value = line.split(': ')
      # initialize @property_hash
      new(
        :name   => name[3, name.length],
        :ensure => :present,
        :value  => value
      )
    end
  end

  def self.prefetch(resources)
    items = instances
    resources.keys.each do |name|
      if provider = items.find{ |item| item.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    t = Tempfile.new('openldap_global_conf')
    t << "dn: cn=config"
    t << "add: olc#{name}"
    t << "olc#{name}: #{value}"
    t.close
    slapadd('-b', 'cn=config', '-l', t.path)
    @property_hash[:ensure] = :present
  end

  def destroy
    t = Tempfile.new('openldap_global_conf')
    t << "dn: cn=config"
    t << "delete: olc#{name}"
    t.close
    slapadd('-b', 'cn=config', '-l', t.path)
    @property_hash.clear
  end

  def value=(value)
    t = Tempfile.new('openldap_global_conf')
    t << "dn: cn=config\n"
    t << "replace: olc#{name}\n"
    t << "olc#{name}: #{value}\n"
    t.close
    slapadd('-b', 'cn=config', '-l', t.path)
    @property_hash[:value] = value
  end

end