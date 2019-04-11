# nginx config notes

Make a file in this folder called htpasswd for HTTP basic authentication for
the `/admin` endpoint.  This can be done with `htpasswd` which is available
in the `apache2-utils` package.

```shell
$ htpasswd -c htpasswd <username>
```

## TODO:

Make the script walk a user through this automatically on running the install
command.
