# docker-perl-app-opan
Docker image providing App::opan running as a (preforking) server

## Usage

### Running the container
There is one mandatory environment variable that must be set: `OPAN_AUTH_TOKENS`. This should be a comma separated list of passwords that can be used when uploadring new releases. For more information on environment variables see [the documentation](https://metacpan.org/dist/App-opan/view/script/opan#uploads);

An example of running the container locally using docker:

```
# Create a directory where App::opan can persist data
mkdir -p pans
# Start the service
docker run \
    -it \
    --rm \
    --name opan \
    -e OPAN_AUTH_TOKENS=39703b48af5743d9a7867b73a3ae8256 \
    -p 3000:3000 \
    --user $(id -u):$(id -g) \
    --mount src="$(pwd)"/pans,target=/opt/opan/pans,type=bind \
    ghcr.io/stix/opan:main
```

This runs the container with:

 - password of `39703b48af5743d9a7867b73a3ae8256` for uploads (the username is `opan`)
 - service port of 3000 exposed
 - a directory called `pans/` mounted so that files are kept when stopping the container

**A note on mounting:** managing file permissions when running containers in multiple environments (locally, Swarm, k8s etc) can be a bit of a chore. You'll notice in the example above that the `--user` option is used. The way it is used here makes it so that the process in the container is run with *your* effective UID/GID so that all files stored by the process is owned by you. *This may or may not be what you want.* This is almost certainly not what you would want to do in a production environment, so modify accordingly.

### Uploading
Your release process is pretty much up to you, but if the common thing is that you have to set the username, password and uri the cpan uploader should use in whatever way you prefer. An example here for `Dist::Zilla` (file: `dist.ini`) using the `UploadToCPAN` plugin:

```
[%PAUSE]
username = opan
password = 39703b48af5743d9a7867b73a3ae8256
```

Uploading is then a matter of running:
```
CPAN_UPLOADER_UPLOAD_URI=http://localhost:3000/upload dzil release
```

You are _supposed to_ be able to set `upload_uri` in the `[%PAUSE]` block in `dist.ini`, but that doesn't seem to work. Using the environment variable does work however.

Storing the actual username and password in your `dist.ini` is naturally up to you, but not what is recommended. Most likely you'll have a CI/CD pipeline that builds and releases for you, and in that case you'll want to have the username and password stored as a secret in whatever system you are using and then inject them into `~/.pause`. An example `~/.pause` file would look like this (the whitespaces are important):

```
user opan
password 39703b48af5743d9a7867b73a3ae8256
```

### Installing modules
If you want to install modules from this PAN using `cpanm` you do:

```
cpanm \
    -n \
    --quiet \
    --mirror http://localhost:3000/combined/ \
    --mirror-only \
    -l $PERL_LOCAL_LIB_ROOT \
    Foo::Bar
```

In this example `Foo::Bar` and its dependencies are installed and:
 - not running tests (`-n`)
 - making the output neater (`--quiet`)
 - setting `App::opan` as your mirror combining both your custom distributions and cpan as a whole (`--mirror $url`)
 - fetching a combined `02packages` only from our mirror
 - placing the installed distributions to a `local::lib` managed directory
