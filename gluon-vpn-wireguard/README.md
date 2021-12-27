# gluon-mesh-vpn-wireguard-vxlan

You can use this package for connecting with wireguard to the Freifunk Mayen-Koblenz network.

You should use something like the following in the site.conf:

	
```
 mesh_vpn = {
	wireguard = {
		ntp = '0.openwrt.pool.ntp.org'
		peers = {
				{
					publickey ='N9uF5Gg1B5AqWrE9IuvDgzmQePhqhb8Em/HrRpAdnlY=',
					endpoint ='wg-ko1.freifunk-myk.de:30020',
					link_address = 'fe80::f000:22ff:fe12:01',
				},
				{
					publickey ='liatbdT62FbPiDPHKBqXVzrEo6hc5oO5tmEKDMhMTlU=',
					endpoint ='wg-ko2.freifunk-myk.de:30020',
					link_address = 'fe80::f000:22ff:fe12:02',
				},
			},
	},
	
```


And you should include the package in the site.mk of course!
