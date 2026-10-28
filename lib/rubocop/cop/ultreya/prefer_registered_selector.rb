require "rubocop"
require "digest"
require_relative "../../../../test/support/app_selectors"

module RuboCop
  module Cop
    module Ultreya
      class PreferRegisteredSelector < Base
        MSG = "Use the registered selector %<selectors>s instead of CSS for this application concept."
        RESTRICT_ON_SEND = %i[ within find all assert_selector assert_no_selector ].freeze

        def on_send(node)
          selector = css_argument(node)
          return unless selector

          replacements = AppSelectors.css_replacements.filter_map do |name, replacement|
            next unless replacement[:pattern].match?(selector.value)
            next unless replacement[:within].empty? || within_registered_scope?(node, replacement[:within])

            name
          end
          return if replacements.empty?

          add_offense(selector, message: format(MSG, selectors: replacements.map { |name| ":#{name}" }.join(", ")))
        end

        def external_dependency_checksum
          Digest::SHA256.hexdigest(AppSelectors.css_replacements.inspect)
        end

        private

        def css_argument(node)
          selector = node.first_argument
          selector = node.arguments[1] if selector&.sym_type? && selector.value == :css
          selector if selector&.str_type?
        end

        def within_registered_scope?(node, scopes)
          node.each_ancestor(:block).any? do |block|
            call = block.send_node
            next false unless call.method_name == :within

            selector = call.first_argument
            css = css_argument(call)
            (selector&.sym_type? && scopes.include?(selector.value)) ||
              (css && scopes.any? { |name| AppSelectors.css_replacements.dig(name, :pattern)&.match?(css.value) })
          end
        end
      end
    end
  end
end
