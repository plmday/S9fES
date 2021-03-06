;;
;; Scheme 9 from Empty Space, real number arithmetics
;; By Nils M Holm, 2007-2010
;; Placed in the Public Domain
;;

(require-extension realnums)

; Some of these procedures redefine those in "s9.scm"

(define number? real?)

(define (expt x y)
  (letrec
    ((square
       (lambda (x) (* x x)))
     (expt2
       (lambda (x y)
         (cond ((zero? y) 1)
               ((even? y) (square (expt2 x (quotient y 2))))
               (else      (* x (square (expt2 x (quotient y 2)))))))))
    (cond ((negative? y)
            (/ (expt (exact->inexact x) (- y))))
          ((integer? y)
            (expt2 x y))
          (else
            (exp (* y (log x)))))))

(define (ceiling x)
  (- (floor (- x))))

(define (round x)
  (let ((x+ (+ 0.5 x)))
    (let ((rx (floor x+)))
      (if (and (odd? (inexact->exact rx))
               (= x+ rx))
          (- rx 1)
          rx))))

(define (truncate x)
  ((if (< x 0) ceiling floor) x))

; used by SIN, COS, ATAN, and EXP
(define (fact2 n m)
  (if (< n 2)
      m
      (let ((k (quotient n 2)))
        (* (fact2 k m)
           (fact2 (- n k) (+ m k))))))

(define exp
  (let ((fact2 fact2))
    (lambda (x)
      (letrec
        ((e-series
           (lambda (x y r last)
             (if (= r last)
                 r
                 (e-series x
                           (+ 1 y)
                           (+ r (/ (expt x y)
                                   (fact2 y 1)))
                           r)))))
    (if (>= x 2.0)
        (let ((e^x/2 (exp (/ x 2))))
          (* e^x/2 e^x/2))
        (+ 1 x (e-series x 2 0.0 1.0)))))))

(define (log x)
  (letrec
    ((l-series
       (lambda (x y r last lim)
         (cond ((and lim (zero? lim))
                 r)
               ((= r last)
                 (* 2 r))
               (else
                 (l-series x
                           (+ 2 y)
                           (+ r (/ (expt (/ (- x 1)
                                            (+ x 1))
                                         y)
                                   y))
                           r
                           (if lim (- lim 1) lim)))))))
    (cond ((negative? x)
            (/ 1.0 0))
          ((< 0.1 x 5)
            (l-series x 1 0.0 1.0 #f))
          (else
            (let ((approx (l-series x 1 0.0 1.0 5)))
              (let ((a (/ x (exp approx))))
                (+ approx (log a))))))))

; auxiliary definitions for SIN, COS, TAN, ATAN

(define pi 3.141592653589793238462643383279502884197169399375105820974944)
(define pi/4  (/ pi 4))
(define pi/2  (/ pi 2))
(define 3pi/4 (+ pi/2 pi/4))
(define 3pi/2 (+ pi pi/2))
(define 5pi/4 (+ pi pi/4))
(define 7pi/4 (+ pi 3pi/4))
(define 2pi   (+ pi pi))

(define ->circle
  (let ((2pi 2pi))
    (lambda (x)
      (let* ((x+ (abs x))
             (d  (* 2pi (floor (/ x+ 2pi))))
             (x+ (- x+ d)))
         (if (negative? x)
             (- 2pi x+)
             x+)))))

(define sine-series 
  (let ((fact2 fact2))
    (lambda (x y r add last)
      (if (= r last)
          r
          (sine-series x
                       (+ 2 y)
                       ((if add + -) r (/ (expt x y)
                                          (fact2 y 1)))
                       (not add)
                       r)))))

(define cos
  (let ((->circle    ->circle)
        (sine-series sine-series)
        (pi          pi)
        (pi/2        pi/2)
        (3pi/2       3pi/2)
        (2pi         2pi))
    (lambda (x)
      (let ((x (->circle x)))
        (cond ((= 0     x)       (if (inexact? x) 1.0 1))
              ((= pi/2  x)        0.0)
              ((= pi    x)       -1.0)
              ((= 3pi/2 x)        0.0)
              ((<= 0    x pi/2)  (sine-series    x         2 1.0 #f 0))
              ((<= pi/2 x pi)    (- (sine-series (- pi x)  2 1.0 #f 0)))
              ((<= pi   x 3pi/2) (- (sine-series (- x pi)  2 1.0 #f 0)))
              (else              (sine-series    (- 2pi x) 2 1.0 #f 0)))))))

(define sin
  (let ((->circle    ->circle)
        (sine-series sine-series)
        (pi          pi)
        (pi/2        pi/2)
        (3pi/2       3pi/2)
        (2pi         2pi))
    (lambda (x)
      (let ((x (->circle x)))
        (cond ((= 0     x) (if (inexact? x) 0.0 0))
              ((= pi/2  x)  1.0)
              ((= pi    x)  0.0)
              ((= 3pi/2 x) -1.0)
              (else (let ((z (cond ((<= 0    x  pi/2) x)
                                   ((<= pi/2 x  pi)   (- pi x))
                                   ((<= pi   x 3pi/2) (- x pi))
                                   (else              (- 2pi x)))))
                      (if (> x pi)
                          (- (sine-series z 3 z #f 0))
                          (sine-series z 3 z #f 0)))))))))

(define tan
  (let ((->circle ->circle)
        (pi       pi)
        (pi/4     pi/4)
        (3pi/4    3pi/4)
        (5pi/4    5pi/4)
        (7pi/4    7pi/4))
    (lambda (x)
      (let ((x (->circle x)))
        (cond ((or (= x 0)     (= x  pi))   (if (inexact? x) 0.0 0))
              ((or (= x  pi/4) (= x 5pi/4))  1.0)
              ((or (= x 3pi/4) (= x 7pi/4)) -1.0)
              (else                         (/ (sin x) (cos x))))))))

(define atan
  (let ((pi/2 pi/2))
    (letrec
      ((at-series
         (lambda (x y r last)
           (if (= r last)
               r
               (at-series x
                          (+ 1 y)
                          (+ r (* (/ (* (expt 2 (+ y y))
                                        (expt (fact2 y 1) 2))
                                     (fact2 (+ y y 1) 1))
                                  (/ (expt x (+ y y 1))
                                     (expt (+ 1 (* x x))
                                           (+ 1 y)))))
                          r)))))
      (lambda (x)
        (cond ((negative? x)
                (- (at-series (- x) 0.0 0 1)))
              ((> x 1)
                (- pi/2 (atan (/ x))))
              (else
                (at-series x 0.0 0 1)))))))

(define (asin x)
  (cond ((= 1 x)
          (* 2 (atan x)))
        ((negative? x)
          (- (asin (- x))))
        (else
          (atan (/ x (sqrt (- 1 (* x x))))))))

(define acos
  (let ((pi   pi)
        (pi/2 pi/2))
    (lambda (x)
      (cond ((= -1 x) pi)
            ((=  1 x) 0)
            (else (- pi/2 (asin x)))))))

(define (sqrt square)
  (letrec
    ((sqrt2
       (lambda (x last)
          (if (= last x)
              x
              (sqrt2 (/ (+ x (/ square x)) 2)
                     x)))))
    (if (negative? square)
        (error "sqrt: negative argument" square)
        (sqrt2 square 0))))

; Used by NUMBER->STRING and STRING->NUMBER
(define (number-of-digits n r)
    (if (zero? n)
        (if (zero? r) 1 r)
        (number-of-digits (quotient n 10) (+ 1 r))))

(define number->string
  (let ((number-of-digits number-of-digits))
    (lambda (n . radix)
      (letrec
        ((digits
           (list->vector
             (string->list "0123456789abcdefghijklmnopqrstuvwxyz")))
         (conv
           (lambda (n rdx res)
             (if (zero? n)
                 (if (null? res) '(#\0) res)
                 (conv (quotient n rdx)
                       rdx
                       (cons (vector-ref digits (remainder n rdx))
                             res)))))
         (conv-int
           (lambda (n rdx)
             (if (negative? n)
                 (list->string (cons #\- (conv (abs n) rdx '())))
                 (list->string (conv n rdx '())))))
         (conv-sci-real
           (lambda (m e)
             (let ((m-str (conv-int m 10))
                   (e-str (conv-int e 10))
                   (i     (if (negative? m) 2 1)))
               (let ((k (string-length m-str)))
                 (string-append (substring m-str 0 i)
                                "."
                                (if (= k i) "0" (substring m-str i k))
                                "e"
                                (if (>= e 0) "+" "")
                                e-str)))))
         (zeroes
           (lambda (n)
             (let loop ((n n)
                        (z '()))
               (if (positive? n)
                   (loop (- n 1) (cons #\0 z))
                   (list->string z)))))
         (conv-expanded-real
           (lambda (n expn digits)
             (let ((m      (abs n))
                   (offset (+ expn digits)))
               (string-append
                 (if (negative? n) "-" "")
                 (cond ((negative? offset) "0.")
                       ((zero? offset)     "0")
                       (else               ""))
                 (zeroes (- offset))
                 (let ((m-str (conv-int m 10)))
                   (if (<= 0 offset digits)
                       (string-append (substring m-str 0 offset)
                                      "."
                                      (substring m-str offset digits)
                                      (if (= offset digits) "0" ""))
                       m-str))
                 (if (> offset digits)
                     (string-append (zeroes (- offset digits)) ".0")
                     "")))))
         (conv-real
           (lambda (n)
             (let ((m (mantissa n))
                   (e (exponent n)))
               (let ((d (number-of-digits m 0)))
                 (if (< -4 (+ e d) 10)
                     (conv-expanded-real m e d)
                     (conv-sci-real m (+ e d -1)))))))
         (get-radix
           (lambda ()
             (cond ((null? radix) 10)
                   ((<= 2 (car radix) 36) (car radix))
                   (else (error "number->string: invalid radix"
                                (car radix)))))))
        (let ((r (get-radix)))
          (cond ((not (or (exact? n)
                          (= 10 r)))
                  (error "number->string: real number needs a radix of 10" n))
                ((exact? n)
                  (conv-int n r))
                (else
                  (conv-real n))))))))

(define string->number
  (let ((number-of-digits number-of-digits)
        (make-inexact #f)
        (make-exact   #f))
    (lambda (str . radix)
      (letrec
        ((digits
           (string->list "0123456789abcdefghijklmnopqrstuvwxyz"))
         (value-of-digit
           (lambda (x)
             (letrec
               ((v (lambda (x d n)
                     (cond ((null? d) 36)
                           ((char=? (car d) x) n)
                           (else (v x (cdr d) (+ n 1)))))))
               (v (char-downcase x) digits 0))))
         (exponent-mark
           (lambda (c)
             (memv c '(#\d #\D #\e #\E #\f #\F #\l #\L #\s #\S))))
         (make-result cons)
         (value       car)
         (rest        cdr)
         (FAILED      '(#f . #f))
         (failed? (lambda (res)
                    (eq? #f (cdr res))))
         (ok?     (lambda (res)
                    (not (eq? #f (cdr res)))))
         (conv3
           (lambda (lst val rdx)
             (if (null? lst)
                 (make-result val '())
                 (let ((dval (value-of-digit (car lst))))
                   (if (< dval rdx)
                       (conv3 (cdr lst)
                              (+ (value-of-digit (car lst))
                                 (* val rdx))
                              rdx)
                       (make-result val lst))))))
         (conv
           (lambda (lst rdx)
             (if (null? lst)
                 FAILED
                 (conv3 lst 0 rdx))))
         (conv-int
           (lambda (lst rdx)
             (cond ((null? lst)
                     FAILED)
                   ((char=? (car lst) #\+)
                     (conv (cdr lst) rdx))
                   ((char=? (car lst) #\-)
                     (let ((r (conv (cdr lst) rdx)))
                       (if (ok? r)
                           (make-result (- (value r)) (rest r))
                           FAILED)))
                   (else
                     (conv lst rdx)))))
         (make-frag
           (lambda (x)
             (let ((d (number-of-digits x -1)))  ; 123 --> 0.123
               (- (/ x (expt 10.0 d)) 1.0))))
         (make-real
           (lambda (int frag expn)
             (let ((v (* (+ 0.0 (abs int) (make-frag frag))
                         (expt 10.0 expn))))
               (if (negative? int) (- v) v))))
         (conv-exponent
           (lambda (int frag lst)
             (if (null? lst)
                 FAILED
                 (let ((exp-part (conv-int lst 10)))
                   (if (failed? exp-part)
                       FAILED
                       (make-result (make-real int frag (value exp-part))
                                    (rest exp-part)))))))
         (conv-decimals
           (lambda (int lst)
             (cond ((null? lst)
                     (make-result (exact->inexact int) '()))  ; trailing #\.
                   ((exponent-mark (car lst))
                     (conv-exponent int 10 (cdr lst)))
                   (else
                     (let ((frag-part (conv3 lst 1 10)))
                       (if (null? (rest frag-part))
                           (make-result (make-real int (value frag-part) 0)
                                        '())
                           (if (exponent-mark (car (rest frag-part)))
                               (conv-exponent int
                                              (value frag-part)
                                              (cdr (rest frag-part)))
                               FAILED)))))))
         (assert-radix-ten
           (lambda (rdx)
             (cond ((= 10 rdx))
                   ((null? radix) #f)
                   (else
                     (error (string-append "string->number: real number"
                                           " needs a radix of 10"))))))
         (mantissa?
           (lambda (x)
             (cond ((null? x)               #f)
                   ((char-numeric? (car x)) #t)
                   ((exponent-mark (car x)) #f)
                   (else (mantissa? (cdr x))))))
         (conv-real
           (lambda (lst rdx)
             (let ((int-part (conv-int lst rdx)))
               (cond ((failed? int-part)
                       FAILED)
                     ((and (zero? (value int-part))  ; "" or "e"
                           (not (mantissa? lst)))
                       FAILED)
                     ((null? (rest int-part))
                       int-part)
                     ((exponent-mark (car (rest int-part)))
                       (assert-radix-ten rdx)
                       (conv-exponent (value int-part)
                                      10
                                      (cdr (rest int-part))))
                     ((char=? #\. (car (rest int-part)))
                       (assert-radix-ten rdx)
                       (conv-decimals (value int-part)
                                      (cdr (rest int-part))))
                     (else
                       FAILED)))))
         (replace-inexact-digits!
           (lambda (a)
             (cond ((null? a))
                   ((char=? #\# (car a))
                     (set-car! a #\5)
                     (set! make-inexact #t)
                     (replace-inexact-digits! (cdr a)))
                   (else
                     (replace-inexact-digits! (cdr a))))))
         (get-radix
           (lambda ()
             (cond ((null? radix) 10)
                   ((<= 2 (car radix) 36) (car radix))
                   (else (error "string->number: invalid radix"
                                (car radix)))))))
        (set! make-inexact #f)
        (set! make-exact #f)
        (let ((radix   (get-radix))
              (lst     (string->list str)))
          (if (and (> (string-length str) 1)
                   (char=? #\# (car lst)))
              (let ((mod (cadr lst)))
                (set! lst (cddr lst))
                (cond ((char=? mod #\d))
                      ((char=? mod #\e) (set! make-exact #t))
                      ((char=? mod #\i) (set! make-inexact #t))
                      ((char=? mod #\b) (set! radix 2))
                      ((char=? mod #\o) (set! radix 8))
                      ((char=? mod #\x) (set! radix 16))
                      (else             (set! lst '())))))
          (if (or (null? lst)
                  (memv (car lst) '(#\+ #\- #\.))
                  (char-numeric? (car lst)))
              (replace-inexact-digits! lst))
          (let ((r (cond ((null? lst)
                           FAILED)
                         ((char=? #\- (car lst))
                           (conv-real (cdr lst) radix))
                         (else
                           (conv-real lst radix)))))
            (if (null? (rest r))
                (let ((v (if (char=? #\- (car lst))
                             (- (value r))
                             (value r))))
                  (cond (make-inexact
                          (exact->inexact v))
                        (make-exact
                          (if (integer? v)
                              (inexact->exact v)
                              #f))
                        (else
                          v)))
                #f)))))))

