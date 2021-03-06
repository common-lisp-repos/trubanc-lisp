; -*- mode: lisp -*-

(cl:defpackage #:trubanc-loader
    (:use #:cl :ccl)
  (:export #:add-to-registry
           #:loadsys
           #:load-swank
           #:*source-directory*))

(in-package #:trubanc-loader)

(defvar *source-directory*
  (make-pathname :name nil :type nil
                 :defaults (or *load-pathname* *default-pathname-defaults*))
  "The directory that holds the Trubanc source files, which is assumed
   to be the same directory that this file is being loaded from.")

(require "asdf")

(defun add-to-registry (&rest paths)
  (dolist (path paths)
    (pushnew (truename (merge-pathnames path *source-directory*))
             asdf:*central-registry*)))

(defun loadsys (system)
  (asdf:oos 'asdf:load-op system))

(let ((systems-wildcard
       (merge-pathnames
        (make-pathname :directory "systems" :name :wild :type :wild)
        *source-directory*)))
  (apply 'add-to-registry
         (directory systems-wildcard :directories t :files nil))
  (add-to-registry *source-directory*))

(defun load-swank (&optional port)
  (when (and port (integerp port))
    (loadsys :swank)
    (let ((sym (find-symbol "*DEFAULT-WORKER-THREAD-BINDINGS*" :swank)))
      (when (and sym (boundp sym) (listp (symbol-value sym)))
        (set sym (cons (cons '*package* (find-package :trubanc))
                       (symbol-value sym)))))
    (funcall (find-symbol "CREATE-SERVER" :swank) :port port :dont-close t)))

(when (member (ccl:getenv "LOADSWANK") '("YES" "yes" "true" "TRUE")
              :test #'equal)
  (pushnew :loadswank *features*))

;; Remove this to switch to the new all-lisp crypto code
(pushnew :openssl-cffi *features*)

(loadsys :trubanc)

(let ((port (ignore-errors (parse-integer (ccl:getenv "TRUBANC_PORT")))))
  (when port
    (trubanc:trubanc-web-server nil :port port)))


;; This is not in the :trubanc package def, so that people
;; who incorporate that system, instead of loading it from here,
;; won't need this file.
(use-package :trubanc-loader :trubanc)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Copyright 2009-2010 Bill St. Clair
;;;
;;; Licensed under the Apache License, Version 2.0 (the "License");
;;; you may not use this file except in compliance with the License.
;;; You may obtain a copy of the License at
;;;
;;;     http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or agreed to in writing, software
;;; distributed under the License is distributed on an "AS IS" BASIS,
;;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;; See the License for the specific language governing permissions
;;; and limitations under the License.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
