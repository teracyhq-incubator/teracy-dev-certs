# teracy-dev-certs

teracy-dev extension is used for certificates related functionalities.

This extension will generate self signed CA certificate and use that own CA to sign other certificates.


For example, the generated files:

```
$ tree workspace/certs/
workspace/certs/
├── node-local-ca-key.pem
├── node-local-ca.crt
├── node-local-key.pem
├── node-local.crt
└── node-local.csr

0 directories, 5 files
```


## Prerequisites

- Vagrant >= 2.1, VirtualBox >= 5.2
- Ansible >= 2.7 if you're running Ansible on the host machine
- teracy-dev >= 0.6.0-a5, < 0.7.0
- teracy-dev-core >= 0.4.0


## Supported Guest Operating System

- Ubuntu
- Debian
- RedHat
- Fedora
- FreeBSD

## How to use

Configure `workspace/teracy-dev-entry/config_default.yaml` with the following similar content:

- Use specific version:

```yaml
teracy-dev:
  extensions:
    - _id: "entry-certs"
      path:
        extension: teracy-dev-certs
      location:
        git:
          remote:
            origin: https://github.com/teracyhq-incubator/teracy-dev-certs.git
          branch: v0.5.0
      require_version: ">= 0.5.0"
      enabled: true
```

- Use latest stable version (auto update):

```yaml
teracy-dev:
  extensions:
    - _id: "entry-certs"
      path:
        extension: teracy-dev-certs
      location:
        git:
          remote:
            origin: https://github.com/teracyhq-incubator/teracy-dev-certs.git
          branch: master
      require_version: ">= 0.5.0"
      enabled: true
```

- Use latest develop version (auto update):

```yaml
teracy-dev:
  extensions:
    - _id: "entry-certs"
      path:
        extension: teracy-dev-certs
      location:
        git:
          remote:
            origin: https://github.com/teracyhq-incubator/teracy-dev-certs.git
          branch: develop
      require_version: ">= 0.6.0-SNAPSHOT"
      enabled: true
```

- Then configure your specified variables by following the [Reference](#reference)

- After that, `$ vagrant up --provision` or `$ vagrant provision` should generate certificates.


## How to trust the self-signed CA certificate

- The root CA certificate is generated at the `workspace/certs/<common_name>-ca.crt` and you must add this certificate
  as trusted on the running systems

- See:
  + http://wiki.cacert.org/FAQ/ImportRootCert
  + http://www.robpeck.com/2010/10/google-chrome-mac-os-x-and-self-signed-ssl-certificates/#.W88C1hMzab8
  + https://portal.threatpulse.com/docs/sol/Solutions/ManagePolicy/SSL/ssl_firefox_cert_ta.htm


## Useful openssl commands

We can use the following useful commands to check and verify the generated files.

### Check a private key

For example:

```bash
$ cd workspace/certs
$ openssl rsa -check -in node-local-ca-key.pem
$ openssl rsa -check -in node-local-key.pem
```

### Check a certificate

For example:

```bash
$ cd workspace/certs
$ openssl x509 -text -noout -in node-local-ca.crt
$ openssl x509 -text -noout -in node-local.crt
```

### Check a Certificate Signing Request (CSR)

For example:

```bash
$ cd workspace/certs
$ openssl req -text -noout -verify -in node-local.csr
```

### Check an MD5 hash of the public key to ensure that it matches with what is in a CSR or private key

For example:

```bash
$ cd workspace/certs
$ # root CA
$ openssl x509 -noout -modulus -in node-local-ca.crt | openssl md5
$ openssl rsa -noout -modulus -in node-local-ca-key.pem | openssl md5
$ # cert signed by the root CA
$ openssl x509 -noout -modulus -in node-local.crt | openssl md5
$ openssl rsa -noout -modulus -in node-local-key.pem | openssl md5
$ openssl req -noout -modulus -in node-local.csr | openssl md5
```

### Check an SSL connection. All the certificates (including Intermediates) should be displayed

For example:

```bash
$ cd workspace/certs
$ openssl s_client -connect node.local:443 -CAfile node-local-ca.crt
```


- See more:

  + https://www.sslshopper.com/article-most-common-openssl-commands.html


## Configuration Reference

You can override the following configuration variables on the
`workspace/teracy-dev-entry/config_override.yaml` file:

```yaml
teracy-dev-certs:
  # the node id which certs will provision
  node_id: "0" # 0 by default from teracy-dev-core
  ansible
    mode: guest # or host to run ansible from the host machine
    install_mode: pip
  ca:
    days: 2000 # valid days for the root CA cert
    pkcs1_generated: false # to generate the PKCS#1 *-ca.key from the *-ca-key.pem file
  cert:
    days: 825 # valid days for the owned CA signed cert
    generated: true # enabled by default to generate the owned CA signed cert
  common_name: "%{node_hostname_prefix}.%{node_domain_affix}"
  alt_names:
    - "%{node_hostname_prefix}.%{node_domain_affix}"
```

`ansible` has 2 modes:

- The `guest` mode (default): ansible is automatically installed in the VM machine by vagrant.

- The `host` mode: users need to install ansible into their host machine.

For example, this configuration specifies the `host` mode to run ansible with other options.

```yaml
teracy-dev-certs:
  # the node id which certs will provision
  node_id: "0" # 0 by default from teracy-dev-core
  ansible
    mode: host # or host to run ansible from the host machine
  ca:
    days: 3000 # valid days for the root CA cert
  cert:
    days: 825 # valid days for the owned CA signed cert
  common_name: "%{node_hostname_prefix}.%{node_domain_affix}"
  alt_names:
    - "%{node_hostname_prefix}.%{node_domain_affix}"
    - "accounts.%{node_hostname_prefix}.%{node_domain_affix}"
    - "login.%{node_hostname_prefix}.%{node_domain_affix}"
```


## How to develop

You should configure the forked git repo into the `workspace` directory by adding the following
similar content into `workspace/teracy-dev-entry/config_override.yaml`:


```yaml
teracy-dev:
  extensions:
    - _id: "entry-certs" # must match the _id configured from the config_default.yaml file
      path:
        lookup: workspace # use workspace directory to lookup for this extension
      location:
        git:
          remote:
            origin: git@github.com:hoatle/teracy-dev-certs.git # your forked repo
            upstream: git@github.com:teracyhq-incubator/teracy-dev-certs.git
        branch: develop
      require_version: ">= 0.6.0-SNAPSHOT"
```
