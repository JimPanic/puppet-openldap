require File.expand_path(File.join(File.dirname(__FILE__), %w[.. openldap]))

Puppet::Type.
  type(:openldap_global_conf).
  provide(:olc, :parent => Puppet::Provider::Openldap) do

  # TODO: Use ruby bindings (can't find one that support IPC)

  mk_resource_methods

  def self.instances
    items = slapcat(
      '-b',
      'cn=config',
      '-H',
      'ldap:///???(objectClass=olcGlobal)'
    )

    resources = get_entries(items).reduce({}) do |properties, entry|
      # Return at most two items from split, otherwise value might end up being
      # an array if the value holds e.g. a schema definition and has ": " in it.
      name, value = entry.split(': ', 2)

      if !properties.keys.include?(name)
        properties[name] = value
      else
        properties[name] = [properties[name], value].flatten
      end

      properties
    end

    resources.collect do |name, value|
      new(
        :name   => name,
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
    if resource.nil?
      return @property_hash[:ensure] == :present
    end

    if resource[:value].is_a?(Hash)
      return (resource[:value].keys - self.class.instances.map { |item| item.name }).empty?
    end

    @property_hash[:ensure] == :present
  end

  def create
    ldif = temp_ldif()
    ldif << cn_config()

    if resource[:value].is_a?(Hash)
      resource[:value].each do |key, value|
        ldif << add(key)
        ldif << key_value(key, value)
        ldif << delimit
      end
    else
      ldif << add(resource[:name])

      if resource[:value].is_a?(Array)
        resource[:value].each do |value|
          ldif << add(resource[:name])
          ldif << key_value(resource[:name], value)
          ldif << delimit
        end
      else
        ldif << key_value(resource[:name], resource[:value])
      end
    end

    ldif.close
    ldif_content = IO.read(ldif.path)

    Puppet.debug(ldif_content)

    begin
      ldapmodify('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', ldif.path)

    rescue Exception => e
      raise Puppet::Error,
        "LDIF content:\n#{IO.read ldif.path}\nError message: #{e.message}"
    end

    @property_hash[:ensure] = :present

    ldif_content
  end

  def destroy
    ldif = temp_ldif()
    ldif << cn_config()

    if resource[:value].is_a?(Hash)
      resource[:value].keys.each do |key|
        ldif << del(key)
        ldif << delimit
      end
    else
      ldif << del(name)
    end

    ldif.close

    Puppet.debug(IO.read ldif.path)

    begin
      ldapmodify('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', ldif.path)

    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{IO.read ldif.path}\nError message: #{e.message}"
    end

    @property_hash.clear
  end

  def value
    return @property_hash[:value] if resource.nil?

    if resource[:value].is_a?(Hash)
      instances = self.class.instances

      values = resource[:value].map do |k, v|
        [ k, instances.find { |item| item.name == k }.get(:value) ]
      end

      return Hash[values]
    end

    resource[:value]
  end

  def value=(value)
    ldif = temp_ldif()
    ldif << cn_config()

    if resource.nil?
      ldif << replace(name)
      ldif << key_value(name, value)
    else
      if resource[:value].is_a? Hash
        resource[:value].each do |k, v|
          ldif << replace(k)
          ldif << key_value(k, v)
          ldif << delimit
        end
      end
    end

    ldif.close

    Puppet.debug(IO.read(ldif.path))

    begin
      ldapmodify('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', ldif.path)

      @property_hash[:value] = value

    rescue Exception => e
      raise Puppet::Error,
        "LDIF content:\n#{IO.read ldif.path}\nError message: #{e.message}"
    end

  end

end
