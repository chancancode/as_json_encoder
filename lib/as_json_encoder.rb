require "as_json_encoder/version"

require "active_support"
require "active_support/json"
require "active_support/cache/memory_store"

module AsJsonEncoder

  # Configs
  class << self
    # The cache to use for storing JSON fragments. This will grow unbounded at
    # runtime, so it should be set to a bounded LRU cache implementation, such
    # as +ActiveSupport::Cache::MemoryStore+.
    attr_accessor :cache

    # The namespace to use for the cache keys.
    attr_accessor :namespace
  end

  # Defaults
  self.cache     = ActiveSupport::Cache::MemoryStore.new
  self.namespace = nil

  # Include this into any class to mark them as cacheable.
  module Cachable
    def cache_key
      nil
    end
  end

  class Encoder # :nodoc:

    STRING_ESCAPE_CHAR_MAP = {
      # Stolen from json-pure
      "\x0" => '\u0000',
      "\x1" => '\u0001',
      "\x2" => '\u0002',
      "\x3" => '\u0003',
      "\x4" => '\u0004',
      "\x5" => '\u0005',
      "\x6" => '\u0006',
      "\x7" => '\u0007',
      "\b"  =>  '\b',
      "\t"  =>  '\t',
      "\n"  =>  '\n',
      "\xb" => '\u000b',
      "\f"  =>  '\f',
      "\r"  =>  '\r',
      "\xe" => '\u000e',
      "\xf" => '\u000f',
      "\x10" => '\u0010',
      "\x11" => '\u0011',
      "\x12" => '\u0012',
      "\x13" => '\u0013',
      "\x14" => '\u0014',
      "\x15" => '\u0015',
      "\x16" => '\u0016',
      "\x17" => '\u0017',
      "\x18" => '\u0018',
      "\x19" => '\u0019',
      "\x1a" => '\u001a',
      "\x1b" => '\u001b',
      "\x1c" => '\u001c',
      "\x1d" => '\u001d',
      "\x1e" => '\u001e',
      "\x1f" => '\u001f',
      '"' => '\"',
      '\\' =>  '\\\\',

      # Rails-specific
      "\xE2\x80\xA8".force_encoding(::Encoding::ASCII_8BIT) => '\u2028',
      "\xE2\x80\xA9".force_encoding(::Encoding::ASCII_8BIT) => '\u2029',
      ">" => '\u003e',
      "<" => '\u003c',
      "&" => '\u0026',
    }.freeze

    STRING_ESCAPE_REGEX_WITH_HTML_ENTITIES = /[><&"\\\x0-\x1f]|(?:\xE2\x80\xA8)|(?:\xE2\x80\xA9)/n

    STRING_ESCAPE_REGEX_WITHOUT_HTML_ENTITIES = /["\\\x0-\x1f]|(?:\xE2\x80\xA8)|(?:\xE2\x80\xA9)/n

    private_constant :STRING_ESCAPE_CHAR_MAP,
      :STRING_ESCAPE_REGEX_WITH_HTML_ENTITIES,
      :STRING_ESCAPE_REGEX_WITHOUT_HTML_ENTITIES

    def encode(value)
      fetch_or_encode_value(value, '', true)
    end

    private

      def fetch_or_encode_value(value, buffer, unwrap = false)
        cache, namespace = AsJsonEncoder.cache, AsJsonEncoder.namespace

        if Cachable === value
          buffer << cache.fetch(value.cache_key, namespace: namespace) do
            encode_value(unwrap ? value.as_json : value, '')
          end
        else
          encode_value(unwrap ? value.as_json : value, buffer)
        end
      end

      def encode_value(value, buffer)
        case value
        when String
          encode_string(value, buffer)
        when Symbol
          encode_string(value.to_s, buffer)
        when Float
          buffer << (value.finite? ? value.to_s : 'null'.freeze)
        when Numeric
          buffer << value.to_s
        when NilClass
          buffer << 'null'.freeze
        when TrueClass
          buffer << 'true'.freeze
        when FalseClass
          buffer << 'false'.freeze
        when Hash
          encode_hash(value, buffer)
        when Array
          encode_array(value, buffer)
        else
          fetch_or_encode_value(value.as_json, buffer)
        end
      end

      def encode_string(str, buffer)
        if ActiveSupport::JSON::Encoding.escape_html_entities_in_json
          regexp = STRING_ESCAPE_REGEX_WITH_HTML_ENTITIES
        else
          regexp = STRING_ESCAPE_REGEX_WITHOUT_HTML_ENTITIES
        end

        # Stolen from json-pure

        if str.encoding == ::Encoding::UTF_8
          escaped = str.dup
        else
          escaped = str.encode(::Encoding::UTF_8)
        end

        escaped.force_encoding(::Encoding::ASCII_8BIT)
        escaped.gsub!(regexp, STRING_ESCAPE_CHAR_MAP)
        escaped.force_encoding(::Encoding::UTF_8)

        buffer << '"'.freeze << escaped << '"'.freeze
      end

      def encode_hash(hash, buffer)
        buffer << '{'.freeze

        first = true

        hash.each_pair do |key, value|
          if first
            first = false
          else
            buffer << ','.freeze
          end

          if String === key
            encode_string(key, buffer)
          else
            encode_string(key.to_s, buffer)
          end

          buffer << ':'.freeze

          fetch_or_encode_value(value, buffer)
        end

        buffer << '}'.freeze
      end

      def encode_array(array, buffer)
        buffer << '['.freeze

        first = true

        array.each do |value|
          if first
            first = false
          else
            buffer << ','.freeze
          end

          fetch_or_encode_value(value, buffer)
        end

        buffer << ']'.freeze
      end
  end

  SharedEncoderInstance = Encoder.new

  class ActiveSupportAdapter # :nodoc:
    def initialize(options = nil)
      if options && !options.empty?
        @_encoder = ActiveSupport::JSON::Encoding::JSONGemEncoder.new(options)
      else
        @_encoder = SharedEncoderInstance
      end
    end

    def encode(value)
      @_encoder.encode(value)
    end
  end

  ActiveSupport::JSON::Encoding.json_encoder = ActiveSupportAdapter
end
