# frozen_string_literal: true

require "yaml"
require "time"

module LunarPhases
  PHASE_NAMES = {
    new_moon: "New Moon",
    first_quarter: "1st Quarter",
    full_moon: "Full Moon",
    third_quarter: "3rd Quarter"
  }.freeze

  PHASE_SHORT_NAMES = {
    new_moon: "NM",
    first_quarter: "1Q",
    full_moon: "FM",
    third_quarter: "3Q"
  }.freeze

  # Result object returned by phase lookups
  Result = Data.define(
    :date,
    :timezone,
    :primary_phase,
    :offset,
    :phase_time
  ) do
    def name
      base = PHASE_NAMES[primary_phase]
      return base if offset == 0

      sign = offset > 0 ? "+" : ""
      "#{base}#{sign}#{offset}"
    end

    def short_name
      base = PHASE_SHORT_NAMES[primary_phase]
      return base if offset == 0

      sign = offset > 0 ? "+" : ""
      "#{base}#{sign}#{offset}"
    end

    def primary?
      offset == 0
    end

    def waxing?
      %i[new_moon first_quarter].include?(primary_phase)
    end

    def waning?
      %i[full_moon third_quarter].include?(primary_phase)
    end
  end

  class Phase
    DEFAULT_TIMEZONE = "Australia/Brisbane"

    class << self
      # Main lookup method
      #
      # @param date [Date, String] the date to look up
      # @param timezone [String] IANA timezone name
      # @return [Result] the phase result for that date
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

      # Convenience methods
      def full_moon?(date, timezone = DEFAULT_TIMEZONE)
        result = for_date(date, timezone)
        result.primary_phase == :full_moon && result.offset == 0
      end

      def new_moon?(date, timezone = DEFAULT_TIMEZONE)
        result = for_date(date, timezone)
        result.primary_phase == :new_moon && result.offset == 0
      end

      # Returns all primary phases within a date range
      #
      # @param start_date [Date]
      # @param end_date [Date]
      # @param timezone [String]
      # @return [Array<r>]
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

      # For dropdowns/select boxes
      def collection
        PHASE_NAMES.map { |key, name| [name, key] }
      end

      # All 36 phase combinations for detailed dropdowns
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

      # Valid date range for lookups
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
        # Binary search would be faster, but with ~2500 entries this is fine
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

      # Convert local time to UTC
      def local_to_utc(zone, year, month, day, hour, min, sec)
        if zone.is_a?(TZInfo::Timezone)
          zone.local_to_utc(Time.utc(year, month, day, hour, min, sec))
        else
          # ActiveSupport::TimeZone
          zone.local(year, month, day, hour, min, sec).utc
        end
      end

      # Convert UTC time to local date
      def utc_to_local_date(zone, utc_time)
        if zone.is_a?(TZInfo::Timezone)
          zone.to_local(utc_time).to_date
        else
          # ActiveSupport::TimeZone
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