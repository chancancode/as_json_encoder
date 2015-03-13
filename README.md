# as_json JSON Encoder

A JSON encoder that is tailored to the needs of Rails. The goal is to take
advantage of the domain knowledge and speed up the JSON encoding process in
Rails applications.

This gem is compatible with Rails 4.1+.

## Current Status

At the moment, this is highly experimental. Performance is competitive with the
current Rails JSON encoder, but we have not achieved our performance goals yet.

Using this in production is **not** recommended.

## Installation

Add this line to your Rails application's Gemfile:

```ruby
gem 'as_json_encoder'
```

And then execute:

    $ bundle

## Usage

Simply follow the instructions above to add this to your Gemfile. No further
configuration is necessary.

## Contributing

1. Fork it ( https://github.com/chancancode/as_json_encoder/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
