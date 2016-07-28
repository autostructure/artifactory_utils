[![Build Status](https://travis-ci.org/autostructure/artifactory_utils.svg?branch=master)](https://travis-ci.org/autostructure/artifactory_utils)
[![Puppet Forge](https://img.shields.io/puppetforge/v/autostructure/artifactory_utils.svg)](https://forge.puppetlabs.com/autostructure/artifactory_utils)
[![Puppet Forge](https://img.shields.io/puppetforge/f/autostructure/artifactory_utils.svg)](https://forge.puppetlabs.com/autostructure/artifactory_utils)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with artifactory_utils](#setup)
    * [What artifactory_utils affects](#what-artifactory_utils-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with artifactory_utils](#beginning-with-artifactory_utils)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

Providers and functions that allow Puppet to take advantage of full range of Artifactory capabilities.

## Module Description

Autostructure's artifactory_util module introduces providers which are used to manage resources contained in Artifactory.

This module extends configuration management to Artifactory. Packages, or other files, can be deployed through a simple http server. However Artifactory allows searches, maintains properties and stores checksums externally. These benefits can be leveraged by Puppet to enforce state and allow dynamic changes through the Artifactory UI.

If you need to deploy packages from Artifactory, or you want teams to manage the state of files from Artifactory you should use these utilities.

## Setup

### What artifactory_utils affects

* Files, directories and file systems in general.
* If synchronizing a repository use a unique destination. Anything under the synchronization tree WILL BE MODIFIED OR DELETED to conform to what is in Artifactory.

### Setup Requirements **OPTIONAL**

You will need a service account setup for Puppet in Artifactory. If you add credentials into hiera be sure to use [hiera-eyaml](https://github.com/TomPoulton/hiera-eyaml) to secure your api-key.

### Beginning with artifactory_utils

The very basic steps needed for a user to get the module up and running.

If your most recent release breaks compatibility or requires particular steps for upgrading, you may wish to include an additional section here: Upgrading (For an example, see http://forge.puppetlabs.com/puppetlabs/firewall).

## Usage

### Example of synchronizing a repository

Synchronize a repository:

~~~puppet
  repository_sync {'my-local-repo':
    ensure           => present,
    destination      => $destination,
    artifactory_host => $artifactory_host,
    user             => $user,
    password         => $password,
  }
~~~

Delete a repository:

~~~puppet
  repository_sync {'my-local-repo':
    ensure           => absent,
    destination      => $destination,
  }
~~~

Owners, groups and modes can be assigned through their respective properties in Artifactory:

![alt text](https://raw.githubusercontent.com/autostructure/artifactory_utils/master/images/repository.png "Artifactory example")

### Example of synchronizing a file

Synchronize a file:

~~~puppet
  artifact_sync {'/opt/tomcat/webapps/my_app.war':
    ensure     => present,
    source_url => 'http://artifactory.mydomain.com/artifactory/libs-release-local/com/mydomain/myapp/[RELEASE]/myapp-[RELEASE].war'
  }
~~~

Delete an artifact:

~~~puppet
  artifact_sync {'/opt/tomcat/webapps/my_app.war':
    ensure => absent,
  }
~~~

## Reference

Here, list the classes, types, providers, facts, etc contained in your module. This section should include all of the under-the-hood workings of your module so people know what the module is touching on their system but don't need to mess with things. (We are working on automating this section!)

## Limitations

This currently only work on *-nix nodes.

## Development

No rules for contributing yet, but any assistance on setting up spec is greatly appreciated.
