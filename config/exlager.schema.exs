[
  mappings: [
    "log.journal.level": [
      doc: """
      Choose the logging level for the journal backend.
      """,
      to: "lager.handlers",
      datatype: [enum: [:emerg, :alert, :crit, :error, :warning, :notive, :info, :debug, :false]],
      default: :false
    ],
    "log.console.level": [
      doc: """
      Choose the logging level for the console backend.
      """,
      to: "lager.handlers",
      datatype: [enum: [:info, :error, :false]],
      default: :info
    ],
    "log.gelf.level": [
      doc: """
      Choose the logging level for the graylog backend.
      """,
      to: "lager.handlers",
      datatype: [enum: [:emerg, :alert, :crit, :error, :warning, :notive, :info, :debug, :false]],
      default: :false
    ],
    "log.gelf.host": [
      doc: """
      Hostname of the graylog server to forward log messages to.
      """,
      to: "lager.handlers",
      datatype: :string,
      default: ""
    ],
    "log.gelf.port": [
      doc: """
      Port of the graylog server to forward log messages to.
      """,
      to: "lager.handlers",
      datatype: :integer,
      default: 0
    ],
    "log.file.error": [
      doc: """
      Specify the path to the error log for the file backend
      """,
      to: "lager.handlers",
      datatype: :char_list,
      default: 'false'
    ],
    "log.file.info": [
      doc: """
      Specify the path to the info log for the file backend
      """,
      to: "lager.handlers",
      datatype: :char_list,
      default: 'false'
    ],
    "log.file.crash": [
      doc: """
      Specify the path to the crash log for the file backend
      """,
      to: "lager.crash_log",
      datatype: :char_list,
      default: 'false'
    ]
  ],
  translations: [
    "log.journal.level": fn
      _mapping, false, acc ->
          (acc || [])
      _mapping, level, acc when level in [:emerg, :alert, :crit, :error, :warning, :notive, :info, :debug] ->
          (acc || []) ++ [lager_journald_backend: [level: level]]
      _, level, _ ->
        IO.puts("Unsupported journal logging level: #{level}")
        exit(1)
    end,
    "log.console.level": fn
      _mapping, false, acc ->
          (acc || [])
      _mapping, level, acc when level in [:info, :error] ->
          (acc || []) ++ [lager_console_backend: level]
      _, level, _ ->
        IO.puts("Unsupported console logging level: #{level}")
        exit(1)
    end,
    "log.gelf.level": fn
      _mapping, false, acc ->
          (acc || [])
      _mapping, level, acc when level in [:emerg, :alert, :crit, :error, :warning, :notive, :info, :debug] ->
        old_data = case acc[:lager_udp_backend] do
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
        Dict.put(acc || [], :lager_udp_backend, [:info,
                                                 {:level, level},
                                                 {:formatter, :lager_gelf_formatter},
                                                 {:formatter_config, [{:metadata, [{:service, "SERVICE NAME"}]}]}] ++ append_host ++ append_port)
      _, level, _ ->
        IO.puts("Unsupported journal logging level: #{level}")
        exit(1)
    end,
    "log.gelf.host": fn
      _mapping, "", acc -> acc
      _mapping, host, acc ->
        old_data = case acc[:lager_udp_backend] do
                     [:info | rest] -> rest
                     _ -> []
                   end
        append_level = case old_data[:level] do
                         nil -> []
                         val -> [level: val]
                       end
        append_port = case old_data[:port] do
                        nil -> []
                        val -> [port: val]
                      end
        Dict.put(acc || [], :lager_udp_backend, [:info,
                                                 {:host, host},
                                                 {:formatter, :lager_gelf_formatter},
                                                 {:formatter_config, [{:metadata, [{:service, "SERVICE NAME"}]}]}] ++ append_level ++ append_port)
    end,
    "log.gelf.port": fn
      _mapping, 0, acc -> acc
      _mapping, port, acc ->
        old_data = case acc[:lager_udp_backend] do
                     [:info | rest] -> rest
                     _ -> []
                   end
        append_level = case old_data[:level] do
                         nil -> []
                         val -> [level: val]
                       end
        append_host = case old_data[:host] do
                        nil -> []
                        val -> [host: val]
                      end
        Dict.put(acc || [], :lager_udp_backend, [:info,
                                                 {:port, port},
                                                 {:formatter, :lager_gelf_formatter},
                                                 {:formatter_config, [{:metadata, [{:service, "SERVICE NAME"}]}]}]  ++ append_level ++ append_host)
    end,
    "log.file.error": fn
      _, 'false', acc ->
        (acc || [])
      _, path, acc ->
        (acc || []) ++ [lager_file_backend: [file: path, level: :error]]
    end,
    "log.file.info": fn
      _, 'false', acc ->
        (acc || [])
      _, path, acc ->
        (acc || []) ++ [lager_file_backend: [file: path, level: :info]]
    end,
    "log.file.crash": fn
      _, 'false' -> :undefined
      _, path -> to_char_list(path)
    end
  ]
]
