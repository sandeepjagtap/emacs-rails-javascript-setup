;;; sqlparser-mysql-complete.el --- completing tablename,column name for mysql.
;; -*- coding:utf-8 -*-

;; Copyright (C) 2011 孤峰独秀

;; Author: 孤峰独秀  jixiuf@gmail.com
;; Keywords: sql parse mysql
;; Filename: sqlparser-mysql-complete.el
;; Description:  completing tablename column for mysql when editing
;; Created: 2011年07月21日 星期四 20时03分40秒
;; Version: 0.1.0
;; URL:http://www.emacswiki.org/emacs/down/sqlparser-mysql-complete.el
;; https://github.com/jixiuf/sqlparser
;; screencast :http://screencast-repos.googlecode.com/files/emacs-sqlparse-mysql-complete.mkv.bz2
;; Compatibility: Test on Windows Xp ,and Linux
;;
;; Features that might be required by this library:
;; `anything'
;;
;; Features  that be required by this library
;; `mysql.el'
;; http://www.emacswiki.org/emacs/download/mysql.el
;;

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; it can parsing current sql sentence ,it is smart enough to choose to
;; completing table name or column name depending on your position.
;; 1 after keyword 'use'   :complete schema name
;; 2 after keyword 'select' 'set' 'where'    :complete  columnname.
;; 3 after keyword 'alter', 'from' 'update' 'desc'  'show' : complete tablename
;; 4 after keyword 'into' and and there isn't a
;; "\\(" between 'into' and current postion :complete tablename
;; 4.1 after keyword 'into' but there is a "(" between 'into' and current
;; position  :complete columnname
;; 5 after keyword 'values'  :complete nothing.
;;

;;; Installation:
;;
;; 1 it required mysql.el you should download and add it to you load-path.
;; http://www.emacswiki.org/emacs/download/mysql.el

;; 2 add sqlparser-mysql-complete.el to you load-path
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (eval-after-load 'sql
;;   '(progn
;;      (require 'sqlparser-mysql-complete)
;;      (defun sqlparser-setup-for-mysql()
;;        "initial some variable .some is defined in mysql.el.
;;         some is defined here."
;;        (interactive)
;;        (setq mysql-user "root")
;;        (setq mysql-password "root")
;;        (setq sqlparser-mysql-default-db-name "test")
;;        )
;;      (sqlparser-setup-for-mysql)
;;      (define-key sql-mode-map (quote [M-return]) 'anything-mysql-complete)
;;      (define-key sql-interactive-mode-map  (quote [M-return]) 'anything-mysql-complete)
;;      )
;;   )

;; if you don't want to use this function
;; you can call (sqlparser-setup-for-mysql-interactive)
;;
;; 3 define key bindings for complete .you have two choice .
;;  1). if you using anything.el  you can binding it like this .

;;      (define-key sql-mode-map (quote [M-return]) 'anything-mysql-complete)
;;      (define-key sql-interactive-mode-map  (quote [M-return]) 'anything-mysql-complete)

;;  2). use Emacs default completing system.
;;
;;      (define-key sql-mode-map (quote [M-return]) 'sqlparser-mysql-complete)
;;      (define-key sql-interactive-mode-map  (quote [M-return]) 'sqlparser-mysql-complete)
;;


;;; Commands:
;;
;; Below are complete command list:
;;
;;  `sqlparser-mysql-setup-interactive'
;;    populate some usful variables ,like user ,passwd,db.
;;  `sqlparser-mysql-complete'
;;    complete tablename or column name depending on current point
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `sqlparser-mysql-default-db-name'
;;    default conn to this db .
;;    default = sql-database

;;; Code:
;;;尚未完成，可能永远完不成。不幸已经完成。
(require 'sql)
(require 'mysql)
(require 'anything nil t)

(defgroup sqlparser nil
  "SQL-PARSE"
  :group 'tools
  )

(defcustom sqlparser-mysql-default-db-name sql-database
  "default conn to this db ."
  :group 'sqlparser
  :type 'string)


(defun sqlparser-mysql-setup-interactive()
  "populate some usful variables ,like user ,passwd,db. "
  (interactive)
  (setq mysql-user (read-string "(build conn for completing)mysql-user:(default:root)" "" nil mysql-user))
  (setq mysql-password  (read-passwd "(build conn for completing)mysql-passwd:(default:root)"  nil mysql-password))
  (setq sqlparser-mysql-default-db-name
        (read-string (format "(build conn for completing)mysql-db-name:(default:%s)"
                             sqlparser-mysql-default-db-name) "" nil
                             sqlparser-mysql-default-db-name))
  ;;    (setq sqlparser-mysql-conn (mysql-connect  mysql-user mysql-password sqlparser-mysql-default-db-name ))
  )



(when (featurep 'anything)
  (defvar anything-c-source-mysql-candidates nil)
  (defvar anything-c-source-mysql
    '((name . "SQL Object:")
      (init (lambda() (setq anything-c-source-mysql-candidates ( sqlparser-mysql-context-candidates))))
      (candidates . anything-c-source-mysql-candidates)
      (action . (("Complete" . (lambda(candidate) (backward-delete-char (length (sqlparser-word-before-point))) (insert candidate)))))))

  (defun anything-mysql-complete()
    "call `anything' to complete tablename and column name for mysql."
    (interactive)
    (let ((anything-execute-action-at-once-if-one t)
          (anything-quit-if-no-candidate
           (lambda () (message "complete failed."))))
      (anything '(anything-c-source-mysql)
                ;; Initialize input with current symbol
                (sqlparser-word-before-point)  nil nil))))


(defun sqlparser-mysql-complete()
  "complete tablename or column name depending on current point
position ."
  (interactive)
  (let ((prefix  (sqlparser-word-before-point) )
        (init-pos (point))
        last-mark)
    (insert (completing-read "complete:" (  sqlparser-mysql-context-candidates) nil t prefix ))
    (setq last-mark (point-marker))
    (goto-char init-pos)
    (backward-delete-char (length prefix))
    (goto-char (marker-position last-mark))
    ))

(defun  sqlparser-mysql-context-candidates()
  "it will decide to complete tablename or columnname depend on
  current position."
  (let ((context (sqlparser-parse))
        candidats)
    ;;  (print context)
    (cond
     ((string= "schema" context)
      (setq candidats (sqlparser-mysql-schemaname-candidates))
      )
     ((string= "table" context)
      (setq candidats (sqlparser-mysql-tablename-or-schemaname-candidates))
      )
     ((string= "column" context)
      (setq candidats (  sqlparser-mysql-column-candidates))
      )
     ((null context)
      )
     )
    candidats
    )
  )

;; (setq ac-ignore-case t)
;; (ac-define-source mysql-all
;;   '((candidates . ( sqlparser-mysql-context-candidates ))
;;     (cache)))
;; (define-key sql-mode-map "\C-o" 'ac-complete-mysql-all)

(defun sqlparser-mysql-tablename-or-schemaname-candidates ()
  "is used to complete tablenames ,but sometimes you may
type in `schema.tablename'. so schemaname is considered as
candidats"
  ;;-s means use TAB as separate char . -N means don't print column name.
  (let* (( mysql-options '("-s" "-N"))
         (prefix (sqlparser-get-prefix))
         (sub-prefix (split-string prefix "\\." nil))
         (sql )
         )
    (if (> (length sub-prefix) 1)
        (setq sql (format
                   "select table_name from information_schema.tables where table_schema='%s' and table_name like '%s%%'"
                   (car sub-prefix) (nth 1 sub-prefix)))
      (setq sql (format
                 "select concat( schema_name, '.') as tablename from information_schema.schemata where schema_name like '%s%%' union select table_name as tablename from information_schema.tables where table_schema='%s' and table_name like '%s%%'"
                 prefix
                 sqlparser-mysql-default-db-name
                 prefix
                 ))
      )
    (mapcar 'car (mysql-shell-query sql))
    )
  )


(defun sqlparser-mysql-schemaname-candidates ()
  "all schema-name in mysql database"
  ;;-s means use TAB as separate char . -N means don't print column name.
  (let (( mysql-options '("-s" "-N")))
    (mapcar 'car (mysql-shell-query "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA" ))))

(defun  sqlparser-mysql-column-candidates ()
  "column name candidates of table in current sql "
  (let* ((sql "select column_name from information_schema.columns where 1=0")
         (table-names (sqlparser-fetch-tablename-from-select-sql
                       (sqlparser-sql-sentence-at-point)))
         (prefix (sqlparser-get-prefix))
         (sub-prefix (split-string prefix "\\." nil))
         tablename tablenamelist schemaname )
    (print table-names)
    (if (> (length sub-prefix) 1);;alias.columnsname
        (progn
          (setq tablename (sqlparser-guess-table-name (car sub-prefix)))
          (setq tablenamelist (split-string tablename "[ \t\\.]" t))
          (if (= 1 (length tablenamelist)) ;;just tablename ,not dbname.tablename
              (progn
                (setq tablename (car tablenamelist))
                (setq schemaname nil)
                (setq sql (format "select column_name from information_schema.columns where table_name='%s' and column_name like '%s%%' "
                                  tablename (nth 1 sub-prefix))))
            (setq schemaname (car tablenamelist))
            (setq tablename (cadr tablenamelist))
            (setq sql (format "select column_name from information_schema.columns where table_schema ='%s' and  table_name='%s' and column_name like '%s%%'"
                              schemaname tablename (nth 1 sub-prefix)))
            ))
      (while (> (length table-names) 0)
        (setq tablename (pop table-names))
        (setq tablenamelist (split-string tablename "[ \t\\.]" t))
        (if (= 1 (length tablenamelist))
            (progn
              (setq tablename (car tablenamelist))
              (setq schemaname nil)
              (setq sql (format "%s union select column_name from information_schema.columns where table_name='%s' and column_name like '%s%%' " sql tablename prefix )))
          (setq tablename (cadr tablenamelist))
          (setq schemaname (car tablenamelist))
          (setq sql (format "%s union select column_name from information_schema.columns where table_name='%s' and table_schema='%s' and column_name like '%s%%' "
                            sql tablename schemaname prefix)))))
    (let (( mysql-options '("-s" "-N"))) ;;-s means use TAB as separate char . -N means don't print column name.
      (mapcar 'car (mysql-shell-query sql))
      )))

;; TEST :
;; (sqlparser-fetch-tablename-from-sql "select * from (select id from mysql.emp a , mysql.abc ad) ,abcd  as acd  where name=''")
;; (sqlparser-fetch-tablename-from-sql "update user set age=11 ")
;; (sqlparser-fetch-tablename-from-sql "alter  user add (tim datetime)")

(defun sqlparser-fetch-tablename-from-sql ( &optional sql1)
  "return a list of tablenames from a sql-sentence."
  (let ((sql (or sql1 (sqlparser-sql-sentence-at-point)))
        tablenames)
    (setq tablenames (sqlparser-fetch-tablename-from-select-sql sql))
    (unless tablenames
      (setq tablenames (append tablenames (list (sqlparser-fetch-tablename-from-insert-update-alter-sql sql)))))
    tablenames
    ))

(defun sqlparser-fetch-tablename-from-insert-update-alter-sql( &optional sql1)
  "fetch tablename ,or schema.tablename from a insert sentence or
update sentence or alter sentence."
  (let ((sql (or sql1 (sqlparser-sql-sentence-at-point)))
        tablename)
    (with-temp-buffer
      (insert sql)
      (goto-char (point-min))
      (when (search-forward-regexp "\\(\\binto\\|update\\|alter\\)[ \t]+\\([a-zA-Z0-9\\._]+\\)\\b" (point-max ) t)
        (setq tablename (match-string 2))
        )
      )))

(defun sqlparser-fetch-tablename-from-select-sql ( &optional sql1)
  "return a list of tablenames from a sql-sentence."
  (let* ((sql (or sql1 (sqlparser-sql-sentence-at-point)))
         (sql-stack (list sql)) ele pt result-stack tablename-stack )
    (while (> (length sql-stack) 0)
      (setq ele (pop sql-stack))
      (with-temp-buffer
        (insert ele)
        (goto-char (point-min))
        (while (search-forward-regexp "[ \t]*(" (point-max) t)
          (forward-char -1)
          (setq pt (point))
          (forward-sexp)
          (push (buffer-substring (1+ pt)  (1- (point))) sql-stack)
          (delete-region  pt (point))
          (insert "table "))
        (push (buffer-substring (point-min) (point-max))  result-stack)
        ))
    (while (> (length result-stack) 0)
      (setq ele (pop result-stack))
      (with-temp-buffer
        (insert ele)
        (goto-char (point-min))
        (when  (search-forward-regexp "[ \t]+from[ \t]+" (point-max) t)
          (delete-region (point-min) (point))
          (when (search-forward-regexp "[ \t]+where[ \t]+" (point-max) t)
            (backward-word)
            (delete-region (point) (point-max)))
          (goto-char (point-min))
          (while (search-forward-regexp "," (point-max) t)
            (push (buffer-substring 1 (1- (point))) tablename-stack)
            (delete-region  1 (point))
            )
          (push (buffer-substring (point-min) (point-max)) tablename-stack)
          )
        )
      )
    (while (> (length tablename-stack) 0)
      (setq ele (pop tablename-stack))
      (with-temp-buffer
        (insert ele)
        (goto-char (point-min))
        (replace-regexp "\n" " ")
        (goto-char (point-min))
        (replace-regexp "[ \t]+as[ \t]+" " ")
        (goto-char (point-min))
        (delete-horizontal-space)
        (goto-char (point-max))
        (delete-horizontal-space)

        (if (= 1  (count-matches  "[a-zA-Z0-9_\\. ]+" 1 (point-max)))
            (push (buffer-substring 1 (point-max)) result-stack)
          (goto-char 0)
          (when (search-forward-regexp "[a-zA-Z0-9_\\. ]+" (point-max) t )
            (push (match-string 0) result-stack)
            )
          )
        )
      )
    (delete "table " result-stack)
    result-stack
    ))

;; TEST :
;; (sqlparser-fetch-tablename-from-select-sql "select * from (select id from mysql.emp a , mysql.abc ad) ,abcd  as acd  where name=''")


(defun sqlparser-guess-table-name (alias &optional sql1)
  "find out the true table name depends on the alias.
suppose the sql is `select * from user u where u.age=11'
then the `u' is `alias' and `user' is the true table name."
  (let ((sql  (or sql1 (sqlparser-sql-sentence-at-point)))
        (regexp (concat  "\\([a-zA-Z0-9_\\.]+\\)[ \t]+\\(as[ \t]+\\)?" alias "[, \t\n\r]"))
        table-name)
    (if (and  sql (string-match regexp sql))
        (progn
          (setq table-name (match-string 1 sql))
          (if (string-equal "from" table-name) alias table-name))
      alias)
    ))
;; TEST :
;; (sqlparser-guess-table-name "a"   "select * from (select id from mysql.emp a , mysql.abc ad) ,abcd  as acd  where name=''")


;; (defun sql-mode-hook-fun()
;;   "change the `sentence-end'"
;;   (make-local-variable 'sentence-end)
;;   (make-local-variable 'sentence-end-without-space)
;;   (setq sentence-end nil)
;;   (setq sentence-end-without-space ";")

;;   )
;; (add-hook 'sql-mode-hook 'sql-mode-hook-fun)

(defun sqlparser-sql-sentence-at-point()
  "get current sql sentence. "
  (let* ((bounds (bounds-of-sql-at-point))
         (beg (car bounds))
         (end (cdr bounds)))
    (buffer-substring-no-properties  beg end)
    ))


(defun bounds-of-sql-at-point()
  "get start and end point of current sql."
  (let ((pt (point))begin end empty-line-p empty-line-p next-line-included tail-p)
    (when (and
           (looking-at "[ \t]*\\(\n\\|\\'\\)")
           (looking-back "[ \t]*;[ \t]*" (beginning-of-line))
           )
      (search-backward-regexp "[ \t]*;[ \t]*" (beginning-of-line) t)
      )
    (save-excursion
      (skip-chars-forward " \t\n\r")
      ;;(end-of-line)
      (re-search-backward ";[ \t\n\r]*\\|\\`\\|\n[\r\t ]*\n[^ \t]" nil t)
      (skip-syntax-forward "-")
      (setq begin (match-end 0)))
    (save-excursion
      (skip-chars-forward " \t\n\r")
      (re-search-forward "\n[\r\t ]*\n[^ \t]\\|\\'\\|[ \t\n\r]*;" nil t)
      (unless (zerop (length (match-string 0)))
        (backward-char 1))
      (skip-syntax-backward "-")
      (setq end   (match-beginning 0)))
    (goto-char pt)
    (cons begin end)
    )
  )
;; 1 after keyword 'use'   :complete schema name
;; 2 after keyword 'alter', 'from' 'update' 'desc'  'show' : complete tablename
;; 3 after keyword 'select' 'set' 'where'    :complete  columnname.
;; 4 after keyword 'into' and and there isn't a
;; "\\(" between 'into' and current postion :complete tablename
;; 4.1 after keyword 'into' but there is a "(" between 'into' and current
;; position  :complete columnname
;; 5 after keyword 'values'  :complete nothing.
(defun sqlparser-parse()
  "judge now need complete tablename or column name or don't complete .
it will return 'table' ,or 'column' ,or nil.
"
  (let* ((cur-pos (point))
         (sql-pos-info (bounds-of-sql-at-point))
         (sql-start-pos (car sql-pos-info ))
         (sql-end-pos (cdr sql-pos-info))
         map keyword returnVal)
    (when (search-backward-regexp "\\buse\\b" sql-start-pos t 1)
      (push   (list (- cur-pos (point)) "use") map))
    (when (search-backward-regexp "\\balter\\b" sql-start-pos t 1)
      (push   (list (- cur-pos (point)) "alter") map))
    (goto-char cur-pos)
    (when (search-backward-regexp "\\bfrom\\b" sql-start-pos t 1)
      (push   (list (- cur-pos (point)) "from") map))
    (when (search-backward-regexp "\\bshow\\b" sql-start-pos t 1)
      (push   (list (- cur-pos (point)) "show") map))
    (when (search-backward-regexp "\\bdesc\\b\\|\\bdescribe\\b" sql-start-pos t 1)
      (push   (list (- cur-pos (point)) "desc") map))
    (goto-char cur-pos)
    (when (search-backward-regexp "\\bupdate\\b" sql-start-pos t 1)
      (push   (list (- cur-pos (point)) "update") map))
    (goto-char cur-pos)
    (when (search-backward-regexp "\\bselect\\b" sql-start-pos t 1)
      (push   (list (- cur-pos (point)) "select") map))
    (goto-char cur-pos)
    (when (search-backward-regexp "\\bset\\b" sql-start-pos t 1)
      (push   (list (- cur-pos (point)) "set") map))
    (goto-char cur-pos)
    (when (search-backward-regexp "\\bwhere\\b" sql-start-pos t 1)
      (push   (list (- cur-pos (point)) "where") map))
    (goto-char cur-pos)
    (when (search-backward-regexp "\\bvalues\\b" sql-start-pos t 1)
      (push   (list (- cur-pos (point)) "values") map))
    (goto-char cur-pos)
    (when (search-backward-regexp "\\binto\\b" sql-start-pos t 1)
      (push   (list (- cur-pos (point)) "into") map))
    (goto-char cur-pos)
    (setq map   (sort map (lambda (a b ) (when (< (car a ) (car b)) t))))
    (setq keyword  (car (cdar map)))
    (cond
     ( (null keyword)
       (setq returnVal nil)
       )
     ((string= "into" keyword)
      (progn
        ;; '(' between "into" and current position
        (if (search-backward-regexp (regexp-quote "(") (- cur-pos  (caar map)) t 1)
            (setq returnVal "column")
          (setq returnVal "table")
          )
        )
      )
     ((string-match "use" keyword)
      (setq returnVal "schema")
      )
     ((string-match "from\\|alter\\|update\\|desc\\|describe\\|show" keyword)
      (setq returnVal "table")
      )
     ((string-match "select\\|set\\|where\\|" keyword)
      (setq returnVal "column")
      )
     ((string-match "values" keyword)
      (setq returnVal nil.)
      )
     (t
      (setq returnVal nil)
      )
     )
    (goto-char cur-pos)
    returnVal
    ))


(defun sqlparser-get-prefix()
  "for example `tablename.col' `table.' `str'"
  (let ((init-pos (point)) prefix)
    (when (search-backward-regexp "[ \t,(;]+" (point-min) t)
      (setq prefix (buffer-substring (match-end 0) init-pos)))
    (goto-char init-pos)
    (or prefix "")
    ))

(defun sqlparser-word-before-point()
  "get word before current point or empty string."
  (save-excursion
    (let ((current-pos (point)))
      (if (search-backward-regexp "\s-\\|[ \t]+\\|\\.\\|," (point-at-bol) t )
          (buffer-substring-no-properties (match-end 0) current-pos )
        ""))))


(provide 'sqlparser-mysql-complete)
;;; sqlparser-mysql-complete.el ends here
