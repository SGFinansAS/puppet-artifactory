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

# We create a home path where we unzip the content of artifactory.zip
  file{ "$path/home":
    owner  => $user,
    group  => $group,
    ensure => directory
  }

# Download the artifactory zip to /tmp, notify unzip
  wget::fetch{ "download-$version-artifactory":
    source      => "http://sourceforge.net/projects/artifactory/files/artifactory/$version/artifactory-$version.zip/download",
    destination => "/tmp/artifactory-$version.zip",
    execuser    => $user,
    notify      => Exec["unzip-artifactory-$version"]
  }

# Unzip the stuff that artifactory is made of.
# Create some folders that must be present
  exec{ "unzip-artifactory-$version":
    command     => "rm -rf /tmp/artifactory-$version && unzip /tmp/artifactory-$version.zip -d /tmp/ && cp -r /tmp/artifactory-$version/* $path/home",
    user        => $user,
    creates     => "$path/home/bin",
    require     => File["$path/home"],
    notify      => Service['artifactory']
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
  }

#$user must be able to restart service
  file { "/etc/sudoers.d/artifactory-${user}":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => 0440,
    content => "$user ALL= NOPASSWD: /sbin/service artifactory *\n",
  }

# Create a init file. sudo service start|stop|check and so on.
  file { '/etc/init.d/artifactory':
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('artifactory/init.d.erb'),
    notify  => Service[artifactory], # Restarts Artifactory when init-script changes
  }

# The actual service. Go crazy.
  service{ 'artifactory':
    ensure    => $ensure,
    enable    => 'true',
    hasstatus => false,
    require   => [File[$pidfile],
      File['/etc/init.d/artifactory'],
      File["$path/default"],
      File["$path/home/tomcat/logs/catalina.out"]]
  }
}