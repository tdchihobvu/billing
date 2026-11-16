# Answers DataTables server-side requests, so large tables load one page at a
# time while search and sort still cover every record.
module ServerSideTable
  extend ActiveSupport::Concern

  MAX_PAGE_SIZE = 100

  private

  # columns: one entry per table column. nil means not sortable or searchable,
  # a String is used for both, and a Hash can set :sort and :search separately.
  # The block receives each record and its row number, and returns the cells.
  def render_server_side_table(scope, columns:)
    columns = columns.map { |column| column.is_a?(String) ? text_column(column) : column }
    total = scope.count
    filtered = search_server_side_table(scope, columns)
    start = params[:start].to_i.clamp(0, nil)
    length = params[:length].to_i
    length = 25 unless length.between?(1, MAX_PAGE_SIZE)
    rows = order_server_side_table(filtered, columns).offset(start).limit(length).to_a

    render json: {
      draw: params[:draw].to_i,
      recordsTotal: total,
      recordsFiltered: filtered.count,
      data: rows.each_with_index.map { |record, index| yield(record, start + index + 1) }
    }
  end

  # Text sorts alphabetically, whatever its case or stray spaces.
  def text_column(sql)
    { sort: "LOWER(TRIM(CAST(#{sql} AS text)))", search: sql }
  end

  def search_server_side_table(scope, columns)
    term = params.dig(:search, :value).to_s.strip
    searchable = columns.compact.filter_map { |column| column[:search] }
    return scope if term.empty? || searchable.empty?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    scope.where(searchable.map { |sql| "CAST(#{sql} AS text) ILIKE :pattern" }.join(" OR "), pattern: pattern)
  end

  # The SQL comes only from the columns list, picked by position, so request
  # parameters never reach the ORDER BY text.
  def order_server_side_table(scope, columns)
    order = params.dig(:order, "0")
    column = order && columns[order[:column].to_i]
    tie_breaker = "#{scope.klass.table_name}.id DESC"
    return scope.order(Arel.sql(tie_breaker)) unless column && column[:sort]

    direction = order[:dir].to_s.casecmp("desc").zero? ? "DESC" : "ASC"
    scope.order(Arel.sql("#{column[:sort]} #{direction}, #{tie_breaker}"))
  end
end
