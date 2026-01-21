# frozen_string_literal: true

require "lunar_phases"

RSpec.describe LunarPhases do
  describe ".for_date" do
    # Known Full Moon: 2025-01-13 22:27 UTC
    # In Brisbane (UTC+10): 2025-01-14 08:27 local
    context "Full Moon on 2025-01-13 UTC" do
      it "returns Full Moon for Jan 14 in Brisbane" do
        result = LunarPhases.for_date(Date.new(2025, 1, 14), "Australia/Brisbane")

        expect(result.primary_phase).to eq(:full_moon)
        expect(result.offset).to eq(0)
        expect(result.name).to eq("Full Moon")
      end

      it "returns Full Moon+1 for Jan 15 in Brisbane" do
        result = LunarPhases.for_date(Date.new(2025, 1, 15), "Australia/Brisbane")

        expect(result.primary_phase).to eq(:full_moon)
        expect(result.offset).to eq(1)
        expect(result.name).to eq("Full Moon+1")
      end

      it "returns Full Moon-1 for Jan 13 in Brisbane" do
        result = LunarPhases.for_date(Date.new(2025, 1, 13), "Australia/Brisbane")

        expect(result.primary_phase).to eq(:full_moon)
        expect(result.offset).to eq(-1)
        expect(result.name).to eq("Full Moon-1")
      end

      it "returns Full Moon for Jan 13 in London (different timezone)" do
        result = LunarPhases.for_date(Date.new(2025, 1, 13), "Europe/London")

        expect(result.primary_phase).to eq(:full_moon)
        expect(result.offset).to eq(0)
      end
    end
  end

  describe ".full_moon?" do
    it "returns true on Full Moon day" do
      expect(LunarPhases.full_moon?(Date.new(2025, 1, 14), "Australia/Brisbane")).to be true
    end

    it "returns false on adjacent days" do
      expect(LunarPhases.full_moon?(Date.new(2025, 1, 13), "Australia/Brisbane")).to be false
      expect(LunarPhases.full_moon?(Date.new(2025, 1, 15), "Australia/Brisbane")).to be false
    end
  end

  describe ".new_moon?" do
    # Known New Moon: 2025-01-29 12:36 UTC
    # In Brisbane (UTC+10): 2025-01-29 22:36 local
    it "returns true on New Moon day" do
      expect(LunarPhases.new_moon?(Date.new(2025, 1, 29), "Australia/Brisbane")).to be true
    end
  end

  describe ".phases_in_range" do
    it "returns all primary phases in a month" do
      phases = LunarPhases.phases_in_range(
        Date.new(2025, 1, 1),
        Date.new(2025, 1, 31),
        "Australia/Brisbane"
      )

      # January 2025 should have ~4 primary phases
      expect(phases.length).to be >= 3
      expect(phases.length).to be <= 5
      expect(phases.all?(&:primary?)).to be true
    end
  end

  describe "Result" do
    let(:result) do
      LunarPhases.for_date(Date.new(2025, 1, 16), "Australia/Brisbane")
    end

    describe "#short_name" do
      it "returns abbreviated form" do
        fm = LunarPhases.for_date(Date.new(2025, 1, 14), "Australia/Brisbane")
        expect(fm.short_name).to eq("FM")

        fm_plus_2 = LunarPhases.for_date(Date.new(2025, 1, 16), "Australia/Brisbane")
        expect(fm_plus_2.short_name).to eq("FM+2")
      end
    end

    describe "#waxing? and #waning?" do
      it "correctly identifies waxing phases" do
        # New Moon is start of waxing
        nm = LunarPhases.for_date(Date.new(2025, 1, 29), "Australia/Brisbane")
        expect(nm.waxing?).to be true
        expect(nm.waning?).to be false
      end

      it "correctly identifies waning phases" do
        # Full Moon is start of waning
        fm = LunarPhases.for_date(Date.new(2025, 1, 14), "Australia/Brisbane")
        expect(fm.waning?).to be true
        expect(fm.waxing?).to be false
      end
    end
  end

  describe ".collection" do
    it "returns array suitable for select boxes" do
      collection = LunarPhases.collection

      expect(collection).to include(["New Moon", :new_moon])
      expect(collection).to include(["Full Moon", :full_moon])
      expect(collection.length).to eq(4)
    end
  end

  describe ".detailed_collection" do
    it "returns all 36 phase combinations" do
      collection = LunarPhases.detailed_collection

      expect(collection.length).to eq(36) # 4 phases × 9 offsets
      expect(collection).to include(["New Moon", "new_moon:0"])
      expect(collection).to include(["Full Moon+2", "full_moon:2"])
      expect(collection).to include(["1st Quarter-3", "first_quarter:-3"])
    end
  end

  describe ".valid_range" do
    it "returns the supported date range" do
      range = LunarPhases.valid_range

      expect(range).to be_a(Range)
      expect(range.first.year).to be <= 2001
      expect(range.last.year).to be >= 2049
    end
  end

  describe "edge cases" do
    it "raises error for dates outside valid range" do
      expect { LunarPhases.for_date(Date.new(1990, 1, 1)) }
        .to raise_error(ArgumentError, /outside valid range/)
    end

    it "raises error for unknown timezone" do
      expect { LunarPhases.for_date(Date.new(2025, 1, 1), "Invalid/Zone") }
        .to raise_error(ArgumentError, /Unknown timezone/)
    end

    it "accepts string dates" do
      result = LunarPhases.for_date("2025-01-14", "Australia/Brisbane")
      expect(result.primary_phase).to eq(:full_moon)
    end
  end
end
