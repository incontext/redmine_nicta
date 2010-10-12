require 'sqlite3'

module ExperimentsHelper
  def render_sqlite_graph(result_filename)
    db = SQLite3::Database.new(result_filename)
    db.results_as_hash = false
    tables = db.execute( "select name from sqlite_master where type = 'table'" ).flatten.find_all {|v| !(v =~ /^_/)}
    tables.map do |table|
      db.results_as_hash = false
      nodes = db.execute( "select distinct name from #{table} join _senders on oml_sender_id = _senders.id")
      nodes.map do |node|
        db.results_as_hash = true
        rows = db.execute( "select * from #{table} join _senders on oml_sender_id = _senders.id and name = '#{node}'")
        graph_rows = rows.map do |row|
          {}.tap do |hash|
            row.keys.each do |key|
              if !(key =~ /^oml/ || key =~ /id$/ || key.class == Fixnum) && row[key] =~ /^(-|\.|[0-9])+$/
                hash[key] = row[key]
              end
            end
            hash['oml_ts_server'] = row['oml_ts_server']
          end
        end
        build_dygraph(table, node, graph_rows) unless graph_rows.empty? || graph_rows.first.keys.size < 2
      end
    end.flatten.join("")
  end

  def build_dygraph(table, node, rows)
    "
    <hr />
    <p><b>Graph #{table} : #{node} </b></p>
    <div class=\"graph\" id=\"graph_#{table}_#{node}\" style=\"width: 550px; height: 350px;\"></div>
    <script type=\"text/javascript\">
      g_#{table}_#{node}= new Dygraph(
        document.getElementById(\"graph_#{table}_#{node}\"),
    " +
    "\"oml_ts_server,#{(rows.first.keys-['oml_ts_server']).join(',')}\\n\" + " +
    rows.map { |row| "\"#{([row['oml_ts_server']] + row.except('oml_ts_server').values).join(',')}\\n\"" }.join(' + ') +
      "
      );
      function data_#{table}_#{node}_change(el) {
        g_#{table}_#{node}.setVisibility(el.id, el.checked);
      }
    </script>
    <p>Display:
    " +
    (rows.first.keys-['oml_ts_server']).each_with_index.map do |key, index|
      "
      <input type=\"checkbox\" checked=\"\" onclick=\"data_#{table}_#{node}_change(this)\" id=\"#{index}\">
      <label for=\"#{index}\"> #{key} </label>
      "
    end.join("") +
    "
    </p>
    "
  end
end
