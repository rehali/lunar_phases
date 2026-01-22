# frozen_string_literal: true

require "lunar_phases"

RSpec.describe LunarPhases do
  # Known Full Moon: 2025-01-13 22:27 UTC
  # Known New Moon: 2025-01-29 12:36 UTC

  describe ".for_date" do
    it "returns Full Moon for Jan 13 (the UTC date of the Full Moon)" do
      result = LunarPhases.for_date(Date.new(2025, 1, 13))

      expect(result.primary_phase).to eq(:full_moon)
      expect(result.offset).to eq(0)
      expect(result.name).to eq("Full Moon")
    end

    it "returns Full Moon+1 for Jan 14" do
      result = LunarPhases.for_date(Date.new(2025, 1, 14))

      expect(result.primary_phase).to eq(:full_moon)
      expect(result.offset).to eq(1)
      expect(result.name).to eq("Full Moon+1")
    end

    it "returns Full Moon-1 for Jan 12" do
      result = LunarPhases.for_date(Date.new(2025, 1, 12))

      expect(result.primary_phase).to eq(:full_moon)
      expect(result.offset).to eq(-1)
      expect(result.name).to eq("Full Moon-1")
    end

    it "accepts string dates" do
      result = LunarPhases.for_date("2025-01-13")

      expect(result.primary_phase).to eq(:full_moon)
      expect(result.offset).to eq(0)
    end

    it "raises error for dates outside valid range" do
      expect { LunarPhases.for_date(Date.new(1990, 1, 1)) }
        .to raise_error(ArgumentError, /outside valid range/)
    end
  end

  describe ".for_datetime" do
    context "timezone conversion" do
      # Full Moon at 2025-01-13 22:27 UTC
      # In Brisbane (UTC+10): 2025-01-14 08:27 local

      it "converts UTC datetime to local date before lookup" do
        # 20:00 UTC on Jan 13 = 06:00 Jan 14 in Brisbane
        result = LunarPhases.for_datetime("2025-01-13T20:00:00Z", "Australia/Brisbane")

        expect(result.date).to eq(Date.new(2025, 1, 14))
        expect(result.primary_phase).to eq(:full_moon)
        expect(result.offset).to eq(0)
        expect(result.name).to eq("Full Moon")
      end

      it "returns different results for same UTC time in different timezones" do
        # 20:00 UTC on Jan 13
        # In London: Jan 13 (Full Moon-1... wait no, Full Moon is at 22:27 so Jan 13 is Full Moon)
        # In Brisbane: Jan 14 (Full Moon)
        utc_datetime = "2025-01-13T20:00:00Z"

        london_result = LunarPhases.for_datetime(utc_datetime, "Europe/London")
        brisbane_result = LunarPhases.for_datetime(utc_datetime, "Australia/Brisbane")

        expect(london_result.date).to eq(Date.new(2025, 1, 13))
        expect(brisbane_result.date).to eq(Date.new(2025, 1, 14))
      end

      it "handles Time objects" do
        time = Time.utc(2025, 1, 13, 20, 0, 0)
        result = LunarPhases.for_datetime(time, "Australia/Brisbane")

        expect(result.date).to eq(Date.new(2025, 1, 14))
      end

      it "handles DateTime objects" do
        datetime = DateTime.new(2025, 1, 13, 20, 0, 0)
        result = LunarPhases.for_datetime(datetime, "Australia/Brisbane")

        expect(result.date).to eq(Date.new(2025, 1, 14))
      end
    end

    it "raises error for unknown timezone" do
      expect { LunarPhases.for_datetime("2025-01-13T20:00:00Z", "Invalid/Zone") }
        .to raise_error(ArgumentError, /Unknown timezone/)
    end

    it "raises error for dates outside valid range" do
      expect { LunarPhases.for_datetime("1990-01-01T12:00:00Z", "UTC") }
        .to raise_error(ArgumentError, /outside valid range/)
    end
  end

  describe ".full_moon?" do
    it "returns true on Full Moon day" do
      expect(LunarPhases.full_moon?(Date.new(2025, 1, 13))).to be true
    end

    it "returns false on adjacent days" do
      expect(LunarPhases.full_moon?(Date.new(2025, 1, 12))).to be false
      expect(LunarPhases.full_moon?(Date.new(2025, 1, 14))).to be false
    end
  end

  describe ".new_moon?" do
    it "returns true on New Moon day" do
      expect(LunarPhases.new_moon?(Date.new(2025, 1, 29))).to be true
    end

    it "returns false on adjacent days" do
      expect(LunarPhases.new_moon?(Date.new(2025, 1, 28))).to be false
      expect(LunarPhases.new_moon?(Date.new(2025, 1, 30))).to be false
    end
  end

  describe ".for_id" do
    it "returns phase name for legacy ID" do
      expect(LunarPhases.for_id(14)).to eq("Full Moon")
      expect(LunarPhases.for_id(16)).to eq("Full Moon+2")
      expect(LunarPhases.for_id(0)).to eq("New Moon")
    end

    it "returns nil for unknown ID" do
      expect(LunarPhases.for_id(999)).to be_nil
    end
  end

  describe ".phases_in_range" do
    it "returns all primary phases in a month" do
      phases = LunarPhases.phases_in_range(
        Date.new(2025, 1, 1),
        Date.new(2025, 1, 31)
      )

      expect(phases.length).to be >= 3
      expect(phases.length).to be <= 5
      expect(phases.all?(&:primary?)).to be true
    end

    it "accepts timezone for local date range" do
      phases = LunarPhases.phases_in_range(
        Date.new(2025, 1, 1),
        Date.new(2025, 1, 31),
        "Australia/Brisbane"
      )

      expect(phases).to all(have_attributes(timezone: "Australia/Brisbane"))
    end
  end

  describe "Result" do
    describe "#short_name" do
      it "returns abbreviated form for primary phase" do
        result = LunarPhases.for_date(Date.new(2025, 1, 13))
        expect(result.short_name).to eq("FM")
      end

      it "returns abbreviated form with offset" do
        result = LunarPhases.for_date(Date.new(2025, 1, 15))
        expect(result.short_name).to eq("FM+2")
      end
    end

    describe "#primary?" do
      it "returns true when offset is 0" do
        result = LunarPhases.for_date(Date.new(2025, 1, 13))
        expect(result.primary?).to be true
      end

      it "returns false when offset is not 0" do
        result = LunarPhases.for_date(Date.new(2025, 1, 14))
        expect(result.primary?).to be false
      end
    end

    describe "#waxing? and #waning?" do
      it "correctly identifies waxing phases (New Moon, 1st Quarter)" do
        nm = LunarPhases.for_date(Date.new(2025, 1, 29))
        expect(nm.waxing?).to be true
        expect(nm.waning?).to be false
      end

      it "correctly identifies waning phases (Full Moon, 3rd Quarter)" do
        fm = LunarPhases.for_date(Date.new(2025, 1, 13))
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

      expect(collection.length).to eq(36)
      expect(collection).to include(["New Moon", "New Moon"])
      expect(collection).to include(["Full Moon+2", "Full Moon+2"])
      expect(collection).to include(["1st Quarter-3", "1st Quarter-3"])
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
end