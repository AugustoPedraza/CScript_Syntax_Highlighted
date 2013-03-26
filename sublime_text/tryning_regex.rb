class CScriptRegexValidator
  @@file_paths = []
  @@sections   =  Hash.new {|h,k| h[k] = Array.new }

  ExtractorsProcs = {
    headers:                    Proc.new{ |line| line[/<unit/] },
    classes:                    Proc.new{ |line| line[/<class/] && !line[/[Ee]xception/] },
    exceptions:                 Proc.new{ |line| line[/<class/] && line[/[Ee]xception/] },
    methods:                    Proc.new{ |line| line[/<method/] && !line[/\sas/] },
    interface_implementations:  Proc.new{ |line| line[/<method/] && line[/\sas.*\/>/] },
  }

  @@parsed_files = {}

  Exceptions = {
    headers: [],
    classes: [
        '<class/>',
        '<class name="IdMatchRes" inherits="Payee.IdMatchRes"/>',
        '<class name="FormItem" inherits="wsForms.FormItem"/>',
        '<class name="BlockedRecipient" inherits="SBR.BRecipient"/>',
        '<class name="IDMatchRes" inherits="Fvxml.IdMatchResult"/>',
        '<class name="IDMatchDet" inherits="Fvxml.IdMatchDetail"/>',
        '<class name="Sessions" inherits="Session"/>',
        '<class name="HttpParam" inherits="Http.Param"/>',
        '<class name="General" inherites="Fvxml.WebServiceSession">'
    ],
    exceptions: [
      '<class name="ENextTokenRequired" inherits="Exception">', #This exception is a class, because have body.
      '<class name="DefaultError" inherits="Exception"/>'
    ],
    methods: []
  }

  def self.path_files_finder(base_dir, ext)
    @@file_paths = Dir.glob("#{base_dir}/**/*").select do |entry|
      File.file?(entry) && File.extname(entry) == ext
    end

    files_parses

    nil
  end

  def self.files_parses
    ExtractorsProcs.each_pair do |key, value|
      @@file_paths.each do |path|
        @@sections[key] << File.open(path, 'r').readlines.select(&value)
      end

      @@sections[key].flatten!
    end

    split_methods
  end

  def self.split_methods
    all        = @@sections[:methods]
    partitions = []

    @@method_partitions = {
      with_mods: MethodPartition.new("methods without params",
        /mods\s*=\s*"\s*(virtual|spawn|queue)\s*"/),

      with_kind_at_end: MethodPartition.new("methods with kind at end",
        /\s+kind\s*=\s*"\s*(list|lookup|update|insert|delete|dml)"\s*\/?>/),

      without_params: MethodPartition.new("methods without params",
        /sign\s*="(void|int|[A-Za-z]+(\.[A-Za-z]+)*(\[\])?\^?)\s+[A-Za-z]+(\.[A-Za-z]+)*\s*\(\s*\)/),

      with_kind_list_delete_or_dml: MethodPartition.new("methods with kind list, delete or dml before method",
        /<method\s+kind\s*=\s*"\s*(list|delete|dml)"/),

      with_kind_update_insert_lookup: MethodPartition.new("methods with kind update, insert or lookup after method",
        /<method\s+kind\s*=\s*"\s*(update|insert|lookup)"/),

      with_for_or_more_params: MethodPartition.new("methods with 4 or more params",
        /(,\s*\w+\.?\w+(\[\])?\^?\s*\w+\.?\w+\s*){3,}/),

      with_one_parm: MethodPartition.new("methods with one param",
        /\(\s*\w+\.?\w+(\[\])?\^?\s*\w+\.?\w+\s*\)/),

      with_two_params: MethodPartition.new("methods wiht two params",
        /\(\s*\w+\.?\w+(\[\])?\^?\s*\w+\.?\w+\s*,\s*\w+\.?\w+(\[\])?\^?\s*\w+\.?\w+\s*\)/)
    }

    @@method_partitions.each_pair do |key, partition|
      all = partition.extract_values(all)
    end

    @@sections[:methods] = all #Back to push the remainder
  end

  def self.generate_methods_sample(include_all)
    sample = []
    show_all = 
    @@method_partitions.each_pair do |key, partition|
      # Fixme: all this methods, should be refactoring to move the kind to the start
      sample << partition.sample(include_all) unless key == :with_kind_at_end #No include the methods that had kind at end
    end

    @@sections[:methods] = (@@sections[:methods] + sample).flatten
    puts "The sample methods have #{@@sections[:methods].size} elements"
  end

  def self.report
    puts @@file_paths
    puts "files .unit = #{@@file_paths.count}"
  end

  def self.validate(section, regex, options={include_all: true})
    generate_methods_sample(options[:include_all]) if section == :methods

    no_matcheds = []
    matched_count = 0
    @@sections[section].each do |item|
      if (item[regex])
        output = '.'
        matched_count += 1
      else
        no_matcheds << item
        output ='F'
      end

      print output
    end

    show_result_validate(section, no_matcheds, matched_count)
  end

  def self.show_result_validate(section, no_matcheds, matched_count)
    puts "\nResult match to #{section.to_s}: #{matched_count}/#{@@sections[section].count}"

    unless no_matcheds.count == 0
      puts "Do you seen the unmatched values to #{section.to_s} (Press y/n)"
      if gets.chomp.downcase == 'y'
        puts "\n" * 2
        puts no_matcheds
        puts
      end
    else
      puts "\n#{'*' * 3} You regex in valid to all #{section.to_s} #{'*' * 3}\n\n\n\n"
    end
  end
end

class MethodPartition
  attr_reader :values

  def initialize(comment, regex)
    @regex   = regex
    @comment = comment
    @values  = []
  end

  def to_string
    "There are #{@values.size} that are \"#{@comment}\""
  end

  def extract_values(array)
    @values, reduced = array.partition { |string| string[@regex] }

    reduced
  end

  def sample(include_all)
    return @values if include_all

    n = @values.size > 100 ? @values.size / 4 : @values.size

    @values.sample(n)
  end
end

CScriptRegexValidator.path_files_finder('X:/Products/FormView2/Convey', '.unit')
# puts CScriptRegexValidator.report


CScriptRegexValidator.validate(:headers, /<(unit)\s+(name)\s*=\s*("[A-Za-z]+[a-zA-Z0-9_]*")\s+(xmlns:xsi)=("_")\s+(xsi:type)=\s?("Unit")>/)
CScriptRegexValidator.validate(:exceptions, /<(class)\s+(name)\s*=\s*("E[A-Za-z]+[a-zA-Z0-9_]*")\s+(inherits)\s*=\s*"(Exception)"\s*(\/>)/)
CScriptRegexValidator.validate(:classes, /<(class)\s+(name)\s*=\s*(\"[A-Za-z]+[a-zA-Z0-9_]*\")\s*(\s+(inherits)\s*=\s?(\"[A-Za-z]+(\.[a-zA-Z0-9]+)*\")\s*)?>/)
CScriptRegexValidator.validate(:methods, /<(method)\s+(?<kind definition>kind\s*=\s*"\s*(list|lookup|update|insert|delete|dml)")?\s*sign\s*="\s*(?<return type>[a-zA-Z]{1}(\.?_*[a-zA-Z0-9]+)*(\[\])?\^?){1}\s*(?<fuction name>[a-zA-Z]{1}_*[_a-zA-Z0-9]*){1}\s*\(\s*(?<params>(?<first param type>[a-zA-Z]{1}(\.?_*[a-zA-Z0-9]+)*(\[\])?\^?){1}\s+(?<first param name>[a-zA-Z]{1}[_a-zA-Z0-9]*){1}(\s*,\s*(?<param type>[a-zA-Z]{1}(\.?_*[a-zA-Z0-9]+)*(\[\])?\^?)\s+(?<param name>[a-zA-Z]{1}[_a-zA-Z0-9]*))*\s*)?\)\s*"\s*(?<mods definition>mods\s*=\s*"\s*(virtual|spawn|queue)")?\s*\/?>/)

# NOTE: remember that a methods without body should be separated.
