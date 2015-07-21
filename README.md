# tokamak

## helium container management

`tokamak` allows you to manage containers on Helium's SmartDatacenter infrastructure service.

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

See https://gist.github.com/bdha/ba7ce117cb246eeed0fc for examples.

## Requirements

`tokamak` requires access to SDC and Helium's Chef account.

You must have a working Chef setup for the Helium Hosted Chef account.

## Configuration

You must configure `~/.tokamakrc` to contain your SDC auth information. You will need to have a working SDC SSH key on the system you are running `tokamak` on.

See `tokamakrc.example`.

## Installation

### Carton from the CPAN

`tokamak` uses a Perl module called Carton to localize its depenencies. If you've used `bundler` in Ruby, same idea.

If your OS does not offer a `p5-Carton` package, you can install it from the CPAN easily.

You will likely want to accept the defaults CPAN offers for your distribution.

```
cpan
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

### SmartOS 

```
pkgin -y up
pkgin -y in build-essential

npm install -g smartdc
```

### Arch Linux

```
pacman base-devel git
```

### Debian

```
apt-get install build-essenetial git
```

### OS X

### Building tokamak

```
git clone git@github.com:helium/tokamak.git
cd tokamak
carton install
cd local/lib/perl5
ln -s ../../../lib/Tokamak* .
cd ../../..
```
