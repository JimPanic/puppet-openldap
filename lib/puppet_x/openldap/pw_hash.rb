require 'digest/md5'

module Puppet
  module Puppet_X
    module Openldap
      class PwHash

        def self.hash_string(string, salt)
          # The pw_hash function doesn't work on all platforms. Using MD5
          # instead.
          #pw_hash(string, :sha256, salt.to_s)
          Digest::MD5.hexdigest("#{string}-#{salt.to_s}")
        end

        # NOTE: This code has been copied directly from puppetlabs-stdlib's parser
        #       functions!
        #
        # Hashes a password using the crypt function. Provides a hash
        # usable on most POSIX systems.
        #
        # The first argument to this function is the password to hash. If it is
        # undef or an empty string, this function returns undef.
        #
        # The second argument to this function is which type of hash to use. It
        # will be converted into the appropriate crypt(3) hash specifier. Valid
        # hash types are:
        #
        # |Hash type            |Specifier|
        # |---------------------|---------|
        # |MD5                  |1        |
        # |SHA-256              |5        |
        # |SHA-512 (recommended)|6        |
        #
        # The third argument to this function is the salt to use.
        #
        # NOTE: this uses the Puppet Master's implementation of crypt(3). If your
        # environment contains several different operating systems, ensure that they
        # are compatible before using this function.
        def self.pw_hash(string, hashing_type_name, salt)
          unless string.is_a?(String)
            raise ArgumentError, "pw_hash(): first argument must be a string" 
          end
          
          unless [String, Symbol].include?(hashing_type_name.class)
            raise ArgumentError, "pw_hash(): second argument must be a string
            or symbol, not '#{hashing_type_name.class}'"
          end

          hashes = { :md5    => '1',
                     :sha256 => '5',
                     :sha512 => '6' }
          hash_type = hashes[hashing_type_name.to_sym]

          raise ArgumentError, "pw_hash(): #{hashing_type_name} is not a valid hash type" if hash_type.nil?

          unless salt.is_a?(String)  
            raise ArgumentError, "pw_hash(): third argument must be a string"
          end

          raise ArgumentError, "pw_hash(): third argument must not be empty" if salt.empty?
          unless salt.match(/\A[a-zA-Z0-9.\/]+\z/)
            raise ArgumentError, "pw_hash(): characters in salt must be in the set [a-zA-Z0-9./]" 
          end

          return nil if string.nil? || string.empty?

          # handle weak implementations of String#crypt
          if 'test'.crypt('$1$1') != '$1$1$Bp8CU9Oujr9SSEw53WV6G.'
            # JRuby < 1.7.17
            if RUBY_PLATFORM == 'java'
              # override String#crypt for password variable
              def string.crypt(salt)
                # puppetserver bundles Apache Commons Codec
                org.apache.commons.codec.digest.Crypt.crypt(self.to_java_bytes, salt)
              end
            else
              # MS Windows and other systems that don't support enhanced salts
              raise Puppet::ParseError, 'system does not support enhanced salts'
            end
          end

          string.crypt("$#{hash_type}$#{salt.to_s}")
        end
      end
    end
  end
end
