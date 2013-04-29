require 'rubygems'
require 'bundler'
require 'time'
require 'gemterms/ruby_gems'

module Gemterms
  
  # Accepts a Gemfile and Gemfile.lock to produce a <tt>Gemterm::Project</tt> 
  # based upon the rubygems defined. Can output statistics on that basis.
  class GemFiler
    attr_accessor :no_remote
    attr_reader :bundle, :project

    def initialize(licenser)
      @licenser = licenser
      @no_remote = false
    end

    def run(gemfile, lockfile)
      @project = Project.new
      Bundler.settings[:frozen] = true
      @bundle = Bundler::Dsl.evaluate(gemfile, lockfile, {})
      load
      @project
    end

    protected

    def load
      # @todo Do we include *all* dependencies of a given gem here? Technically
      # they are not in use, but they are linked to the gem. Maybe one for
      # --very-strict mode
      @sources = {}
      @bundle.specs.each do |spec|
        @project << load_spec_as_component(spec)
      end
      puts "\n\n" if @sources.length > 0
      @project
    end

    def load_spec_as_component(spec)
      if spec.licenses.nil? || spec.licenses == []
        licenses = []
        if (spec.source.class == Bundler::Source::Rubygems) && !no_remote 
          puts "Getting missing license data from RubyGems (use --no-remote to skip) " if @sources.length == 0
          STDOUT.print "."
          STDOUT.flush
          licenses = rubygem_licences(spec)
        end
      else
        licenses = spec.licenses
      end
      component = Component.new(spec.name, spec.version, @licenser.rubygem_licenses(licenses))
    end

    def rubygem_licences(spec)
      licenses = []
      source = spec.source.remotes.first

      begin
        rg = @sources[source]
        return [] if rg == :unavailable
        rg = @sources[source] = RubyGems.new(source) if rg.nil?        

        versions = rg.versions(spec.name)

        # Sue for an exact match
        version = versions.detect { |v| v["number"] == spec.version.to_s }
        licenses = version.nil? ? nil : version["licenses"]

        # @todo this should be disabled when a --strict mode is introduced.
        # Try for any later version. e.g. Rails 4 is marked as MIT licensed,
        # but earlier versions aren't. We assume MIT for the earlier versions.
        if licenses.nil? || licenses == []
          version = versions.detect do |v| 
            (Gem::Version.new(v["number"]) > spec.version) && 
              !v["licenses"].nil? && v["licenses"].length > 0
          end
          licenses = version["licenses"] unless version.nil?
        end

        # if licenses.nil? || licenses == []
          # data = rg.data(spec.name)
          # puts data["source_code_uri"]
          # puts data.inspect
        # end

      rescue SourceUnavailableError => sae
        @sources[source] = :unavailable
        licenses = []
      end
      licenses || []
    end

  end

end
