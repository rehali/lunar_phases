# frozen_string_literal: true

require_relative "lunar_phases/version"
require_relative "lunar_phases/phase"

# LunarPhases provides timezone-aware moon phase lookups for any date
# between 2000 and 2050.
#
# == Installation
#
#   gem 'lunar_phases', git: 'https://github.com/rehali/lunar_phases.git'
#
# == Quick Start
#
#   require 'lunar_phases'
#
#   # Get phase for today
#   result = LunarPhases.for_date(Date.today, "Australia/Brisbane")
#   puts result.name        # => "Full Moon+2"
#   puts result.short_name  # => "FM+2"
#
#   # Check for specific phases
#   LunarPhases.full_moon?(Date.today)  # => false
#   LunarPhases.new_moon?(Date.today)   # => false
#
#   # Find phases in a date range
#   LunarPhases.phases_in_range(Date.new(2025,1,1), Date.new(2025,12,31))
#
# == Timezone Handling
#
# Moon phases occur at specific UTC instants. The calendar date depends
# on the observer's timezone. For example, a Full Moon at 22:27 UTC on
# January 13 falls on January 14 in Brisbane (UTC+10).
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
    # Looks up the moon phase for a given date and timezone.
    #
    # See LunarPhases::Phase.for_date for full documentation.
    #
    # == Example
    #
    #   LunarPhases.for_date(Date.today, "Australia/Brisbane")
    #   # => #<LunarPhases::Result name="Full Moon+2" ...>
    #
    def for_date(date, timezone = Phase::DEFAULT_TIMEZONE)
      Phase.for_date(date, timezone)
    end

    # Returns true if the given date is exactly a Full Moon.
    #
    # == Example
    #
    #   LunarPhases.full_moon?(Date.new(2025, 1, 14), "Australia/Brisbane")
    #   # => true
    #
    def full_moon?(date, timezone = Phase::DEFAULT_TIMEZONE)
      Phase.full_moon?(date, timezone)
    end

    # Returns true if the given date is exactly a New Moon.
    #
    # == Example
    #
    #   LunarPhases.new_moon?(Date.new(2025, 1, 29), "Australia/Brisbane")
    #   # => true
    #
    def new_moon?(date, timezone = Phase::DEFAULT_TIMEZONE)
      Phase.new_moon?(date, timezone)
    end

    # Returns all primary phases within a date range.
    #
    # See LunarPhases::Phase.phases_in_range for full documentation.
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
    #   # => [["New Moon-4", "new_moon:-4"], ...]
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