require 'tempfile'
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. openldap]))

Puppet::Type.
  type(:openldap_config_hash).
  provide(:olc, :parent => Puppet::Provider::Openldap) do

  defaultfor :osfamily => :debian, :osfamily => :redhat

  mk_resource_methods

  def self.instances
    ldif = slapcat('(objectClass=olcGlobal)')

    entries = get_entries(ldif)

    resources = entries.reduce([]) do |tuples, entry|
      # Return at most two items from split, otherwise value might end up being
      # an array if the value holds e.g. a schema definition and has ": " in it.
      tuples << entry.split(': ', 2)
      tuples
    end

    resources.collect do |name, value|
      new(
        :name   => name,
        :value  => value,
        :ensure => :present
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
    if !resource.nil? && resource[:value].is_a?(Hash)
      (resource[:value].keys - self.class.instances.map { |item| item.name }).empty?
    else
      @property_hash[:ensure] == :present
    end
  end

  def create
    t = Tempfile.new('openldap_global_conf')
    t << "dn: cn=config\n"
    t << "changetype: modify\n"

    if resource[:value].is_a? Hash
      t << resource[:value].collect do |k, v|
        "add: olc#{k}\nolc#{k}: #{v}\n"
      end.join("-\n")
    else
      t << "add: olc#{resource[:name]}\n"
      t << "olc#{resource[:name]}: #{resource[:value]}\n"
    end

    t.close

    ldif_content = IO.read(t.path)

    Puppet.debug(ldif_content)

    begin
      ldapmodify(t.path)

    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{ldif_content}\nError message: #{e.message}"
    end

    @property_hash[:ensure] = :present

    ldif_content
  end

  def destroy
    t = Tempfile.new('openldap_global_conf')
    t << "dn: cn=config\n"
    t << "changetype: modify\n"
    if resource[:value].is_a? Hash
      t << resource[:value].keys.collect { |key| "delete: olc#{key}\n" }.join("-\n")
    else
      t << "delete: olc#{name}\n"
    end

    t.close

    ldif_content = IO.read(t.path)

    Puppet.debug(ldif_content)

    begin
      ldapmodify(t.path)

    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{ldif_content}\nError message: #{e.message}"
    end

    @property_hash.clear

    ldif_content
  end

  def value
    if resource[:value].is_a? Hash
      instances = self.class.instances
      values = resource[:value].map do |k, v|
        [ k, instances.find { |item| item.name == k }.get(:value) ]
      end
      Hash[values]
    else
      @property_hash[:value]
    end
  end

  def value=(value)
    t = Tempfile.new('openldap_global_conf')
    t << "dn: cn=config\n"
    t << "changetype: modify\n"
    if resource[:value].is_a? Hash
      resource[:value].each do |k, v|
        t << "replace: olc#{k}\n"
        t << "olc#{k}: #{v}\n"
        t << "-\n"
      end
    else
      t << "replace: olc#{name}\n"
      t << "olc#{name}: #{value}\n"
    end
    t.close
    Puppet.debug(IO.read(t.path))
    begin
      ldapmodify(t.path)
    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{IO.read(t.path)}\nError message: #{e.message}"
    end
    @property_hash[:value] = value
  end

end
