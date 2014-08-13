# This class downloads versioned Artifactory into folders chosen by the user
# [user]
#    Which user is going to run service and own folders
# [user]
#    Which group is going to own folders. Default is $user.
# [path]
#    The path to where Artifactory will be installed. Make sure it is created.
# [ensure]
#    Whether the service should be running.
#    Valid values are stopped (also called false), running (also called true).
#    Default is running
# [pidfile]
#    If you'd like to change this one. Default is /var/run/artifactory/artifactory.pid
# [version]
#    Version of Artifactory. Default 3.3.0
class artifactory(
  $user,
  $path,
  $group=$user,
  $ensure=running,
  $pidfile='/var/run/artifactory.pid',
  $version='3.3.0'
) {
# This file sets home, user, pid etc. This one is sourced in from init.d/artifactory.
  file { "$path/default":
    owner   => $user,
    group   => $group,
    mode    => '0744',
    content => template('artifactory/default.erb'),
  }

# Pidfile
  file{ '/var/run/artifactory':
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0644'
  }->
  file { $pidfile:
    owner   => $user,
    group   => $group,
    mode    => '0644',
  }

  wget::fetch{ "download-$version-artifactory":
    source      => "http://sourceforge.net/projects/artifactory/files/artifactory/3.3.0/artifactory-$version.zip/download",
    destination => "/tmp/artifactory.zip",
    execuser    => $user,
    require     => File["$path/default"]
  }->
  file{ "$path/home":
    owner  => $user,
    group  => $group,
    ensure => directory
  }->
  exec{ "unzip-artifactory-$version":
    command     => "rm -rf /tmp/artifactory-$version && unzip /tmp/artifactory.zip -d /tmp/ && cp -r /tmp/artifactory-$version/* $path/home",
    user        => $user,
  }->
  file{ "$path/home/tomcat/logs":
    owner   => $user,
    group   => $group,
    ensure  => directory,
    require => Exec["unzip-artifactory-$version"]
  }->
  file{ "$path/home/tomcat/logs/catalina.out":
    owner       => $user,
    group       => $group,
    ensure      => present,
    require     => Exec["unzip-artifactory-$version"],
    notify      => Service['artifactory']
  }

#$user must be able to restart service
  file { "/etc/sudoers.d/artifactory-${user}":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => 0440,
    content => "$user ALL= NOPASSWD: /sbin/service artifactory *\n",
  }

  file { '/etc/init.d/artifactory':
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('artifactory/init.d.erb'),
    notify  => Service[artifactory], # Restarts Artifactory when init-script changes
  }

  service{ 'artifactory':
    ensure    => $ensure,
    enable    => 'true',
    hasstatus => false,
    require   => [File[$pidfile],
      File['/etc/init.d/artifactory']]
  }
}