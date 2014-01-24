# ex: syntax=puppet si ts=4 sw=4 et

class android_ec2_vpn (
    $username,
    $password,
    $pre_shared_key,
    $public_ipv4    = $::ec2_public_ipv4,
    $local_ipv4     = $::ec2_local_ipv4,
    $debug = false,
) {
    File {
        ensure => present,
        owner => 'root',
        group => 'root',
        mode  => '0644',
    }

    package { 'xl2tpd':
        ensure => latest,
    }

    package { 'racoon':
        ensure => latest,
    }

    package { 'ipsec-tools':
        ensure => latest,
    }

    file { '/etc/xl2tpd/xl2tpd.conf':
        content => template('android_ec2_vpn/xl2tpd/xl2tpd.conf.erb'),
        require => Package['xl2tpd'],
    }

    file { '/etc/ppp/options.xl2tpd':
        content => template('android_ec2_vpn/ppp/options.xl2tpd.erb'),
        require => Package['xl2tpd'],
    }

    file { '/etc/ppp/chap-secrets':
        content => template('android_ec2_vpn/ppp/chap-secrets.erb'),
        require => Package['xl2tpd'],
    }

    file { '/etc/racoon/racoon.conf':
        content => template('android_ec2_vpn/racoon/racoon.conf.erb'),
        require => Package['racoon'],
    }

    file { '/etc/racoon/psk.txt':
        content => template('android_ec2_vpn/racoon/psk.txt.erb'),
        mode    => '0600',
        require => Package['racoon'],
    }

    file { '/etc/ipsec-tools.conf':
        content => template('android_ec2_vpn/ipsec-tools/ipsec-tools.conf.erb'),
        require => Package['ipsec-tools'],
    }

    file { '/etc/ipsec-tools.d/l2tp.conf':
        content => template('android_ec2_vpn/ipsec-tools/l2tp.conf.erb'),
        require => Package['ipsec-tools'],
    }

    service { 'xl2tpd':
        ensure     => running,
        pattern    => '/usr/sbin/xl2tpd',
        hasstatus  => false,
        hasrestart => true,
        subscribe  => File['/etc/xl2tpd/xl2tpd.conf', '/etc/ppp/options.xl2tpd'],
    }

    service { 'racoon':
        ensure     => running,
        pattern    => '/usr/sbin/racoon',
        hasstatus  => false,
        hasrestart => true,
        subscribe  => File['/etc/racoon/racoon.conf', '/etc/racoon/psk.txt'],
    }

    exec { 'setkey restart':
        command     => '/usr/sbin/service setkey restart',
        user        => 'root',
        refreshonly => true,
        subscribe   => File['/etc/ipsec-tools.conf', '/etc/ipsec-tools.d/l2tp.conf'],
    }

    class { 'shorewall':
        ipv4_tunnels  => true,
        ip_forwarding => true,
    }
    shorewall::zone { 'inet':
        order => '50',
    }
    shorewall::zone { 'vpn':
        order => '50',
    }
    shorewall::policy { 'local-all':
        priority => '10',
        source   => '$FW',
        dest     => 'all',
        action   => 'ACCEPT',
    }
    shorewall::policy { 'vpn-inet':
        priority => '10',
        source   => 'vpn',
        dest     => 'inet',
        action   => 'ACCEPT',
    }
    shorewall::policy { 'all-all':
        priority  => '99',
        source    => 'all',
        dest      => 'all',
        action    => 'REJECT',
        log_level => 'info',
    }
    shorewall::iface { 'eth0':
        proto   => 'ipv4',
        options => [ 'tcpflags', 'routefilter', 'nosmurfs', 'logmartians' ],
        zone    => 'inet',
    }
    shorewall::iface { 'ppp+':
        proto   => 'ipv4',
        options => [ 'tcpflags', 'nosmurfs' ],
        zone    => 'vpn',
    }
    shorewall::port { 'ssh':
        application => 'SSH',
        source      => 'all',
        action      => 'ACCEPT',
        order       => '10',
    }
    shorewall::port { 'ike-tcp':
        proto       => 'tcp',
        port        => '500',
        source      => 'inet',
        action      => 'ACCEPT',
        order       => '10',
    }
    shorewall::port { 'ike-udp':
        proto       => 'udp',
        port        => '500',
        source      => 'inet',
        action      => 'ACCEPT',
        order       => '10',
    }
    shorewall::port { 'ipsec-nat-t':
        proto       => 'udp',
        port        => '4500',
        source      => 'inet',
        action      => 'ACCEPT',
        order       => '10',
    }
    shorewall::port { 'l2tp':
        proto       => 'udp',
        port        => '1701',
        source      => 'inet',
        action      => 'ACCEPT',
        order       => '10',
    }
    shorewall::masq { 'eth0':
        sources => [ '192.168.200.0/24' ],
    }
}
