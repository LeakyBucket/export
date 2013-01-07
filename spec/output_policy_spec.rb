require 'spec_helper'

describe "Export::OutputPolicy" do
  describe "OutputPolicy#new" do
    it "should add any presenters defined in Export::Presenters" do
      class Export::Presenters::TestPresenter
        def self.target
          Fixnum
        end
      end

      op = Export::OutputPolicy.new

      expect(op.presenters).to eq({ Fixnum => Export::Presenters::TestPresenter })
    end
  end
end