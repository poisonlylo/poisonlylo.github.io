# frozen_string_literal: true
#
# Lexer Rouge pour le SPL (Splunk Search Processing Language).
# Rouge n'en fournit pas nativement : ce plugin permet la coloration des blocs
# de code ```spl (ou ```splunk) dans les articles.
#
# Les plugins de `_plugins/` sont exécutés car le site est construit par
# GitHub Actions (et non par le build "safe" de GitHub Pages).

require "rouge"
require "set"

module Rouge
  module Lexers
    class SPL < RegexLexer
      title "SPL"
      desc "Splunk Search Processing Language"
      tag "spl"
      aliases "splunk"
      filenames "*.spl"

      def self.functions
        @functions ||= Set.new %w(
          abs avg case cidrmatch coalesce count dc distinct_count earliest
          earliest_time exact first floor if in isnotnull isnull isnum isstr
          json_extract last latest len like list lower ltrim match max md5
          median min mode mvappend mvcount mvdedup mvfilter mvindex mvjoin
          now null nullif per_day per_hour perc percentile range relative_time
          replace round rtrim searchmatch sha1 sha256 spath split sqrt stdev
          strftime strptime substr sum tonumber tostring trim typeof upper
          urldecode values var
        )
      end

      state :root do
        rule %r/\s+/, Text
        # Commentaires SPL : ``` ... ```
        rule %r/```.*?```/m, Comment::Multiline
        # Macros : `ma_macro(arg)`
        rule %r/`[^`\n]+`/, Name::Function::Magic
        rule %r/"(?:\\.|[^"\\])*"/, Str::Double
        rule %r/'(?:\\.|[^'\\])*'/, Str::Single
        # Le pipe introduit une commande
        rule %r/\|/, Punctuation, :command
        # Sous-recherches : [ search ... ] -> la 1re commande est mise en évidence
        rule %r/\[/, Punctuation, :command
        rule %r/[\](),]/, Punctuation
        rule %r/\b(?:AND|OR|NOT|XOR|BY|AS|OVER|IN|OUTPUT|OUTPUTNEW|WHERE|LIKE)\b/i, Operator::Word
        rule %r/\b(?:true|false|null)\b/i, Keyword::Constant
        # Modificateurs de temps : -24h@h, -7d, @d, now
        rule %r/[+-]?\d+(?:s|m|h|d|w|mon|q|y)(?:@\w+)?\b/, Literal::Date
        rule %r/@(?:s|m|h|d|w\d?|mon|q|y)\b/, Literal::Date
        rule %r/\d+\.\d+/, Num::Float
        rule %r/\d+/, Num::Integer
        # Champs internes / par défaut
        rule %r/\b(?:index|sourcetype|source|host|eventtype|tag|earliest|latest|_time|_raw|_indextime)\b/, Name::Builtin
        # Appel de fonction : nom(
        rule %r/[A-Za-z_][\w.]*(?=\()/ do |m|
          if self.class.functions.include?(m[0].downcase)
            token Name::Function
          else
            token Name
          end
        end
        # Nom de champ suivi d'un opérateur de comparaison / affectation
        rule %r/[A-Za-z_][\w.:{}\-]*(?=\s*(?:!=|==|<=|>=|=|<|>))/, Name::Attribute
        rule %r/!=|==|<=|>=|=|<|>|\+|-|\*|\/|%|\./, Operator
        rule %r/[A-Za-z_][\w.:{}\-]*/, Name
        rule %r/./, Text
      end

      state :command do
        rule %r/[ \t]+/, Text
        rule %r/\n\s*/, Text
        rule %r/[A-Za-z_]\w*/, Keyword, :pop!
        rule(//) { pop! }
      end
    end
  end
end
