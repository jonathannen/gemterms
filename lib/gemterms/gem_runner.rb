require 'gemterms/gem_filer'
require 'gemterms/runner'

module Gemterms

  # Command line utility for running reports on Bundler (Gemfile) based
  # projects. Think includes Rails v3+ projects.
  class GemRunner < Runner
    attr_reader :no_remote

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

      filer = GemFiler.new(licenser)
      filer.disable_api = @disable_api = !!args.delete("--disable-api")
      filer.use_remotes = @use_remotes = !!args.delete("--use-remotes")

      case (args.shift || 'report')
      when 'report'
        gemfiles(args)
        @project = filer.process(@gemfile, @lockfile)
        commentary = "This is from the #{counter(filer.bundle.dependencies.length)} listed in your Gemfile, plus any dependencies."
        stats(commentary)
        ruler && license_breakdown

        unlicensed = @project.count_unlicensed
        ruler && no_remote_instructions(unlicensed) if no_remote && (unlicensed > 0)
      end
    end

    # Instructions when there is missing license information, but the user
    # has specified --disable-api - preventing remote license sources being used.
    def no_remote_instructions(unlicensed)
      puts <<-INST
There is no license defined for #{counter(unlicensed)}. You are running with the `--disable-api`
option. If you remove this option, gemterms will attempt to use RubyGems and 
other sources for license information.
INST
      true
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

  gemterms report [options] [GEMFILE] [LOCKFILE]
    Produces a report on license usage.

  gemterms show-license <code>
    Shows the details for the license given the code. e.g. Try the code
    Ruby for details of the ruby license. See also "list-licenses" above.

Options:
  GEMFILE and LOCKFILE will default to your current directory. Generally you'll
  run gemterms from your Rails (or similar project) directory and omit these
  arguments.

  --disable-api
    If the gem metadata isn't complete, gemterms seeks additional information
    from the source (e.g. RubyGems) API. This option disables that feature.

  --use-remotes
    If gem metadata is not available, gemterms will use the gem sources (e.g
    https://rubygems.org).

USAGE
      true
    end

  end

end
