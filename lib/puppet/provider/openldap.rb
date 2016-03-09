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
    items.strip.
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

  def delimit
    "-\n"
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

  def add_or_replace_key(key, force_replace = :false)
    # This list of possible attributes of cn=config has been extracted from a
    # running slapd with the following command:
    #   ldapsearch -s base -b cn=Subschema attributeTypes -o ldif-wrap=no | \
    #     grep SINGLE-VALUE | grep "NAME 'olc" | \
    #     sed -e "s|.*NAME '||g" \
    #         -e "s|' SYNTAX.*||g" \
    #         -e "s|' EQUALITY.*||g" \
    #         -e "s|' DESC.*||g"

    single_value_attributes = %w[ConfigFile ConfigDir AddContentAcl ArgsFile
      AuthzPolicy Backend Concurrency ConnMaxPending ConnMaxPendingAuth Database
      DefaultSearchBase GentleHUP Hidden IdleTimeout IndexSubstrIfMinLen
      IndexSubstrIfMaxLen IndexSubstrAnyLen IndexSubstrAnyStep IndexIntLen LastMod
      ListenerThreads LocalSSF LogFile MaxDerefDepth MirrorMode ModulePath Monitoring
      Overlay PasswordCryptSaltFormat PidFile PluginLogFile ReadOnly Referral
      ReplicaArgsFile ReplicaPidFile ReplicationInterval ReplogFile ReverseLookup
      RootDN RootPW SaslAuxprops SaslHost SaslRealm SaslSecProps SchemaDN SizeLimit
      SockbufMaxIncoming SockbufMaxIncomingAuth Subordinate SyncUseSubentry Threads
      TLSCACertificateFile TLSCACertificatePath TLSCertificateFile
      TLSCertificateKeyFile TLSCipherSuite TLSCRLCheck TLSCRLFile TLSRandFile
      TLSVerifyClient TLSDHParamFile TLSProtocolMin ToolThreads UpdateDN WriteTimeout
      DbDirectory DbCheckpoint DbNoSync DbMaxReaders DbMaxSize DbMode DbSearchStack
      PPolicyDefault PPolicyHashCleartext PPolicyForwardUpdates PPolicyUseLockout
      MemberOfDN MemberOfDangling MemberOfRefInt MemberOfGroupOC MemberOfMemberAD
      MemberOfMemberOfAD MemberOfDanglingError SpCheckpoint SpSessionlog SpNoPresent
      SpReloadHint]

    use_replace = single_value_attributes.include?(key.to_s) || force_replace == :true

    return use_replace ?
      replace_value(key) :
      add(key)
  end
end
