# bitwarden_rs_helper

Collection of blank configuration files, and helper script for managing
[bitwarden_rs](https://github.com/dani-garcia/bitwarden_rs) on my self hosted
instance.

This is deployed on an AWS EC2 t2.micro (free tier) instance on Debian 9.

## Usage

Still a work in progress so not super user friendly, but in general clone the
repository and duplicate any `*.example` file to the same name and location,
but without the `.example` extension.  Then change any personalised information
within those files and you should be good to go!

```
$ ./bitwarden_rs.sh help
Helper for bitwarden_rs management.
Usage: ./bitwarden_rs.sh COMMAND

    i[nstall] - sets up a fresh installation
    u[p]      - updates binaries, renews certs and starts bitwarden_rs
    d[own]    - stops bitwarden_rs
    h[elp]    - prints this message
```

At some point this will all be automated into the `install` command on the
script.
