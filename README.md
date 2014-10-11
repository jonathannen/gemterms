# Gemterms
Checks the licensing of your Gemfile.

## Status

This is an early release. It's functional, but I'll be adding more useful
utilities soon.

## Installation and Usage

To install, simply grab the gem:

    gem install gemterms

Change a project directory with a Gemfile (e.g. Your Rails v3+ project) and
type:

    gemterms report

This will output a list (known) licenses for your gems. For more
information and options, run gemterms with the --help option:
    
    gemterms --help
 
## Use of this Software

This tool is based upon a number of heuristics and guesses. It should not 
be treated as legal advice. The MIT-LICENSE.txt really applies here.

Help is more than welcome. Use the usual Fork, Pull Request approach to 
contribute. In particular, it's good to get additional licenses and
compatibilities.

## License
MIT Licensed. See MIT-LICENSE.txt for more information.

Thanks, [@jonathannen](http://twitter.com/jonathannen).
