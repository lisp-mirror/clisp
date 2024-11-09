;; -*- Lisp -*- vim:filetype=lisp
;; some tests for SYSCALLS
;; ./clisp -E 1:1 -q -norc -i ../tests/tests -x '(run-test "../modules/syscalls/test" :logname "syscalls/test")'

(null (require "syscalls")) T
(listp (show (multiple-value-list (ext:module-info "syscalls" t)) :pretty t)) T

(os:hostent-p (show (os:resolve-host-ipaddr "localhost")))
T

(listp (show (os:resolve-host-ipaddr) :pretty t)) T
(os:service-p (show (os:service "smtp"))) T
(os:service-p (show (os:service 25))) T
(> (length (show (os:service) :pretty t)) (length (os:service nil "tcp"))) T
(equalp (os:service "www" "tcp") (os:service "http" "tcp")) T

;; same as "%F %T" on GNU, but more portable
(let* ((fmt "%Y-%m-%d %H:%M:%S") (string (show (os:string-time fmt))))
  (string= string (os:string-time fmt (show (os:string-time fmt string)))))
T

(defmacro with-C-time (&body body)
  "Set LC_TIME to \"C\" during body, restoring the previously set value
afterwards."
  (let ((original-locale-name (gensym)))
    `(let ((,original-locale-name (i18n:set-locale :TIME)))
       (unwind-protect
            (progn (i18n:set-locale :TIME "C")
                   ,@body)
         (i18n:set-locale :TIME ,original-locale-name)))))
WITH-C-TIME

;; for this to work, datum must specify _all_ fields in struct tm
(defun check-time-date (fmt datum)
  (and (fboundp 'os:getdate)
       (with-C-time
           (let ((gd (os:getdate datum))
                 (st (os:string-time fmt datum)))
             (show (list fmt datum gd (os:string-time "%Y-%m-%d %a %H:%M:%S" gd)))
             (unless (= gd st)
               (show (list st (os:string-time "%Y-%m-%d %a %H:%M:%S" st))))))))
CHECK-TIME-DATE

(check-time-date "%m/%d/%y %I %p" "10/1/87 4 PM") NIL
(check-time-date "%A %B %d, %Y, %H:%M:%S" "Friday September 18, 1987, 10:30:30") NIL
(check-time-date "%d,%m,%Y %H:%M" "24,9,1986 10:30") NIL

(defun check-time-date (fmt datum)
  (declare (ignore fmt))
  (and (fboundp 'os:getdate)
       (null (show (with-C-time
                       (os:string-time "%Y-%m-%d %a %H:%M:%S"
                                       (os:getdate datum)))))))
CHECK-TIME-DATE

(check-time-date "%m/%d/%y" "11/27/86") NIL
(check-time-date "%d.%m.%y" "27.11.86") NIL
(check-time-date "%y-%m-%d" "86-11-27") NIL
(check-time-date "%A %H:%M:%S" "Friday 12:00:00") NIL
(check-time-date "%A" "Friday") NIL
(check-time-date "%a" "Mon") NIL
(check-time-date "%a" "Sun") NIL
(check-time-date "%a" "Fri") NIL
(check-time-date "%B" "September") NIL
(check-time-date "%B" "January") NIL
(check-time-date "%B" "December") NIL
(check-time-date "%b %a" "Sep Mon") NIL
(check-time-date "%b %a" "Jan Fri") NIL
(check-time-date "%b %a" "Dec Mon") NIL
(check-time-date "%b %a %Y" "Jan Wed 1989") NIL
(check-time-date "%a %H" "Fri 9") NIL
(check-time-date "%b %H:%S" "Feb 10:30") NIL
(check-time-date "%H:%M" "10:30") NIL
(check-time-date "%H:%M" "13:30") NIL

#+unix
(when (fboundp 'os:getutxent)
  (show (loop :for utmpx = (os:getutxent) :while utmpx
          :count (show utmpx :pretty t)))
  (os:endutxent))               ; close the FD!
#+unix NIL

(defparameter *tmp1* (os:mkstemp "syscalls-tests-")) *tmp1*
(defparameter *tmp2* (os:mkstemp "syscalls-tests-")) *tmp2*

(let ((*standard-output* (make-broadcast-stream
                          *standard-output* *tmp1* *tmp2*)))
  (show (write *tmp1* :stream *tmp1*)) (terpri *tmp1*)
  (show (write *tmp2* :stream *tmp2*)) (terpri *tmp2*)
  T)
T

#+unix (find :rdwr (show (os:stream-options *tmp1* :fl))) #+unix :RDWR
#+unix (ext:appease-cerrors
        (with-open-file (s *tmp1*)
          (find :rdonly (show (os:stream-options s :fl)))))
#+unix :RDONLY
#+unix (os:stream-options *tmp1* :fd) NIL
#+unix (os:stream-options *tmp1* :fd '(:cloexec)) NIL
#+unix (os:stream-options *tmp1* :fd) #+unix (:cloexec)
#+unix (os:stream-options *tmp1* :fd nil) NIL
#+unix (os:stream-options *tmp1* :fd) NIL

;; may fail with ENOLCK or EOPNOTSUPP - in which case we do not test locking
(handler-case (os:stream-lock *tmp1* t)
  (system::simple-file-error (err)
    (format t "~S: ~A" 'os:stream-lock err)
    (pushnew :no-stream-lock *features*)
    T))
T
#-:no-stream-lock (os:stream-lock *tmp1* nil) #-:no-stream-lock NIL

(typep (show (os:priority (os:process-id))) '(or keyword (integer -20 20))) T

;; we are testing CLISP, not the accuracy of the underlying libc implementation
;; so we will be as lenient as necessary to ensure success
;; if FLOAT= fails, just replace it with FLOAT~
(defun float= (x y) (= y (/ (+ x y) 2))) FLOAT=
(defun float~ (x y)
  (< (abs (/ (- x y) (+ x y) 1/2)) #.(sqrt double-float-epsilon)))
FLOAT~

(float= (os:erf -6)     -1.0d0)  T
(float= (os:erf -5)     -0.9999999999984626d0)  T
(float= (os:erf -4)     -0.9999999845827421d0)  T
(float~ (os:erf -3)     -0.9999779095030014d0)  T ; MacOSX 10.4.11
(float= (os:erf -2)     -0.9953222650189527d0)  T
(float~ (os:erf -1)     -0.8427007929497149d0)  T ; MacOSX 10.4.11
(float= (os:erf 0)      0.0d0)  T
(float~ (os:erf 1)      0.8427007929497149d0)  T ; MacOSX 10.4.11
(float= (os:erf 2)      0.9953222650189527d0)  T
(float~ (os:erf 3)      0.9999779095030014d0)  T ; MacOSX 10.4.11
(float= (os:erf 4)      0.9999999845827421d0)  T
(float= (os:erf 5)      0.9999999999984626d0)  T
(float= (os:erf 6)      1.0d0)  T

(float= (os:erfc -6)    2.0d0)  T
(float= (os:erfc -5)    1.9999999999984626d0)  T
(float= (os:erfc -4)    1.999999984582742d0)  T
(float= (os:erfc -3)    1.9999779095030015d0)  T
(float= (os:erfc -2)    1.9953222650189528d0)  T
(float= (os:erfc -1)    1.842700792949715d0)  T
(float= (os:erfc 0)     1.0d0)  T
(float~ (os:erfc 1)     0.15729920705028513d0)  T ; MacOSX 10.4.11
(float= (os:erfc 2)     0.004677734981047265d0)  T
(float= (os:erfc 3)     2.209049699858544d-5)  T
(float= (os:erfc 4)     1.541725790028002d-8)  T
(float= (os:erfc 5)     1.5374597944280351d-12)  T
(float~ (os:erfc 6)     2.1519736712498916d-17)  T ; MacOSX 10.4.11
(float~ (os:erfc 7)     4.183825607779414d-23)  T  ; MacOSX 10.4.11
(float= (os:erfc 8)     1.1224297172982928d-29)  T
(float= (os:erfc 9)     4.13703174651381d-37)  T
(float= (os:erfc 10)    2.088487583762545d-45)  T
(float~ (os:erfc 11)    1.4408661379436945d-54)  T ; Cygwin 2.9.0
(float= (os:erfc 12)    1.3562611692059042d-64)  T
(float= (os:erfc 13)    1.7395573154667246d-75)  T
(float= (os:erfc 14)    3.037229847750312d-87)  T
(float~ (os:erfc 15)    7.212994172451206d-100)  T ; MacOSX 10.4.11
(float= (os:erfc 16)    2.3284857515715308d-113)  T
(float= (os:erfc 17)    1.0212280150942608d-127)  T
(float~ (os:erfc 18)    6.082369231816399d-143)  T ; MacOSX 10.4.11
(float= (os:erfc 19)    4.917722839256475d-159)  T
(float= (os:erfc 20)    5.3958656116079005d-176)  T
(float= (os:erfc 21)    8.032453871022456d-194)  T
(float= (os:erfc 22)    1.6219058609334726d-212)  T
(float= (os:erfc 23)    4.441265948088057d-232)  T
(float= (os:erfc 24)    1.6489825831519335d-252)  T
;; NetBSD https://sourceforge.net/p/clisp/mailman/message/21248044/
(float~ (os:erfc 25)    8.300172571196522d-274)  T
(float~ (os:erfc 26)    5.663192408856143d-296)  T
(float= (os:erfc 30)    0.0d0)  T

(loop :for i :from -10 :to 10
  :for e = (os:erf i) :and c = (os:erfc i)
  :for s = (+ e c)
  :unless (float= s 1) :collect (list i e c (- 1 s)))
()

(float= (os:j0 0)       1.0d0)  T
(float= (os:j0 1.0)     0.7651976865579666d0)  T
(float= (os:j1 0)       0.0d0)  T
(float= (os:j1 1.0)     0.4400505857449335d0)  T
(float= (os:jN 0 0)     1.0d0)  T
(float= (os:jN 1 1.0)   0.4400505857449335d0)     T
(float= (os:jN 2 1.0)   0.11490348493190048d0)    T
(float= (os:jN 2 1)     0.11490348493190048d0)    T
(float= (os:jN 2 0)     0.0d0)  T
(float~ (os:y0 1.0)     0.08825696421567696d0)    T
(float~ (os:y0 10.0)    0.055671167283599395d0)   T
(float~ (os:y1 1.0)     -0.7812128213002887d0)    T
(float~ (os:y1 10.0)    0.24901542420695383d0)    T
(float~ (os:yN 2 1.0)   -1.6506826068162543d0)    T
(float~ (os:yN 2 10.0)  -0.005868082442208629d0)  T
;; neither signgam not lgamma_r are defined on win32
(multiple-value-list (os:lgamma 2))   (0.0d0 #+win32 nil #-win32 1)
(mapcar (lambda (n)
          (multiple-value-bind (lg s) (os:lgamma n)
            (list n (float (/ (! (1- n)) (exp lg)) 0f0) s)))
        '(3 5 10 15 30 50 100))
((3 1f0 #+win32 nil #-win32 1) (5 1f0 #+win32 nil #-win32 1)
 (10 1f0 #+win32 nil #-win32 1) (15 1f0 #+win32 nil #-win32 1)
 (30 1f0 #+win32 nil #-win32 1) (50 1f0 #+win32 nil #-win32 1)
 (100 1f0 #+win32 nil #-win32 1))

(loop :for n :upfrom 3 :for lg = (os:lgamma n)
  :unless (= 1 (/ (log (! (1- n))) lg)) :return n)
29                    ; not bad...

(loop :for n :upfrom 3
  :for lg = (handler-case (os:lgamma n)
              (floating-point-overflow () 'floating-point-overflow))
  :for l! = (handler-case (log (float (! (1- n)) lg))
              (floating-point-overflow () 'floating-point-overflow))
  :unless (and (floatp lg) (floatp l!) (= 1 (float (/ l! lg) 0f0)))
  ;; round off at single precision: different gamma implementations have
  ;; very different levels of accuracy
  ;; https://sourceforge.net/p/clisp/mailman/message/20367574/
  :return (list n (float lg 0f0) l!))
(172 711.7147f0 FLOATING-POINT-OVERFLOW)

;; tgamma has widely varying accuracy on different platforms:
;; solaris 8: 4
;; glibc: 5
;; win32: 34
;; solaris 10: (172 FLOATING-POINT-OVERFLOW)
(loop :for n :upfrom 3
  :for tg = (handler-case (os:tgamma n)
              (floating-point-overflow () 'floating-point-overflow))
  :while (and (floatp tg) (= 1 (/ (! (1- n)) tg)))
  :finally (show (list n tg)))
NIL

(loop :for n :upfrom 3
  :for tg = (handler-case (os:tgamma n)
              (floating-point-overflow () 'floating-point-overflow))
  :unless (and (floatp tg) (= 1 (float (/ (! (1- n)) tg) 0f0)))
  :return (list n tg))
(172 FLOATING-POINT-OVERFLOW) ; ... but it IS accurate at single precision!

#+unix (= (show (os:process-id)) (show (os:getppid))) #+unix NIL
#+unix (let ((id (show (os:uid)))) (= id (setf (os:uid) id))) T
#+unix (let ((id (show (os:gid)))) (= id (setf (os:gid) id))) T
#+unix (let ((id (show (os:euid)))) (= id (setf (os:euid) id))) T
#+unix (let ((id (show (os:egid)))) (= id (setf (os:egid) id))) T
#+unix (let* ((pid (os:process-id))
              (gid (show (os:pgid pid))))
         (check-os-error (= gid (setf (os:pgid pid) gid))
                         (:eperm 1))) #+unix T
#+unix (= (os:uid) (os:euid)) T
#+unix (= (os:gid) (os:egid)) T
#+unix (multiple-value-list (os:setreuid (os:uid) (os:euid))) NIL
#+unix (multiple-value-list (os:setregid (os:gid) (os:egid))) NIL
#+unix (multiple-value-list (os:setreuid -1 -1)) NIL
#+unix (multiple-value-list (os:setregid -1 -1)) NIL
#+unix (listp (show (if (fboundp 'os:groups) (os:groups)
                        '(no os:groups)) :pretty t)) T
#+unix (if (and (fboundp 'os:groups) (fboundp 'os::%setgroups))
           (let ((g (os:groups))) ; setgroups may fail with EPERM
	     (eq g (or (ignore-errors (setf (os:groups) g)) g)))
           t) T

#+unix (listp (show (if (fboundp 'os:sysconf)
                        (os:sysconf) '(no os:sysconf)) :pretty t)) T
#+unix (listp (show (if (fboundp 'os:confstr)
                        (os:confstr) '(no os:confstr)) :pretty t)) T

#+unix (listp (show (if (fboundp 'os:pathconf)
                        (os:pathconf "/") '(no os:pathconf)) :pretty t)) T
#+unix (listp (show (if (fboundp 'os:pathconf)
                        (os:pathconf *tmp1*) '(no os:pathconf)) :pretty t)) T

#+unix
(listp (show (if (fboundp 'os:usage) (os:usage) '(no os:usage)) :pretty t))
T
#+unix
(listp (show (if (fboundp 'os:rlimit) (os:rlimit) '(no os:rlimit)) :pretty t))
T

(os:uname-p (show (os:uname) :pretty t)) T

#+unix (listp (show (os:user-info) :pretty t)) T
;; (os:user-info :default) calls getlogin which may fail in cron
#+unix (os:user-info-p
        (handler-case (show (os:user-info :default) :pretty t)
          (:error (c) (princ-error c)
                  (use-value (os:make-user-info "" "" 0 0 "" "" ""))))) T
;; some SF CF hosts (solaris, openbsd) are misconfigured:
;; user GID is 100, but there is no group with GID 100
#+unix (os:group-info-p
        (show
         (handler-bind ((error (lambda (c) (princ-error c) (use-value 0))))
           (os:group-info (os:user-info-gid (os:user-info (os:uid)))))
         :pretty t)) T
#+unix (listp (show (os:group-info) :pretty t)) T
#+unix (= (os:uid) (os:user-info-uid (os:user-info (os:uid)))) T
#+unix (= (os:gid) (os:user-info-gid (os:user-info (os:uid)))) T

(and (fboundp 'os:user-shells)
     (notevery #'stringp (show (os:user-shells)))) NIL

(os:file-stat-p (show (os:file-stat *tmp1*) :pretty t)) T
(os:file-stat-p (show (os:file-stat (pathname *tmp1*)) :pretty t)) T

#-:win32 (= (posix:file-stat-ino (os:file-stat *tmp1*))
            (posix:file-stat-ino (os:file-stat *tmp2*)))
#-:win32 NIL

#+:unix
(or (null (ext:probe-directory "/proc/"))
    (null (probe-file "/proc/kcore"))
    (plusp (posix:file-stat-size (show (posix:file-stat "/proc/kcore")))))
#+:unix T

(os:convert-mode #o0666)
(:RUSR :WUSR :RGRP :WGRP :ROTH :WOTH)

(os:convert-mode '(:RWXU :RWXG :RWXO))
#o0777

(and (fboundp 'os:stat-vfs)
     (not (os:stat-vfs-p (show (os:stat-vfs *tmp2*) :pretty t))))
NIL

;; https://sourceforge.net/p/clisp/mailman/message/20367601/
;; (FILE-OWNER *TMP1*) ==> "BUILTIN\\Administrators"
;; - local group name, which actually owns the file and includes
;; "OFFICE_DOMAIN\\Kavenchuk_Yaroslav" - a member of a windows NT domain.
;; so, if the user is not local - the test will be always broken,
;; but all functions are working correctly (in terms of MS).
#+unix
(string= (show #+win32 (ext:string-concat (ext:getenv "USERDOMAIN") "\\"
                                          (ext:getenv "USERNAME"))
               ;; $USER is void when running as root on MacOSX 10.4.11
               ;; https://sourceforge.net/p/clisp/mailman/message/22834980/
               #+unix (or (ext:getenv "USER")
                          (posix:user-info-login-id
                           (show (posix:user-info :default))))
               #-(or unix win32) ERROR)
         (show (os:file-owner *tmp1*)))
#+unix T

(progn (close *tmp1*) (close *tmp2*) T) T

(listp (show (os:copy-file *tmp1* *tmp2* :if-exists :append))) T
(listp (show (os:copy-file *tmp2* *tmp1* :if-exists :append))) T
(listp (show (os:copy-file *tmp1* *tmp2* :if-exists :append))) T
(listp (show (os:copy-file *tmp2* *tmp1* :if-exists :append))) T
(listp (show (os:copy-file *tmp1* *tmp2* :if-exists :append))) T
(listp (show (os:copy-file *tmp2* *tmp1* :if-exists :append))) T
(listp (show (os:copy-file *tmp1* *tmp2* :if-exists :append))) T
(listp (show (os:copy-file *tmp2* *tmp1* :if-exists :append))) T
(listp (show (os:copy-file *tmp1* *tmp2* :if-exists :append))) T
(listp (show (os:copy-file *tmp2* *tmp1* :if-exists :append))) T

(integerp (show (with-open-file (s *tmp1* :direction :input) (file-length s))))
T

(integerp (show (with-open-file (s *tmp2* :direction :input) (file-length s))))
T

(let ((src "src-file") (dst "dst-file"))
  (open src :direction :probe :if-does-not-exist :create) ; touch
  (open dst :direction :probe :if-does-not-exist :create) ; touch
  (unwind-protect
       (handler-case
           (multiple-value-list (os:copy-file src dst :method :rename
                                              :if-exists :error))
         (error (e) (princ-error e) :good))
    (delete-file src)
    (delete-file dst)))
:GOOD

(let ((src "src-file") (dst "dst-file") inode)
  (open src :direction :probe :if-does-not-exist :create) ; touch
  (open dst :direction :probe :if-does-not-exist :create) ; touch
  (setq inode (posix:file-stat-ino (posix:file-stat src)))
  (unwind-protect
       (progn (os:copy-file src dst :method :rename :if-exists :overwrite)
              (= inode (posix:file-stat-ino (posix:file-stat dst))))
    (delete-file src)
    (delete-file dst)))
T

;; win32 functions barf on cygwin pathnames
#+win32 (os:file-info-p (show (os:file-info *tmp2*) :pretty t)) T
#+win32 (listp (show (os:file-info (make-pathname :name "syscalls-tests-*"
                                                  :defaults *tmp2*)
                                   t)
                     :pretty t))
T

#+(or win32 cygwin)
(os:system-info-p (show (os:system-info) :pretty t))
#+(or win32 cygwin) T

#+(or win32 cygwin)
(os:version-p (show (os:version) :pretty t))
#+(or win32 cygwin) T

#+(or win32 cygwin)
(os:memory-status-p (show (os:memory-status)))
#+(or win32 cygwin) T

#+win32
(let ((filever (os:file-version (make-pathname :name "clisp" :type "exe"
                                               :defaults *lib-directory*)))
      (liv (show (lisp-implementation-version))))
  (show filever :pretty t)
  (and (string= (format nil "~D.~D~[~;+~]~[~;+~]"
                        (os:file-version-major filever)
                        (os:file-version-minor filever)
                        (os:file-version-build filever)
                        (os:file-version-revision filever))
                liv :end2 (position #\Space liv))
       (string= (os:file-version-product-version filever)
                liv :end2 (length (os:file-version-product-version filever)))))
#+win32 T

#+(or win32 cygwin) (stringp (os:get-user-sid))
#+(or win32 cygwin) T

#+(or win32 cygwin) (stringp (os:get-user-sid (ext:getenv "USERNAME")))
#+(or win32 cygwin) T

(let ((sysconf #+unix (os:sysconf) #-unix nil))
  ;; guard against broken unixes, like FreeBSD 4.10-BETA
  (if #+unix (and (getf sysconf :PAGESIZE)
                  (getf sysconf :PHYS-PAGES)
                  (getf sysconf :AVPHYS-PAGES))
      #-unix T
      (listp (show (multiple-value-list (os:physical-memory))))
      T))
T

;; test file locking
(let ((buf (make-array 100 :fill-pointer t :adjustable t
                       :element-type 'character))
      (timeout
       (let* ((uname (os:uname)))
         (cond ((and (string= (os:uname-sysname uname) "Linux")
                     (string= (os:uname-machine uname) "ppc64"))
                (format t "~&~S: increase timeout for openpower-linux1~%"
                        'flush-clisp)
                100)
               (t 1)))))
  (defun flush-clisp (stream)
    (when #-:win32 (socket:socket-status (cons stream :input) timeout)
          ;; select on win32 does not work with pipes
          #+:win32 (progn (sleep 1) (listen stream))
      ;; read from the clisp stream until the next prompt
      (setf (fill-pointer buf) 0)
      (loop :with pos-NL = 0 :for ch = (read-char stream)
        :until (and (char= ch #\Space) (char= #\[ (char buf pos-NL))
                    (let ((pos1 (position #\] buf :start pos-NL)))
                      (and pos1 (char= #\> (char buf (1+ pos1))))))
        :do (when (char= ch #\Newline) (setq pos-NL (1+ (length buf))))
        (vector-push-extend ch buf))
      (show buf))))
FLUSH-CLISP

(defun proc-send (proc fmt &rest args)
  (apply #'format proc fmt args)
  (terpri proc) (force-output proc)
  (flush-clisp proc))
PROC-SEND

(multiple-value-bind (run args) (cmd-args)
  (push "abort" args) (push "-on-error" args)
  (show (cons run args) :pretty t)
  (defparameter *proc1* (ext:run-program run :arguments args
                                         :input :stream :output :stream))
  (defparameter *proc2* (ext:run-program run :arguments args
                                         :input :stream :output :stream))
  (flush-clisp *proc1*)
  (flush-clisp *proc2*)
  t)
T

(stringp
 (proc-send *proc1* "(setq s (open ~S :direction :output :if-exists :append))"
            (truename *tmp1*)))
T
(stringp
 (proc-send *proc2* "(setq s (open ~S :direction :output :if-exists :append))"
            (truename *tmp1*)))
T

#-:no-stream-lock (read-from-string (proc-send *proc1* "(stream-lock s t)"))
#-:no-stream-lock T
#-:no-stream-lock (proc-send *proc2* "(stream-lock s t)")
#-:no-stream-lock NIL           ; blocked

#-:no-stream-lock (read-from-string (proc-send *proc1* "(stream-lock s nil)"))
#-:no-stream-lock NIL           ; released
#-:no-stream-lock (read-from-string (flush-clisp *proc2*))
#-:no-stream-lock T             ; acquired

#-:no-stream-lock (read-from-string (proc-send *proc1* "(stream-lock s t :block nil)"))
#-:no-stream-lock NIL
#-:no-stream-lock (read-from-string (proc-send *proc2* "(stream-lock s nil)"))
#-:no-stream-lock NIL           ; released
#-:no-stream-lock (read-from-string (proc-send *proc1* "(stream-lock s t :block nil)"))
#-:no-stream-lock T
#-:no-stream-lock (read-from-string (proc-send *proc1* "(stream-lock s nil)"))
#-:no-stream-lock NIL           ; released

;; reap *proc1* & *proc2* as soon as we do not need them to avoid
;; woe32 ERROR_SHARING_VIOLATION in accessing *TMP1* & *TMP2*
(progn (proc-send *proc1* "(close s)(ext:quit)")
       (close (two-way-stream-input-stream *proc1*))
       (close (two-way-stream-output-stream *proc1*))
       (close *proc1*) (symbol-cleanup '*proc1*)
       (proc-send *proc2* "(close s)(ext:quit)")
       (close (two-way-stream-input-stream *proc2*))
       (close (two-way-stream-output-stream *proc2*))
       (close *proc2*) (symbol-cleanup '*proc2*))
T

(multiple-value-list (os:sync)) ()

;; We are testing that the inode number is different for a file created with
;; :IF-EXISTS :RENAME-AND-DELETE.
;; For that, the file has to be open by another process so that the
;; inode is not immediately reused.
;; This test cannot work on woe32: a file which is open by another process
;; cannot be renamed or removed.
#-win32
(let ((inode (show (posix:file-stat-ino (posix:file-stat *tmp1*)))))
  (multiple-value-bind (run args) (cmd-args)
    (push "abort" args) (push "-on-error" args)
    (show (cons run args) :pretty t)
    (with-open-stream (s (ext:run-program run :arguments args
                                          :input :stream :output :stream))
      (flush-clisp s)
      (proc-send s (format nil "(setq s (open ~S))" (namestring *tmp1*)))
      (unwind-protect
           (with-open-file (new *tmp1* :direction :output
                                :if-exists :rename-and-delete)
             (= inode (show (posix:file-stat-ino (posix:file-stat new)))))
        (proc-send s "(close s)(ext:quit)")))))
#-win32 NIL

(let ((file "foo.bar") (dates '(3141592653 3279321753)))
  (unwind-protect
       (progn (with-open-file (s file :direction :output) (write s :stream s))
              (loop :for d :in dates :do (posix:set-file-stat file :mtime d)
                :collect (= d (with-open-file (s file) (file-write-date s)))))
    (delete-file file)))
(T T)

(posix:set-file-stat "this file does not exist" :uid (1+ (posix:uid))) ERROR

(let ((s (floor (os:file-size *tmp1*) 2)))
  (list (= s (setf (os:file-size *tmp1*) s))
        (= s (os:file-size *tmp1*))))
(T T)

(with-open-file (s *tmp2* :direction :io)
  (let ((l (floor (file-length s) 2)))
    (list (= l (setf (os:file-size s) l))
          (= l (file-length s)))))
(T T)

(listp (show (os:copy-file *tmp1* *tmp2* :method :hardlink))) T
(listp (show (os:copy-file *tmp2* *tmp1* :method :hardlink-or-copy))) T

(let ((file "foo.bar") s)
  (unwind-protect
       (progn (setq s (open file :direction :probe :if-does-not-exist :create))
              (list (os:file-size file)
                    (setf (os:file-size s) 100)
                    (os:file-size file)
                    (setf (os:file-size file) 1000)
                    (os:file-size s)))
    (delete-file file)))
(0 100 100 1000 1000)

(defparameter *foo* (os:fopen "foo" "w")) *foo*
(os::%fputc 65 *foo*) 65
(os:feof *foo*) NIL
(os:ferror *foo*) NIL
(os:clearerr *foo*) NIL
(os:fflush *foo*) NIL
(os:fclose *foo*) NIL
(defparameter *foo* (os:fopen "foo" "r")) *foo*
(os::%fgetc *foo*) 65
(os:feof *foo*) NIL
(os::%fgetc *foo*) -1
(os:feof *foo*) T
(os:ferror *foo*) NIL
(os:clearerr *foo*) NIL
(os:fclose *foo*) NIL
(finish-file "foo") 1

;; unknown errnos are reported differently on different platforms.
;; linux: "unknown error 47"
;; hurd: "Unknown error (os/?) 34742"
;;       or "(system kern) error with unknown subsystem"
;; cygwin: "error 47"
;; win32: some localized abomination
(loop :with all = (os:errno t)
  :for e :from (loop :for p :in all :for e = (car p) :minimize e)
         :to   (loop :for p :in all :for e = (car p) :maximize e)
  :do (print (list e (os:errno e) (os:strerror)))
  :finally (os:errno nil))
()

#+(or :win32 :cygwin)
(loop :with all = (os:last-error t)
  :for e :from 0 :to (loop :for p :in all :for e = (car p)
                       :when (< e #.(ash 1 16)) :maximize e)
  :do (print (list e (os:last-error e) (os:format-message)))
  :finally (os:last-error nil))
#+(or :win32 :cygwin) ()

(and (fboundp 'os:hostid) (not (integerp (show (os:hostid))))) NIL
#+unix (and (fboundp 'os::%sethostid)
            (zerop (os:euid))
            (not (= (setf (os:hostid) (os:hostid)) (os:hostid))))
#+unix NIL
(and (fboundp 'os:domainname) (not (stringp (show (os:domainname))))) NIL
#+unix (and (fboundp 'os::%setdomainname)
            (zerop (os:euid))
            (not (string= (setf (os:domainname) (os:domainname))
                          (os:domainname))))
#+unix NIL

(defun ipaddr-closure (address)
  (let ((ht (make-hash-table :test 'equalp)))
    (labels ((handle (s)
               (unless (gethash s ht)
                 (handler-bind ((error (lambda (c)
                                         (setf (gethash s ht) c)
                                         (return-from handle nil))))
                   (let ((he (os:resolve-host-ipaddr s)))
                     (setf (gethash s ht) he)
                     (handle (os:hostent-name he))
                     (mapc #'handle (os:hostent-aliases he))
                     (mapc #'handle (os:hostent-addr-list he)))))))
      (handle address))
    ht))
IPADDR-CLOSURE
(hash-table-p (show (ipaddr-closure "localhost") :pretty t)) T
(hash-table-p (show (ipaddr-closure :default) :pretty t)) T

;; wait
(defun run-sleep (sec)
  (ext::launch "sleep" :arguments (list (princ-to-string sec))
               :wait nil :output nil))
RUN-SLEEP

#+unix
(multiple-value-bind (pid kind status) (posix:wait :pid (run-sleep 1))
  (list (integerp (show pid)) kind status))
#+unix (T :EXITED 0)

#+unix
(posix:with-subprocesses
  (let ((pid-l (run-sleep 1)))
    (sleep 2)
    (multiple-value-bind (pid-w kind status) (posix:wait)
      (show (list 'pid-l pid-l 'pid-w pid-w))
      (list (= pid-l pid-w) kind status))))
#+unix (T :EXITED 0)

#+unix
(posix:with-subprocesses
  (let ((pid-l-1 (run-sleep 1))
        (pid-l-2 (run-sleep 1)))
    (sleep 2)
    (multiple-value-bind (pid-w-1 kind1 status1) (posix:wait)
      (multiple-value-bind (pid-w-2 kind2 status2) (posix:wait)
        (show (list 'pid-l-1 pid-l-1 'pid-l-2 pid-l-2
                    'pid-w-1 pid-w-1 'pid-w-2 pid-w-2))
        (list (or (and (= pid-l-1 pid-w-1) (= pid-l-2 pid-w-2))
                  (and (= pid-l-1 pid-w-2) (= pid-l-2 pid-w-1)))
              kind1 kind2 status1 status2)))))
#+unix (T :EXITED :EXITED 0 0)


#+unix (posix:wait :pid (run-sleep 1) :nohang t) #+unix 0

#+(and :unix (not :cygwin))
(let ((pid (run-sleep 1)))
  (posix:kill pid :SIGTERM)
  (multiple-value-bind (pid1 kind status rusage) (posix:wait :pid pid :usage t)
    (assert (= pid pid1) () "pid: ~S<>~S" pid pid1)
    (list kind status (posix:usage-p (show rusage)))))
#+(and :unix (not :cygwin)) (:SIGNALED :SIGTERM T)

#+(and :unix (not :cygwin))
(let ((pid (run-sleep 1)))
  (posix:kill pid :SIGSTOP)
  (multiple-value-bind (pid1 kind status) (posix:wait :pid pid :untraced t)
    (assert (= pid pid1) () "pid: ~S<>~S" pid pid1)
    (assert (eq kind :STOPPED) () "kind=~S <> :STOPPED" kind)
    (assert (eq status :SIGSTOP) () "status=~S <> :SIGCONT" status))
  (posix:kill pid :SIGCONT)
  (multiple-value-bind (pid1 kind status) (posix:wait :pid pid :continued t)
    (assert (= pid pid1) () "pid: ~S<>~S" pid pid1)
    (assert (eq kind :CONTINUED) () "kind=~S <> :CONTINUED" kind)
    (assert (null status) () "status=~S is non-NIL" status)))
#+(and :unix (not :cygwin)) NIL

(every #'sys::double-float-p
       (show (handler-case (multiple-value-list (os:loadavg))
               (error (c) (princ-error c))))) T
(every #'sys::fixnump
       (show (handler-case (multiple-value-list (os:loadavg t))
               (error (c) (princ-error c))))) T

(os:version<= "a" "b") T
(os:version< "1.10" "1.8") NIL
(os:version> "foo100" "foo99") T
(os:version>= "d" "d") T
(os:version-compare "foo" "bar") >
(os:version-compare "z" "z") =
(os:version-compare "foo2" "foo10") <

#+unix                          ; no file-tree-walk on windows
(let (res0 res1 res2)
  (ensure-directories-exist "dir1/dir2/dir3/" :verbose t)
  (open "dir1/file1" :direction :probe :if-does-not-exist :create)
  (open "dir1/dir2/file2" :direction :probe :if-does-not-exist :create)
  (open "dir1/dir2/dir3/file3" :direction :probe :if-does-not-exist :create)
  (setq res0
        (posix:file-tree-walk "dir1"
          (lambda (f s k b l)
            (print (list k f))
            (case k
              ((:D :DP :DNR) (push (list f s k b l) res1)))
            (if (= l 3) f))))
  (posix:file-tree-walk "dir1"
    (lambda (f s k b l)
      (print (list k f))
      (push (list f s k b l) res2)
      (case k
        ((:D :DP :DNR) (ext:delete-directory (ext:probe-pathname f)))
        (T (delete-file f)))
      nil)
    :depth t)
  (list
   (pathname-name res0)
   (set-exclusive-or
    (mapcar (lambda (l) (pathname-name (first l)))
            (show (nreverse res1) :pretty t))
    '("dir1" "dir2" "dir3")
    :test #'equal)
   (set-exclusive-or
    (mapcar (lambda (l)
              (list (equalp (first l) (os:file-stat-file (second l)))
                    (pathname-name (first l))
                    (third l) (fifth l)))
            (show (nreverse res2) :pretty t))
    '((T "file3" :F 3) (T "dir3" :DP 2)
      (T "file2" :F 2) (T "dir2" :DP 1)
      (T "file1" :F 1) (T "dir1" :DP 0))
    :test #'equal)
   (ext:probe-directory "dir1/")))
#+unix
("file3" NIL NIL NIL)

#+unix                          ; no file-tree-walk on windows
(let* ((d1 "syscalls-tests-dir-1")
       (d2 "syscalls-tests-dir-2")
       (f1 "syscalls-tests-file-1")
       (d (make-pathname :directory (list :relative d1 d2)))
       (f (make-pathname :name f1 :defaults d))
       (l (lambda (p) (string= f1 (pathname-name p))))
       (w (make-pathname :directory (list :relative d1 :wild-inferiors)
                         :name :wild)))
  (ensure-directories-exist d :verbose t)
  (open f :direction :probe :if-does-not-exist :create)
  (unwind-protect
      (list
        (mapcar l (directory w))
        (os:set-file-stat d :mode 0)
        (handler-case (directory w)
          (error (e) (princ-error e) (type-of e)))
        ;; https://sourceforge.net/p/clisp/mailman/message/27584189/
        (directory w :if-does-not-exist :keep) ; cannot recurse but no error
        (os:set-file-stat d :mode :RWXU)
        (mapcar l (directory w))
        (posix:file-tree-walk d1
          (lambda (f s k b l)
            (case k
              ((:D :DP :DNR) (ext:delete-directory (ext:probe-pathname f)))
              (T (delete-file f)))
            nil)
          :depth t))
    (when (ext:probe-directory d) (os:set-file-stat d :mode :RWXU))))
#+unix ((T) NIL OS-FILE-ERROR NIL NIL (T) NIL)

(fnmatch "foo" "bar") NIL

(letf (#+unicode (*misc-encoding* charset:utf-8)
       (*apropos-matcher* #'fnmatch-matcher))
  (apropos-list "FNMATCH*R"))
(POSIX:FNMATCH-MATCHER)

(fnmatch "foo*bar" "foobar") T
(fnmatch "foo*bar" "foo*bar") T
(fnmatch "foo*bar" "fooAbar") T
(fnmatch "foo*bar" "foo/bar") T
(fnmatch "foo*bar" "foo/bar" :pathname t) NIL
(fnmatch "foo*bar" "fooABAR") NIL
(fnmatch "foo*bar" "fooABAR" :case-sensitive nil) T

;; FIXME: ELOOP in DELETE-FILE when dest has no slash
(let ((dir "syscalls-tests-dir/") (dest "qwer/adsf") copy)
  (when (nth-value 1 (ensure-directories-exist dir :verbose t))
    ;; the directory is already there -- clean it up
    (mapc #'delete-file (directory (concatenate 'string dir "**")
                                   :if-does-not-exist :keep)))
  (setq copy (copy-file dest dir :method :symlink))
  (list (string= dest (caar copy))
        (string= (pathname-name dest)
                 (pathname-name (delete-file (cadar copy))))
        (ext:delete-directory dir)
        (ext:probe-pathname dir)))
(T T T NIL)

(let ((dir "syscalls-tests-dir/") (link #P"syscalls-tests-symlink/"))
  (list (ext:make-directory dir)
        (string= dir (caar (os:copy-file dir link :method :symlink)))
        (ext:delete-directory dir)
        (ext:delete-directory link)))
(T T T T)

(let ((dir "syscalls-tests-dir/") (dest "foo/bar"))
  (ext:make-directory dir)
  (os:copy-file dest dir :method :symlink)
  (handler-case (or (ext:delete-directory dir)
                    (error "deleted non-empty directory"))
    (ext:os-error (e)
      (or (eq (ext:os-error-code e)
              #+UNIX :ENOTEMPTY
              #+WIN32 :ERROR_DIR_NOT_EMPTY)
          (integerp (ext:os-error-code e)) ; for g++
          (error "wrong error code: ~s" (ext:os-error-code e)))))
  (mapc #'delete-file (directory (concatenate 'string dir "**")
                                 :if-does-not-exist :keep))
  (ext:delete-directory dir))
T

(let* ((l "my-symlink")
       (n (make-string 64 :initial-element #\a))
       (f (truename (open n :direction :probe :if-does-not-exist :create)))
       (cp (os:copy-file n l :method :symlink)))
  (list
   (list (string= n (caar cp))
         (string= l (pathname-name (cadar cp)))
         (null (cdr cp)))
   (list (equal f (truename l))
         (equal f (truename n)))
   (list (equal f (delete-file n))
         (string= l (pathname-name (delete-file l))))))
((T T T) (T T) (T T))

(let* ((l "my-symlink")
       (d (make-string 64 :initial-element #\a))
       (p (make-pathname :directory (list :relative d) :name "my-file"))
       (dp (make-pathname :name nil :defaults p)))
  (ensure-directories-exist dp)
  (open p :direction :probe :if-does-not-exist :create)
  (os:copy-file p (ext:absolute-pathname l) :method :symlink)
  (list
   (equal (truename l) (delete-file p))
   (ext:delete-directory dp)
   (string= l (pathname-name (delete-file l)))))
(T T T)

;; copy-file merges source file type into the destination
(defparameter *csv1* "my-tmp-1.csv") *csv1*
(defparameter *csv2* "my-tmp-2") *csv2*
(defparameter *csv3* (concatenate 'string *csv2* ".csv")) *csv3*
(delete-file *csv1*) NIL
(delete-file *csv2*) NIL
(delete-file *csv3*) NIL
(progn
  (open *csv1* :direction :probe :if-does-not-exist :create)
  (os:copy-file *csv1* *csv2*)  ; creates *csv3*
  (list (probe-file *csv2*)
        (null (delete-file *csv3*))))
(NIL NIL)
(progn
  (os:copy-file (make-pathname :name *csv1*) *csv2*)  ; creates *csv2*
  (list (null (delete-file *csv1*))
        (probe-file *csv3*)
        (null (delete-file *csv2*))))
(NIL NIL NIL)


(progn
  (delete-file *tmp1*) (delete-file *tmp2*)
  (setq *features* (delete :no-stream-lock *features*))
  (symbols-cleanup '(*tmp1* *tmp2* flush-clisp proc-send check-time-date)))
()
