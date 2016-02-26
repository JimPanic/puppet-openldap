# See README.md for details.
define openldap::server::globalconf(
  $ensure = 'present',
  $key,
  $value,
) {

  if ! defined(Class['openldap::server']) {
    fail 'class ::openldap::server has not been evaluated'
  }

  if $::openldap::server::provider == 'augeas' {
    Openldap::Server::Globalconf[$title] ~> Class['openldap::server::service']
  }

  # Use a unique hash instead of the actual value to identify it
  $hashed_value = pw_hash($value, "sha-256", "openldap_global_conf")
  $name = "${key}-${hashed_value}"

  openldap_global_conf { $name:
    ensure   => $ensure,
    provider => $::openldap::server::provider,
    target   => $::openldap::server::conffile,
    key      => $key,
    value    => $value,
  }
}
