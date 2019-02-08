# SFW Boilerplate

This project is a template for setup scripts that can be used
with new Schema Framework development.  The goal of the setup
scripts is to make site migration very easy by automating the
entire setup from an almost empty directory.

This project will likely be found useful for production
projects as well, but the extra steps and possible lack of
flexibility may be too great a burden.

## First Steps

### Uninitializing GIT

First task upon cloning: change to cloned directory and
uninitialize git:

~~~sh
cd new_app_directory
rm -rf .git
~~~

This should be done to protect the boilerplate project from
being update with files meant for a new application.

### Use *protected* Directory for Tables and Customization

To make deleting files easier in other directories, the scripts
in the *protected* directory are linked into other directories
as needed.

The main script that belongs in this directory is a MySQL
script for generating the tables.  The *setup* script executes
script files that begin with *tables* before any other MySQL
scripts.

Other MySQL scripts in this directory will be linked into the
*sql* directory to be loaded in alphabetical order.  Consider
the loading order when naming script files:

- Procedures that are called by other procedures should be loaded
  first.  Give those script files a prefix number to enforce
  early loading.  *0_session.sql* is a generated file.  If you
  want to load before *0_session.sql* , use 00_something.

- Procedures that replace generated procedures should be loaded
  last.  Use prefix *zz_*, like *zz_procs.sql** to ensure
  later loading.

- These loading order considerations are primarily for
  instructional projects.  Having discrete scripts to highlight
  changes makes it easier to discuss the changes from the
  generated files.  A real-life project is not required to
  follow these guidelines.

### The *setup_params* Script

This special script collects customizing variables into
one place, isolating the values from the executing script code.

new project should edit the *setup_params* script to

For now, the variables are explain in the *setup_params* file
included in the root directory.  As the boilerplate project
matures, the number of *setup_params* variables will likely
increase, with the documentation migrating to this README
file.

## Executable Shell Scripts

The files in this project will certainly evolve as the issues
around automated setup become more clear.  However, at the
start, the executable scripts are:

### The *setup* Script

The *setup* script does most of the work:
- create a new MySQL database
- create directories, including 'site' to host the website
- initialize Schema Framework in MySQL and 'site' directory
- create tables in MySQL database
- generate and distribute .gsf, .sql, and .srm files
- load scripts to create MySQL stored procedures
- generate an autoload.srm file to create navigation between
  different MySQL table pages.

### The *setup_apache* Script

The *setup_apache* script does as its name implies,
set up Apache to run the web application.

- **setup_apache** creates an Apache .conf file in the
  /etc/apache2/sites-available directory, enabling the
  site, and, if a URL is not provided, add an entry in
  /etc/hosts to allow the site to run on localhost.

  This script should be run as *root* (sudo), as all the
  steps taken, from writing files to calling Apache scripts,
  require root privileges.
  
- **Update *setup_params* script**  The file,
  **setup_params**, contains several variables that direct
  the **setup** and **setup_apache** scripts.  The variables
  are documented in **setup_params** until I make time to
  provide more complete documentation here.

- Replace, change, or delete the file *protected/tables.sql*
  so the file will subsequently contain tables associated
  with the new project.

## Boilerplate Usage Explicit Steps

- Install the boilerplate to begin a new project:

  `git clone https://github.com/cjungmann/sfw_boilerplate.git sfw_newsite`

- Change to new directory:

  `cd sfw_newsite`

- Uninitialize *git* (assuming you're in sfw_newsite):

  `rm -rf .git`

- Create MySQL scripts, especially *tables.sql* in the protected
  directory.

- Update **setup_params** with application-specific values

- run `./setup`

- run `sudo ./setup_apache`

To Disable/Remove an Application

- run `sudo ./setup_apache uninstall` to disable the site,
  remove the configuration file, remove the hostname from
  the file */etc/hosts*, and drop tables and procedures from
  MySQL.

- run `./setup uninstall` to remove the generated files, but
  leaving the directories and the file *default.xsl* and the
  linked directory *includes*.
