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
      @sources = {} # Rubygem sources, if necessary
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
      remote = false
      specs = @bundle.resolve
      specs.each do |spec|
        licenses = []
        mspec = spec.__materialize__

        if mspec.nil? || mspec.licenses.nil? || mspec.licenses == []
          mspec = spec
          unless no_remote
            unless remote
              STDOUT.print "Getting version data from RubyGems ."
              remote = true
            else
              STDOUT.print "."
            end
            STDOUT.flush
            licenses = rubygem_licences(spec)
          end
        else
          licenses = mspec.licenses
        end
        
        component = Component.new(mspec.name, mspec.version, @licenser.rubygem_licenses(licenses))
        @project << component
      end

      puts "\n\n" if remote

      @project
    end

    def rubygem_licences(spec)
      return [] unless spec.source.class == Bundler::Source::Rubygems

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

        # Try for any later version. e.g. Rails 4 is marked as MIT licensed,
        # but earlier versions aren't. We assume MIT for the earlier versions.
        # if licenses.nil? || licenses == []
        #   version = versions.detect do |v| 
        #     (Gem::Version.new(v["number"]) > spec.version) && 
        #       !v["licenses"].nil? && v["licenses"].length > 0
        #   end
        #   licenses = version["licenses"] unless version.nil?
        # end

        if licenses.nil? || licenses == []
          data = rg.data(spec.name)
          puts data["source_code_uri"]
          # puts data.inspect
        end

      rescue SourceUnavailableError => sae
        @sources[source] = :unavailable
        licenses = []
      end
      licenses || []
    end

  end

end
