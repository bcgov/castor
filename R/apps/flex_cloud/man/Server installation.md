---
title: "Creating FLEX Cloud Deployment image"
output: github_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## Creating base image

A new droplet is created with the following parameters:

-   Distro: Ubuntu 22.04 LTS x64

-   Plan: Shared CPU - Basic

-   CPU Options:

    -   Regular with SSD

    -   2GB / 1 CPU

    -   50GB SSD Disk

    -   2TB transfer

-   Data center: Toronto (TOR1)

-   SSH keys: select all

-   Enabled monitoring

-   Host name: `flex-cloud-image`

## Initial Server Setup

As documented at <https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04>.

SSH to droplet and update OS (replace DROPLET_IP_ADDRESS with actual public IP address of the droplet:

```{bash}
ssh root@DROPLET_IP_ADDRESS -i ~/.ssh/sasha
apt update
apt upgrade -y

ufw app list
ufw allow OpenSSH
ufw enable
ufw status
```


## Add swap space

From the tutorial at https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-20-04.

```{bash}
fallocate -l 16G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
swapon --show
cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
sysctl vm.swappiness=10
sysctl vm.vfs_cache_pressure=50
nano /etc/sysctl.conf
```

Add the following settings at the bottom of the file:

```
vm.swappiness=10
vm.vfs_cache_pressure=50
```

## Generate public-private key pair for communication with scenario droplet

Generate public-private key pair for communication with scenario droplet, to be able to download the
scenario to the droplet running the simulation.

```
ssh-keygen
```

## Install OS Libraries

Start a `screen` session on the server (so that any running jobs will keep running
if the connection is dropped, and you can reconnect and continue as needed).

```{bash}
screen -S install
```

`screen` tips:

- To detach from the `screen` session and return to the main ssh connection, 
press and hold `Ctrl` key and then press `A` and `D` in sequence.

- If the connection is dropped, you can reconnect with `screen -x install`.

- When the job is done, you can end the session by typing `exit`.

- If you are not sure if you are inside the screen session or not, type `echo $STY`.
If the output is empty, you are not in the `screen` session but in the main ssh 
connection session. If the output is not empty, it is the name of the `screen` 
session you are in.

Install system dependencies:

``` bash
apt install -y libsodium-dev \
    libudunits2-dev \
    libgdal-dev \
    libproj-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    vim \
    curl \
    git \
    fonts-roboto \
    ghostscript \
    libssl-dev \
    libxml2-dev \
    gdebi-core
```

## Install Java

As per guide at https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-ubuntu-20-04.

```
apt install default-jre
apt install default-jdk
```

## Install R

See the following for installation of specific version of R:

- https://cloud.r-project.org/bin/linux/ubuntu/
- https://cloud.r-project.org/bin/linux/ubuntu/bionic-cran40/
- https://stackoverflow.com/questions/68486319/installing-a-specific-version-of-r-from-an-apt-repository

```
apt update -qq
apt install --no-install-recommends software-properties-common dirmngr
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
export VERSION=4.2.3-1.2204.0
apt install -y --no-install-recommends \
  r-base-core=${VERSION} \
  r-base-html=${VERSION} \
  r-doc-html=${VERSION} \
  r-base-dev=${VERSION}
```

Guide at https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-22-04 can also be used to install the latest version of R.

Start `R` session:

```{bash}
sudo -i R
```

Install packages:

```{r}

install.packages('remotes')

if (!'sqldf' %in% installed.packages()) remotes::install_version('sqldf', '0.4-11', upgrade = 'never')
if (!'RSQLite' %in% installed.packages()) remotes::install_version('RSQLite', '2.2.18', upgrade = 'never')
if (!'gsubfn' %in% installed.packages()) remotes::install_version('gsubfn', '0.7', upgrade = 'never')  
if (!'proto' %in% installed.packages()) remotes::install_version('proto', '1.0.0', upgrade = 'never')
if (!'rgdal' %in% installed.packages()) remotes::install_version('rgdal', '1.5-32', upgrade = 'never')
if (!'raster' %in% installed.packages()) remotes::install_version('raster', '3.6-3', upgrade = 'never')
if (!'sp' %in% installed.packages()) remotes::install_version('sp', '1.5-0', upgrade = 'never')
if (!'sf' %in% installed.packages()) remotes::install_version('sf', '1.0-8', upgrade = 'never')
if (!'rpostgis' %in% installed.packages()) remotes::install_version('rpostgis', '1.4.3', upgrade = 'never')
if (!'RPostgreSQL' %in% installed.packages()) remotes::install_version('RPostgreSQL', '0.7-4', upgrade = 'never')
if (!'DBI' %in% installed.packages()) remotes::install_version('DBI', '1.1.3', upgrade = 'never')
if (!'RANN' %in% installed.packages()) remotes::install_version('RANN', '2.6.1', upgrade = 'never')
if (!'truncnorm' %in% installed.packages()) remotes::install_version('truncnorm', '1.0-8', upgrade = 'never')
if (!'here' %in% installed.packages()) remotes::install_version('here', '1.0.1', upgrade = 'never')
if (!'forcats' %in% installed.packages()) remotes::install_version('forcats', '0.5.2', upgrade = 'never')
if (!'stringr' %in% installed.packages()) remotes::install_version('stringr', '1.4.1', upgrade = 'never')
if (!'dplyr' %in% installed.packages()) remotes::install_version('dplyr', '1.0.10', upgrade = 'never')
if (!'purrr' %in% installed.packages()) remotes::install_version('purrr', '0.3.5', upgrade = 'never')
if (!'readr' %in% installed.packages()) remotes::install_version('readr', '2.1.3', upgrade = 'never')
if (!'tidyr' %in% installed.packages()) remotes::install_version('tidyr', '1.2.1', upgrade = 'never')
if (!'tibble' %in% installed.packages()) remotes::install_version('tibble', '3.1.8', upgrade = 'never')
if (!'ggplot2' %in% installed.packages()) remotes::install_version('ggplot2', '3.3.6', upgrade = 'never')
if (!'tidyverse' %in% installed.packages()) remotes::install_version('tidyverse', '1.3.2', upgrade = 'never')
if (!'keyring' %in% installed.packages()) remotes::install_version('keyring', '1.3.0', upgrade = 'never')
if (!'terra' %in% installed.packages()) remotes::install_version('terra', '1.6-17', upgrade = 'never')
if (!'data.table' %in% installed.packages()) remotes::install_version('data.table', '1.14.4', upgrade = 'never')
if (!'SpaDES.core' %in% installed.packages()) remotes::install_version('SpaDES.core', '1.1.1', upgrade = 'never')
```

If installation of `SpaDES.core` fails, run the following (reference https://github.com/PredictiveEcology/SpaDES.core/issues/232 ):

```
remotes::install_github("PredictiveEcology/SpaDES.core@development")
```

or 

```
install.packages("SpaDES.core", repos = c("https://predictiveecology.r-universe.dev/", "https://cloud.r-project.org"))
```

Proceed with other packages:

```{r}
if (!'SpaDES.tools' %in% installed.packages()) remotes::install_version('SpaDES.tools', '1.0.0', upgrade = 'never')
if (!'reproducible' %in% installed.packages()) remotes::install_version('reproducible', '1.2.10', upgrade = 'never')
if (!'quickPlot' %in% installed.packages()) remotes::install_version('quickPlot', '0.1.8', upgrade = 'never')
if (!'CircStats' %in% installed.packages()) remotes::install_version('CircStats', '0.2-6', upgrade = 'never')
if (!'fastdigest' %in% installed.packages()) remotes::install_version('fastdigest', '0.6-3', upgrade = 'never')
if (!'fs' %in% installed.packages()) remotes::install_version('fs', '1.5.2', upgrade = 'never')
if (!'fpCompare' %in% installed.packages()) remotes::install_version('fpCompare', '0.2.4', upgrade = 'never')
if (!'lubridate' %in% installed.packages()) remotes::install_version('lubridate', '1.8.0', upgrade = 'never')
if (!'bit64' %in% installed.packages()) remotes::install_version('bit64', '4.0.5', upgrade = 'never')
if (!'RColorBrewer' %in% installed.packages()) remotes::install_version('RColorBrewer', '1.1-3', upgrade = 'never')
if (!'httr' %in% installed.packages()) remotes::install_version('httr', '1.4.4', upgrade = 'never')
if (!'rprojroot' %in% installed.packages()) remotes::install_version('rprojroot', '2.0.3', upgrade = 'never')
if (!'tools' %in% installed.packages()) remotes::install_version('tools', '4.1.2', upgrade = 'never')
if (!'backports' %in% installed.packages()) remotes::install_version('backports', '1.4.1', upgrade = 'never')
if (!'utf8' %in% installed.packages()) remotes::install_version('utf8', '1.2.2', upgrade = 'never')
if (!'R6' %in% installed.packages()) remotes::install_version('R6', '2.5.1', upgrade = 'never')
if (!'KernSmooth' %in% installed.packages()) remotes::install_version('KernSmooth', '2.23-20', upgrade = 'never')
if (!'rgeos' %in% installed.packages()) remotes::install_version('rgeos', '0.5-9', upgrade = 'never')
if (!'colorspace' %in% installed.packages()) remotes::install_version('colorspace', '2.0-3', upgrade = 'never')
if (!'withr' %in% installed.packages()) remotes::install_version('withr', '2.5.0', upgrade = 'never')
if (!'tidyselect' %in% installed.packages()) remotes::install_version('tidyselect', '1.2.0', upgrade = 'never')
if (!'chron' %in% installed.packages()) remotes::install_version('chron', '2.3-58', upgrade = 'never')
if (!'bit' %in% installed.packages()) remotes::install_version('bit', '4.0.4', upgrade = 'never')
if (!'compiler' %in% installed.packages()) remotes::install_version('compiler', '4.1.2', upgrade = 'never')
if (!'cli' %in% installed.packages()) remotes::install_version('cli', '3.4.1', upgrade = 'never')
if (!'rvest' %in% installed.packages()) remotes::install_version('rvest', '1.0.3', upgrade = 'never')
if (!'xml2' %in% installed.packages()) remotes::install_version('xml2', '1.3.3', upgrade = 'never')
if (!'stringfish' %in% installed.packages()) remotes::install_version('stringfish', '0.15.7', upgrade = 'never')
if (!'scales' %in% installed.packages()) remotes::install_version('scales', '1.2.1', upgrade = 'never')
if (!'checkmate' %in% installed.packages()) remotes::install_version('checkmate', '2.1.0', upgrade = 'never')
if (!'classInt' %in% installed.packages()) remotes::install_version('classInt', '0.4-8', upgrade = 'never')
if (!'proxy' %in% installed.packages()) remotes::install_version('proxy', '0.4-27', upgrade = 'never')
if (!'digest' %in% installed.packages()) remotes::install_version('digest', '0.6.30', upgrade = 'never')
if (!'pkgconfig' %in% installed.packages()) remotes::install_version('pkgconfig', '2.0.3', upgrade = 'never')
if (!'dbplyr' %in% installed.packages()) remotes::install_version('dbplyr', '2.2.1', upgrade = 'never')
if (!'fastmap' %in% installed.packages()) remotes::install_version('fastmap', '1.1.0', upgrade = 'never')
if (!'rlang' %in% installed.packages()) remotes::install_version('rlang', '1.0.6', upgrade = 'never')
if (!'readxl' %in% installed.packages()) remotes::install_version('readxl', '1.4.1', upgrade = 'never')
if (!'rstudioapi' %in% installed.packages()) remotes::install_version('rstudioapi', '0.14', upgrade = 'never')
if (!'generics' %in% installed.packages()) remotes::install_version('generics', '0.1.3', upgrade = 'never')
if (!'RApiSerialize' %in% installed.packages()) remotes::install_version('RApiSerialize', '0.1.2', upgrade = 'never')
if (!'jsonlite' %in% installed.packages()) remotes::install_version('jsonlite', '1.8.3', upgrade = 'never')
if (!'googlesheets4' %in% installed.packages()) remotes::install_version('googlesheets4', '1.0.1', upgrade = 'never')
if (!'magrittr' %in% installed.packages()) remotes::install_version('magrittr', '2.0.3', upgrade = 'never')
if (!'Rcpp' %in% installed.packages()) remotes::install_version('Rcpp', '1.0.9.5', upgrade = 'never')
if (!'munsell' %in% installed.packages()) remotes::install_version('munsell', '0.5.0', upgrade = 'never')
if (!'fansi' %in% installed.packages()) remotes::install_version('fansi', '1.0.3', upgrade = 'never')
if (!'lifecycle' %in% installed.packages()) remotes::install_version('lifecycle', '1.0.3', upgrade = 'never')
if (!'lobstr' %in% installed.packages()) remotes::install_version('lobstr', '1.1.2', upgrade = 'never')
if (!'stringi' %in% installed.packages()) remotes::install_version('stringi', '1.7.8', upgrade = 'never')
if (!'whisker' %in% installed.packages()) remotes::install_version('whisker', '0.4', upgrade = 'never')
if (!'MASS' %in% installed.packages()) remotes::install_version('MASS', '7.3-58.1', upgrade = 'never')
if (!'grid' %in% installed.packages()) remotes::install_version('grid', '4.1.2', upgrade = 'never')
if (!'blob' %in% installed.packages()) remotes::install_version('blob', '1.2.3', upgrade = 'never')
if (!'parallel' %in% installed.packages()) remotes::install_version('parallel', '4.1.2', upgrade = 'never')
if (!'crayon' %in% installed.packages()) remotes::install_version('crayon', '1.5.2', upgrade = 'never')
if (!'Require' %in% installed.packages()) remotes::install_version('Require', '0.1.4', upgrade = 'never')
if (!'lattice' %in% installed.packages()) remotes::install_version('lattice', '0.20-45', upgrade = 'never')
if (!'haven' %in% installed.packages()) remotes::install_version('haven', '2.5.1', upgrade = 'never')
if (!'hms' %in% installed.packages()) remotes::install_version('hms', '1.1.2', upgrade = 'never')
if (!'pillar' %in% installed.packages()) remotes::install_version('pillar', '1.8.1', upgrade = 'never')
if (!'tcltk' %in% installed.packages()) remotes::install_version('tcltk', '4.1.2', upgrade = 'never')
if (!'igraph' %in% installed.packages()) remotes::install_version('igraph', '1.3.5', upgrade = 'never')
if (!'boot' %in% installed.packages()) remotes::install_version('boot', '1.3-28', upgrade = 'never')
if (!'codetools' %in% installed.packages()) remotes::install_version('codetools', '0.2-18', upgrade = 'never')
if (!'fastmatch' %in% installed.packages()) remotes::install_version('fastmatch', '1.1-3', upgrade = 'never')
if (!'reprex' %in% installed.packages()) remotes::install_version('reprex', '2.0.2', upgrade = 'never')
if (!'glue' %in% installed.packages()) remotes::install_version('glue', '1.6.2', upgrade = 'never')
if (!'evaluate' %in% installed.packages()) remotes::install_version('evaluate', '0.17', upgrade = 'never')
if (!'RcppParallel' %in% installed.packages()) remotes::install_version('RcppParallel', '5.1.5', upgrade = 'never')
if (!'modelr' %in% installed.packages()) remotes::install_version('modelr', '0.1.9', upgrade = 'never')
if (!'vctrs' %in% installed.packages()) remotes::install_version('vctrs', '0.5.0', upgrade = 'never')
if (!'tzdb' %in% installed.packages()) remotes::install_version('tzdb', '0.3.0', upgrade = 'never')
if (!'cellranger' %in% installed.packages()) remotes::install_version('cellranger', '1.1.0', upgrade = 'never')
if (!'gtable' %in% installed.packages()) remotes::install_version('gtable', '0.3.1', upgrade = 'never')
if (!'qs' %in% installed.packages()) remotes::install_version('qs', '0.25.4', upgrade = 'never')
if (!'assertthat' %in% installed.packages()) remotes::install_version('assertthat', '0.2.1', upgrade = 'never')
if (!'cachem' %in% installed.packages()) remotes::install_version('cachem', '1.0.6', upgrade = 'never')
if (!'gridBase' %in% installed.packages()) remotes::install_version('gridBase', '0.4-7', upgrade = 'never')
if (!'broom' %in% installed.packages()) remotes::install_version('broom', '1.0.1', upgrade = 'never')
if (!'e1071' %in% installed.packages()) remotes::install_version('e1071', '1.7-12', upgrade = 'never')
if (!'class' %in% installed.packages()) remotes::install_version('class', '7.3-20', upgrade = 'never')
if (!'googledrive' %in% installed.packages()) remotes::install_version('googledrive', '2.0.0', upgrade = 'never')
if (!'gargle' %in% installed.packages()) remotes::install_version('gargle', '1.2.1', upgrade = 'never')
if (!'memoise' %in% installed.packages()) remotes::install_version('memoise', '2.0.1', upgrade = 'never')
if (!'units' %in% installed.packages()) remotes::install_version('units', '0.8-0', upgrade = 'never')
if (!'ellipsis' %in% installed.packages()) remotes::install_version('ellipsis', '0.3.2', upgrade = 'never')
if (!'knitr' %in% installed.packages()) remotes::install_version('knitr', '1.37', upgrade = 'never')
install.packages(c('sampling', 'BalancedSampling', 'snow'))
remotes::install_github("PredictiveEcology/SpaDES.experiment", dependencies = TRUE) 

q()
```

Shutdown the droplet in Digital Ocean:

```{bash}
shutdown now
```

Create the snapshot with the following name: `flex-cloud-image-YYYYmmdd`, 
replacing the `YYYYmmdd` portion with actual date.
