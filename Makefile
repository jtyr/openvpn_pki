ECHO=echo
OPENSSL=openssl
OPENVPN=openvpn
CHMOD=chmod
RM=rm
RM_F=$(RM) -f
MKDIR=mkdir
MKDIR_P=$(MKDIR) -p

INDEX=index.txt
SERIAL=serial
SERIAL_NUM=01
SERVER=server
CLIENT=client
CONFIG=openssl.cnf
EXTENSION=server
BATCH=-batch
DAYS=3650
BITS=2048
CA=ca
TA=ta
DH=dh$(BITS)
DEST=./keys
PASSWORD=-password pass:
COMMIN_CONFIG_PARAMS=MY_CA=$(CA) \
    MY_DAYS=$(DAYS) \
    MY_DEST=$(DEST) \
    MY_INDEX=$(INDEX) \
    MY_SERIAL=$(SERIAL)
SERVER_CONFIG_PARAMS=$(COMMIN_CONFIG_PARAMS) \
    MY_CN=$(SERVER)
CLIENT_CONFIG_PARAMS=$(COMMIN_CONFIG_PARAMS) \
    MY_CN=$(CLIENT)

define OPENSSL_CONFIG =
[req]
distinguished_name              = req_distinguished_name

[req_distinguished_name]
countryName                     = Country Name (2 letter code)
countryName_default             = ""
stateOrProvinceName             = State or Province Name (full name)
stateOrProvinceName_default     = ""
localityName                    = Locality Name (eg, city)
localityName_default            = ""
0.organizationName              = Organization Name (eg, company)
0.organizationName_default      = ""
organizationalUnitName          = Organizational Unit Name (eg, section)
organizationalUnitName_default  = ""
commonName                      = Common Name (e.g. server FQDN or YOUR name)
emailAddress                    = Email Address
emailAddress_default            = ""
commonName_default              = $$ENV::MY_CN

[ca]
default_ca                      = CA_default

[CA_default]
default_days                    = $$ENV::MY_DAYS
private_key                     = $$ENV::MY_DEST/$$ENV::MY_CA.key
certificate                     = $$ENV::MY_DEST/$$ENV::MY_CA.crt
new_certs_dir                   = $$ENV::MY_DEST
database                        = $$ENV::MY_DEST/$$ENV::MY_INDEX
default_md                      = sha256
policy                          = policy_anything
serial                          = $$ENV::MY_DEST/$$ENV::MY_SERIAL

[policy_anything]
countryName                     = optional
stateOrProvinceName             = optional
localityName                    = optional
organizationName                = optional
organizationalUnitName          = optional
commonName                      = supplied
name                            = optional
emailAddress                    = optional

[server]
basicConstraints                = CA:FALSE
nsCertType                      = server
nsComment                       = "Easy-RSA Generated Server Certificate"
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer:always
extendedKeyUsage                = serverAuth
keyUsage                        = digitalSignature, keyEncipherment
endef
export OPENSSL_CONFIG


.PHONY: all


all:
	@echo "OpenVPN PKI creation for the server and clients."
	@echo ""
	@echo "Usage: make [server|client]"
	@echo ""
	@echo "Examples:"
	@echo "  # Create only the server side stuff"
	@echo "  make server SERVER=myserver"
	@echo "  # Create only the client side stuff"
	@echo "  make client CLIENT=client01"
	@echo "  # Allow to set a password for the .p12 file"
	@echo "  make client CLIENT=client01 PASSOWRD=''"
	@echo "  # Create the server and the client side stuff with bigger keys"
	@echo "  make client server SERVER=myserver CLIENT=client01 BITS=4096"
	@echo "  # Prompt for all certificate details instead of reading if from the config file"
	@echo "  make server BATCH=''"
	@echo "  # Use an alternative OpenSSL config file"
	@echo "  make server CONFIG=./my_openssl.cnf"


server: init ca server_pki dh ta


ca: $(DEST)/$(CA).key $(DEST)/$(CA).crt

$(DEST)/$(CA).key $(DEST)/$(CA).crt:
	$(info ##### Creating CA key and certificate)
	$(SERVER_CONFIG_PARAMS) \
	$(OPENSSL) req $(BATCH) -days $(DAYS) -nodes -new -newkey rsa:$(BITS) -x509 -keyout $(DEST)/$(CA).key -out $(DEST)/$(CA).crt -config $(CONFIG)


server_pki: $(DEST)/$(SERVER).key $(DEST)/$(SERVER).csr $(DEST)/$(SERVER).crt

$(DEST)/$(SERVER).key $(DEST)/$(SERVER).csr:
	$(info ##### Creating Server key and certificate signed request)
	$(SERVER_CONFIG_PARAMS) \
	$(OPENSSL) req $(BATCH) -nodes -new -newkey rsa:$(BITS) -keyout $(DEST)/$(SERVER).key -out $(DEST)/$(SERVER).csr -extensions $(EXTENSION) -config $(CONFIG)

$(DEST)/$(SERVER).crt:
	$(info ##### Creating Server certificate)
	$(SERVER_CONFIG_PARAMS) \
	$(OPENSSL) ca $(BATCH) -days $(DAYS) -in $(DEST)/$(SERVER).csr -extensions $(EXTENSION) -config $(CONFIG) -out $(DEST)/$(SERVER).crt


dh: $(DEST)/$(DH).pem

$(DEST)/$(DH).pem:
	$(info ##### Creating Diffie-Hellman certificate)
	$(OPENSSL) dhparam -out $(DEST)/$(DH).pem $(BITS)


ta: $(DEST)/$(TA).key

$(DEST)/$(TA).key:
	$(info ##### Creating HMAC key)
	$(OPENVPN) --genkey --secret $(DEST)/$(TA).key


init: $(DEST) $(DEST)/$(INDEX) $(DEST)/$(SERIAL) $(CONFIG)

$(DEST):
	$(MKDIR_P) $(DEST)

$(DEST)/$(INDEX):
	$(ECHO) -n "" > $(DEST)/$(INDEX)

$(DEST)/$(SERIAL):
	$(ECHO) $(SERIAL_NUM) > $(DEST)/$(SERIAL)

$(CONFIG):
	$(ECHO) "$$OPENSSL_CONFIG" > $(CONFIG)

client: client_pki client_p12

client_pki: $(DEST)/$(CLIENT).key $(DEST)/$(CLIENT).csr $(DEST)/$(CLIENT).crt

$(DEST)/$(CLIENT).key $(DEST)/$(CLIENT).csr:
	$(info ##### Creating Client key and certificate signed request)
	$(CLIENT_CONFIG_PARAMS) \
	$(OPENSSL) req $(BATCH) -nodes -new -newkey rsa:$(BITS) -keyout $(DEST)/$(CLIENT).key -out $(DEST)/$(CLIENT).csr -config $(CONFIG)

$(DEST)/$(CLIENT).crt:
	$(info ##### Creating Client certificate)
	$(CLIENT_CONFIG_PARAMS) \
	$(OPENSSL) ca $(BATCH) -days $(DAYS) -out $(DEST)/$(CLIENT).crt -in $(DEST)/$(CLIENT).csr -config $(CONFIG)


client_p12: $(DEST)/$(CLIENT).p12

$(DEST)/$(CLIENT).p12:
	$(info ##### Exporting the Server CA and the Client key and certificate into one file (e.g. for Android))
	$(OPENSSL) pkcs12 -export -certfile $(DEST)/$(CA).crt -inkey $(DEST)/$(CLIENT).key -in $(DEST)/$(CLIENT).crt -out $(DEST)/$(CLIENT).p12 $(PASSWORD)


clear:
	$(RM_F) $(DEST)/*.{key,csr,crt,pem,p12}
	$(RM_F) $(DEST)/$(INDEX)*
	$(RM_F) $(DEST)/$(SERIAL)*
