;;; mcrl2-mode.el --- Major mode for editing mCRL2. -*- lexical-binding: t -*-

;;; Commentary:

;; Version: 0.1

;; Emacs integration for mCRL2
;;
;; Inspired by:
;; - Erik Post's mCRL2 mode: https://github.com/epost/mcrl2-mode
;; - Robert Kornacki's mCRL2 Spacemacs Layer: https://github.com/robkorn/mCRL2-spacemacs-layer

(defun mcrl2-unindent ()
  "remove 2 spaces from beginning of of line"
  (interactive)
  (save-excursion
    (save-match-data
      (beginning-of-line)
      ;; get rid of tabs at beginning of line
      (when (looking-at "^\\s-+")
        (untabify (match-beginning 0) (match-end 0)))
      (when (looking-at "^  ")
        (replace-match "")))))

(setq mcrl2-font-lock-keywords
      (let* (
             (symbols-regex '";\\|:\\|\\.\\|,\\|=>\\|=\\|+\\|->\\|-\\|*\\|\|\\|!\\|#\\|\<\>\\|(\\|)\\|{\\|}\\|\\[\\|\\]\\|<\\|>\\|&&\\|&\\|\\\\")
             (x-keywords '("sort" "cons" "act" "proc" "init" "struct"
			   "sum" "eqn" "map" "var"
			   "in" "mu" "nu" "forall" "exists" "val" "end"
			   "delay" "yaled" "glob" "if"
			   "lambda" "mod" "div" "mu" "nu" "pbes" "whr"
			   "false" "delta" "nil" "tau" "true"))
             (x-types '("Bag" "Bool" "Nat" "Int" "Set" "List" "Real" "Pos"))
             (x-functions '("allow" "comm" "hide" "rename" "block"))

             (x-keywords-regexp (regexp-opt x-keywords 'symbols))
             (x-types-regexp (regexp-opt x-types 'symbols))
             (x-functions-regexp (regexp-opt x-functions 'symbols))
             )
        `(
          (,x-keywords-regexp . font-lock-keyword-face)
          (, (concat
              "\\(\\_<\\|[^_[:word:]]\\|\\)\\(true\\|false\\|lambda\\|min\\|max\\|succ\\|pred\\|div\\|mod\\|floor\\|ceil\\|abs\\|exp\\|round\\|Pos2Nat\\|Nat2Pos\\|Int2Nat\\|Real2Nat\\|tau\\|delta\\)\\("
              symbols-regex
              "\\|\\_>\\)") (2 font-lock-keyword-face))
          (,x-types-regexp . font-lock-type-face)
          (,x-functions-regexp . font-lock-function-name-face)
          (,symbols-regex . font-lock-constant-face)

          )))

(defconst mcrl2-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?% "< 1" table)
    (modify-syntax-entry ?\n "> " table)
    table))

(progn
  (setq mcrl2-mode-map (make-sparse-keymap))
  (define-key mcrl2-mode-map (kbd "C-c C-l") 'mcrl2-create-lps-reg)
  (define-key mcrl2-mode-map (kbd "C-c C-t") 'mcrl2-create-lts)
  (define-key mcrl2-mode-map (kbd "C-c C-g") 'mcrl2-lts-graph-current)
  (define-key mcrl2-mode-map (kbd "C-c C-s") 'mcrl2-lts-sim-current)
  (define-key mcrl2-mode-map (kbd "C-c C-i") 'mcrl2-repl-current)
  )

(progn
  (setq mcf-mode-map (make-sparse-keymap))
  (define-key mcf-mode-map (kbd "C-c C-p") 'mcf-create-lps-pbes)
  (define-key mcf-mode-map (kbd "C-c C-b") 'mcf-pbes-bool)
  (define-key mcf-mode-map (kbd "C-c C-s") 'mcf-pbes-solve)
  )

(define-derived-mode mcrl2-mode prog-mode "mCRL2 mode"
  "Major mode for editing mcrl2 and mcf files."
  
  :syntax-table mcrl2-mode-syntax-table

  (progn
    (setq-local font-lock-defaults '(mcrl2-font-lock-keywords))
    (setq-local comment-start "\%")
    (setq-local comment-end "")
    (setq major-mode 'mcrl2-mode)
    (setq mode-name "mCRL2")
    (use-local-map mcrl2-mode-map)
    (run-hooks 'mcrl2-mode-hook)
    (local-set-key (kbd "<backtab>") 'mcrl2-unindent)
    (setq-local tab-width 2)
    (setq-local mcrl2-output-buffer nil)))

(define-derived-mode mcf-mode prog-mode "mCRL2 mode"
  "Major mode for editing mcrl2 and mcf files."
  
  :syntax-table mcrl2-mode-syntax-table

  (progn
    (setq-local font-lock-defaults '(mcrl2-font-lock-keywords))
    (setq-local comment-start "\%")
    (setq-local comment-end "")
    (setq major-mode 'mcrl2-mode)
    (setq mode-name "mCRL2")
    (use-local-map mcf-mode-map)
    (run-hooks 'mcrl2-mode-hook)
    (local-set-key (kbd "<backtab>") 'mcrl2-unindent)
    (setq-local tab-width 2)
    (setq-local mcrl2-output-buffer nil)))

(provide 'mcrl2-mode)

(defun mcrl2-get-output-buffer ()
  (if mcrl2-output-buffer
      (if (buffer-name mcrl2-output-buffer)
          (if (process-live-p (get-buffer-process mcrl2-output-buffer))
              (progn
                (display-buffer-use-some-window mcrl2-output-buffer nil)
                (if (y-or-n-p "A process is running in the associated output buffer. Create new associated output buffer?")
                    (setq-local mcrl2-output-buffer (generate-new-buffer "*mCRL2 Output*"))
                  nil))
            mcrl2-output-buffer)
        (setq-local mcrl2-output-buffer (generate-new-buffer "*mCRL2 Output*")))
    (setq-local mcrl2-output-buffer (generate-new-buffer "*mCRL2 Output*"))))

(defun mcrl2-cmd (cmd)
  (let ((out (mcrl2-get-output-buffer)))
    (if out
        (async-shell-command cmd out)
      nil)))
        

(defun mcrl2-create-lps-reg (&optional set-line)
  (interactive)
  (mcrl2-cmd (concat "mcrl22lps -l regular "
                     (shell-quote-argument buffer-file-name)
                     " > "
                     (shell-quote-argument (concat buffer-file-name
                                                   ".lps")))))

(defun mcrl2-create-lps-reg2 (&optional set-line)
  (interactive)
  (mcrl2-cmd (concat "mcrl22lps -l regular2 "
                     (shell-quote-argument buffer-file-name) " > "
                     (shell-quote-argument (concat buffer-file-name ".lps")))))

(defun mcrl2-create-lps-stack (&optional set-line)
  (interactive)
  (mcrl2-cmd (concat "mcrl22lps -l stack "
                     (shell-quote-argument buffer-file-name) " > "
                     (shell-quote-argument (concat buffer-file-name ".lps")))))

 ;; LTS Creation Functions
(defun mcrl2-create-lts (&optional set-line)
  (interactive)
  (mcrl2-cmd (concat "lps2lts --verbose "
                     (shell-quote-argument (concat buffer-file-name ".lps"))
                     " "
                     (shell-quote-argument buffer-file-name) ".lts" )))

;; PBES Creation Functions
(defun mcf-create-lps-pbes (&optional set-line)
  (interactive)
  (mcrl2-cmd (concat "lps2pbes -c "
                     (read-file-name "Enter .lps file name:")
                     " -f " (shell-quote-argument buffer-file-name)
                     " " (shell-quote-argument (concat buffer-file-name ".pbes")) )))

(defun mcf-pbes-bool (&optional set-line)
  (interactive)
  (mcrl2-cmd (concat "pbes2bool --verbose "
                     (shell-quote-argument buffer-file-name) ".pbes")))

;; PBES Model Checking Functions
(defun mcf-pbes-solve (&optional set-line)
  (interactive)
  (mcrl2-cmd (concat "pbessolve -v --file="
                     (shell-quote-argument (expand-file-name (read-file-name "Enter .lps or .lts file name:")))
                     " "
                     (shell-quote-argument (concat buffer-file-name ".pbes")) )))

;; LTS Graph Functions
(defun mcrl2-lts-graph-current (&optional set-line)
  (interactive)
  (mcrl2-cmd (concat "ltsgraph " (shell-quote-argument buffer-file-name) ".lts")))

(defun mcrl2-lts-graph-evidence (&optional set-line)
  (interactive)
  (mcrl2-cmd (concat "ltsgraph "
                     (shell-quote-argument buffer-file-name)
                     ".pbes.evidence.lts")))

(defun mcrl2-lts-sim-current (&optional set-line)
  (interactive)
  (mcrl2-cmd (concat "lpssim "
                     (shell-quote-argument buffer-file-name)
                     ".lps")))

(defun mcrl2-repl-current (&optional set-line)
  (interactive)
  (mcrl2-cmd (concat "mcrl2i "
                     (shell-quote-argument buffer-file-name)
                     ".lps")))
;;; mcrl2-mode.el ends here
