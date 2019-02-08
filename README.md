# SFW Boilerplate

This project is a template for setup scripts that can be used
with new Schema Framework development.  The goal of the setup
scripts is to make site migration very easy by automating the
entire setup from an almost empty directory.

The files in this project will certainly evolve as the issues
around automated setup become more clear.  However, at the
start, the executable scripts are:

- **setup** for the larger part of setup, with the following
  tasks:
  - create a new MySQL database
  - create directories, including 'site' to host the website
  - initialize Schema Framework in MySQL and 'site' directory
  - create tables in MySQL database
  - generate and distribute .gsf, .sql, and .srm files
  - load scripts to create MySQL stored procedures
  - generate an autoload.srm file to create navigation between
    different MySQL table pages.

- **setup_apache** creates an Apache .conf file in the
  /etc/apache2/sites-available directory, enabling the
  site, and, if a URL is not provided, add an entry in
  /etc/hosts to allow the site to run on localhost.

  This script should be run as *root* (sudo), as all the
  steps taken, from writing files to calling Apache scripts,
  require root privileges.
  
## Setup

After cloning this project to begin a new project, the
following steps should be executed:

- **Delete hidden *.git* directory** to uninitialize the
  git tracking of this project.  **This is very important.**
  There are two reasons to do this immediately:
  - a new project deserves its own repository
  - for safety, prevent commits/pushes intended for the new
    project from corrupting this boilerplate project.

- **Update *setup_params* script**  The file,
  **setup_params**, contains several variables that direct
  the **setup** and **setup_apache** scripts.  The variables
  are documented in **setup_params** until I make time to
  provide more complete documentation here.

- Replace, change, or delete the file *protected/tables.sql*
  so the file will subsequently contain tables associated
  with the new project.

## Usage

- Install the boilerplate to begin a new project:

  `git clone https://github.com/cjungmann/sfw_boilerplate.git sfw_newsite`

- Create MySQL scripts, especially *tables.sql* in the protected
  directory.

- Update **setup_params**

- run `./setup`

- run `sudo ./setup_apache`

To unsetup,

- run `sudo ./setup_apache uninstall` to disable the site,
  remove the configuration file, remove the hostname from
  the file */etc/hosts*, and drop tables and procedures from
  MySQL.

- run `./setup uninstall` to remove the generated files, but
  leaving the directories and the file *default.xsl* and the
  linked directory *includes*.
