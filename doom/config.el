;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq display-line-numbers-type 'relative
      doom-font (font-spec :family "FiraCode" :size 18)
      doom-theme 'doom-dracula
      doom-themes-treemacs-theme "doom-colors"
      doom-variable-pitch-font (font-spec :family "FiraCode" :size 18)
      lsp-enable-file-watchers nil
      lsp-haskell-formatting-provider "brittany"
      lsp-haskell-server-path "haskell-language-server"
      lsp-ui-doc-enable t
      mac-right-option-modifier nil
      ns-use-native-fullscreen t
      org-directory "~/org/"
      org-latex-pdf-process
        '("xelatex -shell-escape -interaction nonstopmode %f"
          "bibtex %b"
          "xelatex -shell-escape -interaction nonstopmode %f")
      ;; user-full-name "USERNAME"
      ;; user-mail-address "EMAIL"
      which-key-idle-delay 0.1
      zoom-size '(0.60 . 0.60)
      )

(global-display-fill-column-indicator-mode)

(map! "C-h" #'evil-window-left
      "C-j" #'evil-window-down
      "C-k" #'evil-window-up
      "C-l" #'evil-window-right
      )
