# Redmine - project management software
# Copyright (C) 2006-2014  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'diff'

module Redmine
  module Helpers
    class Diff
      include ERB::Util
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::TextHelper
      attr_reader :diff, :words

      def initialize_with_redactor(content_to, content_from)
        @words = sanitize(content_to.to_s, tags: ["br"]).split(/(\s+)/)
        @words = @words.select {|word| word != ' '}
        words_from = sanitize(content_from.to_s, tags: ["br"]).split(/(\s+)/)
        words_from = words_from.select {|word| word != ' '}
        @diff = words_from.diff @words
      end

      alias_method_chain :initialize, :redactor

      def to_html_with_redactor
        words = self.words
        # p words
        # begin
        #   words = words.map { |e|
        #     r = e.gsub("<br>", /\n|\r/)
        #     r = r.gsub(/<.*?>/, '').strip
        #     r.empty? ? "" : r
        #   }
        # rescue
        #   words = self.words
        # end
        # p words
        words = words.collect{|word| h(word)}
        words_add = 0
        words_del = 0
        dels = 0
        del_off = 0
        diff.diffs.each do |diff|
          add_at = nil
          add_to = nil
          del_at = nil
          deleted = ""
          diff.each do |change|
            pos = change[1]
            if change[0] == "+"
              add_at = pos + dels unless add_at
              add_to = pos + dels
              words_add += 1
            else
              del_at = pos unless del_at
              deleted << ' ' unless deleted.empty?
              deleted << h(change[2])
              words_del  += 1
            end
          end
          if add_at
            words[add_at] = '<span class="diff_in">'.html_safe + words[add_at].gsub("&lt;", "<").gsub("&gt;", ">")
            words[add_to] = words[add_to]+ '</span>'.html_safe
          end
          if del_at
            words.insert del_at - del_off + dels + words_add, '<span class="diff_out">'.html_safe + deleted.gsub("&lt;", "<").gsub("&gt;", ">") + '</span>'.html_safe
            dels += 1
            del_off += words_del
            words_del = 0
          end
        end
        p words
        words.join(' ').html_safe
      end
      alias_method_chain :to_html, :redactor
    end
  end
end
