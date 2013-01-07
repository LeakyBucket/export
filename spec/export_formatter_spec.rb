require 'spec_helper'

describe "Export::Exporter" do
  let (:exporter) { Export::Exporter.new 'data', [:split, { :to_s => [:split] }] }
  let (:formats) { { :xls => Export::Formatters::XLSFormatter, :csv => Export::Formatters::CSVFormatter } }

  describe "Exporter.format_map" do
    it "maintains a format map of known formats" do
      Export::Exporter.instance_eval { @subclasses }.should == [Export::Formatters::CSVFormatter, Export::Formatters::XLSFormatter]
    end
  end

  describe "Exporter.load_formats" do
    it "should load the csv and xls formatters into the map" do
      Export::Exporter.load_formats

      Export::Exporter.format_map.should == formats
    end
  end

  describe "Exporter#build_chains" do
    it "should build a compound chain for nexted hashes" do
      exporter.build_chains

      exporter.instance_eval { @chains }.should include('to_s.split')
    end

    it "should convert the map into a group of method chains" do
      exporter.build_chains

      exporter.instance_eval { @chains }.should == ['split', 'to_s.split']
    end
  end

  describe "Exporter#data_method" do
    it "should return the next method from the map" do
      exporter.data_method.should == :split
    end

    it "should increment the last index by one" do
      old = exporter.instance_eval { @indexes[-1] }
      exporter.data_method

      exporter.instance_eval { @indexes[-1] }.should == (old + 1)
    end
  end

  describe "Exporter#get_method" do
    before(:each) do
      exporter.should_receive(:get_method).at_least(:once).and_call_original
    end

    it "should get the next terminal value" do
      exporter.send(:get_method).should == :split
    end

    it "should call descend if the current value is a hash" do
      exporter.should_receive(:descend).once

      2.times { exporter.send(:get_method) }
    end

    it "should call ascend if at the end of an array and there is a prologue" do
      exporter.should_receive(:ascend).once

      3.times { exporter.send(:get_method) }
    end
  end

  describe "Exporter#descend" do
    before(:each) do
      exporter.send(:data_method)
      exporter.send :descend
    end

    it "should add a new index" do
      expect(exporter.instance_eval {@indexes.length}).to eq(2)
    end

    it "should add the values at the current index to @vals" do
      expect(exporter.instance_eval {@vals}).to  eq([[:split]])
    end

    it "should set the current index to 0" do
      expect(exporter.instance_eval {@indexes[-1]}).to eq(0)
    end
  end

  describe "Exporter#ascend" do
    before(:each) do
      2.times { exporter.send(:data_method) }
      exporter.send :ascend
    end

    it "should remove an index" do
      expect(exporter.instance_eval { @indexes.length }).to eq(1)  
    end

    it "should remove the last set of values from @vals" do
      expect(exporter.instance_eval { @vals }).to eq([])
    end

    it "should increment the current index" do
      expect(exporter.instance_eval { @indexes[-1] }).to eq(2)
    end

    it "should remove the current prologue from the list" do
      expect(exporter.instance_eval { @prologue }).to eq([])
    end
  end

  describe "Exporter#current_coordinate_value" do
    it "should return just the value from the map if @vals is empty" do
      expect(exporter.send :current_coordinate_value).to eq(:split)
    end

    it "should return the @vals value corresponding to @indexes[-1]" do
      exporter.send :data_method
      exporter.send :descend

      expect(exporter.send :current_coordinate_value).to eq(exporter.instance_eval { @vals.last.last })
    end
  end

  describe "Exporter.update_map" do
    before(:all) do
      class Export::Formatters::NewFormatter < Export::Exporter
        def self.data_format
          :new
        end
      end
    end

    it "update_map adds new formats to the map" do
      Export::Exporter.update_map

      Export::Exporter.format_map.should == formats.merge({ :new => Export::Formatters::NewFormatter })
    end
  end
end