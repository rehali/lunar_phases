# frozen_string_literal: true

require "yaml"
require "time"

# LunarPhases provides timezone-aware moon phase lookups for any date
# between 2000 and 2050.
#
# == Basic Usage
#
#   result = LunarPhases.for_date(Date.today, "Australia/Brisbane")
#   result.name        # => "Full Moon+2"
#   result.short_name  # => "FM+2"
#   result.primary_phase # => :full_moon
#   result.offset      # => 2
#
# == Timezone Handling
#
# Moon phases are global events occurring at specific UTC instants.
# The same phase may fall on different calendar dates depending on timezone:
#
#   # Full Moon at 2025-01-13 22:27 UTC
#   LunarPhases.for_date(Date.new(2025, 1, 13), "Europe/London").name
#   # => "Full Moon"
#
#   LunarPhases.for_date(Date.new(2025, 1, 13), "Australia/Brisbane").name
#   # => "Full Moon-1"  (it's Jan 14 in Brisbane when the Full Moon occurs)
#
# == Data Source
#
# Moon phase data derived from tables published by the Astronomical
# Applications Department of the U.S. Naval Observatory.
#
module LunarPhases
  # Human-readable names for each primary phase.
  #
  #   PHASE_NAMES[:full_moon]  # => "Full Moon"
  #   PHASE_NAMES[:new_moon]   # => "New Moon"
  #
  PHASE_NAMES = {
    new_moon: "New Moon",
    first_quarter: "1st Quarter",
    full_moon: "Full Moon",
    third_quarter: "3rd Quarter"
  }.freeze

  # Abbreviated names for each primary phase.
  #
  #   PHASE_SHORT_NAMES[:full_moon]  # => "FM"
  #   PHASE_SHORT_NAMES[:new_moon]   # => "NM"
  #
  PHASE_SHORT_NAMES = {
    new_moon: "NM",
    first_quarter: "1Q",
    full_moon: "FM",
    third_quarter: "3Q"
  }.freeze

  # Result object returned by phase lookups.
  #
  # == Attributes
  #
  # * +date+ - The queried Date
  # * +timezone+ - The timezone used for the lookup (String)
  # * +primary_phase+ - Symbol: :new_moon, :first_quarter, :full_moon, or :third_quarter
  # * +offset+ - Days from the primary phase (-4 to +4)
  # * +phase_time+ - UTC Time when the primary phase occurs
  #
  # == Example
  #
  #   result = LunarPhases.for_date(Date.new(2025, 1, 16), "Australia/Brisbane")
  #   result.date          # => #<Date: 2025-01-16>
  #   result.timezone      # => "Australia/Brisbane"
  #   result.primary_phase # => :full_moon
  #   result.offset        # => 2
  #   result.phase_time    # => 2025-01-13 22:27:00 UTC
  #   result.name          # => "Full Moon+2"
  #   result.short_name    # => "FM+2"
  #   result.primary?      # => false
  #   result.waning?       # => true
  #
  Result = Data.define(
    :date,
    :timezone,
    :primary_phase,
    :offset,
    :phase_time
  ) do
    # Returns the full human-readable name including offset.
    #
    #   result.name  # => "Full Moon+2" or "New Moon" (if offset is 0)
    #
    def name
      base = PHASE_NAMES[primary_phase]
      return base if offset == 0

      sign = offset > 0 ? "+" : ""
      "#{base}#{sign}#{offset}"
    end

    # Returns the abbreviated name including offset.
    #
    #   result.short_name  # => "FM+2" or "NM" (if offset is 0)
    #
    def short_name
      base = PHASE_SHORT_NAMES[primary_phase]
      return base if offset == 0

      sign = offset > 0 ? "+" : ""
      "#{base}#{sign}#{offset}"
    end

    # Returns true if this is exactly on a primary phase (offset is 0).
    #
    #   result.primary?  # => true if offset == 0
    #
    def primary?
      offset == 0
    end

    # Returns true if the moon is waxing (between New Moon and Full Moon).
    # This includes New Moon and 1st Quarter phases.
    #
    #   result.waxing?  # => true for new_moon or first_quarter
    #
    def waxing?
      %i[new_moon first_quarter].include?(primary_phase)
    end

    # Returns true if the moon is waning (between Full Moon and New Moon).
    # This includes Full Moon and 3rd Quarter phases.
    #
    #   result.waning?  # => true for full_moon or third_quarter
    #
    def waning?
      %i[full_moon third_quarter].include?(primary_phase)
    end
  end

  # Provides moon phase lookup functionality.
  #
  # All methods are class methods - there's no need to instantiate this class.
  #
  # == Example
  #
  #   LunarPhases::Phase.for_date(Date.today)
  #   LunarPhases::Phase.full_moon?(Date.today)
  #   LunarPhases::Phase.phases_in_range(Date.new(2025,1,1), Date.new(2025,12,31))
  #
  class Phase
    # Default timezone used when none is specified.
    DEFAULT_TIMEZONE = "Australia/Brisbane"

    class << self
      # Looks up the moon phase for a given date and timezone.
      #
      # Each date is assigned to its nearest primary phase (New Moon,
      # 1st Quarter, Full Moon, or 3rd Quarter) with an offset indicating
      # days before (-) or after (+) that phase.
      #
      # == Parameters
      #
      # * +date+ - A Date object or String parseable as a date
      # * +timezone+ - IANA timezone name (default: "Australia/Brisbane")
      #
      # == Returns
      #
      # A Result object containing the phase information.
      #
      # == Raises
      #
      # * +ArgumentError+ if the date is outside the valid range (2000-2050)
      # * +ArgumentError+ if the timezone is unknown
      #
      # == Example
      #
      #   result = LunarPhases::Phase.for_date(Date.new(2025, 1, 14), "Australia/Brisbane")
      #   result.name  # => "Full Moon"
      #
      #   result = LunarPhases::Phase.for_date("2025-01-16", "Europe/London")
      #   result.name  # => "Full Moon+3"
      #
      def for_date(date, timezone = DEFAULT_TIMEZONE)
        date = Date.parse(date.to_s) unless date.is_a?(Date)
        validate_date!(date)

        zone = find_timezone(timezone)
        day_midpoint = local_to_utc(zone, date.year, date.month, date.day, 12, 0, 0)

        # Find the nearest primary phase
        nearest = find_nearest_phase(day_midpoint)

        # Calculate offset in days
        phase_date = utc_to_local_date(zone, nearest[:time])
        offset = (date - phase_date).to_i

        Result.new(
          date: date,
          timezone: timezone,
          primary_phase: nearest[:phase].to_sym,
          offset: offset,
          phase_time: nearest[:time]
        )
      end

      # Returns true if the given date is exactly a Full Moon.
      #
      # == Example
      #
      #   LunarPhases::Phase.full_moon?(Date.new(2025, 1, 14), "Australia/Brisbane")
      #   # => true
      #
      def full_moon?(date, timezone = DEFAULT_TIMEZONE)
        result = for_date(date, timezone)
        result.primary_phase == :full_moon && result.offset == 0
      end

      # Returns true if the given date is exactly a New Moon.
      #
      # == Example
      #
      #   LunarPhases::Phase.new_moon?(Date.new(2025, 1, 29), "Australia/Brisbane")
      #   # => true
      #
      def new_moon?(date, timezone = DEFAULT_TIMEZONE)
        result = for_date(date, timezone)
        result.primary_phase == :new_moon && result.offset == 0
      end

      # Returns all primary phases within a date range.
      #
      # Useful for calendars or finding upcoming Full Moons.
      #
      # == Parameters
      #
      # * +start_date+ - Start of range (Date or String)
      # * +end_date+ - End of range (Date or String)
      # * +timezone+ - IANA timezone name
      #
      # == Returns
      #
      # Array of Result objects, each with offset = 0.
      #
      # == Example
      #
      #   phases = LunarPhases::Phase.phases_in_range(
      #     Date.new(2025, 1, 1),
      #     Date.new(2025, 1, 31),
      #     "Australia/Brisbane"
      #   )
      #   phases.each { |p| puts "#{p.date}: #{p.name}" }
      #   # 2025-01-07: Full Moon
      #   # 2025-01-14: 3rd Quarter
      #   # ...
      #
      def phases_in_range(start_date, end_date, timezone = DEFAULT_TIMEZONE)
        start_date = Date.parse(start_date.to_s) unless start_date.is_a?(Date)
        end_date = Date.parse(end_date.to_s) unless end_date.is_a?(Date)
        zone = find_timezone(timezone)

        range_start = local_to_utc(zone, start_date.year, start_date.month, start_date.day, 0, 0, 0)
        range_end = local_to_utc(zone, end_date.year, end_date.month, end_date.day, 23, 59, 59)

        data.select { |p| p[:time] >= range_start && p[:time] <= range_end }
            .map do |p|
              phase_date = utc_to_local_date(zone, p[:time])
              Result.new(
                date: phase_date,
                timezone: timezone,
                primary_phase: p[:phase].to_sym,
                offset: 0,
                phase_time: p[:time]
              )
            end
      end

      # Returns an array suitable for Rails select boxes.
      #
      # == Returns
      #
      # Array of [name, key] pairs for the four primary phases.
      #
      # == Example
      #
      #   LunarPhases::Phase.collection
      #   # => [["New Moon", :new_moon], ["1st Quarter", :first_quarter], ...]
      #
      #   # In a Rails form:
      #   select(:catch, :moon_phase, LunarPhases::Phase.collection)
      #
      def collection
        PHASE_NAMES.map { |key, name| [name, key] }
      end

      # Returns all 36 phase combinations for detailed dropdowns.
      #
      # Includes each primary phase with offsets from -4 to +4.
      #
      # == Returns
      #
      # Array of [name, value] pairs where value is "phase:offset".
      #
      # == Example
      #
      #   LunarPhases::Phase.detailed_collection
      #   # => [["New Moon-4", "new_moon:-4"], ["New Moon-3", "new_moon:-3"], ...]
      #
      def detailed_collection
        phases = %i[new_moon first_quarter full_moon third_quarter]
        offsets = (-4..4).to_a

        phases.flat_map do |phase|
          offsets.map do |offset|
            base = PHASE_NAMES[phase]
            name = offset == 0 ? base : "#{base}#{offset > 0 ? '+' : ''}#{offset}"
            [name, "#{phase}:#{offset}"]
          end
        end
      end

      # Returns the valid date range for lookups.
      #
      # == Returns
      #
      # A Range of Dates (approximately 2000-01-06 to 2050-12-21).
      #
      # == Example
      #
      #   LunarPhases::Phase.valid_range
      #   # => #<Date: 2000-01-06>..#<Date: 2050-12-21>
      #
      #   LunarPhases::Phase.valid_range.cover?(Date.today)
      #   # => true
      #
      def valid_range
        times = data.map { |p| p[:time] }
        start_date = times.min.to_date
        end_date = times.max.to_date
        start_date..end_date
      end

      private

      def data
        @data ||= load_data
      end

      def load_data
        path = File.join(__dir__, "data", "phases.yml")
        raw = YAML.load_file(path, permitted_classes: [Date, Time])

        raw.map do |entry|
          {
            phase: entry["phase"],
            time: Time.parse(entry["utc"]).utc
          }
        end
      end

      def find_nearest_phase(utc_time)
        data.min_by { |p| (p[:time] - utc_time).abs }
      end

      def find_timezone(name)
        if defined?(ActiveSupport::TimeZone)
          ActiveSupport::TimeZone[name] || raise(ArgumentError, "Unknown timezone: #{name}")
        else
          require "tzinfo"
          TZInfo::Timezone.get(name)
        end
      rescue TZInfo::InvalidTimezoneIdentifier
        raise ArgumentError, "Unknown timezone: #{name}"
      end

      def local_to_utc(zone, year, month, day, hour, min, sec)
        if zone.is_a?(TZInfo::Timezone)
          zone.local_to_utc(Time.utc(year, month, day, hour, min, sec))
        else
          zone.local(year, month, day, hour, min, sec).utc
        end
      end

      def utc_to_local_date(zone, utc_time)
        if zone.is_a?(TZInfo::Timezone)
          zone.to_local(utc_time).to_date
        else
          utc_time.in_time_zone(zone).to_date
        end
      end

      def validate_date!(date)
        range = valid_range
        return if range.cover?(date)

        raise ArgumentError, "Date #{date} is outside valid range (#{range.first} to #{range.last})"
      end
    end
  end
end