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

`tokamak` is written in Perl, utilizing `App::Cmd` and `Carton` to deliver a bundled, easy to develop program.

On SmartOS, the following will get you ready to hack on `tokamak`:

```
pkgin -y up
pkgin -y in build-essential

npm install -g smartdc

cpan
> sudo
> install Carton
> exit

export PATH=/opt/local/lib/perl5/site_perl/bin:/opt/chef/bin

git clone git@github.com:helium/tokamak.git
cd tokamak
carton install
cd local/lib/perl5
ln -s ../../../lib/Tokamak* .
cd ../../..
```
