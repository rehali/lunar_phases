# LunarPhases

Timezone-aware moon phase lookup for any date between 2000-2050.

## Installation

Add to your Gemfile:

```ruby
gem 'lunar_phases', git: 'https://github.com/rehali/lunar_phases.git'
```

## Usage

```ruby
require 'lunar_phases'

# Get phase for a date
result = LunarPhases.for_date(Date.today, "Australia/Brisbane")
result.name         # => "Full Moon+2"
result.short_name   # => "FM+2"
result.primary_phase # => :full_moon
result.offset       # => 2
result.phase_time   # => 2025-01-13 22:27:00 UTC

# Check for specific phases
LunarPhases.full_moon?(Date.today, "Australia/Brisbane")  # => false
LunarPhases.new_moon?(Date.today, "Australia/Brisbane")   # => false

# Get all primary phases in a range
phases = LunarPhases.phases_in_range(Date.new(2025, 1, 1), Date.new(2025, 12, 31), "Australia/Brisbane")
phases.each { |p| puts "#{p.date}: #{p.name}" }

# For select boxes
LunarPhases.collection           # => [["New Moon", "New Moon"], ...]
LunarPhases.detailed_collection  # => [["New Moon-4", "New Moon-4"], ...]

# Check valid date range
LunarPhases.valid_range  # => Date(2000-01-06)..Date(2050-12-21)
```

## Result Object

The `Result` object includes:

- `date` - The queried date
- `timezone` - The timezone used
- `primary_phase` - Symbol: `:new_moon`, `:first_quarter`, `:full_moon`, `:third_quarter`
- `offset` - Days from primary phase (-4 to +4)
- `phase_time` - UTC Time of the primary phase event
- `name` - Human readable name like "Full Moon+2"
- `short_name` - Abbreviated like "FM+2"
- `primary?` - True if offset is 0
- `waxing?` - True for New Moon and 1st Quarter phases
- `waning?` - True for Full Moon and 3rd Quarter phases

## Timezone Handling

Moon phases are global events occurring at specific UTC instants. The same phase may fall on different calendar dates depending on timezone:

```ruby
# Full Moon at 2025-01-13 22:27 UTC
LunarPhases.for_date(Date.new(2025, 1, 13), "Europe/London").name    # => "Full Moon"
LunarPhases.for_date(Date.new(2025, 1, 13), "Australia/Brisbane").name # => "Full Moon-1"
LunarPhases.for_date(Date.new(2025, 1, 14), "Australia/Brisbane").name # => "Full Moon"
```

## Data Source

Moon phase data derived from tables published by the Astronomical Applications Department of the U.S. Naval Observatory.

## License

MIT
