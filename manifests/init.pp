class fastmc (
  $id,
  $port,
  $jar,
  $java_version = 17,
  $heap_size    = '1G',
) {

  if $java_version == 17 {
    $runtime_source = 'https://github.com/ibmruntimes/semeru17-binaries/releases/download/jdk-17.0.1%2B12_openj9-0.29.1/ibm-semeru-open-jre_x64_linux_17.0.1_12_openj9-0.29.1.tar.gz'
  } elsif $java_version == 11 {
    $runtime_source = 'https://github.com/ibmruntimes/semeru11-binaries/releases/download/jdk-11.0.13%2B8_openj9-0.29.0/ibm-semeru-open-jre_x64_linux_11.0.13_8_openj9-0.29.0.tar.gz'
  } elsif $java_version == 8 {
    $runtime_source = 'https://github.com/ibmruntimes/semeru8-binaries/releases/download/jdk8u312-b07_openj9-0.29.0/ibm-semeru-open-jre_x64_linux_8u312b07_openj9-0.29.0.tar.gz'
  } else {
    fail("Unknown Java version '$java_version'")
  }

  # Dependencies

  include epel
  include firewall

  package { 'vmtouch':
    ensure => installed,
  }

  package { 'tmux':
    ensure => installed,
  }

  class { 'selinux':
    mode => permissive,
  }

  user { 'mc':
    ensure => present,
  }

  group { 'mc':
    ensure  => present,
    members => ['mc'],
  }
 
  firewall { "100 MC $id - Open port $port/TCP":
    ensure => present,
    dport  => $port,
    proto  => tcp,
    action => accept,
  }

  archive { "/opt/runtime-$java_version.tar.gz":
    ensure          => present,
    source          => $runtime_source,
    extract         => true,
    extract_command => "tar zxvf %s --one-top-level=runtime-$java_version --strip-components=1",
    extract_path    => '/opt/',
    cleanup         => true,
    creates         => "/opt/runtime-$java_version/",
  }

  file { "/opt/$id":
    ensure => directory,
    owner  => 'mc',
    group  => 'mc',
    mode   => '0770',
  }

  # Create this directory early to ensure vmtouch pre-loads the world on first run
  file { "/opt/$id/world":
    ensure => directory,
    owner  => 'mc',
    group  => 'mc',
    mode   => '0770',
  }

  archive { "/opt/$id/server.jar":
    ensure => present,
    source => $jar,
  }

  $start_script_hash = {
    'id'        => $id,
    'runtime'   => "/opt/runtime-$java_version/bin/java",
    'heap_size' => $heap_size,
  }
  file { "/opt/$id/start.sh":
    content => epp('fastmc/start.sh.epp', $start_script_hash),
    owner   => 'mc',
    group   => 'mc',
    mode    => '0770',
  }

  $server_props_hash = {
    'port' => $port,
  }
  file { "/opt/$id/server.properties":
    content => epp('fastmc/server.properties.epp', $server_props_hash),
    owner   => 'mc',
    group   => 'mc',
    mode    => '0770',
  }

  $service_hash = {
    'id' => $id,
  }
  file { "/etc/systemd/system/mc-$id.service":
    content => epp('fastmc/service.service.epp', $service_hash),
  }

  service { "mc-$id":
    ensure => running,
  }

}
