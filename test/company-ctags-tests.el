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

(require 'ert)
(require 'company-ctags nil t)

(defvar tags-file-content '("\014\nhello.js,124\n"
                            "function hello() {\177hello\0011,0\n"
                            "export class CHello {\177CHello\0013,21\n"
                            " hello() {\177hello\0014,43\n"
                            " test() {\177test\0016,59\n"
                            "  hi() {\177hi\0018,74\n"
                            "\014\ntest.js,29\n"
                            "function hello() {\177hello\0011,0\n"))

(defun tags-file-size ()
  (let* ((rlt 0))
    (dolist (s tags-file-content)
      (setq rlt (+ (length s) rlt)))
    rlt))

(defun create-tags-file (filepath)
  (with-temp-buffer
    (apply #'insert tags-file-content)
    ;; not empty
    (should (> (length (buffer-string)) 50))
    (write-region (point-min) (point-max) filepath)))

(defun get-full-path (filename)
  (concat
   (if load-file-name (file-name-directory load-file-name) default-directory)
   filename))

(ert-deftest company-ctags-test-load-tags-file ()
  ;; one hello function in test.js
  ;; one hello function, one hello method and one test method in hello.js
  (let* (cands
         (tags-file-name (get-full-path "TAGS"))
         file-info
         file-size
         dict)
    (create-tags-file tags-file-name)
    (should (file-exists-p tags-file-name))
    (setq company-ctags-tags-file-caches nil)
    (should (company-ctags-load-tags-file tags-file-name nil t t t))
    (should company-ctags-tags-file-caches)
    (delete-file tags-file-name) ; clean up
    (setq file-info (gethash tags-file-name company-ctags-tags-file-caches))
    (should file-info)
    ;; check the file meta data
    (should (eq (plist-get file-info :filesize) (tags-file-size)))
    (should (eq (length (plist-get file-info :raw-content)) (tags-file-size)))
    (setq dict (plist-get file-info :tagname-dict))
    (should dict)))

(ert-deftest company-ctags-test-completion ()
  (let* (cands
         (tags-file-name (get-full-path "TAGS"))
         file-info
         dict
         cands)
    (create-tags-file tags-file-name)
    (setq company-ctags-tags-file-caches nil)
    (should (company-ctags-load-tags-file tags-file-name nil t t t))
    (should company-ctags-tags-file-caches)
    (delete-file tags-file-name) ; clean up

    (setq file-info (gethash tags-file-name company-ctags-tags-file-caches))
    (setq dict (plist-get file-info :tagname-dict))
    ;; completion with prefix
    (setq cands (company-ctags-all-completions "C" dict))
    (should (eq (length cands) 1))
    (should (string= (car cands) "CHello"))
    (setq cands (company-ctags-all-completions "he" dict))
    (should (eq (length cands) 3))
    (setq cands (company-ctags-all-completions "test" dict))
    (should (eq (length cands) 1))
    (setq cands (company-ctags-all-completions "h" dict))
    (should (eq (length cands) 4))))

(ert-deftest company-ctags-test-diff ()
  (let* (cands
         (tags-file-name (get-full-path "TAGS"))
         file-info
         dict
         cands)

    ;; load initial tags file
    (create-tags-file tags-file-name)
    (setq company-ctags-tags-file-caches nil)
    (should (company-ctags-load-tags-file tags-file-name nil t t t))
    (should company-ctags-tags-file-caches)
    (delete-file tags-file-name) ; clean up

    (setq file-info (gethash tags-file-name company-ctags-tags-file-caches))
    (setq dict (plist-get file-info :tagname-dict))

    ;; completion with prefix
    (setq cands (company-ctags-all-completions "C" dict))
    (should (eq (length cands) 1))
    (should (string= (car cands) "CHello"))
    (setq cands (company-ctags-all-completions "he" dict))
    (should (eq (length cands) 3))
    (setq cands (company-ctags-all-completions "test" dict))
    (should (eq (length cands) 1))
    (setq cands (company-ctags-all-completions "h" dict))
    (should (eq (length cands) 4))

    ;; add more tags then load updated tags file using diff
    (when (executable-find diff-command)
      ;; diff is used when `company-ctags-tags-file-caches' is not empty
      (should company-ctags-tags-file-caches)
      ;; add new tags
      (setq file-info (gethash tags-file-name company-ctags-tags-file-caches))
      (setq dict (plist-get file-info :tagname-dict))
      (push "function hello() {\177hello\0011,0\n" tags-file-content)
      (push "function newtag() {\177newtag\0011,0\n" tags-file-content)
      (create-tags-file tags-file-name)
      (should (company-ctags-load-tags-file tags-file-name nil t nil t))
      (delete-file tags-file-name) ; clean up

      (setq file-info (gethash tags-file-name company-ctags-tags-file-caches))
      (setq dict (plist-get file-info :tagname-dict))
      (setq cands (company-ctags-all-completions "h" dict))
      (should (eq (length cands) 5))
      (setq cands (company-ctags-all-completions "he" dict))
      (should (eq (length cands) 4))
      (setq cands (company-ctags-all-completions "newtag" dict))
      (should (eq (length cands) 1)))))

(ert-run-tests-batch-and-exit)