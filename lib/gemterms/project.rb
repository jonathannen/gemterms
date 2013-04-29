module Gemterms

  # A licenced component that is part of an overall project.
  class Component
    attr_reader :licenses, :name, :version

    def initialize(name, version, licenses)
      @name = name
      @version = version
      @licenses = licenses
    end

    # @return [ true, false ] if this component has at least one "known"
    # license
    def licensed?
      !@licenses.nil? && @licenses.detect { |l| !l.unknown }
    end

    # @return [ true, false ] if this component has at least two "known"
    # licenses.
    def multiple?
      !@licenses.nil? && (@licenses.count { |l| !l.unknown } > 1)
    end

  end

  # A collection of components to be evaluated as a set.
  class Project
    attr_reader :components

    def <<(component)
      @components << component
    end

    def components_for_license(license)
      @components.select { |c| c.licenses.include?(license) }
    end

    def initialize
      @components = []
    end

    def licenses(include_unknown = true)
      result = @components.map { |c| c.licenses }.flatten
      result.reject! { |l| l.unknown? } unless include_unknown
      result
    end

    # @return [ int ] number of components in the project
    def size
      @components.length
    end

    # @param [ true, false ] include_unknown If true, unknown licenses are 
    # included in the returned list. Defaults to true.
    #
    # @return [ Array<License> ] array of unique licenses in use by this 
    # project.
    def unique_licenses(include_unknown = true)
      self.licenses.uniq
    end

  end

end
