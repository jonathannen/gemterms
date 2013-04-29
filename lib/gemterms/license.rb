require 'yaml'

module Gemterms

  # An actual license in the system. For example an MIT License, or BSD
  # 3-Clause License.
  class License
    attr_accessor :unknown
    attr_reader :classified, :compatible, :code, :name, :uri
    alias :unknown? :unknown
    
    def initialize(code, data)
      @code = code || "Unknown"
      @name = data.delete("name")
      @uri = data.delete("uri")

      @classified = []
      @compatible = []
      @unknown = false
    end  

    def inspect 
      "#<License code=#{code} name='#{name}' uri=#{uri} compat_count=#{@compatible.length}>"
    end

    def mark_classified(*args)
      @classified << args
    end

    #license, fer, warning = false
    def mark_compatible(*args)
      @compatible << args
    end

    def to_s
      "#{name} [#{code}]"
    end

  end

  class Licensing
    attr_reader :licenses, :references, :unknown_license

    UNKNOWN_LICENSE_CODE = "Unknown"

    def[](code)
      licenses[code] || @unknown_license
    end

    def initialize(filename = nil)
      filename ||= File.join(File.dirname(__FILE__), '..', '..', 'compatability.yml')
      load(filename)
    end

    def inspect
      "#<Licensing licence_count=#{@licenses.length}>"
    end

    # @param [ String, Array ] term_or_terms The terms provided in the license 
    # or licenses portion of the rubygem specification.
    #
    # @return [ Array<License> ] The given licenses.
    def rubygem_licenses(term_or_terms)
      return [unknown_license] if term_or_terms == []      
      values = term_or_terms.respond_to?(:map) ? term_or_terms : [term_or_terms.to_s]
      values = values.map { |v| @rubygems[v.to_s] || "Unknown" }
      values.map { |v| self[v] }
    end

    protected

    def load(filename)
      data = YAML.load(File.read(filename))["licenses"]
      
      @references = data.delete("references")
      @rubygems = data.delete("rubygems")

      @licenses = data.inject({}) { |memo,(code, element)| memo[code] = License.new(code, element); memo }
      @unknown_license = self[UNKNOWN_LICENSE_CODE]
      @unknown_license.unknown = true

      data.each do |code,element|
        target = self[code]
        element.each do |ref, value|
          next unless ref.to_s[0] =~ /[A-Z0-9]/
          names = value.respond_to?(:each) ? value : [value.to_s]
          compat = ref.to_i.to_s == ref.to_s
          names.each do |name|
            name.strip!
            warning = name[0] == "!"
            name = name[1..-1] if warning
            raise "Compatability file '#{filename}' lists a compatability with '#{UNKNOWN_LICENSE_CODE}'. This is not allowed." if name == UNKNOWN_LICENSE_CODE
            peer = @licenses[name]
            raise "Compatability file '#{filename}' references License coded '#{name}', but it is not specified elsewhere in the file." if peer.nil?

            if compat
              target.mark_compatible(peer, ref, warning)
            else
              target.mark_classified(peer, ref, warning)
            end
          end
        end
      end

    end

  end
end
