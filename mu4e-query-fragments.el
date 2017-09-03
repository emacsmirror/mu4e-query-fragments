;;; mu4e-query-fragments.el --- mu4e query fragments extension  -*- lexical-binding: t -*-

;; Author: Yuri D'Elia <wavexx@thregr.org>
;; Version: 1.0
;; URL: https://github.com/wavexx/mu4e-query-fragments.el
;; Package-Requires: ((emacs "24.4") mu4e)
;; Keywords: mu4e, mail, convenience

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; `mu4e-query-fragments' allows to define query snippets ("fragments") that
;; can be used in regular `mu4e' searches or bookmars. Fragments can be used to
;; define complex filters to apply in existing searches, or supplant bookmarks
;; entirely. Fragments compose properly with regular mu4e/xapian operators, and
;; can be arbitrarily nested.
;;
;; To use `mu4e-query-fragments', use the following:
;;
;; (require 'mu4e-query-fragments)
;; (setq mu4e/qf-fragments
;;   '(("%junk" . "maildir:/Junk OR subject:SPAM")
;;     ("%hidden" . "flag:trashed OR %junk")))
;;
;; The terms %junk and %hidden can subsequently be used anywhere in mu4e. See
;; the documentation of `mu4e/qf-fragments' for more details.
;;
;; Fragments are *not* shown expanded in order to keep the modeline short. To
;; test an expansion, use `mu4e/qf-query-expand'.

;;; Code:

(require 'mu4e)

;;;###autoload
(defvar mu4e/qf-fragments nil
  "Define query fragments available in `mu4e' searches and bookmarks.
List of (FRAGMENT . EXPANSION), where FRAGMENT is the string to be substituted
and EXPANSION is the query string to be expanded.

FRAGMENT should be an unique text symbol that doesn't conflict with the regular
mu4e/xapian search syntax or previous fragments. EXPANSION is expanded
as (EXPANSION), composing properly with boolean operators and can contain
fragments in itself.

Example:

\(setq mu4e/qf-fragments
   '((\"%junk\" . \"maildir:/Junk OR subject:SPAM\")
     (\"%hidden\" . \"flag:trashed OR %junk\")))")

(defun mu4e/qf--expand-1 (frags str)
  (if (null frags) str
    (with-syntax-table (standard-syntax-table)
      (let ((case-fold-search nil))
	(replace-regexp-in-string
	 (regexp-opt (mapcar 'car frags) 'symbol)
	 (lambda (it) (cdr (assoc it frags)))
	 str t t)))))

;;;###autoload
(defun mu4e/qf-query-expand (query)
  "Expand fragments defined in `mu4e/qf-fragments' in QUERY."
  (let (tmp (frags (mapcar (lambda (entry)
			     (cons (car entry) (concat "(" (cdr entry) ")")))
			   mu4e/qf-fragments)))
    ;; expand recursively until nothing is substituted
    (while (not (string-equal
		 (setq tmp (mu4e/qf--expand-1 frags query))
		 query))
      (setq query tmp)))
  query)

(defun mu4e/qf--proc-find-query-expand (args)
  (let ((query (car args))
	(rest (cdr args)))
    (cons (mu4e/qf-query-expand query) rest)))

(advice-add 'mu4e~proc-find :filter-args 'mu4e/qf--proc-find-query-expand)

(provide 'mu4e-query-fragments)

;;; mu4e-query-fragments.el ends here