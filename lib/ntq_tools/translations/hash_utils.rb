module NtqTools
  module Translations
    module HashUtils
      def dig_set(obj, keys, value)
        key = keys.first
        if keys.length == 1
          obj[key] = value
        else
          obj[key] = {} unless obj[key]
          dig_set(obj[key], keys.slice(1..-1), value)
        end
      end
    end
  end
end