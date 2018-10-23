# teracy-dev-certs

teracy-dev extension for working with certificates related features.

This extension will generate self signed CA certificate and use that own CA to sign other certificates
to be used.

For example:

```
$ tree workspace/certs/
workspace/certs/
├── ca-key.pem
├── ca.crt
├── ca.csr
├── node.local.crt
├── node.local.csr
└── node.local.pem

0 directories, 6 files
```



## Prerequisites

- Vagrant >= 2.1, VirtualBox >= 5.2
- Ansible >= 2.7 if you're running Ansible on the host machine
- teracy-dev v0.6


## Supported Guest Operating System

- Ubuntu


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
        git: https://github.com/teracyhq-incubator/teracy-dev-certs.git
        branch: v0.1.0
      require_version: ">= 0.1.0"
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
        git: https://github.com/teracyhq-incubator/teracy-dev-certs.git
        branch: master
      require_version: ">= 0.1.0"
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
        git: https://github.com/teracyhq-incubator/teracy-dev-certs.git
        branch: develop
      require_version: ">= 0.1.0-SNAPSHOT"
      enabled: true
```



## How to trust the self-signed CA certificate

- The root CA certificate is generated at the `workspace/certs/ca.crt` and you must add this certificate
  as trusted on the running systems

- See:
  + http://wiki.cacert.org/FAQ/ImportRootCert
  + http://www.robpeck.com/2010/10/google-chrome-mac-os-x-and-self-signed-ssl-certificates/#.W88C1hMzab8
  + https://portal.threatpulse.com/docs/sol/Solutions/ManagePolicy/SSL/ssl_firefox_cert_ta.htm 


## Reference

You can override the following configuration variables on the
`workspace/teracy-dev-entry/config_override.yaml` file:

```yaml
teracy-dev-certs:
  # the node id which certs will provision
  node_id: "0" # 0 by default from teracy-dev-core
  ansible_mode: guest # or host to run ansible from the host machine
  common_name: "%{node_hostname_prefix}.%{node_domain_affix}"
  alt_names:
    - "%{node_hostname_prefix}.%{node_domain_affix}"
```

For example:

```yaml
teracy-dev-certs:
  # the node id which certs will provision
  node_id: "0" # 0 by default from teracy-dev-core
  ansible_mode: host # or host to run ansible from the host machine
  common_name: "%{node_hostname_prefix}.%{node_domain_affix}"
  alt_names:
    - "%{node_hostname_prefix}.%{node_domain_affix}"
    - "auth.%{node_hostname_prefix}.%{node_domain_affix}"
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
        git: git@github.com:hoatle/teracy-dev-certs.git # your forked repo
        branch: develop
      require_version: ">= 0.1.0-SNAPSHOT"
```
