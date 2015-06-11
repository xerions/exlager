[
  mappings: [
    "log.journal.level": [
      doc: """
      Choose the logging level for the journal backend.
      """,
      to: "lager.handlers",
      datatype: [enum: [:emerg, :alert, :crit, :err, :warning, :notive, :info, :debug, :false]],
      default: :false
    ],
    "log.console.level": [
      doc: """
      Choose the logging level for the console backend.
      """,
      to: "lager.handlers",
      datatype: [enum: [:info, :error, :false]],
      default: :false
    ],
    "log.file.error": [
      doc: """
      Specify the path to the error log for the file backend
      """,
      to: "lager.handlers",
      datatype: :binary,
      default: "false"
    ],
    "log.file.info": [
      doc: """
      Specify the path to the info log for the file backend
      """,
      to: "lager.handlers",
      datatype: :binary,
      default: "false"
    ]
  ],
  translations: [
    "log.journal.level": fn
      _mapping, false, acc ->
          (acc || [])
      _mapping, level, acc when level in [:emerg, :alert, :crit, :err, :warning, :notive, :info, :debug] ->
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
    "log.file.error": fn
      _, "false", acc ->
        (acc || [])
      _, path, acc ->
        (acc || []) ++ [lager_file_backend: [file: path, level: :error]]
    end,
    "log.file.info": fn
      _, "false", acc ->
        (acc || [])
      _, path, acc ->
        (acc || []) ++ [lager_file_backend: [file: path, level: :info]]
    end
  ]
]
