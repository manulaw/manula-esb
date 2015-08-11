define esb::push_templates ($directory, $target) {
  file { "${target}/repository/${name}":
    ensure  => present,
    owner   => $esb::owner,
    group   => $esb::group,
    mode    => '0755',
    content => template("${directory}/${name}.erb"),
    notify  => Service["wso2${esb::service_code}"],
  }
}
