[
  mappings: [
    "log.journal.level": [
      doc: """
      Choose the logging level for the journal backend.
      """,
      to: "lager.handlers.journal.level",
      datatype: [enum: [:emerg, :alert, :crit, :error, :warning, :notive, :info, :debug, :false]],
      default: :false
    ],
    "log.console.level": [
      doc: """
      Choose the logging level for the console backend.
      """,
      to: "lager.handlers.console.level",
      datatype: [enum: [:info, :error, :false]],
      default: :info
    ],
    "log.gelf.level": [
      doc: """
      Choose the logging level for the graylog backend.
      """,
      to: "lager.handlers.gelf.level",
      datatype: [enum: [:emerg, :alert, :crit, :error, :warning, :notive, :info, :debug, :false]],
      default: :false
    ],
    "log.gelf.host": [
      doc: """
      Hostname of the graylog server to forward log messages to.
      """,
      to: "lager.handlers.gelf.host",
      datatype: :binary,
      default: ""
    ],
    "log.gelf.port": [
      doc: """
      Port of the graylog server to forward log messages to.
      """,
      to: "lager.handlers.gelf.port",
      datatype: :integer,
      default: 0
    ],
    "log.file.error": [
      doc: """
      Specify the path to the error log for the file backend
      """,
      to: "lager.handlers.file.error",
      datatype: :charlist,
      default: 'false'
    ],
    "log.file.info": [
      doc: """
      Specify the path to the info log for the file backend
      """,
      to: "lager.handlers.file.info",
      datatype: :charlist,
      default: 'false'
    ],
    "log.file.crash": [
      doc: """
      Specify the path to the crash log for the file backend
      """,
      to: "lager.crash_log",
      datatype: :charlist,
      default: 'false'
    ],
    "lager.handlers": [
      doc: """
      """,
      to: "lager.handlers",
      default: []
    ]
  ],
  transforms: [
    "lager.handlers": fn table ->
      lager = Conform.Conf.get(table, "lager")
      journal = case Conform.Conf.get(table, "lager.handlers.journal.level") do
                  [{_, level}] when is_atom(level) and level != false ->
                    if level in [:emerg, :alert, :crit, :error, :warning, :notive, :info, :debug] do
                      [lager_journald_backend: [level: level]]
                    else
                      IO.puts("Unsupported journal logging level: #{level}")
                      exit(1)
                    end
                  _ ->
                    []
                end
      console = case Conform.Conf.get(table, "lager.handlers.console.level") do
                  [{_, level}] when is_atom(level) and level != false ->
                    if level in [:info, :error] do
                      [lager_console_backend: level]
                    else
                      IO.puts("Unsupported console logging level: #{level}")
                      exit(1)
                    end
                  _ ->
                    []
                end
      gelf = case Conform.Conf.get(table, "lager.handlers.gelf.level") do
               [{_, level}] when is_atom(level) and level != false ->
                 if level in [:emerg, :alert, :crit, :error, :warning, :notive, :info, :debug] do
                   backends = case lager do
                                [] ->
                                  []
                                _ ->
                                  Keyword.get(lager, :handlers)
                              end
                   old_data = case backends[:lager_udp_backend] do
                                [:info | rest] -> rest
                                _ -> []
                              end
                   append_port = case old_data[:port] do
                                   nil -> []
                                   val -> [port: val]
                                 end
                   append_host = case old_data[:host] do
                                   nil -> []
                                   val -> [host: val]
                                 end

                   [lager_udp_backend: [:info, {:level, level}, {:formatter, :lager_gelf_formatter},
                                        {:formatter_config, [{:metadata, [{:service, "SERVICE NAME"}]}]}] ++ append_host ++ append_port]
                 else
                   IO.puts("Unsupported journal logging level: #{level}")
                   exit(1)
                 end
               _ ->
                 []
             end
      gelf_host = case Conform.Conf.get(table, "lager.handlers.gelf.host") do
                    [{_, ""}] ->
                      []
                    [{_, host}] ->
                      if gelf != [] do
                        [lager_udp_backend: data] = gelf
                        [lager_udp_backend: data ++ [{:host, host}]]
                      else
                        []
                      end
                  end
      gelf_port = case Conform.Conf.get(table, "lager.handlers.gelf.port") do
                    [{_, 0}] ->
                      []
                    [{_, port}] ->
                      if gelf_host != [] do
                        [lager_udp_backend: data] = gelf_host
                        [lager_udp_backend: data ++ [{:port, port}]]
                      else
                        []
                      end
                  end
      file_error = case Conform.Conf.get(table, "lager.handlers.file.error") do
                    [{_, 'false'}] ->
                       []
                    [{_, path}] ->
                       [lager_file_backend: [file: path |> to_char_list, level: :error]]
                   end
      file_info = case Conform.Conf.get(table, "lager.handlers.file.info") do
                    [{_, 'false'}] ->
                      []
                    [{_, path}] ->
                      [lager_file_backend: [file: path |> to_char_list, level: :info]]
                  end
      # Delete extra fields from the mappings, we no need in it
      # anymore. In other way we will see it in sys.config
      # TODO delete it with match
      :ets.delete(table, ['lager', 'handlers', 'file', 'info'])
      :ets.delete(table, ['lager', 'handlers', 'file', 'error'])
      :ets.delete(table, ['lager', 'handlers', 'gelf', 'host'])
      :ets.delete(table, ['lager', 'handlers', 'gelf', 'port'])
      :ets.delete(table, ['lager', 'handlers', 'gelf', 'level'])
      :ets.delete(table, ['lager', 'handlers', 'file', 'level'])
      :ets.delete(table, ['lager', 'handlers', 'journal', 'level'])
      journal ++ console ++ gelf_port ++ file_error ++ file_info
  end,
  "lager.crash_log": fn table ->
    crash_log = Conform.Conf.get(table, "lager.crash_log")
    [{_, opts}] = Conform.Conf.get(table, "lager.handlers")
    :ets.delete(table, ['lager', 'crash_log'])
    case crash_log do
      [] ->
        :undefined
      [{_, 'false'}] ->
        :undefined
      [{_, path}] ->
        path
    end
  end,
  ]
]
