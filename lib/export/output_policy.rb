module Export
  # OutputPolicy is intended to apply any presenters that might be defined in order
  # to customize the format of the final output.
  #
  # @author Glen Holcomb
  class OutputPolicy
    class UglyPresenter < NameError; end

    attr_reader :presenters

    def initialize(id_technique = nil)
      @presenters = query_presenters(find_presenters)
      id_technique ? @id_by = id_technique : @id_by = :is_a?
    end

    # filter is the method we call to start the process.  It looks at
    # @id_by to determine which identification process to use.
    #
    # @param (object) object is the object we want to potentially run through a presenter.
    #
    # @author Glen Holcomb
    def filter(object)
      @id_by == :is_a? ? is(object) : kind(object)
    end

    # kind holds the logic for kind_of policies
    #
    # @param (object) object is any object we want to potentially run through a presenter.
    #
    # @author Glen Holcomb
    def kind(object)
      matches = @presenters.keys.select { |klass| object.kind_of? klass }

      matches.empty? ? object : matches.first.new.present(object)
    end

    # is holds the logic for is_a policies
    #
    # @param (object) object is any object we want to potentially run through a presenter.
    #
    # @author Glen Holcomb
    def is(object)
      @presenters[object.class] ? @presenters[object.class].new.present(object) : object
    end

    # def integer(object)
    #   object.to_i
    # end

    # def float(object)
    #   sprintf("%0.02f", object)
    # end

    # def string(object)
    #   object.gsub(/<.+?>/, '')
    # end


    private

    # We want any and all presenters defined in the Export::Presenters
    # namespace.
    #
    # @author Glen Holcomb
    def find_presenters
      Presenters.instance_eval do
        constants.collect { |presenter| const_get presenter }
      end
    end

    # Build a list of targets for the defined presenters
    #
    # @author Glen Holcomb
    def query_presenters(presenters)
      presenters.inject({}) do |list, presenter|
        begin
          list.merge({ presenter.target => presenter })
        rescue MethodMissing => e
          raise UglyPresenter, "#{presenter} must respond to .target"
        end
      end
    end
  end
end