require 'rubygems'
require 'bundler'
require 'time'
require 'gemterms/ruby_gems'

module Gemterms
  
  # Accepts a Gemfile and Gemfile.lock to produce a <tt>Gemterm::Project</tt> 
  # based upon the rubygems defined. Can output statistics on that basis.
  class GemFiler
    attr_accessor :disable_api, :use_remotes
    attr_reader :bundle, :project

    def initialize(licenser)
      @licenser = licenser
      @use_remotes = @disable_api = false
    end

    def read_bundle
      # Read the Bundle from the Gem and Lockfiles
      Bundler.settings[:frozen] = true
      @bundle = Bundler::Dsl.evaluate(@gemfile, @lockfile, {})
    end

    def read_bundle_specs
      read_bundle
      missing = []
      @specs = bundle.resolve.materialize(bundle.dependencies, missing)

      # Happy path - all the specs are available locally.
      if missing.length == 0
        # Use requested specs instead. This is due to the fact that
        # bundler cleverly excludes itself. However, if it's an explicit
        # spec we want to evaluate it's licence too (ps. It's MIT)
        @specs = bundle.requested_specs
        return true
      end
      
      # If we can, try and get the additional gem data from RubyGem sources
      # (typically https://rubygems.org). Otherwise give the user a warning.
      if use_remotes
puts "Sourcing gem information from gem sources. This may take some time."
        read_bundle
        @specs = bundle.resolve_remotely!
      else
        # @todo This path will be missing bundler - if it was supplied.
        puts missing.length == 1 ? "The following gem isn't installed:" : "The following gems aren't installed:"
        puts <<-INST
  #{missing.map { |s| s.full_name } * ', '}

We cannot report on uninstalled gems. You can use `bundle install` to install.
Alternatively, if you run with the `--use-remotes` option, gemterms will use 
your RubyGem sources to load gem metadata (note, this will be slower).

INST
      end
    end

    def process(gemfile, lockfile)
      @gemfile = gemfile
      @lockfile = lockfile
      @project = Project.new

      read_bundle_specs
      load_specs
      @project
    end

    protected

    def load_specs
      # @todo Do we include *all* dependencies of a given gem here? Technically
      # they are not in use, but they are linked to the gem. Maybe one for
      # --very-strict mode
      @sources = {}
      @specs.each do |spec|
        spec = spec.__materialize__ if Bundler::LazySpecification == spec
        @project << load_spec_as_component(spec)
      end
      puts "\n\n" if @sources.length > 0
      @project
    end

    def load_spec_as_component(spec)
      if spec.licenses.nil? || spec.licenses == []
        licenses = []
        if (spec.source.class == Bundler::Source::Rubygems) && !disable_api 
          puts "Getting missing license data from gem source (use --disable-api to skip) " if @sources.length == 0
          STDOUT.print(".") & STDOUT.flush
          licenses = rubygem_licences_from_spec(spec)
        end
      else
        licenses = spec.licenses
      end
      component = Component.new(spec.name, spec.version, @licenser.rubygem_licenses(licenses))
    end

    # Iterates over the remotes in the spec, using the API to access rubygem
    # data. If a particular remote ever fails, it's not tried again.
    # 
    # @param [ Gem::Specification ] spec The specification to source
    # @return [ Array<String> ] the array of license strings (can be empty)
    def rubygem_licences_from_spec(spec)
      # Try every remote until we (hopefully) get a result
      licenses = spec.source.remotes.each do |remote|
        begin
          source = @sources[remote]
          next if source == :unavailable
          @sources[remote] = source = RubyGems.new(remote) if source.nil?
          licenses = rubygem_licenses_from_versions(spec, source)
          return licenses unless licenses.nil?
        rescue SourceUnavailableError => sae
          @sources[source] = :unavailable
          nil
        end
      end
      []
    end

    def rubygem_licenses_from_versions(spec, source)
      versions = source.versions(spec.name)

      # Try for an exact match. If this has license information, we'll use it.
      version = versions.detect { |v| v["number"] == spec.version.to_s }
      licenses = version.nil? ? nil : version["licenses"]

      # Try for any later version. e.g. Rails 4 is marked as MIT licensed,
      # but earlier versions aren't. We assume MIT for the earlier versions.
      # @todo this should be disabled when a --strict mode is introduced.
      if licenses.nil? || licenses == []
        if spec.name == 'actionmailer'
          puts versions.inspect
        end
        version = versions.detect do |v| 
          (Gem::Version.new(v["number"]) > spec.version) && 
            !v["licenses"].nil? && v["licenses"].length > 0
        end
        licenses = version.nil? ? nil : version["licenses"] 
      end
      
      licenses
    end

  end

end
