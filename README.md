# Serverstestapi
## Hello, this is test task for servers.com from Roman K.

This case implement simple API that allow to add hostname or IP ad address and track it TTL. 
Here I choice way without pure SQL, using gems: activerecord, sinatra, json, net-ping, net-uri

####POST /ips - add hosts
Allowed params: adress, on.
```
curl -X POST -d "address=hostname&on=true" http://api-test.frontandstart.com/ips
```

####UPDATE /ips/:id
```
curl -X PUT -d "address=hostname2&on=false" http://api-test.frontandstart.com/ips/:id/
```
####DELETE /api/:id
```
curl -X DELETE http://api-test.frontandstart.com/ips/:id/
```

#### GET /ips - list of hosts adress.
Get host information and statistic:

```
curl -X GET http://api-test.frontandstart.com/ips/
```

#### GET Hosts adress params. /ips/:id/
```
curl -X GET http://api-test.frontandstart.com/ips/:id/
```

#### GET all ping data between time interval /ips/1/pings/?from=2016-07-22T00:00:00Z&to=2016-07-23T00:00:00Z
```
curl -X GET http://api-test.frontandstart.com/ips/1/pings/?from=2016-07-22T00:00:00Z&to=2016-07-23T00:00:00Z
```

#### GET statistic data /ips/1/pings/?from=2016-07-22T00:00:00Z&to=2016-07-23T00:00:00Z
```
curl -X GET http://api-test.frontandstart.com/ips/1/pings/?stat=on&from=2016-07-19T11:06:18%22&to=2016-07-19T11:12:30
```

### Build graphic in browser with &graph=on method
#### GET /ips/1/pings/?from=2016-07-22T00:00:00Z&to=2016-07-23T00:00:00Z&graph=on
Open url in browser
1 day interval:
```
http://api-test.frontandstart.com/ips/1/pings/?from=2016-07-22T00:00:00Z&to=2016-07-23T00:00:00Z&graph=on
```
few minutes range
http://api-test.frontandstart.com/ips/1/pings/?from=2016-07-21T22:08:00Z&to=2016-07-21T22:09:33Z&graph=on

#### GET compact data (need for build ?graph=on)
```
curl -X GET http://api-test.frontandstart.com/ips/1/pings/?compact=on&from=2016-07-19T11:06:18:22&to=2016-07-19T11:12:30
```
I backup in production DB development database, that is reason why somewhere on graph you see how line connect and in another cases line goest to ground. That is mean some period my algorythm write nill and another perods ""
I leave empty becouse this is more relevant. Also i have very poor internet connetion in this location sometime work across mobile and wi-fi hostspot was really far from my place and somewhere you see hadled 5s and 40s pings(promise that is not me by own hand).
Generally all process take less 3-4 days most of time i reseaerch ICMP
And find few more elegant way to pass this without net::ping::icmp (needed root for working)
for ex this (https://github.com/zzip/icmp4em)

#### yandex.ru
Good situation (http://api-test.frontandstart.com/ips/1/pings/?from=2016-07-23T22:08:00Z&to=2016-07-23T22:09:33Z&graph=on)
Bad (http://api-test.frontandstart.com/ips/1/pings/?from=2016-07-21T20:01:00Z&to=2016-07-21T20:20:33Z&graph=on)
