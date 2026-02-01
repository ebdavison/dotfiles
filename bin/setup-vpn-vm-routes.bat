@echo off

rem ===================
rem CISCO subnets
rem /32 routes
route add 10.22.31.77 mask 255.255.255.255 10.211.2.133 metric 10 if 16
route add 10.204.156.250 mask 255.255.255.255 10.211.2.133 metric 10 if 16
route add 54.175.232.95 mask 255.255.255.255 10.211.2.133 metric 10 if 16

rem /21 routes
route add 199.91.136.0 mask 255.255.255.248 10.211.2.133 metric 10 if 16

rem /24 routes
route add 10.83.92.0 mask 255.255.255.0 10.211.2.133 metric 10 if 16
route add 10.83.192.0 mask 255.255.255.0 10.211.2.133 metric 10 if 16
route add 10.115.70.0 mask 255.255.255.0 10.211.2.133 metric 10 if 16
route add 10.123.173.0 mask 255.255.255.0 10.211.2.133 metric 10 if 16
route add 172.18.151.0 mask 255.255.255.0 10.211.2.133 metric 10 if 16

rem /16 routes
route add 64.104.0.0 mask 255.255.0.0 10.211.2.133 metric 10 if 16
route add 72.163.0.0 mask 255.255.0.0 10.211.2.133 metric 10 if 16
route add 149.96.0.0 mask 255.255.0.0 10.211.2.133 metric 10 if 16

rem /14 routes
route add 64.100.0.0 mask 255.252.0.0 10.211.2.133 metric 10 if 16
route add 173.36.0.0 mask 255.252.0.0 10.211.2.133 metric 10 if 16

rem calgary lab route
route add 10.85.0.0 mask 255.255.0.0 10.211.2.133 metric 10 if 16

rem ===================
rem MS subnets
rem /18 routes
route add 40.126.0.0 mask 255.255.192.0 10.211.2.133 metric 10 if 16

rem /17 routes
route add 40.125.0.0 mask 255.255.128.0 10.211.2.133 metric 10 if 16

rem /16 routes
route add 40.124.0.0 mask 255.255.0.0 10.211.2.133 metric 10 if 16

rem /14 routes
route add 13.104.0.0 mask 255.252.0.0 10.211.2.133 metric 10 if 16
route add 40.76.0.0 mask 255.252.0.0 10.211.2.133 metric 10 if 16
route add 40.120.0.0 mask 255.255.0.0 10.211.2.133 metric 10 if 16

rem /13 routes
route add 13.96.0.0 mask 255.248.0.0 10.211.2.133 metric 10 if 16
route add 23.96.0.0 mask 255.248.0.0 10.211.2.133 metric 10 if 16
route add 104.208.0.0 mask 255.248.0.0 10.211.2.133 metric 10 if 16
route add 40.112.0.0 mask 255.255.0.0 10.211.2.133 metric 10 if 16

rem /12 routes
route add 40.80.0.0 mask 255.240.0.0 10.211.2.133 metric 10 if 16
route add 40.96.0.0 mask 255.240.0.0 10.211.2.133 metric 10 if 16

rem /11 routes
route add 13.64.0.0 mask 255.224.0.0 10.211.2.133 metric 10 if 16

