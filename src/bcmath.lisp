(in-package :trubanc)

;; Arbitrary precision floating point math, ala PHP's bcmath package.

(defvar *bcmath-precision* 0)

(defun number-precision (number &optional remove-dot-p)
  "Return the number of digits after the decimal point in a numeric string.
   As a second value, return the position of the decimal point.
   If REMOVE-DOT-P is true, remove the string with the decimal point
   removed as the second argument, instead of its position."
  (let ((i (position #\. number)))
    (values
     (cond ((null i) 0)
           (t (- (length number) i 1)))
     (if remove-dot-p
         (if (null i) number (strcat (subseq number 0 i) (subseq number (1+ i))))
         i))))

(defun remove-decimal-part (number)
  "Remove the decimal point and to its right from a number, rounding as appropriate"
  (let ((pos (position #\. number)))
    (if (not pos)
        number
        (let ((res (subseq number 0 pos))
              (dec (if (> (length number) pos)
                       (char-code (aref number (1+ pos)))
                       0)))
          (if (>= dec #.(char-code #\5))
              (format nil "~d" (1+ (parse-integer res :radix 10)))
              res)))))

(defmacro with-bcmath-precision ((precision) &body body)
  `(let ((*bcmath-precision* ,precision))
     ,@body))

(defun bcshift-precision (x)
  "Shift a string or integer to the left *bcmath-precision* places.
   Truncate, and return an integer."
  (if (integerp x)
      (* x (expt 10 *bcmath-precision*))
      (multiple-value-bind (precision num) (number-precision x t)
        (let* ((diff (- *bcmath-precision* precision))
               (str (cond ((> diff 0)
                           (strcat num (make-string diff :initial-element #\0)))
                          ((< diff 0)
                           (subseq num 0 (+ (length num) diff)))
                          (t num))))
          (parse-integer str :radix 10)))))

(defun bcunshift-precision (x)
  "Shift a string or integer to the right *bcmath-precision* places.
   Return a string."
  (when (integerp x) (setq x (format nil "~d" x)))
  (if (eql *bcmath-precision* 0)
      x
      (let* ((diff (- (length x) *bcmath-precision*)))
        (if (> diff 0)
            (strcat (subseq x 0 diff) "." (subseq x diff))
            (strcat "0." (make-string (- diff) :initial-element #\0) x)))))

(defun bcadd (&rest numbers)
  (bcunshift-precision (apply '+ (mapcar 'bcshift-precision numbers))))

(defun bcsub (&rest numbers)
  (bcunshift-precision (apply '- (mapcar 'bcshift-precision numbers))))

(defun bcmul (&rest numbers)
  (let ((res (bcshift-precision (or (car numbers) 0))))
    (dolist (num (cdr numbers))
      ;; It's tempting to do all the multiplies, then all the shifts,
      ;; but PHP can't do that, and it gets pretty big.
      ;; Could optimize this by using an integer divide.
      (setq res (parse-integer
                 (remove-decimal-part
                  (bcunshift-precision
                   (* res (bcshift-precision num))))
                 :radix 10)))
    (bcunshift-precision res)))

(defun bcdiv (dividend &rest divisors)
  (let ((res (bcshift-precision dividend))
        (shifter (expt 10 *bcmath-precision*)))
    (dolist (num divisors)
      (setq res (/ (* res shifter) (bcshift-precision num))))
    (bcunshift-precision res)))

(defun bccomp (x y)
  (let ((diff (- (bcshift-precision x) (bcshift-precision y))))
    (cond ((< diff 0) -1)
          ((eql diff 0) 0)
          (t 1))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Copyright 2009 Bill St. Clair
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
