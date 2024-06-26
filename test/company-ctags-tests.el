;; company-ctags-tests.el --- unit tests for company-ctags -*- coding: utf-8 -*-

;; Author: Chen Bin <chenbin DOT sh AT gmail DOT com>

;;; License:

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'company-ctags nil t)

(defun get-full-path (filename)
  "Get full path of FILENAME."
  (concat
   (if load-file-name (file-name-directory load-file-name) default-directory)
   filename))

(defun company-ctags-test-load-tags-file-internal (file-name)
  "Run test by FILE-NAME of tags file."
  (let* (cands
         (tags-file-name (get-full-path file-name))
         file-info
         (file-size (nth 7 (file-attributes tags-file-name)))
         dict)
    (should (file-exists-p tags-file-name))
    (setq company-ctags-tags-file-caches nil)
    (should (company-ctags-load-tags-file tags-file-name nil t t))
    (setq file-info (gethash tags-file-name company-ctags-tags-file-caches))
    (should file-info)
    ;; check the file meta data
    (should (eq (plist-get file-info :filesize) file-size))
    (should (eq (length (plist-get file-info :raw-content)) file-size))
    (setq dict (plist-get file-info :tagname-dict))
    (should dict)))

(ert-deftest company-ctags-test-load-tags-file ()
  ;; one hello function in test.js
  ;; one hello function, one hello method and one test method in hello.js
  (company-ctags-test-load-tags-file-internal "TAGS")
  (company-ctags-test-load-tags-file-internal "tags"))

(defun company-ctags-test-completion-internal (file-name)
  "Run test by FILE-NAME of tags file."
  (let* (cands
         (tags-file-name (get-full-path file-name))
         file-info
         dict
         cands)
    (setq company-ctags-tags-file-caches nil)
    (should (company-ctags-load-tags-file tags-file-name nil t t))
    (should company-ctags-tags-file-caches)

    (setq file-info (gethash tags-file-name company-ctags-tags-file-caches))
    (setq dict (plist-get file-info :tagname-dict))
    ;; completion with prefix
    (setq cands (company-ctags-all-candidates "C" dict))
    (should (eq (length cands) 1))
    (should (string= (car cands) "CHello"))
    (setq cands (company-ctags-all-candidates "he" dict))
    (should (eq (length cands) 4))
    (setq cands (company-ctags-all-candidates "test" dict))
    (should (eq (length cands) 1))
    (setq cands (company-ctags-all-candidates "h" dict))
    (should (eq (length cands) 5))))

(ert-deftest company-ctags-test-completion ()
  (company-ctags-test-completion-internal "TAGS")
  (company-ctags-test-completion-internal "tags"))

(defun company-ctags-test-case-sensitive-and-partial-match-internal (file-name)
  "Run test by FILE-NAME of tags file."
  (let* (cands
         (tags-file-name (get-full-path file-name))
         file-info
         dict
         cands)
    ;; fill the cache
    (should (company-ctags-load-tags-file tags-file-name nil t t))
    (setq file-info (gethash tags-file-name company-ctags-tags-file-caches))
    (setq dict (plist-get file-info :tagname-dict))

    ;; case insensitive & fuzzy match
    (setq company-ctags-ignore-case t)
    (setq company-ctags-fuzzy-match-p t)
    (should (company-ctags-load-tags-file tags-file-name nil t t))
    (setq cands (company-ctags-all-candidates "hello" dict))
    (should (cl-find-if (lambda (e) (string= e "CHello")) cands))

    ;; case insensitive & no fuzzy match
    (setq company-ctags-ignore-case t)
    (setq company-ctags-fuzzy-match-p nil)
    (setq cands (company-ctags-all-candidates "hello" dict))
    ;; "CHello" should NOT be the candidate
    (should (not (cl-find-if (lambda (e) (string= e "CHello")) cands)))

    ;; case sensitive & fuzzy match
    (setq company-ctags-ignore-case nil)
    (setq company-ctags-fuzzy-match-p t)
    (setq cands (company-ctags-all-candidates "Hello" dict))
    ;; "hello" should NOT be the candidate
    (should (not (cl-find-if (lambda (e) (string= e "hello")) cands)))))

(ert-deftest company-ctags-test-case-sensitive-and-partial-match ()
  (company-ctags-test-case-sensitive-and-partial-match-internal "TAGS")
  (company-ctags-test-case-sensitive-and-partial-match-internal "tags"))

(ert-run-tests-batch-and-exit)
;;; company-ctags-tests.el ends here
