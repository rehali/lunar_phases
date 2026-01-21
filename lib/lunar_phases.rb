# frozen_string_literal: true

require_relative "lunar_phases/version"
require_relative "lunar_phases/phase"

module LunarPhases
  class << self
    def for_date(date, timezone = Phase::DEFAULT_TIMEZONE)
      Phase.for_date(date, timezone)
    end

    def full_moon?(date, timezone = Phase::DEFAULT_TIMEZONE)
      Phase.full_moon?(date, timezone)
    end

    def new_moon?(date, timezone = Phase::DEFAULT_TIMEZONE)
      Phase.new_moon?(date, timezone)
    end

    def phases_in_range(start_date, end_date, timezone = Phase::DEFAULT_TIMEZONE)
      Phase.phases_in_range(start_date, end_date, timezone)
    end

    def collection
      Phase.collection
    end

    def detailed_collection
      Phase.detailed_collection
    end

    def valid_range
      Phase.valid_range
    end
  end
end
