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
         (file-size (nth 7 (file-attributes tags-file-name)))
         dict)
    (should (file-exists-p tags-file-name))
    (setq company-ctags-tags-file-caches nil)
    (should (company-ctags-load-tags-file tags-file-name nil t t t))
    (setq file-info (gethash tags-file-name company-ctags-tags-file-caches))
    (should file-info)
    ;; check the file meta data
    (should (eq (plist-get file-info :filesize) file-size))
    (should (eq (length (plist-get file-info :raw-content)) file-size))
    (setq dict (plist-get file-info :tagname-dict))
    (should dict)))

(ert-deftest company-ctags-test-completion ()
  (let* (cands
         (tags-file-name (get-full-path "TAGS"))
         file-info
         dict
         cands)
    (setq company-ctags-tags-file-caches nil)
    (should (company-ctags-load-tags-file tags-file-name nil t t t))
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

(ert-run-tests-batch-and-exit)
