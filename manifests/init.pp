# ----------------------------------------------------------------------------
#  Copyright 2005-2013 WSO2, Inc. http://www.wso2.org
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# ----------------------------------------------------------------------------
#
# Class: esb
#
# This class installs WSO2 BAM
#
# Parameters:
#
# Actions:
#   - Install WSO2 BAM
#
# Requires:
#
# Sample Usage:
#

class esb (
  $version            = undef,
  $offset             = 0,
  $hazelcast_port     = 4000,
  $config_db          = governance,
  $maintenance_mode   = true,
  $depsync            = false,
  $sub_cluster_domain = mgt,
  $clustering         = false,
  $cloud              = false,
  $members            = {},
  $owner              = root,
  $group              = root,
  $target             = '/mnt',
  $monitoring         = false,
) inherits params {

  $deployment_code = 'esb'
  $service_code    = 'esb'
  $carbon_version  = $version
  $carbon_home     = "${target}/wso2${service_code}-${carbon_version}"

  $service_templates = [
    'conf/axis2/axis2.xml',
    'conf/datasources/esb-datasources.xml',
    'conf/jndi.properties',
    'conf/carbon.xml',
  ]

  $common_templates = [
    'conf/user-mgt.xml',
    'conf/registry.xml',
    'conf/datasources/master-datasources.xml',
    ] 

  tag($service_code)

  clean { $deployment_code:
    mode   => $maintenance_mode,
    target => $carbon_home;
  }

  initialize { $deployment_code:
    repo      => $package_repo,
    version   => $carbon_version,
    mode      => $maintenance_mode,
    service   => $service_code,
    local_dir => $local_package_dir,
    owner     => $owner,
    target    => $target,
    require   => Clean[$deployment_code];
  }

  deploy { $deployment_code:
    service       => $service_code,
    security      => true,
    owner         => $owner,
    group         => $group,
    target        => $carbon_home,
    require       => Initialize[$deployment_code];
  }

  push_templates {
    $service_templates:
      target    => $carbon_home,
      directory => $service_code,
      require   => Deploy[$deployment_code];

    $common_templates:
      target    => $carbon_home,
      directory => 'wso2base',
      require   => Deploy[$deployment_code];
  }

  file { "${carbon_home}/bin/wso2server.sh":
    ensure    => present,
    owner     => $owner,
    group     => $group,
    mode      => '0755',
    content   => template("${deployment_code}/wso2server.sh.erb"),
    require   => Deploy[$deployment_code],
    notify    => Service["wso2${service_code}"],
  }


  file { "/etc/init.d/wso2${service_code}":
      ensure    => present,
      owner     => 'root',
      group     => 'root',
      mode      => '0775',
      content   => template("${deployment_code}/wso2${service_code}.erb"),
      require   => Deploy[$deployment_code],
  }

  cron { 'remove old files':
    command => "/usr/bin/find ${carbon_home}/repository/logs/ -type f -mtime +10 -exec rm {} \;",
    user    => 'root',
    hour    => 23, 
    minute  => 59,
  }


  service { "wso2${service_code}":
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      enable     => true,
      require    => [
            Initialize[$deployment_code],
            Deploy[$deployment_code],
            Push_templates[$service_templates],
            File["${carbon_home}/bin/wso2server.sh"],
            File["/etc/init.d/wso2${service_code}"],
      ]
 

  }
}

