# android_ec2_vpn

## Overview

IPsec is a total pain in the ass, and Android devices are finicky about their
VPN servers.  Add that with EC2 both the server and the device are NATted,
and...  well... you have trouble sleeping.

## Inspiration

There are lots of fun tutorials and war stories about how to set this up.  Here
are the ones that guided me:

* http://confoundedtech.blogspot.com/2011/08/android-nexus-one-ipsec-psk-vpn-with.html
* https://wiki.debian.org/HowTo/AndroidVPNServer
* http://blogs.nopcode.org/brainstorm/2010/08/22/android-l2tpipsec-vpn-mini-howto/
* http://www.dikant.de/2010/10/08/setting-up-a-vpn-server-on-amazon-ec2/
* http://www.stormacq.com/build-a-private-vpn-server-on-amazons-ec2/

I probably missed some (in addition, of course, to the google+ post I can find
any more about incorrect/missing SPD entries when the server is NATted).  Many
thanks to the Internet.

## How to use it

### Server

The VPN server is an EC2 instance.  Start one up with a security group that has
these ports open for inbound traffic:

* TCP port 22
* TCP port 500
* UDP port 500
* UDP port 4500

Install this module using the command ```puppet module
inkblot/android_ec2_vpn```.  This will ensure that all of its dependencies are
satisfied.

Using puppet and this module, apply something like this on the server:

```puppet
class { 'android_ec2_vpn':
	username       => 'guesswho',
	password       => 'qwertyuiop',
	pre_shared_key => 'asdfghjkl;',
}
```

### Client

The VPN client is an Android device.  Create a new VPN connection:

* Name it whatever you want
* Set type to: ```L2TP/IPSec PSK```
* Set the ```Server address``` to the EC2 instance's public IP
* Leave ```L2TP secret``` blank
* Leave ```IPSec identifier``` blank
* Set the ```IPSec pre-shared key``` to the value of pre_shared_key parameter
  you used with the puppet class.

When you tell your device to connect, it will prompt for a username and
password.  Use the ```username``` and ```password``` parameter values that you
used with the puppet class.
