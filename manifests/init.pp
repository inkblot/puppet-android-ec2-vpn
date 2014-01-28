# ex: syntax=puppet si ts=4 sw=4 et

class android_ec2_vpn (
    $username,
    $password,
    $pre_shared_key,
    $public_ipv4    = $::ec2_public_ipv4,
    $local_ipv4     = $::ec2_local_ipv4,
    $mtu            = '1300',
    $mru            = '1300',
    $debug          = false,
) {

    class { 'racoon':
        pre_shared_keys => {
            'android-user' => {
                'peer' => '*',
                'key'  => $pre_shared_key,
            },
        },
        encapsulate     => {
            'l2tp-local'  => {
                local_ip => $local_ipv4,
                port     => 'l2tp',
                proto    => 'udp',
            },
            'l2tp-public' => {
                local_ip => $public_ipv4,
                port     => 'l2tp',
                proto    => 'udp',
            },
        },
        remotes         => {
            'android-user' => {
                'address'         => 'anonymous',
                'mode'            => 'main',
                'generate_policy' => true,
                'my_identifier'   => {
                    'type'  => 'address',
                    'value' => $public_ipv4,
                },
                'nat_traversal'   => 'on',
                'proposal'        => {
                    'encryption_algorithm'  => '3des',
                    'hash_algorithm'        => 'sha1',
                }
            },
        },
        associations    => {
            'android-user' => {
                'type'                     => 'anonymous',
                'encryption_algorithm'     => [ 'aes', '3des' ],
                'authentication_algorithm' => [ 'hmac_sha1', 'hmac_md5' ],
                'compression_algorithm'    => 'deflate',
            },
        },
    }

    class { 'xl2tpd':
        min_dynamic_ip => '192.168.200.100',
        max_dynamic_ip => '192.168.200.110',
        tunnel_ip      => '192.168.200.10',
        dns_servers    => [ '8.8.4.4', '8.8.8.8' ],
        mtu            => $mtu,
        mru            => $mru,
        debug          => $debug,
    }

    class { 'ppp':
        chap_users => {
            "${username}" => {
                password => $password,
            },
        },
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
