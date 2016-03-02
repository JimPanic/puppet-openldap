require 'tempfile'

class Puppet::Provider::Openldap < Puppet::Provider

  initvars # without this, commands won't work

  defaultfor :osfamily => :debian,
             :osfamily => :redhat

  commands :original_slapcat    => 'slapcat',
           :original_ldapmodify => 'ldapmodify'

  def self.slapcat(filter)
    original_slapcat(
      '-b',
      'cn=config',
      '-H',
      "ldap:///???#{filter}"
    )
  end

  def delimit
    "-\n"
  end

  def cn_config()
    dn('cn=config')
  end

  def ldapmodify(path)
    original_ldapmodify('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', path)
  end

  def self.get_entries(items)
    items.
      gsub("\n ", "").
      split("\n").
      select  { |entry| entry =~ /^olc/ }.
      collect { |entry| entry.gsub(/^olc/, '') }
  end


  def temp_ldif()
    Tempfile.new('openldap_global_conf')
  end

  def dn(dn)
    "dn: #{dn}\n"
  end

  def changetype(t)
    "changetype: #{t}\n"
  end

  def add(key)
    "add: olc#{key}\n"
  end

  def del(key)
    "delete: olc#{key}\n"
  end

  def replace_value(key)
    "replace: olc#{key}\n"
  end

  def key_value(key, value)
    "olc#{key}: #{value}\n"
  end
end
