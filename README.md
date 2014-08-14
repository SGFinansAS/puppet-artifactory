puppet-artifactory
==================

Install of Artifactory as a service using zip not package

### Why
Why another puppet artifactory? Well sometimes your host provider simple does not allow you to create users as you'd like. Artifactory package creates an user named artifactory, and sometimes that's not wanted.

Also, package, and install-script, creates some [defaults](http://www.jfrog.com/confluence/display/RTF/Installing+on+Linux+Solaris+or+Mac+OS#InstallingonLinuxSolarisorMacOS-ManagedFilesandFolders) like ARTIFACTORY_HOME equals var/opt/jfrog/artifactory. This version you can specify ARTIFACTORY_HOME.


### Usage
```puppet
class{ 'artifactory':
    user     => 'app-user',
    group    => 'www-users',
    path     => '/app/artifactory',
    ensure   => running,
    version  => '3.3.0',
    pidfile  => '/var/run/artifactory.pid',
    require  => File['/app/artifactory']
}
```
This also lists the defaults. Apart from **user** and **path** which are mandatory. **group** will be same as **user** if not given.

### Dependencies

* maestrodev/wget (https://github.com/maestrodev/puppet-wget)
* Some form of Java
* Package['unzip']

### FAQ
**Is it "production" ready?**<br>
Well, we use it.
