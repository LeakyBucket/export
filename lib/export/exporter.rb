# The ExportFormatter is a bit of a delegator and factory.
# The only requirements for children is that they quack in
# two ways: SubClass.data_format and SubClass#process
#
# @author Glen Holcomb
module Export
  class Exporter
    # Keep a map of the available formats.  This
    # way we can function as a format factory.
    @format_map = {}
    @subclasses = []

    class << self
      attr_reader :format_map
    end

    class UnknownExportFormat < ArgumentError; end

    def initialize(data, method_map)
      @data = data
      @map = method_map
      @indexes = [0]
      @prologue = []
      @vals = []
      @chains = []
      @output = OutputPolicy.new

      @is_collection = @data.respond_to? :each
    end

    # Build a list of our subclasses as they inheriet.
    #
    # @author Glen Holcomb
    def self.inherited(base)
      @subclasses << base
    end

    # Delegate to the proper format subclass for
    # actual processing.  Then return the formatted
    # data.
    #
    # @author Glen Holcomb
    def self.to(format, data, map)
      update_map    
      raise(UnknownExportFormat, "Unknown format #{format}") unless @format_map[format]

      format_map[format].new(data, map).process
    end

    # build_chains builds method chains from @map.  Word of
    # warning, this isn't smart enough to inject accessor calls
    # for chains that respond with collections at any point.
    #
    # @author Glen Holcomb
    def build_chains
      while col_meth = data_method do
        @prologue.empty? ? @chains << col_meth.to_s : @chains << @prologue.join('.') + ".#{col_meth}"
      end
    end

    # data_method returns the next method to be called
    # on the item.  It should be smart enough to handle
    # nested hashes.
    #
    # @author Glen Holcomb
    def data_method
      meth = get_method
      @indexes[-1] += 1

      meth
    end


    private

    # Run through our list of subclasses and make sure we
    # have format info from them.  Can't do this in the
    # inherited callback process as it would appear that
    # the class hasn't been fully ingested yet and is empty.
    #
    # @author Glen Holcomb
    def self.update_map
      load_formats if ENV['RAILS_ENV'] == ('development' or 'concerted_development')

      @subclasses.each do |formatter|
        @format_map[formatter.data_format] = formatter
      end
    end

    # In non production mode the subclasses don't get loaded until called
    # this breaks.  So this handles that case.
    #
    # @author Glen Holcomb
    def self.load_formats
      @format_map[:xls] = Formatters::XLSFormatter
      @format_map[:csv] = Formatters::CSVFormatter
    end

    # get_method looks at @map and determines what method
    # or method chain should be called next.
    #
    # @author Glen Holcomb
    def get_method
      descend if current_coordinate_value.is_a? Hash
      ascend if current_coordinate_value.nil? and @prologue.length > 0

      current_coordinate_value
    end

    # descend will start an index for a nested list, add
    # the hash key to the prologue and add the current
    # nested datastructure to the @vals array.
    #
    # @author Glen Holcomb
    def descend
      add_prologue
      @vals << current_coordinate_value.values.flatten
      @indexes.push 0
    end

    # ascend will remove the index from the
    # list, .  This is intended to indicate that we are
    # finished with a nested resource.
    #
    # @author Glen Holcomb
    def ascend
      @indexes.pop
      remove_prologue
      @vals.pop
      @indexes[-1] += 1
    end

    # current_coordinate_value returns the value at the current
    # index position in @map.
    #
    # @author Glen Holcomb
    def current_coordinate_value
      @vals.empty? ? @map[@indexes.last] : @vals.last[@indexes.last]
    end

    # add_prefix adds a value to the current list of
    # prologue methods.  This is basically for nested
    # structures.
    #
    # @author Glen Holcomb
    def add_prologue
      @prologue << current_coordinate_value.keys.first
    end

    # remove_prologue will remove the current level
    # from the prologue array.  This is used to remove
    # a level of nesting on the item.
    #
    # @author Glen Holcomb
    def remove_prologue
      @prologue.pop
    end

    # reset_indexing resets the index list.  This is
    # usually called when we are starting on a new item.
    #
    # @author Glen Holcomb
    def reset_indexing
      @indexes = [0]
    end
  end
end