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

## Installation

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
apt-get install build-essenetial git
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
