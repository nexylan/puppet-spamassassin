# == Class: spamassassin
#
# This module manages spamassassin
#
class spamassassin (
  $allowedips       = '127.0.0.1',
  $allowtell        = false,
  $blacklist_from   = [],
  $createprefs      = false,
  $cron_ensure      = present,
  $helperhomedir    = '',
  $listenip         = '127.0.0.1',
  $local            = false,
  $maxchildren      = 5,
  $maxconnperchild  = 200,
  $maxspare         = 2,
  $minchildren      = 1,
  $minspare         = 2,
  $nouserconfig     = false,
  $package_ensure   = latest,
  $report_safe      = 1,
  $roundrobin       = false,
  $service_enable   = true,
  $service_ensure   = running,
  $syslog           = 'mail',
  $trusted_networks = '', # e.g. '192.168.'
  $whitelist_from   = [],

) {
  case $::osfamily {
    RedHat: {
      $package_list = [
        'perl-Encode-Detect', 'perl-Geography-Countries',
        'perl-IP-Country', 'perl-Mail-DKIM',
        'perl-Mail-DomainKeys', 'perl-Mail-SPF',
        'perl-Mail-SPF-Query', 'perl-Net-Ident',
        'spamassassin'
      ]
      $sa_update = '/usr/share/spamassassin/sa-update.cron 2>&1 | tee -a /var/log/sa-update.log'
      $sa_path = '/etc/mail/spamassassin'
      $sa_service = 'spamassassin'
    }
    Debian: {
      ## Debian seems to not have the following perl packages.
      ## * perl-IP-Country
      ## * perl-Mail-DomainKeys
      ## * perl-Mail-SPF-Query
      $package_list = [
        'libencode-detect-perl',
        'libgeography-countries-perl',
        'libmail-dkim-perl', 'libmail-spf-perl',
        'libnet-ident-perl', 'spamassassin', 'spamc'
      ]
      $sa_update = '/usr/bin/sa-update && /etc/init.d/spamassassin reload'
      $sa_path = '/etc/mail/spamassassin'
      $sa_service = 'spamassassin'
    }
    Gentoo: {
      $package_list = [
        'spamassassin'
      ]
      $sa_update = '/usr/bin/sa-update && /etc/init.d/spamd reload'
      $sa_path = '/etc/spamassassin'
      $sa_service = 'spamd'
    }
    default: {
      fail("Class spamassassin supports osfamilies RedHat, Debian and Gentoo. Detected osfamily is ${::osfamily}.")
    }
  }

  package { $package_list:
    ensure => $package_ensure,
  }

  file { "${sa_path}/init.pre":
    source  => 'puppet:///modules/spamassassin/init.pre',
    require => Package[ $package_list ],
    notify  => Service[ $sa_service ],
  }

  file { "${sa_path}/local.cf":
    content => template('spamassassin/local.cf.erb'),
    require => Package[ $package_list ],
    notify  => Service[ $sa_service ],
  }

  file { "${sa_path}/v310.pre":
    source  => 'puppet:///modules/spamassassin/v310.pre',
    require => Package[ $package_list ],
    notify  => Service[ $sa_service ],
  }

  file { "${sa_path}/v312.pre":
    source  => 'puppet:///modules/spamassassin/v312.pre',
    require => Package[ $package_list ],
    notify  => Service[ $sa_service ],
  }

  file { "${sa_path}/v320.pre":
    source  => 'puppet:///modules/spamassassin/v320.pre',
    require => Package[ $package_list ],
    notify  => Service[ $sa_service ],
  }

  file { "${sa_path}/v330.pre":
    source  => 'puppet:///modules/spamassassin/v330.pre',
    require => Package[ $package_list ],
    notify  => Service[ $sa_service ],
  }

  if $::osfamily == 'Debian' {
    file { '/etc/default/spamassassin':
      content => template('spamassassin/spamassassin-default.erb'),
      require => Package['spamassassin'],
      notify  => Service[ $sa_service ],
    }
  }

  cron { 'sa-update':
    ensure  => $cron_ensure,
    command => $sa_update,
    user    => 'root',
    hour    => 4,
    minute  => 10,
  }

  service { $sa_service:
    ensure  => $service_ensure,
    enable  => $service_enable,
    require => Package['spamassassin'],
  }
}
