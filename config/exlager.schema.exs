[
  mappings: [
    "log.console.level": [
      doc: """
      Choose the logging level for the console backend.
      """,
      to: "lager.handlers",
      datatype: [enum: [:info, :error]],
      default: :info
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
      Specify the path to the console log for the file backend
      """,
      to: "lager.handlers",
      datatype: :binary,
      default: "/var/log/console.log"
    ]
  ],

  translations: [
    "log.console.level": fn
      _mapping, level, nil when level in [:info, :error] ->
          [lager_console_backend: level]
      _mapping, level, acc when level in [:info, :error] ->
          acc ++ [lager_console_backend: level]
      _, level, _ ->
        IO.puts("Unsupported console logging level: #{level}")
        exit(1)
    end,
    "log.file.error": fn
      _, path, nil ->
        [lager_file_backend: [file: path, level: :error]]
      _, path, acc ->
        acc ++ [lager_file_backend: [file: path, level: :error]]
    end,
    "log.file.info": fn
      _, path, nil ->
        [lager_file_backend: [file: path, level: :info]]
      _, path, acc ->
        acc ++ [lager_file_backend: [file: path, level: :info]]
    end
  ]

]
