openvpn_pki
===========

Simple `Makefile` which helps to manage OpenVPN PKI for the server and clients.


Usage
-----

```
# Create only the server side stuff
make server SERVER=myserver

# Create only the client side stuff
make client CLIENT=client01

# Allow to set a password for the .p12 file
make client CLIENT=client01 PASSWORD=''

# Create the server and the client side stuff with bigger keys
make client server SERVER=myserver CLIENT=client01 BITS=4096

# Prompt for all certificate details instead of reading if from the config file
make server BATCH=''

# Use an alternative OpenSSL config file
make server CONFIG=./my_openssl.cnf

# Create Certificate Revocation List (even with no revocation)
make revoke_gen_crl

# Revoke the client certificate
make revoke CLIENT=client01"
```


License
-------

MIT


Author
------

Jiri Tyr
