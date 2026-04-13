$env.config = {
  show_banner: false

  completions: {
    algorithm: fuzzy
    case_sensitive: false
    quick: true
    partial: true
  }

  history: {
    max_size: 100_000
    sync_on_enter: true
    file_format: "sqlite"
    isolation: false
  }

  edit_mode: emacs

  table: {
    mode: rounded
    index_mode: auto
    trim: {
      methodology: wrapping
      wrapping_try_keep_words: true
    }
  }

  datetime_format: {
    normal: "%Y-%m-%d %H:%M:%S"
    table: "%Y-%m-%d"
  }
}
