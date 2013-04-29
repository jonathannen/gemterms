require 'gemterms'

# Generic command-line runner for processing projects of licenced 
# components. Generally you'll use a specialisation of this, such as
# the <tt>Gemterms::GemFiler</tt> class.
class Gemterms::Runner
  attr_reader :component_name, :component_plural, :licenser, :project

  def all_licenses
    @licenser.licenses
  end

  def banner
    puts <<-BANNER
Thanks for using gemterms. Please read the README.md and MIT-LICENCE.txt 
available at https://github.com/jonathannen/gemterms. It contains important 
information about the usage of this tool.
BANNER
    true
  end

  def counter(count)
    count == 1 ? "1 #{component_name}" : "#{count} #{component_plural}"
  end

  # component_name, component_plural
  def initialize(*args)
    @component_name, @component_plural = *args
    @licenser = Gemterms::Licensing.new 
    @verbose = true
    banner && ruler
  end

  def license_breakdown
    puts <<-INST
Following are your #{component_plural} listed by license. Any #{component_plural} listed with a '*' 
have multiple licenses.

INST
    unknown_last(project.unique_licenses).each do |license|
      puts "== #{license}"
      components = project.components_for_license(license).sort_by { |c| c.name.downcase }
      names = components.map do |c| 
        "#{c.multiple? ? '*' : ''}#{c.name}"
      end
      puts names * ', '
      puts ""
    end
    # puts ls.inspect
    # ls = projectall_licenses.
    # puts "Break it on down"
    true
  end

  def list_licenses
    count = @licenser.licenses.values.count
    ruler
    unknown_last(all_licenses.values).each do |l|
      puts "#{l.name} [#{l.code}]"
    end
    ruler
    puts "#{count} licence#{count == 1 ? '' : 's'} defined."
    true
  end

  def ruler
    puts ""
    true
  end    

  def show_license(arg)
    if arg.nil?
      puts <<-INST
Please specify a licence code (e.g. GPL-2.0) when getting license details. You 
can get a list of licenses and codes with the `list-licenses` command. Use 
the --help command for more information.
INST
      return true
    end

    l = @licenser[arg]
    if l.unknown?
      puts <<-INST
The given code '#{arg}' doesn't map to a known license. You can get a list of 
licenses and codes with the `list-licenses` command. Use the --help command for
more information.
INST
      return true
    end

    puts "#{l.name} [#{l.code}]"
    puts l.uri
    puts ""

    if l.compatible.length > 0
      puts "This license is compatiable with:"
      l.compatible.group_by { |p, ref, warn| ref }.each do |ref, vals|
        puts "  Based on reference [#{ref}] #{@licenser.references[ref]}"
        vals.each { |p, ref, warn| puts "  - #{p.name} [#{p.code}]" }
      end
    else
      puts <<-INST
This license is not listed as being compatible with any licenses. This doesn't 
mean it's true, just that the are no mappings. See the site  
https://github.com/jonathannen/gemterms for more details and how you can help.
INST
    end

    if l.classified.length > 0
      puts "\nThis license is classified as:"
      l.classified.group_by { |p, ref, warn| ref }.each do |ref, vals|
        puts "  Based on reference [#{ref}] #{@licenser.references[ref]}"
        vals.each { |p, ref, warn| puts "  - #{p.name} [#{p.code}]" }
      end
    end

    puts ""
    true
  end


  # Runs the standard commands if possible. This includes things like
  # listing licenses and the such.
  def standard_commands(args)
    return usage if args.delete('--help')
    case args.first
    when "list-licenses" then list_licenses
    when "show-license" then show_license(args[1])
    else
      false
    end
  end

  def stats(commentary = nil)
    ns = counter(project.count)
    lg = counter(project.components.select { |c| c.licensed? }.count)
    ul = project.unique_licenses(false).count
    puts "Ok. Your project has #{ns} listed."
    puts commentary unless commentary.nil?
    puts "There is an explict license for #{lg}. There #{ul == 1 ? "is 1 unique license" : "#{ul} unique licenses"} referenced."
    true
  end

  protected

  # @param [ Array<License> ] list The list of licenses to process.
  # @return [ Array<License> ] The list with unknown licenses at the end.
  def unknown_last(list)
    list.partition { |l| !l.unknown? }.flatten.each
  end

end
