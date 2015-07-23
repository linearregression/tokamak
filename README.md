# tokamak

## SDC container management

`tokamak` allows you to manage containers on Joyent's SmartDatacenter infrastructure service.

`tokamak` is still under initial development. While basic functionality exists, quite a bit more is planned. Please see the GitHub Issues page.

## Usage

```
$ carton exec ./tokamak
SDC:   helium_dev @ https://cloudapi.helium.systems

tokamak <command>

Available commands:

  commands: list the application's commands
      help: display a command's help screen

        ps: list containers
     roles: list roles defined in Chef
     start: start a container
      stop: stop a container
    verify: verify your admin config
```

See https://gist.github.com/bdha/bf01aa871e9f9839b10d for examples.

## Requirements

Perl.

`tokamak` currently requires Chef for shared configuration (and will soon support bootstrapping containers on creation.)

You must have a working Chef setup.

The Joyent `smartdc` tools, installed from `npm`.

## Configuration

You must configure `~/.tokamakrc` to contain your SDC auth information. You will need to have a working SDC SSH key on the system you are running `tokamak` on.

See `tokamakrc.example`.

## Configuration Setup

You will need to create several data bags in Chef:

* `tokamak::images`

```
{
  "id": "images",
  "comment": "Whitelisted SDC images",
  "list": [
    "b67492c2-055c-11e5-85d8-8b039ac981ec",
    "39f29a9e-cd82-11e4-bd38-0fed3261fa5f",
    "5683089c-d18d-11e4-b067-9f59180479b9",
    "e312a72c-0a18-11e5-9a87-9ba4a03d4234",
    "8777db28-d302-11e4-8cf2-8793bd757e0f",
    "4cbd2426-dee6-11e4-8ae3-b38f8b943cbe",
    "82d952c4-1b7b-11e5-a299-bb55cb08eab1",
    "d8d81aee-20cf-11e5-8503-2bc101a1d577"
  ],
  "defaults": {
    "os": "b67492c2-055c-11e5-85d8-8b039ac981ec",
    "kvm": "4cbd2426-dee6-11e4-8ae3-b38f8b943cbe",
    "lx": "82d952c4-1b7b-11e5-a299-bb55cb08eab1"
  }
}
```

* `tokamak::sizes`

```
{
  "id": "sizes",
  "comment": "Image sizes",
  "default_size": "small",
  "sizes": {
    "os": {
      "tiny":  "860bac7b-1925-e3ff-b078-88e01549b211",
      "small": "a08dfe7f-e9a8-49a6-908d-6d51dd63a012",
      "medium": "1f8ea056-9777-42ac-ace4-70b3d9465955",
      "large": "5e464cac-f7d1-41ec-accb-f7d6f1576393"
    },
    "kvm": {
      "small": "0f37c8fe-a18d-4ce2-bfdd-7074acb16275",
      "medium": "acc59c2a-20cb-4a12-b848-28445a185cd9",
      "large": "881ca665-0953-4779-8764-5fcb914e240d"
    }
  }
}
```

## Client Installation

### SmartOS 

```
pkgin -y up
pkgin -y in build-essential

npm install -g smartdc
```

### Arch Linux

```
pacman -Sy base-devel git
```

### Debian

```
apt-get install build-essential git
```

### OS X

You will need to install the XCode tools to get `gcc`, `git`, et al.


### Carton from the CPAN

`tokamak` uses a Perl module called Carton to localize its depenencies. If you've used `bundler` in Ruby, same idea.

If your OS does not offer a `p5-Carton` package, you can install it from the CPAN easily.

You will likely want to accept the defaults CPAN offers for your distribution.

(`cpan` might ask you to use `local::lib`, `sudo`, or `manual`. Choose `sudo`.)

```
sudo cpan
> o conf prerequisites_policy follow
> o commit
> install Carton
> exit
```

If Carton installs successfully but is not contained in your default `$PATH`,
you may need to look for it in one of your Perl's `@INC` bindirs. This tends to
be very distro-specific, so you might try:

```
find /opt/local -name carton
find /usr -name carton
```

And then add the resulting directory to your `PATH`:

```
export PATH=/opt/local/lib/perl5/site_perl/bin:/opt/chef/bin
```

### Building tokamak

```
git clone git@github.com:helium/tokamak.git
cd tokamak
carton install
cd local/lib/perl5
ln -s ../../../lib/Tokamak* .
cd ../../..
```

`carton exec ./tokamak` should now be ready for use.
