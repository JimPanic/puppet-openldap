require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. .. puppet_x openldap pw_hash.rb]))

module Puppet::Parser::Functions
  newfunction(:openldap_md5, :type => :rvalue, :doc => <<-EOS
      md5 hash function as used in the provider & defined types to uniquely
      identify a key-value pair.
    EOS
  ) do |args|

    raise(Puppet::ParseError, "openldap_md5(): Wrong number of arguments given") if args.size != 2

    string = args[0].to_s
    salt   = args[1].to_s

    Puppet::Puppet_X::Openldap::PwHash.hash_string(string, salt)
  end
end
