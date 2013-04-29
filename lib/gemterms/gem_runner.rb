require 'gemterms/gem_filer'
require 'gemterms/runner'

module Gemterms

  # Command line utility for running reports on Bundler (Gemfile) based
  # projects. Think includes Rails v3+ projects.
  class GemRunner < Runner

    def gemfiles(args)
      @gemfile = args.shift || "./Gemfile"
      @lockfile = args.shift || "./Gemfile.lock"
      errors = []
      errors << "Couldn't file '#{@gemfile}'." unless File.exists?(@gemfile)
      errors << "Couldn't file '#{@lockfile}'." unless File.exists?(@lockfile)
      if errors.length > 0
        puts "#{errors * ' '} Run 'gemterms --help' if you need more information."
        exit -1
      end
    end

    def initialize(args)
      super('gem', 'gems')
      return if standard_commands(args)

      gf = GemFiler.new(licenser)
      gf.no_remote = !!args.delete("--no-remote")        

      case (args.shift || 'report')
      when 'report'
        gemfiles(args)
        @project = gf.run(@gemfile, @lockfile)
        commentary = "This is from the #{counter(gf.bundle.dependencies.length)} listed in your Gemfile, plus their dependencies."
        stats(commentary)
        ruler && license_breakdown
      end
    end

    # Show usage instructions
    def usage
      puts <<-USAGE
Usage:

  gemterms
    Equivalent to `gemfile report` below.

  gemterms --help
    Outputs these usage instructions.
  
  gemterms list-licenses
    Outputs a list of licenses that are referenced by this tool. This list is
    in the form "<name> [<code>]". You can use the code to look up licenses.

  gemterms report [Options] [Gemfile] [Lockfile]
    Produces a report on license usage.

  gemterms show-license <code>
    Shows the details for the license given the code. e.g. Try the code
    Ruby for details of the ruby license. See also "list-licenses" above.

Options:
  Gemfile and Lockfile will default to your current directory. Generally you'll
  run gemterms from your Rails (or similar project) directory and omit these
  arguments.

  --no-remote
    Will prevent gemterms from going to RubyGems, Github and Bitbucket to
    (attempt to) source version data.

USAGE
      true
    end

  end

end
