# One search rule for every search box: each word typed must appear in at least one of the
# given columns, in any order, ignoring capitals and extra spaces. So "kimmy store" finds
# "KIMMY BOTTLE STORE", "14760" finds that account, and "ZM0574" finds invoice ZM05741.
module TextSearch
  MAX_WORDS = 6

  def self.words(term)
    # %, _ and \ are searched for literally (sanitize_sql_like escapes them below).
    term.to_s.squish.split(" ").reject(&:blank?).first(MAX_WORDS)
  end

  # scope: the relation to filter; columns: SQL column names (already joined), e.g. %w[clients.name invoices.invoice_number]
  def self.apply(scope, term, columns)
    words(term).reduce(scope) do |relation, word|
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(word)}%"
      condition = columns.map { |c| "COALESCE(#{c}::text, '') ILIKE :w" }.join(" OR ")
      relation.where("(#{condition})", w: pattern)
    end
  end
end
