openvpn_pki
===========

Simple `Makefile` which helps to manage OpenVPN PKI for the server and clients.


Usage
-----

```
# Create only the server CA and cert
make server SERVER=myserver

# Create server CA and cert with specific organization details
make server SERVER=myserver ORG='My Org Ltd.' OU='IT dep' EMAIL='info@example.com'

# Create server cert with alternative server names
make server SERVER=myserver EXTENSION=san SAN=DNS:server1,DNS:server2

# Create only the client side certificate
make client CLIENT=client01

# Allow to set a password for the .p12 file
make client CLIENT=client01 PASSOWRD=''

# Create the server and the client side certificates in one go and with stronger key
make server client SERVER=myserver CLIENT=client01 BITS=4096

# Prompt for all certificate details instead of reading it from the config file
make server BATCH=''

# Use an alternative OpenSSL config file
make server CONFIG=./my_openssl.cnf

# Create Certificate Revocation List (even with no previous revocation)
make revoke_gen_crl

# Revoke client certificate
make revoke CLIENT=client01
```


License
-------

MIT


Author
------

Jiri Tyr
