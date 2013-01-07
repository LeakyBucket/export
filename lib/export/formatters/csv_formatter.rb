# This is our CSV Formatter.  It is instantiated and
# started by the ExportFormatter class.
#
# @author Glen Holcomb
module Export
  module Formatters
    class CSVFormatter < Exporter
      # Save the data and determine if we have a collection
      # or a single item. Nothing different from ExportFormatter
      # here right now.
      #
      # @author Glen Holcomb
      def initialize(data, map)
        super
      end
      
      # Let ExportFormatter know what kind of data
      # we produce.
      #
      # @author Glen Holcomb
      def self.data_format
        :csv
      end

      # This is how ExportFormatter tells us to
      # start working.
      #
      # @author Glen Holcomb
      def process
        build_chains

        gen_csv
      end


      private

      # Generate the CSV file from the data provided.
      #
      # @author Glen Holcomb
      def gen_csv    
        CSV.generate do |csv|
          csv << @chains.collect { |chain| chain.gsub(/_|\./, ' ').capitalize }

          if @is_collection
            loop_collection(csv)
          else
            csv << @chains.collect { |chain| @output.convert(@data.instance_eval { eval chain }) }
          end
        end
      end

      # Loop through the collection if we have been given
      # one.
      #
      # @param [CSV] csv is the csv object
      # @author Glen Holcomb
      def loop_collection(csv)
        @data.each do |record|
          csv << @chains.collect { |chain| @output.convert(record.instance_eval { eval chain }) }
        end

        csv
      end
    end
  end
end