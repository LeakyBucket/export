# The XLSFormatter generates files for jerks using
# Excel.
#
# @author Glen Holcomb
module Export
  module Formatters
    class XLSFormatter < Exporter
      def initialize(data, map)
        super

        @doc = ''
        @builder = Builder::XmlMarkup.new :indent => 2, :target => @doc
      end
      
      def self.data_format
        :xls
      end

      def process
        @doc = ''
        
        build_chains
        @builder.instruct!

        blow_chunks
      end


      private

      # Stupid XML
      #
      # @author Glen Holcomb (under duress)
      def blow_chunks
        urn = 'urn:schemas-microsoft-com:office:'
        klass = @is_collection ? @data.first.class : @data.class

        @builder.Workbook("xmlns" => "#{urn}spreadsheet", "xmlns:o"=>"#{urn}office", "xmlns:x"=>"#{urn}excel", "xmlns:ss"=>"#{urn}spreadsheet", "xmlns:html"=>"http://www.w3.org/TR/REC-html40") {
          @builder.Worksheet("ss:Name" => "#{klass} Export") {
            @builder.Table {
              @builder.Row {
                @chains.each do |col|
                  @builder.Cell { 
                    @builder.Data(col.gsub(/_|\./, ' ').capitalize, "ss:Type" => "String")
                  }
                end
              }
              if @is_collection
                build_contents
              else
                @builder.Row {
                  @chains.each do |col|
                    @builder.Cell { 
                      @builder.Data(@output.convert(@data.instance_eval { eval col }), "ss:Type" => "#{@data.instance_eval { eval col }.class}")
                    }
                  end
                }
              end
            }
          }
        }
      end

      # Because XML is a horrible horrible thing.
      #
      # @author Glen Holcomb (under duress)
      def build_contents
        @data.each do |record|
          @builder.Row {
            @chains.each do |col|
              @builder.Cell {
                @builder.Data(@output.convert(record.instance_eval { eval col }), "ss:Type" => "#{handle_data_type(record, col)}")
              }
            end
          }
        end
      end

      # Excel doesn't like NilClass for a Cell Type.  Go figure.
      # It also only supports Number and String so we should too.
      #
      # @param (Object) record is the object we want the data from.
      # @param (String) col is a method chain to be invoked on record.
      # @author Glen Holcomb
      def handle_data_type(record, col)
        record.instance_eval { eval col }.class.to_s.match(/num|float|dec/i) ? "Number" : "String"
        #record.instance_eval { eval col }.nil? ? "String" : record.instance_eval { eval col }.class.to_s
      end
    end
  end
end