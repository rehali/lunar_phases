# frozen_string_literal: true

require_relative "lunar_phases/version"
require_relative "lunar_phases/phase"

# LunarPhases provides moon phase lookups for dates between 2000 and 2050.
#
# == Installation
#
#   gem 'lunar_phases', git: 'https://github.com/yourorg/lunar_phases.git'
#
# == Quick Start
#
#   require 'lunar_phases'
#
#   # Get phase for a local date
#   result = LunarPhases.for_date(Date.new(2025, 1, 14))
#   puts result.name  # => "Full Moon"
#
#   # Get phase for a UTC datetime in a timezone
#   result = LunarPhases.for_datetime("2025-01-13T20:00:00Z", "Australia/Brisbane")
#   puts result.name  # => "Full Moon" (20:00 UTC = 06:00 Jan 14 Brisbane)
#   puts result.date  # => 2025-01-14
#
#   # Check for specific phases
#   LunarPhases.full_moon?(Date.new(2025, 1, 13))  # => true
#   LunarPhases.new_moon?(Date.new(2025, 1, 29))   # => true
#
# == Two Lookup Methods
#
# * +for_date+ - Use when you already have the local date
# * +for_datetime+ - Use when you have a UTC datetime and need timezone conversion
#
# == Result Object
#
# All lookups return a LunarPhases::Result with:
#
# * +name+ - Human-readable name like "Full Moon+2"
# * +short_name+ - Abbreviated like "FM+2"
# * +primary_phase+ - Symbol: :new_moon, :first_quarter, :full_moon, :third_quarter
# * +offset+ - Days from primary phase (-4 to +4)
# * +phase_time+ - UTC Time of the primary phase
# * +primary?+ - True if offset is 0
# * +waxing?+ - True for new_moon/first_quarter
# * +waning?+ - True for full_moon/third_quarter
#
# == Data Source
#
# Moon phase data derived from tables published by the Astronomical
# Applications Department of the U.S. Naval Observatory.
#
module LunarPhases
  class << self
    # Looks up the moon phase for a local date.
    #
    # Use this when you already have the date in local time.
    # If you have a UTC datetime, use for_datetime instead.
    #
    # == Example
    #
    #   LunarPhases.for_date(Date.new(2025, 1, 14))
    #   # => #<LunarPhases::Result name="Full Moon" ...>
    #
    def for_date(date)
      Phase.for_date(date)
    end

    # Looks up the moon phase for a UTC datetime in a specific timezone.
    #
    # Converts the UTC datetime to local date, then returns the phase.
    #
    # == Example
    #
    #   # 20:00 UTC on Jan 13 = 06:00 Jan 14 in Brisbane
    #   LunarPhases.for_datetime("2025-01-13T20:00:00Z", "Australia/Brisbane")
    #   # => #<LunarPhases::Result name="Full Moon" date=2025-01-14 ...>
    #
    def for_datetime(datetime, timezone)
      Phase.for_datetime(datetime, timezone)
    end

    # Returns true if the given date is exactly a Full Moon.
    #
    # == Example
    #
    #   LunarPhases.full_moon?(Date.new(2025, 1, 13))
    #   # => true
    #
    def full_moon?(date)
      Phase.full_moon?(date)
    end

    # Returns true if the given date is exactly a New Moon.
    #
    # == Example
    #
    #   LunarPhases.new_moon?(Date.new(2025, 1, 29))
    #   # => true
    #
    def new_moon?(date)
      Phase.new_moon?(date)
    end

    # Returns the phase name for a legacy ID.
    #
    # == Example
    #
    #   LunarPhases.for_id(14)  # => "Full Moon"
    #   LunarPhases.for_id(16)  # => "Full Moon+2"
    #
    def for_id(id)
      Phase.for_id(id)
    end

    # Returns all primary phases within a date range.
    #
    # == Example
    #
    #   phases = LunarPhases.phases_in_range(
    #     Date.new(2025, 1, 1),
    #     Date.new(2025, 12, 31)
    #   )
    #   phases.select { |p| p.primary_phase == :full_moon }
    #
    def phases_in_range(start_date, end_date, timezone = Phase::DEFAULT_TIMEZONE)
      Phase.phases_in_range(start_date, end_date, timezone)
    end

    # Returns an array suitable for Rails select boxes.
    #
    # == Example
    #
    #   LunarPhases.collection
    #   # => [["New Moon", :new_moon], ["1st Quarter", :first_quarter], ...]
    #
    def collection
      Phase.collection
    end

    # Returns all 36 phase combinations for detailed dropdowns.
    #
    # == Example
    #
    #   LunarPhases.detailed_collection
    #   # => [["New Moon-4", "New Moon-4"], ...]
    #
    def detailed_collection
      Phase.detailed_collection
    end

    # Returns the valid date range for lookups.
    #
    # == Example
    #
    #   LunarPhases.valid_range
    #   # => #<Date: 2000-01-06>..#<Date: 2050-12-21>
    #
    def valid_range
      Phase.valid_range
    end
  end
end