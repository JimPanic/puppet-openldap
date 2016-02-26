require File.expand_path(File.join(File.dirname(__FILE__), %w[.. openldap]))
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. .. puppet_x openldap pw_hash.rb]))

Puppet::Type.
  type(:openldap_global_conf).
  provide(:olc, :parent => Puppet::Provider::Openldap) do

  desc <<-EOS
  olc provider for slapd configuration. Uses slapcat and slapadd to change
  configuration.
  EOS

  mk_resource_methods

  def self.instances
    entries = get_entries(slapcat("(objectClass=olcGlobal)"))

    resources = entries.reduce([]) do |tuples, entry|
      # Return at most two items from split, otherwise value might end up being
      # an array if the value holds e.g. a schema definition and has ": " in it.
      tuples << entry.split(': ', 2)
      tuples
    end

    resources.collect do |key, value|
      new(
        # XXX: Is setting the name param here necessary or even
        #      possible/feasable?
        :name   => "#{key}-#{Puppet::Puppet_X::Openldap::PwHash.hash_string(value, :openldapglobalconf)}",
        :ensure => :present,
        :key    => key,
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
    ldif = temp_ldif()
    ldif << cn_config()
    ldif << add(resource[:key])
    ldif << key_value(resource[:key], resource[:value])
    ldif.close

    ldif_content = IO.read(ldif.path)

    Puppet.debug(ldif_content)

    begin
      ldapmodify(ldif.path)

    rescue Exception => e
      raise Puppet::Error,
        "LDIF content:\n#{IO.read(ldif.path)}\nError message: #{e.message}"
    end

    @property_hash[:ensure] = :present

    ldif_content
  end

  def destroy
    ldif = temp_ldif()
    ldif << cn_config()
    ldif << del(resource[:key])
    ldif.close

    Puppet.debug(IO.read(ldif.path))

    begin
      ldapmodify(ldif.path)

    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{IO.read(ldif.path)}\nError message: #{e.message}"
    end

    @property_hash.clear
  end

  def key=(new_key)
    fail("key is a readonly property and cannot be changed.")
  end

  def value=(new_value)
    fail("value is a readonly property and cannot be changed.")
  end

  # NOTE: With the resent change to immutable and uniquely identified pair
  # entries, this should never be called.
  # def value=(new_value)
  #   ldif = temp_ldif()
  #   ldif << cn_config()
  #   ldif << replace(key)
  #   ldif << key_value(key, new_value)
  #   ldif.close
  #
  #   Puppet.debug(IO.read(ldif.path))
  #
  #   begin
  #     ldapmodify('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', ldif.path)
  #
  #     @property_hash[:value] = new_value
  #
  #   rescue Exception => e
  #     raise Puppet::Error,
  #       "LDIF content:\n#{IO.read(ldif.path)}\nError message: #{e.message}"
  #   end
  # end
end
