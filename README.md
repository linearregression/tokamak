# tokamak

## helium container management

`tokamak` allows you to manage containers on Helium's SmartDatacenter infrastructure service.

## Usage

```
carton ./tokamak ps
```

See https://gist.github.com/bdha/ba7ce117cb246eeed0fc for examples.

## Requirements

`tokamak` requires access to SDC and Helium's Chef account. Nominally this means you have an `~/.sdcrc` and `~/.chef/knife.rb` set up.

## Development

`tokamak` is written in Perl, utilizing `App::Cmd` and `Carton` to deliver a bundled, easy to develop program.

Beyond simply adding features, `tokamak` needs to be converged from usng the SDC CLI tools to hitting the SDC API directly. `tokamak` executes `node` twice for every container lookup, which gets Very Slow.

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
